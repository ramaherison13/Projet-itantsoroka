import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/providers/theme_provider.dart';

class HeaderWidget extends StatefulWidget implements PreferredSizeWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(64.0);
}

class _HeaderWidgetState extends State<HeaderWidget>
    with SingleTickerProviderStateMixin {
  bool _menuOpen = false;
  Map<String, dynamic>? _fullProfile;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  OverlayEntry? _overlayEntry;

  static const List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Accueil',
      'path': '/',
      'icon': Icons.home_rounded,
      'outlinedIcon': Icons.home_outlined,
    },
    {
      'label': 'Monographie',
      'path': '/monographie',
      'icon': Icons.grid_view_rounded,
      'outlinedIcon': Icons.grid_view_outlined,
    },
    {
      'label': 'Document',
      'path': '/document',
      'icon': Icons.folder_rounded,
      'outlinedIcon': Icons.folder_outlined,
    },
    {
      'label': 'Actualités',
      'path': '/actualites',
      'icon': Icons.newspaper_rounded,
      'outlinedIcon': Icons.newspaper_outlined,
    },
    {
      'label': "Offres d'Appui",
      'path': '/offres-appui',
      'icon': Icons.handshake_rounded,
      'outlinedIcon': Icons.handshake_outlined,
    },
    {
      'label': 'Projet',
      'path': '/officeprojet',
      'icon': Icons.business_center_rounded,
      'outlinedIcon': Icons.business_center_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _fetchProfile();
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMenu() {
    if (_menuOpen) {
      _animController.reverse().then((_) {
        _removeOverlay();
        if (mounted) setState(() => _menuOpen = false);
      });
    } else {
      setState(() => _menuOpen = true);
      _showOverlayMenu();
      _animController.forward();
    }
  }

  /// Ferme le menu immédiatement (sans animation) puis navigue.
  /// Évite le crash [Duplicate GlobalKey] causé par l'overlay
  /// qui coexiste avec le nouveau widget route pendant la transition.
  void _closeMenuAndNavigate(String path) {
    if (_menuOpen) {
      _animController.stop();
      _removeOverlay();
      if (mounted) setState(() => _menuOpen = false);
    }
    // Repousser la navigation d'une frame pour laisser Flutter
    // nettoyer l'arbre de widgets avant d'insérer la nouvelle route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(path);
    });
  }

  void _showOverlayMenu() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isAuthenticated = _fullProfile != null;
    const bool isActivated = true;
    const brandGreen = Color(0xFF098E00);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 60.0,
        left: 12,
        right: 12,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOutCubic,
            )),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF0F172A).withValues(alpha: 0.98)
                      : Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.5 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._navItems.map((item) {
                      // Utilise le chemin capturé avant la construction de l'overlay
                      // GoRouterState.of(ctx) échouerait car ctx n'est pas dans
                      // la hiérarchie du GoRouter.
                      final bool isActive =
                          GoRouterState.of(context).uri.path == item['path'];
                      final IconData iconData = isActive
                          ? (item['icon'] as IconData)
                          : (item['outlinedIcon'] as IconData);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _closeMenuAndNavigate(item['path'] as String),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? (isDarkMode
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE8F5E9))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? brandGreen.withValues(alpha: 0.2)
                                          : (isDarkMode
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: isActive
                                          ? brandGreen
                                          : (isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      style: TextStyle(
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        color: isActive
                                            ? brandGreen
                                            : (isDarkMode ? Colors.white : const Color(0xFF1E293B)),
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: brandGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    isAuthenticated
                        ? _buildMobileAuthMenu(context, isActivated, _fullProfile)
                        : _buildMobileUnauthMenu(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _showProfilePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profil Utilisateur',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF098E00),
                  ),
                  child: Center(
                    child: Text(
                      (_fullProfile?['user']?['user_pseudo'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fullProfile?['user']?['user_pseudo'] ?? 'Utilisateur connecté',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go('/profile/edit');
                    },
                    child: const Text('Modifier le profil'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF098E00)),
                    child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchProfile() async {
    try {
      final authState = <String, dynamic>{};
      final userId = authState['user_id']?.toString();
      if (userId == null) return;

      const String apiUrl = ApiConstants.gatewayBaseUrl;
      final res = await http.get(Uri.parse('$apiUrl/serviceauth/users/$userId'));
      if (res.statusCode != 200) return;

      final userData = jsonDecode(res.body);
      final userProfile = userData['user'] ?? userData;
      final citizenId = userProfile['id_citizen'] ?? userProfile['citizen_id'];

      const invalidCitizenIds = {
        null,
        '',
        '00000000-0000-0000-0000-000000000000',
        '550e8400-e29b-41d4-a716-446655440000',
      };

      if (citizenId == null || invalidCitizenIds.contains(citizenId)) {
        if (mounted) setState(() => _fullProfile = {'user': userProfile, 'citoyen': null});
        return;
      }

      final citizenRes = await http.get(
          Uri.parse('$apiUrl/servicecitoyen/citizens/getCitizenById/$citizenId'));
      if (citizenRes.statusCode == 200) {
        final citizenData = jsonDecode(citizenRes.body);
        if (mounted) setState(() => _fullProfile = {'user': userProfile, 'citoyen': citizenData});
      } else {
        if (mounted) setState(() => _fullProfile = {'user': userProfile, 'citoyen': null});
      }
    } catch (e) {
      debugPrint('Header: Error fetching user profile: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = _fullProfile != null;
    final bool isActivated = true;
    final dynamic user = _fullProfile;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Container(
      height: 64.0,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withValues(alpha: 0.97)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              // ── Logo / Branding ────────────────────────────────────
              GestureDetector(
                onTap: () {
                  if (_menuOpen) _toggleMenu();
                  context.go('/');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isDarkMode ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ] : null,
                        ),
                        child: Image.asset(
                          'assets/images/logo_dd_v3.png',
                          height: 34,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/logo_dd.png',
                            height: 34,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (ctx, err, _) => Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF098E00), Color(0xFF056B00)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'T',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Nav Desktop ────────────────────────────────────────
              if (isDesktop) ...[
                const SizedBox(width: 32),
                Expanded(
                  child: Row(
                    children: _navItems.map((item) {
                      final bool isActive = currentPath == item['path'];
                      return _NavLink(
                        label: item['label'] as String,
                        path: item['path'] as String,
                        isActive: isActive,
                        isDarkMode: isDarkMode,
                      );
                    }).toList(),
                  ),
                ),
              ] else
                const Spacer(),

              // ── Actions Droite ─────────────────────────────────────
              if (isDesktop) ...[
                isAuthenticated
                    ? _buildAuthenticatedActions(context, isActivated, user, isDarkMode)
                    : _buildUnauthenticatedActions(context, isDarkMode),
              ] else ...[
                // Sur mobile : uniquement l'icône thème + burger
                _buildThemeMenuButton(context, isDarkMode),
                const SizedBox(width: 4),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _menuOpen ? Icons.close_rounded : Icons.menu_rounded,
                      key: ValueKey(_menuOpen),
                      color: isDarkMode ? Colors.white : const Color(0xFF0f0f23),
                    ),
                  ),
                  onPressed: _toggleMenu,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeMenuButton(BuildContext context, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.themeMode;

    IconData currentIcon;
    if (currentMode == ThemeMode.dark) {
      currentIcon = Icons.nightlight_round_outlined;
    } else if (currentMode == ThemeMode.light) {
      currentIcon = Icons.wb_sunny_outlined;
    } else {
      currentIcon = Icons.brightness_auto_outlined;
    }

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Changer le thème (Clair, Sombre, Système)',
      icon: Icon(
        currentIcon,
        size: 20,
        color: isDarkMode ? Colors.amber : const Color(0xFF555577),
      ),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      onSelected: (ThemeMode mode) {
        themeProvider.setThemeMode(mode);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 18, color: currentMode == ThemeMode.light ? const Color(0xFF098E00) : null),
              const SizedBox(width: 10),
              Text(
                'Mode clair',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.light ? FontWeight.bold : FontWeight.normal,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.nightlight_round_outlined, size: 18, color: currentMode == ThemeMode.dark ? const Color(0xFF098E00) : null),
              const SizedBox(width: 10),
              Text(
                'Mode sombre',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.dark ? FontWeight.bold : FontWeight.normal,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.brightness_auto_outlined, size: 18, color: currentMode == ThemeMode.system ? const Color(0xFF098E00) : null),
              const SizedBox(width: 10),
              Text(
                'Mode système',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.system ? FontWeight.bold : FontWeight.normal,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedActions(
      BuildContext context, bool isActivated, dynamic user, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildThemeMenuButton(context, isDarkMode),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showProfilePopup(context),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF098E00), Color(0xFF056B00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF098E00).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (user?['user']?['user_pseudo'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
          tooltip: 'Se déconnecter',
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedActions(BuildContext context, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildThemeMenuButton(context, isDarkMode),
        const SizedBox(width: 2),
        TextButton(
          onPressed: () => context.go('/auth/login'),
          style: TextButton.styleFrom(
            foregroundColor: isDarkMode ? Colors.white70 : const Color(0xFF1a1a2e),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'Se connecter',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),
        const SizedBox(width: 6),
        ElevatedButton(
          onPressed: () => context.go('/auth/check-id-card'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF098E00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            shadowColor: const Color(0xFF098E00).withValues(alpha: 0.4),
          ),
          child: const Text(
            "S'inscrire",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAuthMenu(BuildContext context, bool isActivated, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isActivated)
          ElevatedButton.icon(
            onPressed: () => _closeMenuAndNavigate('/modules'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF098E00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.apps_rounded),
            label: const Text('Accéder aux modules', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _closeMenuAndNavigate('/'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildMobileUnauthMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => _closeMenuAndNavigate('/auth/login'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: const BorderSide(color: Color(0xFF098E00)),
            foregroundColor: const Color(0xFF098E00),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _closeMenuAndNavigate('/auth/check-id-card'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF098E00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Widget NavLink Desktop ──────────────────────────────────────────────────
class _NavLink extends StatefulWidget {
  final String label;
  final String path;
  final bool isActive;
  final bool isDarkMode;

  const _NavLink({
    required this.label,
    required this.path,
    required this.isActive,
    required this.isDarkMode,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF098E00);
    final Color textColor = widget.isActive
        ? activeColor
        : (_hovered
            ? activeColor
            : (widget.isDarkMode ? Colors.white70 : const Color(0xFF444466)));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? activeColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight:
                  widget.isActive ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}