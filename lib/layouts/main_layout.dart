import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'header_widget.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  int _getSelectedIndex(String path) {
    if (path.startsWith('/monographie') || path.startsWith('/monography')) {
      return 1;
    }
    if (path.startsWith('/document')) {
      return 2;
    }
    if (path.startsWith('/offres-appui') || path.startsWith('/offrestd')) {
      return 3;
    }
    if (path.startsWith('/actualites')) {
      return 4;
    }
    if (path.startsWith('/officeprojet')) {
      return 5;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/monographie');
        break;
      case 2:
        context.go('/document');
        break;
      case 3:
        context.go('/offres-appui');
        break;
      case 4:
        context.go('/actualites');
        break;
      case 5:
        context.go('/officeprojet');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideDesktop = screenWidth >= 1024;
    final bool showBottomBar = !isWideDesktop;

    final String currentPath = GoRouterState.of(context).uri.path;
    final int selectedIndex = _getSelectedIndex(currentPath);

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            // ── BARRE LATÉRALE VERTICALE CAPSULE (STYLE CAPTURE 2 SUR ÉCRAN DESKTOP) ────
            if (isWideDesktop)
              _ModernSocialVerticalSideBar(
                selectedIndex: selectedIndex,
                onTap: (idx) => _onItemTapped(context, idx),
                isDarkMode: isDarkMode,
              ),

            // ── CONTENU PRINCIPAL ──────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // En-tête supérieur
                  const HeaderWidget(),

                  // Zone de contenu
                  Expanded(
                    child: Container(
                      color: isDarkMode ? const Color(0xFF101412) : const Color(0xFFF7F9F7),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // ── BARRE INFÉRIEURE FLOTTANTE CAPSULE (STYLE CAPTURE 2 SUR TOUS LES ÉCRANS MOBILES / TABLETTES) ──
      bottomNavigationBar: showBottomBar
          ? _ModernSocialBottomBar(
              selectedIndex: selectedIndex,
              onTap: (idx) => _onItemTapped(context, idx),
              isDarkMode: isDarkMode,
            )
          : null,
    );
  }
}

// ── DONNÉES DES ONGLETS DE NAVIGATION ─────────────────────────────────────────
class _TabItemData {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _TabItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<_TabItemData> _navItemsData = [
  _TabItemData(
    label: 'Accueil',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  _TabItemData(
    label: 'Monographie',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  ),
  _TabItemData(
    label: 'Documents',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
  ),
  _TabItemData(
    label: 'Offres',
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake_rounded,
  ),
  _TabItemData(
    label: 'Actualités',
    icon: Icons.newspaper_outlined,
    selectedIcon: Icons.newspaper_rounded,
  ),
  _TabItemData(
    label: 'Projets',
    icon: Icons.business_center_outlined,
    selectedIcon: Icons.business_center_rounded,
  ),
];

// ── BARRE DE NAVIGATION INFÉRIEURE CAPSULE FLOTTANTE (MOBILES ET TABLETTES) ───
class _ModernSocialBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isDarkMode;

  const _ModernSocialBottomBar({
    required this.selectedIndex,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF098E00);
    final activeBgColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE8F5E9);
    final barBgColor = isDarkMode
        ? const Color(0xFF0F172A).withValues(alpha: 0.96)
        : const Color(0xFFF3F4F8).withValues(alpha: 0.98);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      height: 68,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : Colors.white.withValues(alpha: 0.9),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_navItemsData.length, (index) {
            final item = _navItemsData[index];
            final bool isSelected = selectedIndex == index;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(index),
                  splashColor: brandGreen.withValues(alpha: 0.15),
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? activeBgColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: brandGreen.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected
                              ? brandGreen
                              : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          size: isSelected ? 22 : 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? brandGreen
                              : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── BARRE DE NAVIGATION LATÉRALE VERTICALE CAPSULE (GRANDS ÉCRANS DESKTOP) ────
class _ModernSocialVerticalSideBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isDarkMode;

  const _ModernSocialVerticalSideBar({
    required this.selectedIndex,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF098E00);
    final activeBgColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE8F5E9);
    final barBgColor = isDarkMode
        ? const Color(0xFF0F172A).withValues(alpha: 0.96)
        : const Color(0xFFF3F4F8).withValues(alpha: 0.98);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      width: 76,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : Colors.white.withValues(alpha: 0.9),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_navItemsData.length, (index) {
          final item = _navItemsData[index];
          final bool isSelected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Tooltip(
              message: item.label,
              preferBelow: false,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(26),
                  splashColor: brandGreen.withValues(alpha: 0.15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? activeBgColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: brandGreen.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected
                          ? brandGreen
                          : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      size: isSelected ? 24 : 22,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}