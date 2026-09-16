import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/l10n/app_localization.dart';
import 'package:itantsoroka/services/role_service.dart';
import 'package:itantsoroka/widgets/administration/role_form_modal_widget.dart';
import 'package:itantsoroka/widgets/administration/role_detail_modal_widget.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> with TickerProviderStateMixin {
  List<dynamic> roles = [];
  List<dynamic> _filteredRoles = [];
  bool loading = false;
  Map<String, dynamic>? selectedRole;
  String _searchQuery = '';
  String _selectedApp = 'Toutes';
  final TextEditingController _searchCtrl = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    fetchRoles();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchRoles() async {
    setState(() => loading = true);
    _fadeCtrl.reset();
    try {
      // getAllRolesWithPermission retourne maintenant directement une List
      final res = await RoleService.getAllRolesWithPermission();
      if (res != null) {
        List fetched = [];
        if (res is List) {
          fetched = res;
        } else if (res is Map) {
          fetched = res['data'] ?? res['roles'] ?? res['content'] ?? [];
        }
        if (fetched.isNotEmpty) {
          setState(() {
            roles = List<Map<String, dynamic>>.from(
                fetched.whereType<Map<String, dynamic>>());
            _applyFilters();
          });
          _fadeCtrl.forward();
          return;
        }
      }
      // Fallback: appel direct à l'API avec limit=200
      final response = await http.get(
          Uri.parse('${ApiConstants.serviceAuth}/roles?limit=200'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List raw = data is List
            ? data
            : (data['data'] ?? data['roles'] ?? []);
        setState(() {
          roles = List<Map<String, dynamic>>.from(
              raw.whereType<Map<String, dynamic>>());
          _applyFilters();
        });
        _fadeCtrl.forward();
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des rôles: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // Applique la recherche et le filtre par application
  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filteredRoles = roles.where((r) {
        final name = (r['role_name'] ?? r['name'] ?? '').toLowerCase();
        final appName = (r['application']?['app_name'] ?? '').toLowerCase();
        final matchSearch = q.isEmpty || name.contains(q) || appName.contains(q);
        final matchApp = _selectedApp == 'Toutes' ||
            (r['application']?['app_name'] ?? '') == _selectedApp;
        return matchSearch && matchApp;
      }).toList();
    });
  }

  // Retourne la liste unique des noms d'applications
  List<String> get _appNames {
    final apps = <String>{};
    for (final r in roles) {
      final name = r['application']?['app_name'];
      if (name != null && name.toString().isNotEmpty) apps.add(name.toString());
    }
    return ['Toutes', ...apps.toList()..sort()];
  }

  void _openCreateModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => RoleFormModalWidget(
        appId: RoleService.appId,
        initialData: null,
        onClose: () => Navigator.of(context).pop(),
        createRole: (data) async => await RoleService.createRole(data),
        updateRole: (roleId, data) async =>
            await RoleService.updateRole(roleId, data),
        onSubmit: (formData) {
          Navigator.of(context).pop();
          fetchRoles();
        },
      ),
    );
  }

  void _openDetailModal() {
    if (selectedRole == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => RoleDetailModalWidget(
        role: selectedRole!,
        onClose: () => Navigator.of(context).pop(),
        fetchAllPermissions: () async {
          final res = await RoleService.getAllPermission();
          if (res is Map<String, dynamic>) return res;
          return {'data': res ?? []};
        },
      ),
    );
  }

  void _openEditModal() {
    if (selectedRole == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => RoleFormModalWidget(
        appId: RoleService.appId,
        initialData: selectedRole,
        onClose: () => Navigator.of(context).pop(),
        createRole: (data) async => await RoleService.createRole(data),
        updateRole: (roleId, data) async =>
            await RoleService.updateRole(roleId, data),
        onSubmit: (formData) {
          Navigator.of(context).pop();
          fetchRoles();
        },
      ),
    );
  }

  void _confirmDeleteRole() {
    if (selectedRole == null) return;
    final roleName = selectedRole!['role_name'] ?? 'ce rôle';
    final roleId = selectedRole!['role_id'] ?? selectedRole!['id'];
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AdminTheme.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AdminTheme.danger, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supprimer le rôle',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(
                'Voulez-vous vraiment supprimer "$roleName" ? Cette action est irréversible.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AdminTheme.radiusSm)),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AdminTheme.radiusSm)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        if (roleId != null) {
                          final intId = roleId is int
                              ? roleId
                              : int.tryParse(roleId.toString()) ?? 0;
                          final success =
                              await RoleService.deleteRole(intId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Rôle supprimé avec succès !'
                                    : 'Erreur lors de la suppression.'),
                                backgroundColor:
                                    success ? Colors.green : AdminTheme.danger,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                            if (success) {
                              setState(() => selectedRole = null);
                              fetchRoles();
                            }
                          }
                        }
                      },
                      child: const Text('Supprimer',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool isMobile = context.isMobile;
    final currentSelectedId = selectedRole?['role_id'] ?? selectedRole?['id'];
    final hasSelectedRole = selectedRole != null &&
        currentSelectedId != null &&
        currentSelectedId.toString() != '0';

    return Scaffold(
      backgroundColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── En-tête ──────────────────────────────────────────────
            _buildHeader(isDark, isMobile, hasSelectedRole),

            // ── Contenu ───────────────────────────────────────────────
            Expanded(
              child: loading && roles.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AdminTheme.primary))
                  : roles.isEmpty
                      ? _buildEmpty(isDark)
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: isMobile
                              ? _buildMobileList(
                                  isDark, currentSelectedId, hasSelectedRole)
                              : _buildDesktopTable(
                                  isDark, currentSelectedId, hasSelectedRole),
                        ),
            ),
          ],
        ),
      ),
      // FAB sur mobile si rôle sélectionné
      floatingActionButton: (isMobile && hasSelectedRole)
          ? FloatingActionButton.extended(
              backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _openEditModal,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Modifier',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ── En-tête ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, bool isMobile, bool hasSelectedRole) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AdminTheme.horizontalPadding(context),
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + bouton créer
          Row(
            children: [
              // Icône
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('roles_gestion_titre'),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AdminTheme.textPrimaryDark
                            : AdminTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${roles.length} ${context.tr('roles_enregistres')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AdminTheme.textSecondaryDark
                            : AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton Actualiser
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: isDark
                        ? AdminTheme.textSecondaryDark
                        : AdminTheme.textSecondary,
                    size: 20),
                onPressed: loading ? null : fetchRoles,
                tooltip: context.tr('actualiser'),
              ),

              // Bouton Créer
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AdminTheme.radiusSm)),
                ),
                onPressed: _openCreateModal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: isMobile
                    ? const SizedBox.shrink()
                    : Text(context.tr('creer'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // Barre de recherche & Filtre d'application
          const SizedBox(height: 10),
          Row(
            children: [
              // Recherche
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AdminTheme.surface2Dark : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    border: Border.all(
                      color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                    ),
                    onChanged: (v) {
                      _searchQuery = v;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un rôle ou une app...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filtre par application
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AdminTheme.surface2Dark : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  border: Border.all(
                    color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedApp,
                    isDense: true,
                    dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                    ),
                    icon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF6B7280)),
                    items: _appNames.map((app) {
                      return DropdownMenuItem<String>(
                        value: app,
                        child: Text(app == 'Toutes' ? 'Toutes les apps' : app),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedApp = val;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Actions contextuelles (rôle sélectionné)
          if (hasSelectedRole) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Chip du rôle sélectionné
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AdminTheme.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
                      border: Border.all(
                          color: AdminTheme.purple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded,
                            size: 14, color: AdminTheme.purple),
                        const SizedBox(width: 5),
                        Text(
                          selectedRole!['role_name'] ?? 'Rôle',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AdminTheme.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  AdminTheme.actionButton(
                    icon: Icons.visibility_rounded,
                    label: 'Voir',
                    color: AdminTheme.info,
                    onTap: _openDetailModal,
                  ),
                  const SizedBox(width: 6),
                  AdminTheme.actionButton(
                    icon: Icons.edit_rounded,
                    label: 'Modifier',
                    color: AdminTheme.primary,
                    onTap: _openEditModal,
                  ),
                  const SizedBox(width: 6),
                  AdminTheme.actionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Supprimer',
                    color: AdminTheme.danger,
                    onTap: _confirmDeleteRole,
                  ),
                  const SizedBox(width: 6),
                  AdminTheme.actionButton(
                    icon: Icons.close_rounded,
                    label: 'Désélectionner',
                    color: const Color(0xFF6B7280),
                    onTap: () => setState(() => selectedRole = null),
                    iconOnly: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mobile : liste de cartes ──────────────────────────────────────────────

  Widget _buildMobileList(
      bool isDark, dynamic currentSelectedId, bool hasSelectedRole) {
    final list = _filteredRoles;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AdminTheme.horizontalPadding(context),
        12,
        AdminTheme.horizontalPadding(context),
        hasSelectedRole ? 120 : 100,
      ),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = list[index];
        final rowId = r['role_id'] ?? r['id'];
        final isSelected = currentSelectedId != null &&
            rowId != null &&
            currentSelectedId.toString() == rowId.toString();
        final permCount = (r['rolePermissions'] as List?)?.length ?? 0;
        final userCount = (r['appUserRoles'] as List?)?.length ?? 0;
        final roleName = r['role_name'] ?? r['name'] ?? 'Rôle';
        final appName = r['application']?['app_name'] ?? '';

        return GestureDetector(
          onTap: () =>
              setState(() => selectedRole = isSelected ? null : r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AdminTheme.purple.withValues(alpha: 0.07)
                  : (isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight),
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AdminTheme.purple.withValues(alpha: 0.5)
                    : (isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AdminTheme.purple.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : AdminTheme.shadowSm,
            ),
            child: Row(
              children: [
                // Icône rôle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)])
                        : LinearGradient(
                            colors: [
                              AdminTheme.purple.withValues(alpha: 0.15),
                              AdminTheme.purple.withValues(alpha: 0.08),
                            ],
                          ),
                    borderRadius:
                        BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: isSelected ? Colors.white : AdminTheme.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark
                              ? AdminTheme.textPrimaryDark
                              : AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (appName.isNotEmpty)
                            AdminTheme.badge(appName, AdminTheme.primary),
                          AdminTheme.badge('$permCount perm.', AdminTheme.purple),
                          AdminTheme.badge(
                            '$userCount user${userCount != 1 ? 's' : ''}',
                            AdminTheme.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AdminTheme.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AdminTheme.textMutedDark
                        : AdminTheme.textMuted,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Desktop : tableau ─────────────────────────────────────────────────────

  Widget _buildDesktopTable(
      bool isDark, dynamic currentSelectedId, bool hasSelectedRole) {
    final list = _filteredRoles;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AdminTheme.horizontalPadding(context),
        12,
        AdminTheme.horizontalPadding(context),
        24,
      ),
      child: Column(
        children: [
          // En-tête tableau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AdminTheme.surface2Dark : AdminTheme.dividerLight,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AdminTheme.radiusSm)),
              border: Border.all(
                  color: isDark
                      ? AdminTheme.borderDark
                      : AdminTheme.borderLight),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44),
                const SizedBox(width: 12),
                const Expanded(
                    flex: 3, child: _TH('Rôle')),
                const Expanded(
                    flex: 2, child: _TH('Application')),
                const Expanded(
                    flex: 2, child: _TH('Permissions')),
                const Expanded(
                    flex: 2, child: _TH('Utilisateurs')),
                const SizedBox(width: 80),
              ],
            ),
          ),

          // Lignes
          ...list.map((r) {
            final rowId = r['role_id'] ?? r['id'];
            final isSelected = currentSelectedId != null &&
                rowId != null &&
                currentSelectedId.toString() == rowId.toString();
            final permCount = (r['rolePermissions'] as List?)?.length ?? 0;
            final userCount = (r['appUserRoles'] as List?)?.length ?? 0;
            final roleName = r['role_name'] ?? r['name'] ?? '';
            final appName = r['application']?['app_name'] ?? '-';

            return _RoleTableRow(
              roleName: roleName,
              appName: appName,
              permCount: permCount,
              userCount: userCount,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () =>
                  setState(() => selectedRole = isSelected ? null : r),
              onView: _openDetailModal,
              onEdit: _openEditModal,
              onDelete: _confirmDeleteRole,
            );
          }),
        ],
      ),
    );
  }

  // ── État vide ─────────────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings_outlined,
              size: 72,
              color: (isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted)
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Aucun rôle trouvé',
              style: TextStyle(
                  color: isDark
                      ? AdminTheme.textSecondaryDark
                      : AdminTheme.textSecondary,
                  fontSize: 15)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: AdminTheme.primary),
            onPressed: _openCreateModal,
            icon: const Icon(Icons.add_rounded),
            label: Text('${context.tr('creer')} ${context.tr('roles_gestion_titre').split(' ').first.toLowerCase()}'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE ROW WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _RoleTableRow extends StatefulWidget {
  final String roleName;
  final String appName;
  final int permCount;
  final int userCount;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleTableRow({
    required this.roleName,
    required this.appName,
    required this.permCount,
    required this.userCount,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_RoleTableRow> createState() => _RoleTableRowState();
}

class _RoleTableRowState extends State<_RoleTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AdminTheme.purple.withValues(alpha: 0.07)
                : _hovered
                    ? (widget.isDark
                        ? AdminTheme.surface2Dark.withValues(alpha: 0.5)
                        : AdminTheme.dividerLight)
                    : (widget.isDark
                        ? AdminTheme.surfaceDark
                        : AdminTheme.surfaceLight),
            border: Border(
              bottom: BorderSide(
                  color: widget.isDark
                      ? AdminTheme.borderDark
                      : AdminTheme.borderLight),
              left: BorderSide(
                color: widget.isSelected
                    ? AdminTheme.purple
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // Icône rôle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)])
                      : LinearGradient(
                          colors: [
                            AdminTheme.purple.withValues(alpha: 0.12),
                            AdminTheme.purple.withValues(alpha: 0.06),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: widget.isSelected ? Colors.white : AdminTheme.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Nom du rôle
              Expanded(
                flex: 3,
                child: Text(
                  widget.roleName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: widget.isDark
                        ? AdminTheme.textPrimaryDark
                        : AdminTheme.textPrimary,
                  ),
                ),
              ),

              // Application
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AdminTheme.badge(
                      widget.appName, AdminTheme.primary),
                ),
              ),

              // Permissions
              Expanded(
                flex: 2,
                child: AdminTheme.badge(
                    '${widget.permCount} ${context.tr('roles_permissions')}',
                    AdminTheme.purple),
              ),

              // Utilisateurs
              Expanded(
                flex: 2,
                child: AdminTheme.badge(
                    '${widget.userCount} ${context.tr(widget.userCount != 1 ? 'roles_utilisateurs' : 'roles_utilisateur')}',
                    AdminTheme.info),
              ),

              // Actions
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AdminTheme.actionButton(
                      icon: Icons.visibility_rounded,
                      label: 'Voir',
                      color: AdminTheme.info,
                      onTap: widget.onView,
                      iconOnly: true,
                    ),
                    const SizedBox(width: 4),
                    AdminTheme.actionButton(
                      icon: Icons.edit_rounded,
                      label: 'Modifier',
                      color: AdminTheme.primary,
                      onTap: widget.onEdit,
                      iconOnly: true,
                    ),
                    const SizedBox(width: 4),
                    AdminTheme.actionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Supprimer',
                      color: AdminTheme.danger,
                      onTap: widget.onDelete,
                      iconOnly: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  const _TH(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }
}