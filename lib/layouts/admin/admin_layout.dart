import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'admin_header_widget.dart';
import '../../widgets/sidebar/side_bar_widget.dart';
import '../../widgets/discussion/floating_discussion_button_widget.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout>
    with SingleTickerProviderStateMixin {
  bool _menuOpen = false;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerSlide;
  late Animation<double> _scrimOpacity;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _scrimOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawerController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleMenu(bool open) {
    setState(() => _menuOpen = open);
    if (open) {
      HapticFeedback.lightImpact();
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final double screenWidth = context.screenWidth;
    final bool isDesktop = screenWidth >= AdminTheme.desktopMin;

    String currentPath = '/admin';
    try {
      currentPath = GoRouterState.of(context).uri.toString();
    } catch (_) {}

    final Map<String, dynamic> adminUser = {
      'user_pseudo': 'Admin',
      'user_email': 'admin@example.com',
      'roles': [
        {'role_slug': 'Super-Admin', 'role_name': 'Super-Admin'}
      ],
    };

    // Largeur du drawer adaptatif
    final double drawerWidth = screenWidth < 400
        ? screenWidth * 0.85
        : screenWidth < 600
            ? 300.0
            : 280.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // ─── Disposition principale ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar permanente desktop
                  if (isDesktop)
                    SizedBox(
                      width: 280.0,
                      child: SideBarWidget(
                        menuOpen: _menuOpen,
                        setMenuOpen: _toggleMenu,
                        user: adminUser,
                        currentPathname: currentPath,
                        onLogout: () => context.go('/auth/login'),
                        getAppNavigationForAnUser: (appId) async => [],
                        appId: 8,
                      ),
                    ),

                  // Zone de contenu principale
                  Expanded(
                    child: Column(
                      children: [
                        // Header fixe
                        AdminHeaderWidget(
                          menuOpen: _menuOpen,
                          onMenuToggle: _toggleMenu,
                        ),

                        // Contenu scrollable
                        Expanded(
                          child: ClipRect(
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ─── Scrim (fermeture du drawer) ───────────────────────────
              if (!isDesktop)
                AnimatedBuilder(
                  animation: _scrimOpacity,
                  builder: (context, _) {
                    if (_scrimOpacity.value == 0) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: GestureDetector(
                        onTap: () => _toggleMenu(false),
                        child: Container(
                          color: Colors.black
                              .withValues(alpha: _scrimOpacity.value * 0.55),
                        ),
                      ),
                    );
                  },
                ),

              // ─── Drawer mobile animé ───────────────────────────────────
              if (!isDesktop)
                SlideTransition(
                  position: _drawerSlide,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      // Swipe gauche pour fermer
                      onHorizontalDragUpdate: (details) {
                        if (details.delta.dx < -5) _toggleMenu(false);
                      },
                      child: Material(
                        elevation: 24,
                        shadowColor: Colors.black38,
                        child: SizedBox(
                          width: drawerWidth,
                          height: double.infinity,
                          child: SideBarWidget(
                            menuOpen: _menuOpen,
                            setMenuOpen: _toggleMenu,
                            user: adminUser,
                            currentPathname: currentPath,
                            onLogout: () {
                              _toggleMenu(false);
                              context.go('/auth/login');
                            },
                            getAppNavigationForAnUser: (appId) async => [],
                            appId: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ─── Bouton discussion flottant ────────────────────────────
              Positioned(
                bottom: 24,
                right: 16,
                child: FloatingDiscussionButtonWidget(
                  isAuthenticated: true,
                  discussionWidget: Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}