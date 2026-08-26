import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/role_navigation_service.dart';

/// Tableau de bord adaptatif affiché selon le rôle de l'utilisateur connecté.
class RoleDashboardScreen extends StatelessWidget {
  final String? role;
  const RoleDashboardScreen({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated || auth.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final slugs = auth.roleSlugs;
    final modules = RoleNavigationService.getDashboardModules(slugs);

    if (modules.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roleDisplayName = RoleNavigationService.getRoleDisplayName(slugs);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final crossAxisCount = screenWidth >= 1200 ? 4 : (screenWidth >= 768 ? 3 : 2);
    final childAspectRatio = isMobile ? 0.95 : (isTablet ? 1.0 : 1.1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F4F8),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(
                roleDisplayName: roleDisplayName,
                userName: auth.userName,
                isDark: isDark,
                isMobile: isMobile,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF098E00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Modules disponibles',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A2420),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF098E00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${modules.length} modules',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF098E00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                0,
                isMobile ? 16 : 24,
                isMobile ? 100 : 40,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: isMobile ? 12 : 16,
                  crossAxisSpacing: isMobile ? 12 : 16,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ModuleCard(module: modules[i], isDark: isDark, isMobile: isMobile),
                  childCount: modules.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String roleDisplayName;
  final String userName;
  final bool isDark;
  final bool isMobile;

  const _DashboardHeader({
    required this.roleDisplayName,
    required this.userName,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24, isMobile ? 20 : 28, isMobile ? 16 : 24, isMobile ? 20 : 28,
      ),
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF098E00), Color(0xFF0dba00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF098E00).withValues(alpha: 0.35),
            blurRadius: isMobile ? 16 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? 50 : 64,
            height: isMobile ? 50 : 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Center(
              child: userName.isNotEmpty
                  ? Text(
                      userName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(Icons.person_rounded, color: Colors.white, size: isMobile ? 26 : 32),
            ),
          ),
          SizedBox(width: isMobile ? 14 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bienvenue,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleDisplayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final RoleModule module;
  final bool isDark;
  final bool isMobile;

  const _ModuleCard({required this.module, required this.isDark, required this.isMobile});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
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
    final m = widget.module;
    final isDark = widget.isDark;
    final isMobile = widget.isMobile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) { setState(() => _pressed = true); _controller.forward(); },
        onTapUp: (_) { setState(() => _pressed = false); _controller.reverse(); context.go(m.path); },
        onTapCancel: () { setState(() => _pressed = false); _controller.reverse(); },
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isDark
                  ? (_pressed ? const Color(0xFF1E293B) : const Color(0xFF161E2E))
                  : (_pressed ? const Color(0xFFF0FDF4) : Colors.white),
              borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
              border: Border.all(
                color: _pressed
                    ? m.color.withValues(alpha: 0.5)
                    : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200),
                width: _pressed ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _pressed
                      ? m.color.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: _pressed ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: isMobile ? 42 : 48,
                    height: isMobile ? 42 : 48,
                    decoration: BoxDecoration(
                      color: m.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                    ),
                    child: Icon(m.icon, color: m.color, size: isMobile ? 22 : 26),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A2420),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isMobile) ...[
                        const SizedBox(height: 3),
                        Text(
                          m.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
