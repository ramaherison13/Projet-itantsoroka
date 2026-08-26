import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/l10n/app_localization.dart';

// -----------------------------------------------------------------------------
// MODÈLE DE DONNÉES
// -----------------------------------------------------------------------------
class NavigationItem {
  final int? navigationId;
  final String navigationLabelKey;
  final String navigationPath;
  final String navigationIcon;
  final List<String> requiredRoles;
  final String? navigationComponent;
  final bool navigationShow;
  final String? navigationCategory;
  final int navigationOrder;
  final int appId;

  NavigationItem({
    this.navigationId,
    required this.navigationLabelKey,
    required this.navigationPath,
    required this.navigationIcon,
    required this.requiredRoles,
    this.navigationComponent,
    required this.navigationShow,
    this.navigationCategory,
    required this.navigationOrder,
    required this.appId,
  });

  factory NavigationItem.fromJson(Map<String, dynamic> json, int defaultAppId) {
    var rawRoles = json['requiredRoles'] as List? ?? json['roles'] as List? ?? [];
    List<String> roles = rawRoles.map((r) => r.toString()).toList();

    return NavigationItem(
      navigationId: json['navigation_id'] ?? json['id'],
      navigationLabelKey: json['nameKey'] ?? json['navigation_label_key'] ?? json['name_key'] ?? '',
      navigationPath: json['path'] ?? json['navigation_path'] ?? '',
      navigationIcon: json['icon'] ?? json['navigation_icon'] ?? 'icons/default.png',
      requiredRoles: roles,
      navigationComponent: json['component'] ?? json['navigation_component'],
      navigationShow: json['isShow'] ?? json['navigation_show'] ?? json['is_show'] ?? true,
      navigationCategory: json['category'] ?? json['navigation_category'],
      navigationOrder: json['order'] ?? json['navigation_order'] ?? 0,
      appId: json['app_id'] ?? defaultAppId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'navigation_label_key': navigationLabelKey,
      'navigation_path': navigationPath,
      'navigation_icon': navigationIcon,
      'requiredRoles': requiredRoles,
      'navigation_component': navigationComponent,
      'navigation_show': navigationShow,
      'navigation_category': navigationCategory,
      'navigation_order': navigationOrder,
      'app_id': appId,
    };
  }
}

// -----------------------------------------------------------------------------
// PAGE PRINCIPALE : NAVIGATION PAGE
// -----------------------------------------------------------------------------
class NavigationPage extends StatefulWidget {
  final String baseUrl;
  final int appId;

  const NavigationPage({
    super.key,
    this.baseUrl = ApiConstants.serviceAuth,
    this.appId = 8,
  });

  @override
  NavigationPageState createState() => NavigationPageState();
}

class NavigationPageState extends State<NavigationPage> {
  List<NavigationItem> _navigationItems = [];
  NavigationItem? _editingItem;
  bool _loading = false;
  String? _error;

  // États des filtres et contrôles
  String _searchQuery = "";
  String _viewMode = "auto"; // "auto", "table", "cards"
  String _filterCategory = "all";
  String _filterVisibility = "all"; // "all", "visible", "hidden"
  String _filterRole = "all";
  String _sortBy = "order"; // "order", "label", "category"

