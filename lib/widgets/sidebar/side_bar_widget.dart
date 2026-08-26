import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:itantsoroka/l10n/app_localization.dart';

// Helper function to extract role slugs
List<String> getUserRoleSlugs(Map<String, dynamic>? user) {
  if (user == null) return [];
  final directRoles = user['roles'] is List ? user['roles'] as List : [];
  final appUserRoles = user['appUserRoles'] is List ? user['appUserRoles'] as List : [];

  final slugs = <String>[];

  for (final r in directRoles) {
    if (r is Map && r['role_slug'] != null) {
      slugs.add(r['role_slug'].toString());
    }
  }

  for (final ur in appUserRoles) {
    if (ur is Map && ur['role'] is Map && ur['role']['role_slug'] != null) {
      slugs.add(ur['role']['role_slug'].toString());
    }
  }

  return slugs.toSet().toList();
}

class SideBarWidget extends StatefulWidget {
  final bool menuOpen;
  final ValueChanged<bool> setMenuOpen;
  final Map<String, dynamic>? user;
  final String currentPathname;
  final VoidCallback onLogout;
  final Future<List<dynamic>> Function(int appId) getAppNavigationForAnUser;
  final int appId;

  const SideBarWidget({
    super.key,
    required this.menuOpen,
    required this.setMenuOpen,
    required this.user,
    required this.currentPathname,
    required this.onLogout,
    required this.getAppNavigationForAnUser,
    required this.appId,
  });

  @override
  SideBarWidgetState createState() => SideBarWidgetState();
}

class SideBarWidgetState extends State<SideBarWidget> {
  final Map<String, List<dynamic>> _menuCache = {};
  List<dynamic> _currentMenuItems = [];
  bool _initialLoading = true;
  bool _hasLoadedOnce = false;

  /// Returns the admin menu items using translated labels
  List<Map<String, dynamic>> _buildAdminMenuItems() => [
    {
      'path': '/admin',
      'icon': Icons.space_dashboard_rounded,
      'nameKey': context.tr('sidebar_dashboard'),
    },
    {
      'path': '/admin/users',
      'icon': Icons.people_alt_rounded,
      'nameKey': context.tr('admin_users'),
    },
    {
      'path': '/admin/passwords',
      'icon': Icons.lock_reset_rounded,
      'nameKey': context.tr('admin_passwords'),
    },
    {
      'path': '/admin/roles',
      'icon': Icons.admin_panel_settings_rounded,
      'nameKey': context.tr('admin_roles'),
    },
    {
      'path': '/admin/acte-type-management/type',
      'icon': Icons.gavel_rounded,
      'nameKey': context.tr('admin_act_types'),
    },
    {
      'path': '/admin/navigations',
      'icon': Icons.alt_route_rounded,
      'nameKey': context.tr('admin_navigation'),
    },
  ];

  List<Map<String, dynamic>> _buildAccueilItems() => [
    {
      'path': '/modules',
      'icon': Icons.grid_view_rounded,
      'nameKey': context.tr('sidebar_modules'),
      'color': 'home',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _getNavigation();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SideBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPathname != widget.currentPathname ||
        oldWidget.user != widget.user) {
      _getNavigation();
    }
  }

  List<dynamic> _sortByOrder(List<dynamic> items) {
    final sorted = List.from(items);
    sorted.sort((a, b) {
      final orderA = a['order'] ?? 9007199254740991;
      final orderB = b['order'] ?? 9007199254740991;
      return (orderA as num).compareTo(orderB as num);
    });
    return sorted;
  }

