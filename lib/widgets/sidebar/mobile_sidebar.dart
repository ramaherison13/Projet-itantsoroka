import 'package:flutter/material.dart';
import 'active_marker.dart';
import 'loading_spinner.dart';
import 'logout_button.dart';
import 'menu_item.dart';
import 'mobile_header.dart';

class MobileSidebar extends StatelessWidget {
  final bool menuOpen;
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
  final VoidCallback onClose;
  final VoidCallback onLogout;

  const MobileSidebar({
    super.key,
    required this.menuOpen,
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
    required this.onClose,
    required this.onLogout,
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
    if (!menuOpen) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const greenColor = Color(0xFF00C21C);
    const darkGreenColor = Color(0xFF098E00);

    return Stack(
      children: [
        // Arrière-plan sombre avec effet de flou / overlay
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),

        // Panneau latéral coulissant (Drawer personnalisé)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 256, // w-64 en Flutter (~256px)
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête mobile
                    MobileHeader(onClose: onClose),

                    // Menu principal avec indicateur actif
                    Expanded(
                      child: Stack(
                        children: [
                          if (isActiveInMainMenu)
                            ActiveMarker(
                              top: activeMarkerTop,
                              height: activeMarkerHeight,
                            ),
                          initialLoading
                              ? const Center(child: LoadingSpinner())
                              : ListView.builder(
                                  itemCount: currentMenuItems.length,
                                  itemBuilder: (context, i) {
                                    final item = currentMenuItems[i];
                                    return MenuItemWidget(
                                      item: item,
                                      index: i,
                                      isFooter: false,
                                      onClick: onClose,
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),

                    // Footer du menu mobile
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
                                  onClick: onClose,
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
                                    onClick: onClose,
                                  );
                                }),
                              const SizedBox(height: 8),
                              LogoutButton(
                                label: logoutLabel,
                                onClick: () {
                                  onClose();
                                  onLogout();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Indicateur "En ligne"
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: greenColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: greenColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: greenColor.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "En ligne",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? greenColor : darkGreenColor,
                            ),
                          ),
                        ],
                      ),
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