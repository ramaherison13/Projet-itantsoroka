import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/l10n/app_localization.dart';
import 'package:itantsoroka/widgets/administration/types_table_widget.dart';
import 'package:itantsoroka/widgets/administration/sous_types_table_widget.dart';

class ActeTypeManagementScreen extends StatefulWidget {
  const ActeTypeManagementScreen({super.key});

  @override
  State<ActeTypeManagementScreen> createState() =>
      _ActeTypeManagementScreenState();
}

class _ActeTypeManagementScreenState extends State<ActeTypeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<TypesTableWidgetState> _typesKey = GlobalKey();
  final GlobalKey<SousTypesTableWidgetState> _sousTypesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── API Handlers Types ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _getAllType() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.serviceControleDeLegalite}/acte-types'),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) return {'data': data};
        if (data is Map<String, dynamic>) return data;
      }
    } catch (e) {
      debugPrint('Erreur _getAllType: $e');
    }
    return {'data': []};
  }

  Future<void> _createType(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.serviceControleDeLegalite}/acte-types'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Erreur _createType: $e');
    }
  }

  Future<void> _editType(dynamic id, Map<String, dynamic> data) async {
    try {
      await http.put(
        Uri.parse('${ApiConstants.serviceControleDeLegalite}/acte-types/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Erreur _editType: $e');
    }
  }

  Future<void> _deleteType(dynamic id) async {
    try {
      await http.delete(
        Uri.parse(
            '${ApiConstants.serviceControleDeLegalite}/acte-types/$id/force'),
      );
    } catch (e) {
      debugPrint('Erreur _deleteType: $e');
    }
  }

  // ── API Handlers Sous-Types ────────────────────────────────────────────────

  Future<Map<String, dynamic>> _getAllSousType() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.serviceControleDeLegalite}/acte-sous-types'),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) return {'data': data};
        if (data is Map<String, dynamic>) return data;
      }
    } catch (e) {
      debugPrint('Erreur _getAllSousType: $e');
    }
    return {'data': []};
  }

  Future<void> _createSousType(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.serviceControleDeLegalite}/acte-sous-types'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Erreur _createSousType: $e');
    }
  }

  Future<void> _editSousType(dynamic id, Map<String, dynamic> data) async {
    try {
      await http.put(
        Uri.parse(
            '${ApiConstants.serviceControleDeLegalite}/acte-sous-types/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Erreur _editSousType: $e');
    }
  }

  Future<void> _deleteSousType(dynamic id) async {
    try {
      await http.delete(
        Uri.parse(
            '${ApiConstants.serviceControleDeLegalite}/acte-sous-types/$id'),
      );
    } catch (e) {
      debugPrint('Erreur _deleteSousType: $e');
    }
  }

  void _refreshData() {
    setState(() {});
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool isMobile = context.isMobile;
    final double hPad = AdminTheme.horizontalPadding(context);

    return Scaffold(
      backgroundColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête Responsive ─────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(hPad, isMobile ? 14 : 20, hPad, isMobile ? 14 : 18),
              decoration: BoxDecoration(
                color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                  ),
                ),
                boxShadow: AdminTheme.shadowSm,
              ),
              child: Row(
                children: [
                  // Icône avec gradient chaleureux
                  Container(
                    width: isMobile ? 38 : 44,
                    height: isMobile ? 38 : 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      color: Colors.white,
                      size: isMobile ? 20 : 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Titre & Sous-titre adaptatifs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isMobile ? context.tr('acte_gestion_titre_mobile') : context.tr('acte_gestion_titre'),
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 8),
                              AdminTheme.badge(context.tr('acte_controle_legalite'), AdminTheme.warning),
                            ],
                          ],
                        ),
                        if (!isMobile) ...[
                          const SizedBox(height: 3),
                          Text(
                            context.tr('acte_sous_titre'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: _refreshData,
                    tooltip: context.tr('actualiser'),
                  ),
                ],
              ),
            ),

            // ── TabBar Stylé Responsive ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, isMobile ? 10 : 16, hPad, isMobile ? 8 : 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  border: Border.all(
                    color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                  ),
                  boxShadow: AdminTheme.shadowSm,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF098E00), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: AdminTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? AdminTheme.textSecondaryDark
                      : AdminTheme.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label_rounded, size: isMobile ? 15 : 17),
                          const SizedBox(width: 6),
                          Text(isMobile ? context.tr('acte_types_mobile') : context.tr('acte_type')),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.layers_rounded, size: isMobile ? 15 : 17),
                          const SizedBox(width: 6),
                          Text(isMobile ? context.tr('acte_sous_types_mobile') : context.tr('acte_sous_type')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Contenu dynamique (TabBarView) ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TypesTableWidget(
                      key: _typesKey,
                      getAllType: _getAllType,
                      createType: _createType,
                      editType: _editType,
                      deleteType: _deleteType,
                    ),
                    SousTypesTableWidget(
                      key: _sousTypesKey,
                      getAllSousType: _getAllSousType,
                      getAllType: _getAllType,
                      createSousType: _createSousType,
                      editSousType: _editSousType,
                      deleteSousType: _deleteSousType,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isMobile ? 80 : 12),
          ],
        ),
      ),
    );
  }
}