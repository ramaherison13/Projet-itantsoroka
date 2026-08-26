import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/providers/theme_provider.dart';
import 'package:itantsoroka/providers/auth_provider.dart';
import 'package:itantsoroka/services/role_navigation_service.dart';
import 'package:itantsoroka/widgets/language_setting_widget.dart';

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

  // Les items de navigation sont maintenant dynamiques (voir _buildNavItems)
  // et filtrés selon le rôle de l'utilisateur connecté.

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
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

    // Navigation filtrée par rôle pour le menu mobile
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roleNavItems = RoleNavigationService.getAllowedNavItems(auth.roleSlugs);

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
                    ...roleNavItems.map((item) {
                      // Utilise le chemin capturé avant la construction de l'overlay
                      // GoRouterState.of(ctx) échouerait car ctx n'est pas dans
                      // la hiérarchie du GoRouter.
                      final String currentPath = GoRouterState.of(context).uri.path;
                      final bool isActive = currentPath == item.path ||
                          (item.path != '/' && currentPath.startsWith(item.path));
                      final IconData iconData = isActive ? item.selectedIcon : item.icon;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _closeMenuAndNavigate(item.path),
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
                                      item.label,
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

  AuthProvider? _getAuth(BuildContext ctx) {
    try {
      return Provider.of<AuthProvider>(ctx, listen: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showProfilePopup(BuildContext context) async {
    // Cache context-dependent values before async gap
    final auth = _getAuth(context);
    if (_fullProfile == null) {
      await _fetchProfile();
    }
    if (!mounted) return;

    final userObj = _fullProfile?['user'] as Map<String, dynamic>?;
    final citoyenObj = _fullProfile?['citoyen'] as Map<String, dynamic>?;

    // Calcul du nom complet
    String fullName = '';
    if (citoyenObj != null) {
      final firstName = citoyenObj['citizen_first_name'] ?? citoyenObj['first_name'] ?? citoyenObj['prenom'] ?? userObj?['user_first_name'] ?? '';
      final lastName = citoyenObj['citizen_last_name'] ?? citoyenObj['last_name'] ?? citoyenObj['nom'] ?? userObj?['user_last_name'] ?? '';
      fullName = '$firstName $lastName'.trim();
    }
    if (fullName.isEmpty && userObj != null) {
      fullName = userObj['user_pseudo'] ?? userObj['user_email'] ?? '';
    }
    if (fullName.isEmpty && auth != null) {
      fullName = auth.userName;
    }

    // Pseudo / handle (@pseudo)
    final String rawPseudo = userObj?['user_pseudo'] ?? auth?.user?.userPseudo ?? 'user';
    final String pseudo = rawPseudo.startsWith('@') ? rawPseudo.substring(1) : rawPseudo;

    // Toerana misy (Adresse / Fokontany, Commune, District)
    String locationStr = '';
    if (citoyenObj != null || userObj != null) {
      final rawAddress = citoyenObj?['citizen_adress'] ??
          citoyenObj?['citizen_address'] ??
          citoyenObj?['address'] ??
          citoyenObj?['adresse'] ??
          citoyenObj?['fokontany'] ??
          citoyenObj?['fokontany_name'] ??
          userObj?['user_address'] ??
          userObj?['address'];

      final commune = citoyenObj?['commune_name'] ??
          citoyenObj?['municipality_name'] ??
          citoyenObj?['commune'] ??
          userObj?['municipality_name'] ??
          userObj?['municipalityName'] ??
          '';

      final district = citoyenObj?['district_name'] ??
          citoyenObj?['district'] ??
          userObj?['district_name'] ??
          userObj?['districtName'] ??
          '';

      final parts = <String>[];
      final locCandidates = [rawAddress, commune, district];
      for (final candidate in locCandidates) {
        if (candidate == null) continue;
        final cStr = candidate.toString().trim();
        if (cStr.isEmpty || cStr == 'N/A' || cStr == 'null') continue;

        if (_locationNameCache.containsKey(cStr)) {
          final cached = _locationNameCache[cStr]!;
          if (!parts.contains(cached)) parts.add(cached);
        } else if (_isCodeOrUuid(cStr)) {
          if (!parts.contains(cStr)) parts.add(cStr);
          _resolveLocationName(cStr).then((resolved) {
            if (resolved != null && mounted) {
              setState(() {
                if (citoyenObj != null) {
                  citoyenObj['citizen_adress'] = resolved;
                } else if (userObj != null) {
                  userObj['user_address'] = resolved;
                }
              });
            }
          });
        } else {
          if (!parts.contains(cStr)) parts.add(cStr);
        }
      }

      if (parts.isNotEmpty) {
        locationStr = parts.join(', ');
      }
    }
    if (locationStr.isEmpty && auth?.user?.municipalityName != null && auth!.user!.municipalityName.isNotEmpty) {
      locationStr = auth.user!.municipalityName;
    }
    if (locationStr.isEmpty) {
      locationStr = 'Non renseigné';
    }

    // Andraikitra (Roles)
    String rolesStr = '';
    if (userObj != null && userObj['roles'] != null) {
      final rList = userObj['roles'];
      if (rList is List) {
        rolesStr = rList
            .map((r) => (r is Map ? (r['role_slug'] ?? r['role_name'] ?? r['name']) : r.toString()))
            .where((s) => s.toString().trim().isNotEmpty)
            .join(', ');
      }
    }
    if (rolesStr.isEmpty && auth != null && auth.roleSlugs.isNotEmpty) {
      rolesStr = auth.roleSlugs.join(', ');
    }
    if (rolesStr.isEmpty) {
      rolesStr = 'Citoyen';
    }

    // Mailaka (Email)
    String emailStr = userObj?['user_email'] ?? citoyenObj?['email'] ?? auth?.userEmail ?? '';
    if (emailStr.isEmpty) {
      emailStr = 'Non renseigné';
    }

    // Laharana finday (Phone)
    String phoneStr = citoyenObj?['phone_number'] ??
        citoyenObj?['phone'] ??
        citoyenObj?['citizen_phone'] ??
        userObj?['user_phone'] ??
        userObj?['phone'] ??
        '';
    if (phoneStr.isEmpty) {
      phoneStr = 'Non renseigné';
    }

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (BuildContext ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF161E2E) : const Color(0xFF192231);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 340,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Bouton Fermer (X) ─────────────────────────────────────────
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 10),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                      splashRadius: 18,
                    ),
                  ),
                ),

                // ── Avatar avec Logo Oeil Vert Glowing ────────────────────────
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F2618),
                    border: Border.all(color: const Color(0xFF00E676), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo_dd_v3.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/logo_dd.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, _) => const Icon(
                            Icons.visibility_rounded,
                            color: Color(0xFF00E676),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Nom complet ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ── Pseudo @handle ───────────────────────────────────────────
                Text(
                  '@$pseudo',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00E676),
                  ),
                ),
                const SizedBox(height: 22),

                // ── Liste des informations du profil ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 1. Toerana misy (Location)
                      _buildProfileInfoItem(
                        icon: Icons.location_on_outlined,
                        label: 'Toerana misy',
                        value: locationStr,
                      ),
                      const SizedBox(height: 14),

                      // 2. Andraikitra (Roles)
                      _buildProfileInfoItem(
                        icon: Icons.cases_outlined,
                        label: 'Andraikitra',
                        value: rolesStr,
                      ),
                      const SizedBox(height: 14),

                      // 3. Mailaka (Email)
                      _buildProfileInfoItem(
                        icon: Icons.email_outlined,
                        label: 'Mailaka',
                        value: emailStr,
                      ),
                      const SizedBox(height: 14),

                      // 4. Laharana finday (Phone)
                      _buildProfileInfoItem(
                        icon: Icons.phone_outlined,
                        label: 'Laharana finday',
                        value: phoneStr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Bouton "Modifier mon profil" ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.go('/profile/edit');
                      },
                      icon: const Icon(Icons.edit_square, size: 19),
                      label: const Text(
                        'Modifier mon profil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF098E00),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF098E00).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            color: const Color(0xFF00E676),
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static final Map<String, String> _locationNameCache = {};

  static bool _isCodeOrUuid(String? str) {
    if (str == null) return false;
    final s = str.trim();
    if (s.isEmpty || s == 'N/A' || s == 'null') return false;
    // UUID pattern
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(s)) return true;
    // Pure numeric ID
    if (RegExp(r'^\d+$').hasMatch(s)) return true;
    // Formatted territory code pattern like "056IG256", "DIS-001", "C056IG256" (no spaces, contains numbers + letters)
    if (!s.contains(' ') && RegExp(r'^[A-Za-z0-9_-]{4,30}$').hasMatch(s) && RegExp(r'\d').hasMatch(s)) {
      return true;
    }
    return false;
  }

  Future<String?> _resolveLocationName(String? rawId, {bool isDistrict = false}) async {
    if (rawId == null) return null;
    final id = rawId.trim();
    if (id.isEmpty || id == 'N/A' || id == 'null') return null;

    if (!_isCodeOrUuid(id)) return id;
    if (_locationNameCache.containsKey(id)) return _locationNameCache[id];

    const String apiUrl = ApiConstants.gatewayBaseUrl;
    final endpoints = isDistrict
        ? [
            '$apiUrl/servicetritoire-v2/districts/$id',
            '$apiUrl/servicetritoire-v2/communes/noForm/$id',
            '$apiUrl/servicetritoire-v2/communes/$id',
            '$apiUrl/serviceressource/districts',
          ]
        : [
            '$apiUrl/servicetritoire-v2/communes/noForm/$id',
            '$apiUrl/servicetritoire-v2/communes/$id',
            '$apiUrl/servicetritoire-v2/districts/$id',
          ];

    for (final ep in endpoints) {
      try {
        final res = await http.get(Uri.parse(ep));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map) {
            final name = data['name'] ??
                data['label'] ??
                data['commune_name'] ??
                data['district_name'] ??
                data['name_fr'] ??
                data['libelle'] ??
                data['nom'];
            if (name != null && name.toString().trim().isNotEmpty && !_isCodeOrUuid(name.toString())) {
              final result = name.toString().trim();
              _locationNameCache[id] = result;
              return result;
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _enrichProfileLocationData(Map<String, dynamic> fullProfile) async {
    try {
      final userObj = fullProfile['user'] as Map<String, dynamic>?;
      final citoyenObj = fullProfile['citoyen'] as Map<String, dynamic>?;

      final addrVal = citoyenObj?['citizen_adress'] ?? citoyenObj?['citizen_address'] ?? userObj?['user_address'];
      final communeVal = citoyenObj?['commune_name'] ??
          citoyenObj?['municipality_name'] ??
          citoyenObj?['commune'] ??
          userObj?['municipality_name'] ??
          userObj?['municipalityName'] ??
          userObj?['municipality_id'];
      final districtVal = citoyenObj?['district_name'] ??
          citoyenObj?['district'] ??
          userObj?['district_name'] ??
          userObj?['districtName'] ??
          userObj?['district_id'];

      if (addrVal != null && _isCodeOrUuid(addrVal.toString())) {
        final resolved = await _resolveLocationName(addrVal.toString(), isDistrict: false);
        if (resolved != null) {
          if (citoyenObj != null) citoyenObj['citizen_adress'] = resolved;
          if (userObj != null) userObj['user_address'] = resolved;
        }
      }

      if (communeVal != null && _isCodeOrUuid(communeVal.toString())) {
        final resolved = await _resolveLocationName(communeVal.toString(), isDistrict: false);
        if (resolved != null) {
          if (citoyenObj != null) citoyenObj['commune_name'] = resolved;
          if (userObj != null) userObj['municipality_name'] = resolved;
        }
      }

      if (districtVal != null && _isCodeOrUuid(districtVal.toString())) {
        final resolved = await _resolveLocationName(districtVal.toString(), isDistrict: true);
        if (resolved != null) {
          if (citoyenObj != null) citoyenObj['district_name'] = resolved;
          if (userObj != null) userObj['district_name'] = resolved;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchProfile() async {
    try {
      if (!mounted) return;
      final auth = _getAuth(context);
      String? userId = auth?.user?.userId;

      if (userId == null || userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          try {
            String resolvedToken = token;
            try {
              final parsed = jsonDecode(token);
              if (parsed is String) {
                resolvedToken = parsed;
              } else if (parsed is Map) {
                resolvedToken = parsed['access_token'] ?? parsed['token'] ?? token;
              }
            } catch (_) {}
            final parts = resolvedToken.split('.');
            if (parts.length > 1) {
              final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
              userId = payload['user_id']?.toString() ?? payload['id']?.toString() ?? payload['sub']?.toString();
            }
          } catch (_) {}
        }
      }

      if (userId == null || userId.isEmpty) return;

      const String apiUrl = ApiConstants.gatewayBaseUrl;
      final res = await http.get(Uri.parse('$apiUrl/serviceauth/users/$userId'));
      if (res.statusCode != 200) return;

      final userData = jsonDecode(res.body);
      final userProfile = userData['user'] ?? userData;
      dynamic citoyenObj = userData['citoyen'] ?? userData['citizen'] ?? userProfile['citoyen'] ?? userProfile['citizen'];
      final citizenId = userProfile['id_citizen'] ?? userProfile['citizen_id'];

      const invalidCitizenIds = {
        null,
        '',
        '00000000-0000-0000-0000-000000000000',
        '550e8400-e29b-41d4-a716-446655440000',
      };

      if (citoyenObj is! Map || citoyenObj.isEmpty) {
        citoyenObj = null;
        if (citizenId != null && !invalidCitizenIds.contains(citizenId)) {
          try {
            final citizenRes = await http.get(
              Uri.parse('$apiUrl/servicecitoyen/citizens/getCitizenById/$citizenId'),
            );
            if (citizenRes.statusCode == 200) {
              final cData = jsonDecode(citizenRes.body);
              if (cData is Map && cData.isNotEmpty) {
                citoyenObj = cData;
              }
            }
          } catch (_) {}
        }
      }

      if (citoyenObj == null) {
        try {
          final citizenByUserIdRes = await http.get(
            Uri.parse('$apiUrl/servicecitoyen/citizens/user/$userId'),
          );
          if (citizenByUserIdRes.statusCode == 200) {
            final cData = jsonDecode(citizenByUserIdRes.body);
            if (cData is Map && cData.isNotEmpty) {
              citoyenObj = cData;
            }
          }
        } catch (_) {}
      }

      final profileMap = {'user': userProfile, 'citoyen': citoyenObj};
      await _enrichProfileLocationData(profileMap);
      if (mounted) setState(() => _fullProfile = profileMap);
    } catch (e) {
      debugPrint('Header: Error fetching user profile: $e');
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

    // Navigation filtrée par rôle
    final auth = context.watch<AuthProvider>();
    final roleNavItems = RoleNavigationService.getAllowedNavItems(auth.roleSlugs);

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
                    children: roleNavItems.map((item) {
                      final bool isActive = currentPath == item.path ||
                          (item.path != '/' && currentPath.startsWith(item.path));
                      return _NavLink(
                        label: item.label,
                        path: item.path,
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
        const LanguageSettingWidget(),
        const SizedBox(width: 6),
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
        const LanguageSettingWidget(),
        const SizedBox(width: 6),
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