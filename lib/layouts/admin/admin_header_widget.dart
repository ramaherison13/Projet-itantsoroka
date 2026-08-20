import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/providers/theme_provider.dart';
import 'package:itantsoroka/services/citizens_service.dart';

class AdminHeaderWidget extends StatefulWidget implements PreferredSizeWidget {
  final bool menuOpen;
  final ValueChanged<bool> onMenuToggle;

  const AdminHeaderWidget({
    super.key,
    required this.menuOpen,
    required this.onMenuToggle,
  });

  @override
  State<AdminHeaderWidget> createState() => _AdminHeaderWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(64.0);
}

class _AdminHeaderWidgetState extends State<AdminHeaderWidget>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _fullProfile;
  late AnimationController _menuIconController;

  final bool isAuthenticated = true;
  final dynamic user = {
    'user_id': 1,
    'user_pseudo': 'Admin',
    'user_email': 'admin@example.com',
  };

  @override
  void initState() {
    super.initState();
    _menuIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fetchProfile();
  }

  @override
  void dispose() {
    _menuIconController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdminHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menuOpen != oldWidget.menuOpen) {
      if (widget.menuOpen) {
        _menuIconController.forward();
      } else {
        _menuIconController.reverse();
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = user?['user_id']?.toString();
      if (userId == null || userId == '1') return;

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
        if (mounted) {
          setState(() => _fullProfile = {'user': userProfile, 'citoyen': null});
        }
        return;
      }

      final citizenRes = await http.get(
        Uri.parse('$apiUrl/servicecitoyen/citizens/getCitizenById/$citizenId'),
      );
      if (!mounted) return;
      if (citizenRes.statusCode == 200) {
        final citizenData = jsonDecode(citizenRes.body);
        setState(
          () => _fullProfile = {'user': userProfile, 'citoyen': citizenData},
        );
      } else {
        setState(() => _fullProfile = {'user': userProfile, 'citoyen': null});
      }
    } catch (e) {
      debugPrint('Admin Header: Error fetching user profile: $e');
    }
  }

  String? _getAvatarUrl() {
    final photo =
        _fullProfile?['citoyen']?['citizen_photo'] ??
        _fullProfile?['user']?['user_photo'];
    if (photo != null && photo.toString().trim().isNotEmpty) {
      return CitizensService.getCitizenAvatarPreview(photo.toString().trim());
    }
    return null;
  }

  void _handleLogout() => context.go('/auth/login');

  void _showProfilePopup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusLg)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340,
            decoration: BoxDecoration(
              color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
              boxShadow: AdminTheme.shadowLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête coloré
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AdminTheme.primaryGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AdminTheme.radiusLg),
                      topRight: Radius.circular(AdminTheme.radiusLg),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 2.5),
                        ),
                        child: _buildAvatar(_getAvatarUrl(), 52),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _fullProfile?['user']?['user_pseudo'] ??
                            user?['user_pseudo'] ??
                            'Administrateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fullProfile?['user']?['user_email'] ??
                            user?['user_email'] ??
                            '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AdminTheme.badge('Super-Admin', AdminTheme.accent,
                          fontSize: 11),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _profileMenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Mon Profil',
                        color: AdminTheme.info,
                        isDark: isDark,
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                      const SizedBox(height: 8),
                      _profileMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        color: AdminTheme.warning,
                        isDark: isDark,
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _handleLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AdminTheme.radiusSm)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Déconnexion',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          color: color.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark
                  ? AdminTheme.textMutedDark
                  : AdminTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final String? avatarUrl = _getAvatarUrl();
    final bool isLargeScreen = context.screenWidth >= AdminTheme.tabletMax;
    final bool isMobile = context.isMobile;

    return Container(
      height: 64.0,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Bouton Hamburger animé (mobile/tablette) ──
          if (!isLargeScreen)
            _AnimatedMenuButton(
              isOpen: widget.menuOpen,
              isDark: isDark,
              onTap: () => widget.onMenuToggle(!widget.menuOpen),
            ),

          if (!isLargeScreen) const SizedBox(width: 8),

          // ── Logo / Bouton Accueil Admin ──
          _HomeButton(isMobile: isMobile, isDark: isDark),

          const Spacer(),

          // ── Actions droite ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton thème
              _ThemeToggleButton(isDark: isDark),

              const SizedBox(width: 4),

              // Notifications (badge)
              if (!isMobile) _NotificationButton(isDark: isDark),

              if (!isMobile) const SizedBox(width: 4),

              // Avatar admin
              if (isAuthenticated)
                GestureDetector(
                  onTap: () => _showProfilePopup(context),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AdminTheme.primary, width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: AdminTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _buildAvatar(avatarUrl, 32),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, double size) {
    if (avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialsAvatar(size),
        ),
      );
    }
    return _buildInitialsAvatar(size);
  }

  Widget _buildInitialsAvatar(double size) {
    final String initial =
        user?['user_pseudo']?[0]?.toUpperCase() ??
        user?['user_email']?[0]?.toUpperCase() ??
        'A';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF098E00), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedMenuButton extends StatelessWidget {
  final bool isOpen;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedMenuButton({
    required this.isOpen,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isOpen
            ? AdminTheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              RotationTransition(turns: animation, child: child),
          child: Icon(
            isOpen ? Icons.close_rounded : Icons.menu_rounded,
            key: ValueKey<bool>(isOpen),
            color: isOpen
                ? AdminTheme.primary
                : (isDark ? Colors.white70 : AdminTheme.textSecondary),
            size: 22,
          ),
        ),
        onPressed: onTap,
        tooltip: isOpen ? 'Fermer le menu' : 'Ouvrir le menu',
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final bool isMobile;
  final bool isDark;

  const _HomeButton({required this.isMobile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/admin'),
      borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AdminTheme.surface2Dark.withValues(alpha: 0.6)
              : AdminTheme.dividerLight,
          borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
          border: Border.all(
            color: isDark
                ? AdminTheme.borderDark
                : AdminTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: isDark ? AdminTheme.accent : AdminTheme.primary,
            ),
            if (!isMobile) ...[
              const SizedBox(width: 6),
              Text(
                'Administration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AdminTheme.accent : AdminTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final bool isDark;
  const _ThemeToggleButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDark ? 'Mode Clair' : 'Mode Sombre',
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        onTap: () => Provider.of<ThemeProvider>(context, listen: false)
            .toggleTheme(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            color: isDark
                ? Colors.amber.withValues(alpha: 0.1)
                : AdminTheme.dividerLight,
          ),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            color: isDark ? Colors.amber : AdminTheme.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final bool isDark;
  const _NotificationButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notifications',
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        onTap: () {},
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            color: isDark
                ? AdminTheme.surface2Dark.withValues(alpha: 0.5)
                : AdminTheme.dividerLight,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.white70 : AdminTheme.textSecondary,
                size: 18,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AdminTheme.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}