  @override
  void initState() {
    super.initState();
    _fetchNavigation();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('access_token');
    if (raw == null) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map && parsed.containsKey('access_token')) {
        return parsed['access_token'];
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _fetchNavigation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final endpoints = [
        '${widget.baseUrl}/navigation/by-app/${widget.appId}',
        '${widget.baseUrl}/navigation/app/${widget.appId}',
        '${widget.baseUrl}/navigation/by-application/${widget.appId}',
        '${widget.baseUrl}/navigation',
      ];

      http.Response? res;
      for (final endpoint in endpoints) {
        try {
          final r = await http.get(Uri.parse(endpoint), headers: headers);
          if (r.statusCode >= 200 && r.statusCode < 300) {
            res = r;
            break;
          }
        } catch (_) {}
      }

      if (res != null && res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic decoded = jsonDecode(res.body);
        final List rawList = decoded is List
            ? decoded
            : (decoded['data'] ?? decoded['navigation'] ?? decoded['navigations'] ?? []);
        setState(() {
          _navigationItems = rawList
              .map((item) => NavigationItem.fromJson(item, widget.appId))
              .toList();
        });
      } else {
        setState(() => _error = "Erreur lors du chargement des navigations");
      }
    } catch (err) {
      setState(() => _error = "Erreur réseau lors du chargement des navigations");
      debugPrint("Erreur navigation: $err");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleSave(NavigationItem itemToSave) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      if (_editingItem?.navigationId != null) {
        http.Response res = await http.patch(
          Uri.parse('${widget.baseUrl}/navigation/${_editingItem!.navigationId}'),
          headers: headers,
          body: jsonEncode(itemToSave.toJson()),
        );

        if (res.statusCode < 200 || res.statusCode >= 300) {
          res = await http.put(
            Uri.parse('${widget.baseUrl}/navigation/${_editingItem!.navigationId}'),
            headers: headers,
            body: jsonEncode(itemToSave.toJson()),
          );
        }

        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception("Échec de la mise à jour");
        }
      } else {
        final res = await http.post(
          Uri.parse('${widget.baseUrl}/navigation'),
          headers: headers,
          body: jsonEncode(itemToSave.toJson()),
        );

        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception("Échec de la création");
        }
      }

      setState(() {
        _editingItem = null;
      });
      if (!mounted) return;
      Navigator.pop(context);
      await _fetchNavigation();
    } catch (err) {
      setState(() => _error = "Erreur lors de l'enregistrement de la navigation");
      debugPrint("Erreur enregistrement navigation: $err");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openEditModal(NavigationItem item) {
    setState(() => _editingItem = item);
    _showNavigationFormModal();
  }

  void _openAddModal() {
    setState(() => _editingItem = null);
    _showNavigationFormModal();
  }

  void _showNavigationFormModal() {
    final bool isDark = context.isDark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editingItem != null ? "Modifier la navigation" : "Ajouter une navigation",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              NavigationFormWidget(
                editingItem: _editingItem,
                onSave: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calcul des listes filtrées
  List<String> get _categories {
    final cats = _navigationItems.map((e) => e.navigationCategory).whereType<String>().toSet();
    return cats.toList();
  }

  List<String> get _roles {
    final rolesSet = _navigationItems.expand((e) => e.requiredRoles).toSet();
    final list = rolesSet.toList();
    list.sort();
    return list;
  }

  List<NavigationItem> get _filteredItems {
    var filtered = List<NavigationItem>.from(_navigationItems);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
          item.navigationLabelKey.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.navigationPath.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_filterCategory != "all") {
      filtered = filtered.where((item) => item.navigationCategory == _filterCategory).toList();
    }

    if (_filterVisibility == "visible") {
      filtered = filtered.where((item) => item.navigationShow).toList();
    } else if (_filterVisibility == "hidden") {
      filtered = filtered.where((item) => !item.navigationShow).toList();
    }

    if (_filterRole != "all") {
      filtered = filtered.where((item) => item.requiredRoles.contains(_filterRole)).toList();
    }

    filtered.sort((a, b) {
      if (_sortBy == "order") {
        return a.navigationOrder.compareTo(b.navigationOrder);
      } else if (_sortBy == "label") {
        return a.navigationLabelKey.compareTo(b.navigationLabelKey);
      } else {
        return (a.navigationCategory ?? "").compareTo(b.navigationCategory ?? "");
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool isMobile = context.isMobile;
    final double hPad = AdminTheme.horizontalPadding(context);
    final items = _filteredItems;

    final useCards = _viewMode == "cards" || (_viewMode == "auto" && isMobile);

    return Scaffold(
      backgroundColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ──────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 20, hPad, 16),
                decoration: BoxDecoration(
                  color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFBE185D), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                      ),
                      child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('nav_gestion_titre'),
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (!isMobile)
                            Text(
                              context.tr('nav_gestion_sous_titre'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: _fetchNavigation,
                      tooltip: context.tr('actualiser'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                        ),
                      ),
                      onPressed: _openAddModal,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: isMobile
                          ? const SizedBox.shrink()
                          : Text(context.tr('nav_ajouter'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Message d'erreur
              if (_error != null)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminTheme.danger.withValues(alpha: 0.1),
                    border: Border.all(color: AdminTheme.danger.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AdminTheme.danger, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: AdminTheme.danger, fontSize: 13)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AdminTheme.danger),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // ── Barre de recherche & Filtres ────────────────────────
              Container(
                margin: EdgeInsets.symmetric(horizontal: hPad),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  border: Border.all(
                    color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                  ),
                  boxShadow: AdminTheme.shadowSm,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Champ de recherche
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: "Rechercher une navigation...",
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
                        ),
                        const SizedBox(width: 10),
                        // Bascule Table / Cartes
                        ToggleButtons(
                          isSelected: [!useCards, useCards],
                          onPressed: (index) {
                            setState(() => _viewMode = index == 0 ? "table" : "cards");
                          },
                          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                          selectedColor: Colors.white,
                          color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                          fillColor: AdminTheme.primary,
                          borderColor: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                          selectedBorderColor: AdminTheme.primary,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                          children: const [
                            Icon(Icons.table_rows_rounded, size: 18),
                            Icon(Icons.grid_view_rounded, size: 18),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Filtres déroulants réactifs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterDropdown(
                            isDark: isDark,
                            value: _filterCategory,
                            items: [
                              const DropdownMenuItem(value: "all", child: Text("Toutes catégories")),
                              ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                            ],
                            onChanged: (val) => setState(() => _filterCategory = val ?? "all"),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                            isDark: isDark,
                            value: _filterVisibility,
                            items: const [
                              DropdownMenuItem(value: "all", child: Text("Visibilité : Tous")),
                              DropdownMenuItem(value: "visible", child: Text("Visibles")),
                              DropdownMenuItem(value: "hidden", child: Text("Masqués")),
                            ],
                            onChanged: (val) => setState(() => _filterVisibility = val ?? "all"),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                            isDark: isDark,
                            value: _filterRole,
                            items: [
                              const DropdownMenuItem(value: "all", child: Text("Tous les rôles")),
                              ..._roles.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                            ],
                            onChanged: (val) => setState(() => _filterRole = val ?? "all"),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                            isDark: isDark,
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(value: "order", child: Text("Trier: Ordre")),
                              DropdownMenuItem(value: "label", child: Text("Trier: Nom")),
                              DropdownMenuItem(value: "category", child: Text("Trier: Catégorie")),
                            ],
                            onChanged: (val) => setState(() => _sortBy = val ?? "order"),
                          ),
                          const SizedBox(width: 8),
                          AdminTheme.badge("${items.length} élément(s)", AdminTheme.pink),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Zone de contenu ────────────────────────────────────
              if (_loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AdminTheme.primary),
                  ),
                )
              else if (!useCards)
                _buildTableView(items, isDark, hPad)
              else
                _buildCardsView(items, isDark, hPad),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required bool isDark,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
          ),
          dropdownColor: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(List<NavigationItem> items, bool isDark, double hPad) {
    if (items.isEmpty) {
      return _buildEmpty(isDark);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? AdminTheme.surface2Dark : AdminTheme.dividerLight,
          ),
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
          ),
          columns: [
            DataColumn(label: Text(context.tr('nav_ordre'))),
            DataColumn(label: Text(context.tr('nav_label'))),
            DataColumn(label: Text(context.tr('nav_chemin'))),
            DataColumn(label: Text(context.tr('nav_categorie'))),
            DataColumn(label: Text(context.tr('nav_statut'))),
            DataColumn(label: Text(context.tr('nav_roles_requis'))),
            DataColumn(label: Text("ACTION")),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AdminTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item.navigationOrder.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primary, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    item.navigationLabelKey,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    item.navigationPath,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                    ),
                  ),
                ),
                DataCell(
                  item.navigationCategory != null && item.navigationCategory!.isNotEmpty
                      ? AdminTheme.badge(item.navigationCategory!, AdminTheme.purple)
                      : Text("-", style: TextStyle(color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted)),
                ),
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.navigationShow ? AdminTheme.primaryLight : AdminTheme.danger,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.navigationShow ? "Visible" : "Masqué",
                        style: TextStyle(
                          fontSize: 12,
                          color: item.navigationShow ? AdminTheme.primaryLight : AdminTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: item.requiredRoles.isEmpty
                        ? [Text('Tous', style: TextStyle(fontSize: 11, color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted))]
                        : item.requiredRoles
                            .map((r) => AdminTheme.badge(r, AdminTheme.info, fontSize: 10))
                            .toList(),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 16, color: AdminTheme.primary),
                    onPressed: () => _openEditModal(item),
                    tooltip: 'Modifier',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardsView(List<NavigationItem> items, bool isDark, double hPad) {
    if (items.isEmpty) {
      return _buildEmpty(isDark);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int cols = constraints.maxWidth > 1100
              ? 3
              : constraints.maxWidth > 640
                  ? 2
                  : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 175,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => _openEditModal(item),
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    border: Border.all(
                      color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                    ),
                    boxShadow: AdminTheme.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AdminTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                            ),
                            child: Center(
                              child: Text(
                                "#${item.navigationOrder}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              AdminTheme.badge(
                                item.navigationShow ? "Visible" : "Masqué",
                                item.navigationShow ? AdminTheme.primaryLight : AdminTheme.danger,
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.navigationLabelKey,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.navigationPath,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (item.navigationCategory != null && item.navigationCategory!.isNotEmpty)
                            AdminTheme.badge(item.navigationCategory!, AdminTheme.purple)
                          else
                            const SizedBox.shrink(),
                          if (item.requiredRoles.isNotEmpty)
                            Text(
                              "${item.requiredRoles.length} rôle(s)",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.alt_route_rounded,
              size: 64,
              color: (isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              "Aucune navigation trouvée",
              style: TextStyle(
                color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FORMULAIRE D'ÉDITION INTERNE
// -----------------------------------------------------------------------------
class NavigationFormWidget extends StatefulWidget {
  final NavigationItem? editingItem;
  final Function(NavigationItem) onSave;

  const NavigationFormWidget({super.key, this.editingItem, required this.onSave});

  @override
  NavigationFormWidgetState createState() => NavigationFormWidgetState();
}

class NavigationFormWidgetState extends State<NavigationFormWidget> {
  late TextEditingController _labelController;
  late TextEditingController _pathController;
  late TextEditingController _categoryController;
  late TextEditingController _orderController;
  bool _show = true;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.editingItem?.navigationLabelKey ?? '');
    _pathController = TextEditingController(text: widget.editingItem?.navigationPath ?? '');
    _categoryController = TextEditingController(text: widget.editingItem?.navigationCategory ?? '');
    _orderController = TextEditingController(text: widget.editingItem?.navigationOrder.toString() ?? '0');
    _show = widget.editingItem?.navigationShow ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _pathController.dispose();
    _categoryController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;

    InputDecoration inputDec(String label) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
          ),
          filled: true,
          fillColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            borderSide: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            borderSide: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _labelController,
          style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, fontSize: 14),
          decoration: inputDec("Label"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pathController,
          style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, fontSize: 14),
          decoration: inputDec("Chemin (ex: /admin/roles)"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _categoryController,
          style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, fontSize: 14),
          decoration: inputDec("Catégorie"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _orderController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, fontSize: 14),
          decoration: inputDec("Ordre d'affichage"),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            "Visible dans les menus",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
            ),
          ),
          activeThumbColor: AdminTheme.primary,
          value: _show,
          onChanged: (val) => setState(() => _show = val),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
            ),
            onPressed: () {
              final updated = NavigationItem(
                navigationId: widget.editingItem?.navigationId,
                navigationLabelKey: _labelController.text,
                navigationPath: _pathController.text,
                navigationIcon: widget.editingItem?.navigationIcon ?? 'icons/default.png',
                requiredRoles: widget.editingItem?.requiredRoles ?? [],
                navigationComponent: widget.editingItem?.navigationComponent,
                navigationShow: _show,
                navigationCategory: _categoryController.text,
                navigationOrder: int.tryParse(_orderController.text) ?? 0,
                appId: widget.editingItem?.appId ?? 8,
              );
              widget.onSave(updated);
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}