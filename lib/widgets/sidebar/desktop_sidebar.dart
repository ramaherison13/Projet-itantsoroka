import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'active_marker.dart';
import 'logout_button.dart';
import 'menu_item.dart';
// Note : Assurez-vous d'importer votre widget Logo s'il est disponible dans votre projet,
// ou remplacez-le par un widget personnalisé si nécessaire.

class DesktopSidebar extends StatelessWidget {
  final List<dynamic> currentMenuItems;
  final List<dynamic> accueil;
  final List<dynamic> superAdmin;
  final dynamic user;
  final bool isActiveInMainMenu;
  final bool isActiveInFooter;
  final double activeMarkerTop;
  final double activeMarkerHeight;
  final bool initialLoading;
  final String logoutLabel;
  final VoidCallback onLogout;
  final Function(int index, bool isFooter, GlobalKey key)? onMenuItemKey;

  const DesktopSidebar({
    super.key,
    required this.currentMenuItems,
    required this.accueil,
    required this.superAdmin,
    required this.user,
    required this.isActiveInMainMenu,
    required this.isActiveInFooter,
    required this.activeMarkerTop,
    required this.activeMarkerHeight,
    required this.initialLoading,
    required this.logoutLabel,
    required this.onLogout,
    this.onMenuItemKey,
  });

  bool _isSuperAdmin(dynamic userObj) {
    if (userObj == null) return false;
    try {
      final roles = userObj['roles'] ?? userObj.roles;
      if (roles is List) {
        return roles.any((r) {
          if (r is Map) return r['role_slug'] == "Super-Admin";
          return r.role_slug == "Super-Admin";
        });
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280, // w-70 environ en Flutter (~280px)
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade200.withValues(alpha: 0.8),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête / Logo
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 24.0, top: 0),
                child: Row(
                  children: [
                    // Remplacer par votre widget Logo (ex: Logo(width: 128))
                    SizedBox(
                      width: 128,
                      child: Text(
                        "Logo",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu principal avec marqueur actif
              Expanded(
                child: Stack(
                  children: [
                    if (isActiveInMainMenu)
                      ActiveMarker(
                        top: activeMarkerTop,
                        height: activeMarkerHeight,
                      ),
                    initialLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: currentMenuItems.length,
                            itemBuilder: (context, i) {
                              final item = currentMenuItems[i];
                              return MenuItemWidget(
                                item: item,
                                index: i,
                                isFooter: false,
                                onClick: () {
                                  if (item['path'] != null) {
                                    context.go(item['path'].toString());
                                  }
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Stack(
                  children: [
                    if (isActiveInFooter)
                      ActiveMarker(
                        top: activeMarkerTop,
                        height: activeMarkerHeight,
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...accueil.asMap().entries.map((entry) {
                          final i = entry.key;
                          final a = entry.value;
                          return MenuItemWidget(
                            item: a,
                            index: i,
                            isFooter: true,
                            onClick: () {
                              if (a['path'] != null) {
                                context.go(a['path'].toString());
                              }
                            },
                          );
                        }),
                        if (_isSuperAdmin(user))
                          ...superAdmin.asMap().entries.map((entry) {
                            final i = entry.key;
                            final a = entry.value;
                            return MenuItemWidget(
                              item: a,
                              index: accueil.length + i,
                              isFooter: true,
                              onClick: () {
                                if (a['path'] != null) {
                                  context.go(a['path'].toString());
                                }
                              },
                            );
                          }),
                        const SizedBox(height: 8),
                        LogoutButton(
                          label: logoutLabel,
                          onClick: onLogout,
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
    );
  }
}