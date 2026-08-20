import 'package:flutter/material.dart';
import 'package:itantsoroka/core/admin_theme.dart';

class TypesTableWidget extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() getAllType;
  final Future<void> Function(Map<String, dynamic> data) createType;
  final Future<void> Function(dynamic id, Map<String, dynamic> data) editType;
  final Future<void> Function(dynamic id) deleteType;

  const TypesTableWidget({
    super.key,
    required this.getAllType,
    required this.createType,
    required this.editType,
    required this.deleteType,
  });

  @override
  TypesTableWidgetState createState() => TypesTableWidgetState();
}

class TypesTableWidgetState extends State<TypesTableWidget> {
  List<dynamic> _data = [];
  List<dynamic> _filteredData = [];
  bool _submitting = false;
  String _searchTerm = "";
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  final Set<String> _expandedRows = {};
  bool _loading = true;
  bool _showModal = false;
  String _modalMode = "add"; // "add" or "edit"
  dynamic _selectedType;

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _descriptionController = TextEditingController();
    _searchController = TextEditingController();
    _fetchAllTypes();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllTypes() async {
    try {
      final res = await widget.getAllType();
      if (!mounted) return;
      if (res.containsKey('data')) {
        setState(() {
          _data = res['data'] ?? [];
          _filterData();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des types: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterData() {
    if (_searchTerm.isEmpty) {
      _filteredData = List.from(_data);
    } else {
      _filteredData = _data.where((item) {
        final nom = (item['nom'] ?? '').toString().toLowerCase();
        final description = (item['description'] ?? '').toString().toLowerCase();
        final search = _searchTerm.toLowerCase();
        return nom.contains(search) || description.contains(search);
      }).toList();
    }
    _currentPage = 1;
  }

  void _toggleRow(String id) {
    setState(() {
      if (_expandedRows.contains(id)) {
        _expandedRows.remove(id);
      } else {
        _expandedRows.add(id);
      }
    });
  }

  void _openAddModal() {
    setState(() {
      _modalMode = "add";
      _nomController.text = "";
      _descriptionController.text = "";
      _selectedType = null;
      _showModal = true;
    });
  }

  void _openEditModal(dynamic item) {
    setState(() {
      _modalMode = "edit";
      _nomController.text = item['nom'] ?? '';
      _descriptionController.text = item['description'] ?? '';
      _selectedType = item;
      _showModal = true;
    });
  }

  void _closeModal() {
    setState(() {
      _showModal = false;
      _nomController.text = "";
      _descriptionController.text = "";
      _selectedType = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (_nomController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      return;
    }

    if (mounted) setState(() => _submitting = true);

    final formData = {
      'nom': _nomController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    try {
      if (_modalMode == "add") {
        await widget.createType(formData);
      } else {
        final id = _selectedType?['id'] ?? _selectedType?['type_id'];
        await widget.editType(id, formData);
      }

      if (!mounted) return;
      _closeModal();
      setState(() => _loading = true);
      await _fetchAllTypes();
    } catch (e) {
      debugPrint("Erreur lors de la soumission: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleDelete(dynamic id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce type d\'acte ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) setState(() => _loading = true);
    try {
      await widget.deleteType(id);
      if (!mounted) return;
      await _fetchAllTypes();
    } catch (e) {
      debugPrint("Erreur lors de la suppression: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool isMobile = context.isMobile;

    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AdminTheme.primary),
        ),
      );
    }

    final totalPages = (_filteredData.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < _filteredData.length)
        ? startIndex + _itemsPerPage
        : _filteredData.length;
    final currentItems = _filteredData.isNotEmpty
        ? _filteredData.sublist(startIndex, endIndex > startIndex ? endIndex : startIndex)
        : [];

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
              boxShadow: AdminTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête & Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Types",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AdminTheme.badge("${_filteredData.length}", AdminTheme.primary),
                            ],
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AdminTheme.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                              ),
                            ),
                            onPressed: _openAddModal,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              isMobile ? "Ajouter" : "Ajouter un type",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchTerm = value;
                            _filterData();
                          });
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: "Rechercher par nom ou description...",
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                            borderSide: BorderSide(
                              color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                            borderSide: BorderSide(
                              color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Liste responsive
                if (currentItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        "Aucun type d'acte trouvé",
                        style: TextStyle(
                          color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentItems.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final item = currentItems[index];
                      final idStr = (item['id'] ?? item['type_id'] ?? index).toString();
                      final isExpanded = _expandedRows.contains(idStr);
                      final sousTypes = item['sous_types'] is List ? item['sous_types'] as List : [];
                      final nom = item['nom'] ?? 'Sans nom';
                      final description = item['description'] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ligne 1 : Nom + Actions
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AdminTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                                      ),
                                      child: const Icon(
                                        Icons.label_rounded,
                                        size: 16,
                                        color: AdminTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        nom,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (sousTypes.isNotEmpty)
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up_rounded
                                                  : Icons.keyboard_arrow_down_rounded,
                                              color: AdminTheme.info,
                                            ),
                                            onPressed: () => _toggleRow(idStr),
                                            tooltip: isExpanded ? 'Masquer sous-types' : 'Voir sous-types',
                                          ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(Icons.edit_rounded, size: 18, color: AdminTheme.primary),
                                          onPressed: () => _openEditModal(item),
                                          tooltip: 'Modifier',
                                        ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AdminTheme.danger),
                                          onPressed: () => _handleDelete(item['id'] ?? item['type_id']),
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 8),

                                // Ligne 2 : Badges
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    AdminTheme.badge(
                                      "${sousTypes.length} sous-type(s)",
                                      sousTypes.isNotEmpty ? AdminTheme.info : AdminTheme.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Bloc sous-types déplié
                          if (isExpanded && sousTypes.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              color: isDark
                                  ? AdminTheme.bgDark.withValues(alpha: 0.5)
                                  : AdminTheme.bgLight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sous-types associés (${sousTypes.length}) :",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...sousTypes.map((st) {
                                    final stNom = st['nom'] ?? '';
                                    final stDesc = st['description'] ?? '';
                                    final stDelai = st['delai_traitement_jours'] ?? 0;
                                    final stActive = st['active'] == true;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                                        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                                        border: Border.all(
                                          color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  stNom,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              AdminTheme.badge(
                                                stActive ? "Actif" : "Inactif",
                                                stActive ? AdminTheme.primaryLight : AdminTheme.danger,
                                              ),
                                            ],
                                          ),
                                          if (stDesc.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              stDesc,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            "Délai de traitement : $stDelai jour(s)",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                // Pagination
                if (_filteredData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          "${startIndex + 1}–${endIndex > startIndex ? endIndex : startIndex} sur ${_filteredData.length}",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                              icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            ),
                            Text(
                              "Page $_currentPage / ${totalPages == 0 ? 1 : totalPages}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                              icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Modal d'ajout / modification
        if (_showModal)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: Dialog(
                backgroundColor: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _modalMode == "add" ? "Ajouter un type" : "Modifier le type",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: _closeModal,
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nomController,
                        style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Nom *",
                          labelStyle: TextStyle(fontSize: 13, color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Description *",
                          labelStyle: TextStyle(fontSize: 13, color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _closeModal,
                            child: const Text("Annuler"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _submitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_modalMode == "add" ? "Ajouter" : "Enregistrer"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}