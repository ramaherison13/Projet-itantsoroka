import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/l10n/app_localization.dart';
import 'package:itantsoroka/services/role_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  int _userCount = 0;
  int _roleCount = 0;
  int _acteTypeCount = 0;
  int _navigationCount = 0;

  late AnimationController _bannerController;
  late Animation<double> _bannerFade;
  late Animation<Offset> _bannerSlide;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bannerFade = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOut,
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutCubic,
    ));

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bannerController.forward();
    _fetchStats();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    _refreshController.repeat();
    setState(() => _loading = true);

    try {
      // 1. Décompte utilisateurs
      try {
        final res = await http.get(
            Uri.parse('${ApiConstants.serviceAuth}/users?limit=1000'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is List) {
            _userCount = data.length;
          } else if (data is Map) {
            final list = data['users'] ?? data['data'] ?? [];
            _userCount = data['total'] ??
                data['count'] ??
                data['totalUsers'] ??
                (list is List ? list.length : 0);
          }
        }
      } catch (e) {
        debugPrint("Erreur décompte utilisateurs: $e");
      }

      // 2. Décompte rôles
      try {
        final res = await RoleService.getAllRolesWithPermission();
        List rolesList = [];
        if (res != null) {
          if (res is List) {
            rolesList = res;
          } else if (res is Map) {
            rolesList = res['roles'] ?? res['data'] ?? res['content'] ?? [];
          }
        }

        if (rolesList.isEmpty) {
          final resFallback = await http.get(Uri.parse('${ApiConstants.serviceAuth}/roles'));
          if (resFallback.statusCode >= 200 && resFallback.statusCode < 300) {
            final data = jsonDecode(resFallback.body);
            if (data is List) {
              rolesList = data;
            } else if (data is Map) {
              rolesList = data['roles'] ?? data['data'] ?? data['content'] ?? [];
            }
          }
        }

        _roleCount = rolesList.length;
      } catch (e) {
        debugPrint("Erreur décompte rôles: $e");
      }

      // 3. Décompte types d'actes (Contrôle de Légalité)
      try {
        final res = await http.get(Uri.parse(
            '${ApiConstants.serviceControleDeLegalite}/acte-types'));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final data = jsonDecode(res.body);
          if (data is List) {
            _acteTypeCount = data.length;
          } else if (data is Map) {
            final list = data['data'] ?? data['types'] ?? [];
            _acteTypeCount =
                data['total'] ?? (list is List ? list.length : 0);
          }
        }
      } catch (e) {
        debugPrint("Erreur décompte types actes: $e");
      }

      // 4. Décompte navigations
      try {
        final endpoints = [
          '${ApiConstants.serviceAuth}/navigation/by-app/8',
          '${ApiConstants.serviceAuth}/navigation/by-application/1',
          '${ApiConstants.serviceAuth}/navigation',
        ];
        for (final ep in endpoints) {
          try {
            final res = await http.get(Uri.parse(ep));
            if (res.statusCode >= 200 && res.statusCode < 300) {
              final data = jsonDecode(res.body);
              if (data is List) {
                _navigationCount = data.length;
                break;
              } else if (data is Map) {
                final list = data['data'] ??
                    data['navigation'] ??
                    data['navigations'] ??
                    [];
                _navigationCount =
                    data['total'] ?? (list is List ? list.length : 0);
                if (_navigationCount > 0) break;
              }
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint("Erreur décompte navigations: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _refreshController.stop();
        _refreshController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final double hPad = AdminTheme.horizontalPadding(context);

    final List<Map<String, dynamic>> adminModules = [
      {
        'title': context.tr('admin_users'),
        'description': context.tr('admin_users_desc'),
        'icon': Icons.people_alt_rounded,
        'color': AdminTheme.primaryLight,
        'route': '/admin/users',
        'badge': _loading ? '...' : '$_userCount ${context.tr('admin_comptes')}',
        'gradient': [const Color(0xFF059669), const Color(0xFF10B981)],
      },
      {
        'title': context.tr('admin_passwords'),
        'description': context.tr('admin_passwords_desc'),
        'icon': Icons.lock_reset_rounded,
        'color': AdminTheme.info,
        'route': '/admin/passwords',
        'badge': context.tr('admin_securite'),
        'gradient': [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
      },
      {
        'title': context.tr('admin_roles'),
        'description': context.tr('admin_roles_desc'),
        'icon': Icons.admin_panel_settings_rounded,
        'color': AdminTheme.purple,
        'route': '/admin/roles',
        'badge': _loading ? '...' : '$_roleCount ${context.tr('admin_roles_label')}',
        'gradient': [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)],
      },
      {
        'title': context.tr('admin_act_types'),
        'description': context.tr('admin_act_types_desc'),
        'icon': Icons.gavel_rounded,
        'color': AdminTheme.warning,
        'route': '/admin/acte-type-management/type',
        'badge': _loading ? '...' : '$_acteTypeCount ${context.tr('admin_types')}',
        'gradient': [const Color(0xFFD97706), const Color(0xFFF59E0B)],
      },
      {
        'title': context.tr('admin_navigation'),
        'description': context.tr('admin_navigation_desc'),
        'icon': Icons.alt_route_rounded,
        'color': AdminTheme.pink,
        'route': '/admin/navigations',
        'badge': _loading ? '...' : '$_navigationCount ${context.tr('admin_menus')}',
        'gradient': [const Color(0xFFBE185D), const Color(0xFFEC4899)],
      },
      {
        'title': context.tr('admin_affiliations'),
        'description': context.tr('admin_affiliations_desc'),
        'icon': Icons.account_balance_rounded,
        'color': AdminTheme.primary,
        'route': '/admin/affiliation',
        'badge': context.tr('admin_services'),
        'gradient': [const Color(0xFF04630A), const Color(0xFF098E00)],
      },
    ];

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AdminTheme.primary,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bannière de bienvenue ─────────────────────────────────
            FadeTransition(
              opacity: _bannerFade,
              child: SlideTransition(
                position: _bannerSlide,
                child: _WelcomeBanner(
                  loading: _loading,
                  onRefresh: _fetchStats,
                  refreshController: _refreshController,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Stats rapides ─────────────────────────────────────────
            _QuickStatsRow(
              userCount: _userCount,
              roleCount: _roleCount,
              loading: _loading,
              isDark: isDark,
            ),

            const SizedBox(height: 28),

            // ── Titre de section ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('admin_modules_title'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.text(context),
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (_loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AdminTheme.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Grille responsive de modules ──────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                int cols = 1;
                if (constraints.maxWidth > 1100) {
                  cols = 3;
                } else if (constraints.maxWidth > 640) {
                  cols = 2;
                }

                if (cols == 1) {
                  // Mobile: liste verticale de cartes
                  return Column(
                    children: adminModules
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModuleCard(
                                module: e.value,
                                index: e.key,
                                isDark: isDark,
                                isMobile: true,
                              ),
                            ))
                        .toList(),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 170,
                  ),
                  itemCount: adminModules.length,
                  itemBuilder: (context, index) => _ModuleCard(
                    module: adminModules[index],
                    index: index,
                    isDark: isDark,
                    isMobile: false,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final bool loading;
  final VoidCallback onRefresh;
  final AnimationController refreshController;

  const _WelcomeBanner({
    required this.loading,
    required this.onRefresh,
    required this.refreshController,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: AdminTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône avec cercle lumineux
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.space_dashboard_rounded,
              size: isMobile ? 28 : 36,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),

          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('admin_title'),
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('admin_subtitle'),
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Bouton actualiser
          AnimatedBuilder(
            animation: refreshController,
            builder: (context, child) => Transform.rotate(
              angle: refreshController.value * 2 * math.pi,
              child: child,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Actualiser',
              onPressed: loading ? null : onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK STATS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final int userCount;
  final int roleCount;
  final bool loading;
  final bool isDark;

  const _QuickStatsRow({
    required this.userCount,
    required this.roleCount,
    required this.loading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'label': context.tr('admin_users'),
        'value': loading ? '-' : '$userCount',
        'icon': Icons.people_alt_rounded,
        'color': AdminTheme.primaryLight,
      },
      {
        'label': context.tr('admin_roles_label'),
        'value': loading ? '-' : '$roleCount',
        'icon': Icons.shield_rounded,
        'color': AdminTheme.purple,
      },
      {
        'label': context.tr('admin_statut'),
        'value': context.tr('admin_actif'),
        'icon': Icons.check_circle_rounded,
        'color': AdminTheme.info,
      },
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: s == stats.last ? 0 : 12,
                  ),
                  child: _StatTile(stat: s, isDark: isDark),
                ),
              ))
          .toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  final Map<String, dynamic> stat;
  final bool isDark;

  const _StatTile({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = stat['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat['icon'] as IconData, color: color, size: 20),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AdminTheme.textPrimaryDark
                      : AdminTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stat['label'] as String,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AdminTheme.textSecondaryDark
                  : AdminTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODULE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleCard extends StatefulWidget {
  final Map<String, dynamic> module;
  final int index;
  final bool isDark;
  final bool isMobile;

  const _ModuleCard({
    required this.module,
    required this.index,
    required this.isDark,
    required this.isMobile,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final Color itemColor = module['color'] as Color;
    final List<Color> gradColors = (module['gradient'] as List).cast<Color>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          context.go(module['route'] as String);
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AdminTheme.surfaceDark
                  : AdminTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(
                color: _hovered
                    ? itemColor.withValues(alpha: 0.4)
                    : (widget.isDark
                        ? AdminTheme.borderDark
                        : AdminTheme.borderLight),
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: itemColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : AdminTheme.shadowSm,
            ),
            child: widget.isMobile
                ? _mobileContent(itemColor, gradColors, module)
                : _gridContent(itemColor, gradColors, module),
          ),
        ),
      ),
    );
  }

  /// Layout mobile : horizontal compact
  Widget _mobileContent(
      Color color, List<Color> gradColors, Map<String, dynamic> module) {
    return Row(
      children: [
        // Icône avec gradient
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            module['icon'] as IconData,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module['title'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark
                      ? AdminTheme.textPrimaryDark
                      : AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                module['description'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDark
                      ? AdminTheme.textSecondaryDark
                      : AdminTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AdminTheme.badge(module['badge'] as String, color),
            const SizedBox(height: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: widget.isDark
                  ? AdminTheme.textMutedDark
                  : AdminTheme.textMuted,
            ),
          ],
        ),
      ],
    );
  }

  /// Layout grille tablette/desktop
  Widget _gridContent(
      Color color, List<Color> gradColors, Map<String, dynamic> module) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                module['icon'] as IconData,
                color: Colors.white,
                size: 22,
              ),
            ),
            AdminTheme.badge(module['badge'] as String, color),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module['title'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.isDark
                    ? AdminTheme.textPrimaryDark
                    : AdminTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              module['description'] as String,
              style: TextStyle(
                fontSize: 11.5,
                color: widget.isDark
                    ? AdminTheme.textSecondaryDark
                    : AdminTheme.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
