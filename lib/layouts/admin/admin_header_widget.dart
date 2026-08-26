import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/providers/theme_provider.dart';
import 'package:itantsoroka/services/citizens_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:itantsoroka/providers/auth_provider.dart';
import 'package:itantsoroka/widgets/language_setting_widget.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
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

  AuthProvider? _getAuth(BuildContext ctx) {
    try {
      return Provider.of<AuthProvider>(ctx, listen: false);
    } catch (_) {
      return null;
    }
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

  String? _extractNameFromJson(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      if (data['data'] != null) {
        final res = _extractNameFromJson(data['data']);
        if (res != null) return res;
      }
      if (data['district'] != null) {
        final res = _extractNameFromJson(data['district']);
        if (res != null) return res;
      }
      if (data['commune'] != null) {
        final res = _extractNameFromJson(data['commune']);
        if (res != null) return res;
      }
      final name = data['name'] ??
          data['label'] ??
          data['commune_name'] ??
          data['district_name'] ??
          data['name_fr'] ??
          data['libelle'] ??
          data['nom'];
      if (name != null && name.toString().trim().isNotEmpty && !_isCodeOrUuid(name.toString())) {
        return name.toString().trim();
      }
    } else if (data is List && data.isNotEmpty) {
      return _extractNameFromJson(data.first);
    }
    return null;
  }

  Future<String?> _resolveLocationName(String? rawId, {bool isDistrict = false}) async {
    if (rawId == null) return null;
    final id = rawId.trim();
    if (id.isEmpty || id == 'N/A' || id == 'null') return null;

    if (!_isCodeOrUuid(id)) return id;
    if (_locationNameCache.containsKey(id)) return _locationNameCache[id];

    const String apiUrl = ApiConstants.gatewayBaseUrl;
    final endpoints = [
      '$apiUrl/servicetritoire-v2/districts/$id',
      '$apiUrl/servicetritoire-v2/communes/noForm/$id',
      '$apiUrl/servicetritoire-v2/communes/$id',
      '$apiUrl/servicetritoire-v2/regions/$id',
      '$apiUrl/serviceressource/districts',
    ];

    for (final ep in endpoints) {
      try {
        final res = await http.get(Uri.parse(ep));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final name = _extractNameFromJson(data);
          if (name != null && name.isNotEmpty) {
            _locationNameCache[id] = name;
            return name;
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
      if (mounted) {
        setState(() => _fullProfile = profileMap);
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
    if (fullName.isEmpty) {
      fullName = 'Admin';
    }

    // Pseudo / handle (@pseudo)
    final String rawPseudo = userObj?['user_pseudo'] ?? auth?.user?.userPseudo ?? 'admin';
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
      rolesStr = 'Super-Admin';
    }

    // Mailaka (Email)
    String emailStr = userObj?['user_email'] ?? citoyenObj?['email'] ?? auth?.userEmail ?? '';
    if (emailStr.isEmpty) {
      emailStr = 'admin@example.com';
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
                      _buildAdminProfileInfoItem(
                        icon: Icons.location_on_outlined,
                        label: 'Toerana misy',
                        value: locationStr,
                      ),
                      const SizedBox(height: 14),

                      // 2. Andraikitra (Roles)
                      _buildAdminProfileInfoItem(
                        icon: Icons.cases_outlined,
                        label: 'Andraikitra',
                        value: rolesStr,
                      ),
                      const SizedBox(height: 14),

                      // 3. Mailaka (Email)
                      _buildAdminProfileInfoItem(
                        icon: Icons.email_outlined,
                        label: 'Mailaka',
                        value: emailStr,
                      ),
                      const SizedBox(height: 14),

                      // 4. Laharana finday (Phone)
                      _buildAdminProfileInfoItem(
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

  Widget _buildAdminProfileInfoItem({
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
              const LanguageSettingWidget(),

              const SizedBox(width: 4),

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