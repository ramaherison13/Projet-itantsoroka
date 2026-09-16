import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';

// ── Écran d'édition de publication ──────────────────────────────────────────

class EditPublicationScreen extends StatefulWidget {
  final String type; // 'event' ou 'project'
  final String id;

  const EditPublicationScreen({
    super.key,
    required this.type,
    required this.id,
  });

  @override
  State<EditPublicationScreen> createState() => _EditPublicationScreenState();
}

class _EditPublicationScreenState extends State<EditPublicationScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic> _data = {};

  // ── Contrôleurs de texte ─────────────────────────────────────────────────

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();

  String _visibility = 'public';
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _deadlineController.dispose();
    _budgetController.dispose();
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // ── Chargement des données existantes ───────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String url = widget.type == 'event'
          ? '${ApiConstants.servicePublication}/events/${widget.id}'
          : '${ApiConstants.serviceProjet}/projects/${widget.id}';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final raw = json.decode(response.body);
        final Map<String, dynamic> item =
            raw is Map<String, dynamic> && raw.containsKey('data')
                ? (raw['data'] as Map<String, dynamic>)
                : (raw as Map<String, dynamic>);

        setState(() {
          _data = item;
          _prefillControllers(item);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Impossible de charger la publication (code ${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur réseau : $e';
        _isLoading = false;
      });
    }
  }

  // ── Pré-remplissage des champs ──────────────────────────────────────────

  String _extractString(dynamic val) {
    if (val == null) return '';
    if (val is String) return val;
    if (val is Map) {
      return val['fr']?.toString() ??
          val['mg']?.toString() ??
          val.values.first?.toString() ??
          '';
    }
    return val.toString();
  }

  void _prefillControllers(Map<String, dynamic> item) {
    if (widget.type == 'event') {
      _titleController.text = _extractString(item['title']);
      _descController.text = _extractString(item['description']);
      _startDateController.text =
          (item['startDate'] ?? item['start_date'] ?? '').toString();
      _endDateController.text =
          (item['endDate'] ?? item['end_date'] ?? '').toString();
      _visibility = (item['visibility'] ?? 'public').toString();
    } else {
      _nameController.text = _extractString(item['name']);
      _descController.text = _extractString(item['description']);
      _startDateController.text =
          (item['startDate'] ?? item['start_date'] ?? '').toString();
      _deadlineController.text = (item['deadline'] ?? '').toString();
      _budgetController.text =
          (item['budget'] ?? '0').toString();
      _status = _extractString(item['status']).isNotEmpty
          ? _extractString(item['status'])
          : 'draft';
    }
  }

  // ── Sauvegarde via PUT ──────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;

    final String titleOrName = widget.type == 'event'
        ? _titleController.text.trim()
        : _nameController.text.trim();

    if (titleOrName.isEmpty) {
      _showError(widget.type == 'event'
          ? 'Le titre est obligatoire.'
          : 'Le nom du projet est obligatoire.');
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showError('La description est obligatoire.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String url = widget.type == 'event'
          ? '${ApiConstants.servicePublication}/events/${widget.id}'
          : '${ApiConstants.serviceProjet}/projects/${widget.id}';

      final Map<String, dynamic> payload = widget.type == 'event'
          ? {
              'title': _titleController.text.trim(),
              'description': _descController.text.trim(),
              'startDate': _startDateController.text.trim(),
              'endDate': _endDateController.text.trim(),
              'visibility': _visibility,
            }
          : {
              'name': _nameController.text.trim(),
              'description': _descController.text.trim(),
              'startDate': _startDateController.text.trim(),
              'deadline': _deadlineController.text.trim(),
              'budget': double.tryParse(_budgetController.text) ?? 0.0,
              'status': _status,
            };

      http.Response response = await http
          .patch(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await http
            .put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(payload),
            )
            .timeout(const Duration(seconds: 10));
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publication modifiée avec succès !'),
              backgroundColor: Color(0xFF098E00),
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/itantsorika/gererPublication');
          });
        }
      } else {
        _showError(
            'Erreur lors de la sauvegarde (code ${response.statusCode}) : ${response.body}');
      }
    } catch (e) {
      _showError('Erreur réseau lors de la sauvegarde : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  // ── Sélecteur de date ───────────────────────────────────────────────────

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initial = DateTime.now();
    try {
      if (controller.text.isNotEmpty) {
        initial = DateTime.parse(controller.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isEvent = widget.type == 'event';

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _data.isEmpty
              ? _buildErrorState()
              : _buildBody(isDarkMode, isEvent),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Erreur inconnue',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF098E00),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDarkMode, bool isEvent) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF098E00),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.go('/itantsorika/gererPublication'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 14, right: 16),
              title: Text(
                isEvent
                    ? 'Modifier l\'événement'
                    : 'Modifier le projet',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF098E00), Color(0xFF076D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu du formulaire ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Bannière erreur / succès ─────────────────────────
                      if (_errorMessage != null)
                        _buildBanner(_errorMessage!, Colors.red),
                      if (_successMessage != null)
                        _buildBanner(_successMessage!, const Color(0xFF098E00)),

                      // ── Badge type ───────────────────────────────────────
                      _buildTypeBadge(isEvent, isDarkMode),
                      const SizedBox(height: 20),

                      // ── Card formulaire ──────────────────────────────────
                      _buildFormCard(isDarkMode, isEvent),
                      const SizedBox(height: 24),

                      // ── Boutons action ───────────────────────────────────
                      _buildActionButtons(isDarkMode),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String msg, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.red ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(bool isEvent, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isEvent ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6))
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isEvent ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6))
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEvent ? Icons.event_rounded : Icons.work_rounded,
            size: 16,
            color:
                isEvent ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 8),
          Text(
            isEvent ? 'Événement' : 'Projet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  isEvent ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• ID: ${widget.id}',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isDarkMode, bool isEvent) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête card ─────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: const Color(0xFF098E00),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Informations de la publication',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode
                        ? Colors.white
                        : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // ── Champs formulaire ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEvent) ...[
                  _buildField(
                    label: 'Titre *',
                    controller: _titleController,
                    icon: Icons.title_rounded,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildField(
                    label: 'Nom du projet *',
                    controller: _nameController,
                    icon: Icons.work_outline_rounded,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                ],

                _buildField(
                  label: 'Description *',
                  controller: _descController,
                  icon: Icons.description_outlined,
                  maxLines: 5,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 20),

                // ── Dates ─────────────────────────────────────────────────
                LayoutBuilder(builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 500;
                  final startField = _buildDateField(
                    label: 'Date de début',
                    controller: _startDateController,
                    isDarkMode: isDarkMode,
                  );
                  final endField = _buildDateField(
                    label: isEvent ? 'Date de fin' : 'Date limite (deadline)',
                    controller:
                        isEvent ? _endDateController : _deadlineController,
                    isDarkMode: isDarkMode,
                  );
                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: startField),
                            const SizedBox(width: 16),
                            Expanded(child: endField),
                          ],
                        )
                      : Column(children: [
                          startField,
                          const SizedBox(height: 16),
                          endField,
                        ]);
                }),
                const SizedBox(height: 20),

                if (isEvent) ...[
                  // ── Visibilité ───────────────────────────────────────────
                  _buildSectionLabel('Visibilité', isDarkMode),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _visibility,
                    items: const ['public', 'private', 'restricted'],
                    labels: const ['Public', 'Privé', 'Restreint'],
                    onChanged: (v) => setState(() => _visibility = v!),
                    isDarkMode: isDarkMode,
                  ),
                ] else ...[
                  // ── Statut + Budget ──────────────────────────────────────
                  LayoutBuilder(builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth > 500;
                    final statusWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Statut', isDarkMode),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: _status,
                          items: const [
                            'draft',
                            'active',
                            'completed',
                            'cancelled'
                          ],
                          labels: const [
                            'Brouillon',
                            'Actif',
                            'Terminé',
                            'Annulé'
                          ],
                          onChanged: (v) => setState(() => _status = v!),
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    );
                    final budgetWidget = _buildField(
                      label: 'Budget (Ar)',
                      controller: _budgetController,
                      icon: Icons.savings_outlined,
                      keyboardType: TextInputType.number,
                      isDarkMode: isDarkMode,
                    );
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: statusWidget),
                              const SizedBox(width: 16),
                              Expanded(child: budgetWidget),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              statusWidget,
                              const SizedBox(height: 16),
                              budgetWidget,
                            ],
                          );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/itantsorika/gererPublication'),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Annuler'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDarkMode
                ? Colors.grey.shade300
                : const Color(0xFF475569),
            side: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF475569)
                  : const Color(0xFFCBD5E1),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF098E00),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // ── Widgets de saisie ───────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF475569),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, isDarkMode),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, size: 18, color: const Color(0xFF098E00)),
            filled: true,
            fillColor: isDarkMode
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF098E00), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, isDarkMode),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _pickDate(controller),
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today_rounded,
                size: 18, color: Color(0xFF098E00)),
            hintText: 'YYYY-MM-DD',
            hintStyle: TextStyle(
              color: isDarkMode
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
              fontSize: 13,
            ),
            filled: true,
            fillColor: isDarkMode
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF098E00), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required List<String> labels,
    required ValueChanged<String?> onChanged,
    required bool isDarkMode,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      onChanged: onChanged,
      dropdownColor:
          isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(
        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode
                ? const Color(0xFF334155)
                : const Color(0xFFCBD5E1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode
                ? const Color(0xFF334155)
                : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF098E00), width: 1.5),
        ),
      ),
      items: List.generate(
        items.length,
        (i) => DropdownMenuItem(
          value: items[i],
          child: Text(labels[i]),
        ),
      ),
    );
  }
}
