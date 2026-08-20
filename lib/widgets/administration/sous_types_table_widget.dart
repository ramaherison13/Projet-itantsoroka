import 'package:flutter/material.dart';
import 'package:itantsoroka/core/admin_theme.dart';

class SousTypesTableWidget extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() getAllSousType;
  final Future<Map<String, dynamic>> Function() getAllType;
  final Future<void> Function(Map<String, dynamic> data) createSousType;
  final Future<void> Function(dynamic id, Map<String, dynamic> data) editSousType;
  final Future<void> Function(dynamic id) deleteSousType;

  const SousTypesTableWidget({
    super.key,
    required this.getAllSousType,
    required this.getAllType,
    required this.createSousType,
    required this.editSousType,
    required this.deleteSousType,
  });

  @override
  SousTypesTableWidgetState createState() => SousTypesTableWidgetState();
}

class SousTypesTableWidgetState extends State<SousTypesTableWidget> {
  List<dynamic> _data = [];
  List<dynamic> _filteredData = [];
  List<dynamic> _types = [];
  bool _loading = true;
  bool _submitting = false;
  String _searchTerm = "";
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  bool _showModal = false;
  String _modalMode = "add"; // "add" or "edit"
  dynamic _selectedSousType;

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _delaiController;
  late TextEditingController _searchController;
  dynamic _selectedTypeId;
  bool _estActif = true;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _descriptionController = TextEditingController();
    _delaiController = TextEditingController();
    _searchController = TextEditingController();
    _fetchAllData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _delaiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() => _loading = true);
    try {
      final sousTypesRes = await widget.getAllSousType();
      final typesRes = await widget.getAllType();

      if (mounted) {
        setState(() {
          _data = sousTypesRes['data'] ?? [];
          _types = typesRes['data'] ?? [];
          _filterData();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des sous-types: $e");
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
        final typeNom = (item['acte_type']?['nom'] ?? '').toString().toLowerCase();
        final search = _searchTerm.toLowerCase();
        return nom.contains(search) || description.contains(search) || typeNom.contains(search);
      }).toList();
    }
    _currentPage = 1;
  }

  void _openAddModal() {
    setState(() {
      _modalMode = "add";
      _nomController.text = "";
      _descriptionController.text = "";
      _delaiController.text = "10";
      _selectedTypeId = _types.isNotEmpty ? (_types.first['id'] ?? _types.first['type_id']) : null;
      _estActif = true;
      _selectedSousType = null;
      _showModal = true;
    });
  }

  void _openEditModal(dynamic item) {
    setState(() {
      _modalMode = "edit";
      _nomController.text = item['nom'] ?? '';
      _descriptionController.text = item['description'] ?? '';
      _delaiController.text = (item['delai_traitement_jours'] ?? 10).toString();
      _selectedTypeId = item['acte_type_id'] ?? item['acte_type']?['id'];
      _estActif = item['active'] ?? true;
      _selectedSousType = item;
      _showModal = true;
    });
  }

  void _closeModal() {
    setState(() {
      _showModal = false;
      _nomController.text = "";
      _descriptionController.text = "";
      _delaiController.text = "";
      _selectedSousType = null;
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
      'delai_traitement_jours': int.tryParse(_delaiController.text) ?? 10,
      'acte_type_id': _selectedTypeId,
      'active': _estActif,
    };

    try {
      if (_modalMode == "add") {
        await widget.createSousType(formData);
      } else {
        final id = _selectedSousType?['id'] ?? _selectedSousType?['sous_type_id'];
        await widget.editSousType(id, formData);
      }

      if (!mounted) return;
      _closeModal();
      await _fetchAllData();
    } catch (e) {
      debugPrint("Erreur lors de la soumission du sous-type: $e");
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
        content: const Text('Voulez-vous vraiment supprimer ce sous-type d\'acte ?'),
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
      await widget.deleteSousType(id);
      if (!mounted) return;
      await _fetchAllData();
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
                // En-tête & Recherche
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
                                "Sous-Types",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AdminTheme.badge("${_filteredData.length}", AdminTheme.purple),
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
                              isMobile ? "Ajouter" : "Ajouter un sous-type",
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
                          hintText: "Rechercher par nom, description ou type...",
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

                // Liste sous-types responsive (PAS de débordement horizontal !)
                if (currentItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        "Aucun sous-type d'acte trouvé",
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
                      final nom = item['nom'] ?? 'Sans nom';
                      final description = item['description'] ?? '';
                      final typeNom = item['acte_type']?['nom'] ?? 'Type général';
                      final delai = item['delai_traitement_jours'] ?? 0;
                      final isActive = item['active'] == true;

                      return Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ligne 1 : Nom du sous-type + Actions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AdminTheme.purple.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                                  ),
                                  child: const Icon(
                                    Icons.layers_rounded,
                                    size: 16,
                                    color: AdminTheme.purple,
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
                                      onPressed: () => _handleDelete(item['id'] ?? item['sous_type_id']),
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

                            const SizedBox(height: 10),

                            // Ligne 2 : Badges réactifs via Wrap (ne déborde JAMAIS !)
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AdminTheme.badge(typeNom, AdminTheme.purple),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AdminTheme.surface2Dark : AdminTheme.dividerLight,
                                    borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
                                    border: Border.all(
                                      color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 12,
                                        color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$delai jour(s)",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AdminTheme.badge(
                                  isActive ? "Actif" : "Inactif",
                                  isActive ? AdminTheme.primaryLight : AdminTheme.danger,
                                ),
                              ],
                            ),
                          ],
                        ),
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
                            _modalMode == "add" ? "Ajouter un sous-type" : "Modifier le sous-type",
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
                        maxLines: 2,
                        style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Description *",
                          labelStyle: TextStyle(fontSize: 13, color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_types.isNotEmpty)
                        DropdownButtonFormField<dynamic>(
                          initialValue: _selectedTypeId,
                          style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, fontSize: 14),
                          dropdownColor: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                          decoration: InputDecoration(
                            labelText: "Type parent *",
                            labelStyle: TextStyle(fontSize: 13, color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _types.map<DropdownMenuItem<dynamic>>((t) {
                            final id = t['id'] ?? t['type_id'];
                            return DropdownMenuItem<dynamic>(
                              value: id,
                              child: Text(t['nom'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedTypeId = val),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _delaiController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Délai de traitement (jours)",
                          labelStyle: TextStyle(fontSize: 13, color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(
                          "Actif",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                          ),
                        ),
                        activeThumbColor: AdminTheme.primary,
                        value: _estActif,
                        onChanged: (val) => setState(() => _estActif = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
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