  Future<void> _getNavigation() async {
    final uriSegments =
        widget.currentPathname.split('/').where((s) => s.isNotEmpty).toList();
    final currentCategory = uriSegments.isNotEmpty ? uriSegments[0] : '';

    if (currentCategory == 'admin') {
      if (mounted) {
        setState(() {
          _currentMenuItems = _buildAdminMenuItems();
          _initialLoading = false;
          _hasLoadedOnce = true;
        });
      }
      return;
    }

    if (widget.user == null) {
      setState(() => _initialLoading = false);
      return;
    }

    if (_menuCache.containsKey(currentCategory)) {
      setState(() {
        _currentMenuItems = _menuCache[currentCategory]!;
        if (_initialLoading) _initialLoading = false;
      });
      return;
    }

    if (!_hasLoadedOnce) {
      setState(() => _initialLoading = true);
    }

    try {
      final data = await widget.getAppNavigationForAnUser(widget.appId);
      final userRoleSlugs = getUserRoleSlugs(widget.user);

      List<dynamic> navs = data.where((nav) {
        return nav['category'] == currentCategory;
      }).where((link) {
        final requiredRoles =
            link['requiredRoles'] is List ? link['requiredRoles'] as List : [];
        return requiredRoles
            .any((role) => userRoleSlugs.contains(role.toString()));
      }).toList();

      navs = _sortByOrder(navs);

      if (navs.isEmpty && currentCategory == 'admin') {
        navs = _buildAdminMenuItems();
      }

      _menuCache[currentCategory] = navs;

      if (mounted) {
        setState(() {
          _currentMenuItems = navs;
          _initialLoading = false;
          _hasLoadedOnce = true;
        });
      }
    } catch (error) {
      debugPrint("Erreur lors du chargement du menu: $error");
      if (mounted) {
        setState(() {
          if (currentCategory == 'admin') {
            _currentMenuItems = _buildAdminMenuItems();
          }
          _initialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981);
    final activeBgColor =
        isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFE6F4EA);
    final textColor =
        isDarkMode ? Colors.white : const Color(0xFF1F2937);

    // Rebuild translated items every time build is called so locale changes apply
    final isAdmin = widget.currentPathname.startsWith('/admin');
    final menuItems = isAdmin ? _buildAdminMenuItems() : _currentMenuItems;
    final accueilItems = _buildAccueilItems();

    return Material(
      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          if (_initialLoading) const LinearProgressIndicator(minHeight: 2),

          // Header Sidebar
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('sidebar_administration'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                if (menuItems.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                    child: Text(
                      context.tr('sidebar_menu_general'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...menuItems.map((item) {
                    final String path = item['path']?.toString() ?? '';
                    final isActive = widget.currentPathname == path ||
                        (path != '/admin' &&
                            widget.currentPathname.startsWith(path));
                    final IconData icon = (item['icon'] is IconData)
                        ? item['icon']
                        : Icons.chevron_right_rounded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        tileColor:
                            isActive ? activeBgColor : Colors.transparent,
                        leading: Icon(
                          icon,
                          color: isActive
                              ? primaryColor
                              : (isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                          size: 20,
                        ),
                        title: Text(
                          item['nameKey'] ?? item['name'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isActive ? primaryColor : textColor,
                          ),
                        ),
                        selected: isActive,
                        onTap: () {
                          if (path.isNotEmpty) {
                            context.go(path);
                            widget.setMenuOpen(false);
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                Padding(
                  padding:
                      const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  child: Text(
                    context.tr('sidebar_nav_applicative'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                ...accueilItems.map((item) {
                  final String path = item['path']?.toString() ?? '';
                  final isActive = widget.currentPathname == path;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      tileColor:
                          isActive ? activeBgColor : Colors.transparent,
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isActive
                            ? primaryColor
                            : (isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                        size: 20,
                      ),
                      title: Text(
                        item['nameKey'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive ? primaryColor : textColor,
                        ),
                      ),
                      selected: isActive,
                      onTap: () {
                        if (path.isNotEmpty) {
                          context.go(path);
                          widget.setMenuOpen(false);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(10),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 20),
              title: Text(
                context.tr('deconnexion'),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent),
              ),
              onTap: () {
                widget.onLogout();
                widget.setMenuOpen(false);
              },
            ),
          ),
        ],
      ),
    );
  }
}