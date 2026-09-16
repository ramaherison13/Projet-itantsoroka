import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Role {
  final String roleSlug;
  final int roleId;

  Role({required this.roleSlug, required this.roleId});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleSlug: json['role_slug'] ?? '',
      roleId: json['role_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'role_slug': roleSlug,
        'role_id': roleId,
      };
}

class TokenPayload {
  final String userId;
  final String userEmail;
  final String userPseudo;
  final List<Role> roles;
  final String municipalityName;
  final String? municipalityId;
  final String? districtId;
  final int exp;
  final int iat;

  TokenPayload({
    required this.userId,
    required this.userEmail,
    required this.userPseudo,
    required this.roles,
    required this.municipalityName,
    this.municipalityId,
    this.districtId,
    required this.exp,
    required this.iat,
  });

  factory TokenPayload.fromJson(Map<String, dynamic> json) {
    var rolesList = <Role>[];
    if (json['roles'] is List) {
      rolesList = (json['roles'] as List).map((r) {
        if (r is Map<String, dynamic>) {
          return Role.fromJson(r);
        } else if (r is String) {
          return Role(roleSlug: r, roleId: 0);
        }
        return Role(roleSlug: r.toString(), roleId: 0);
      }).toList();
    } else if (json['appUserRoles'] is List) {
      rolesList = (json['appUserRoles'] as List).map((ur) {
        if (ur is Map) {
          final slug = ur['role']?['role_slug'] ?? ur['role_slug'] ?? '';
          return Role(roleSlug: slug.toString(), roleId: ur['role_id'] ?? 0);
        }
        return Role(roleSlug: ur.toString(), roleId: 0);
      }).toList();
    }

    final id = json['user_id']?.toString() ??
        json['id']?.toString() ??
        json['userId']?.toString() ??
        json['sub']?.toString() ??
        '';
    final email = json['user_email']?.toString() ??
        json['email']?.toString() ??
        json['userEmail']?.toString() ??
        '';
    final pseudo = json['user_pseudo']?.toString() ??
        json['pseudo']?.toString() ??
        json['username']?.toString() ??
        json['userPseudo']?.toString() ??
        '';

    return TokenPayload(
      userId: id,
      userEmail: email,
      userPseudo: pseudo,
      roles: rolesList,
      municipalityName: json['municipality_name']?.toString() ?? json['commune']?.toString() ?? '',
      municipalityId: json['municipality_id']?.toString(),
      districtId: json['district_id']?.toString(),
      exp: json['exp'] is int ? json['exp'] : 0,
      iat: json['iat'] is int ? json['iat'] : 0,
    );
  }
}

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    restoreSession();
  }

  String? _accessToken;
  TokenPayload? _user;
  bool _isAuthenticated = false;
  bool _isActivated = false;
  final String _category = "";
  bool _isInitialized = false;

  String? get accessToken => _accessToken;
  TokenPayload? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isActivated => _isActivated;
  String get category => _category;
  bool get isInitialized => _isInitialized;
  String get userName => _user?.userPseudo ?? 'Utilisateur';
  String get userEmail => _user?.userEmail ?? '';

  static String normalizeRoleSlug(String slug) {
    return slug.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
  }

  /// Liste des slugs de rôles de l'utilisateur (normalisés en majuscules sans tirets/espaces)
  List<String> get roleSlugs =>
      _user?.roles
          .map((r) => normalizeRoleSlug(r.roleSlug))
          .where((s) => s.isNotEmpty)
          .toList() ??
      [];

  /// Rôle principal (premier rôle trouvé dans le token)
  String? get primaryRole => roleSlugs.isNotEmpty ? roleSlugs.first : null;

  /// Vérifie si l'utilisateur possède un rôle donné (insensible à la casse, tirets et espaces)
  bool hasRole(String slug) =>
      roleSlugs.contains(normalizeRoleSlug(slug));

  /// Vérifie si l'utilisateur possède au moins un des rôles donnés
  bool hasAnyRole(List<String> slugs) =>
      slugs.any((s) => hasRole(s));

  /// Route d'accueil selon le rôle principal
  String get homeRoute {
    if (!_isAuthenticated || _user == null) return '/';
    if (hasRole('SUPER_ADMIN') || hasRole('ADMIN') || hasRole('ADMINISTRATEUR')) {
      return '/admin';
    }
    if (hasRole('CHEF_DISTRICT'))    return '/dashboard/chef-district';
    if (hasRole('ADJOINT_DISTRICT')) return '/dashboard/adjoint-district';
    if (hasRole('STD'))              return '/dashboard/std';
    if (hasRole('CTD'))              return '/dashboard/ctd';
    if (hasRole('PARTENAIRE'))       return '/dashboard/partenaire';
    // Citoyen ou rôle inconnu → page d'accueil publique
    return '/';
  }


  Future<void> login(String payloadString) async {
    try {
      // Miroir de authSlice.ts ligne 53-78
      // Le payload est JSON.stringify({ data: responseData, isActivated: bool })
      // où responseData peut être le JWT brut (string) ou un objet { access_token, ... }
      dynamic rawData;
      try {
        rawData = jsonDecode(payloadString);
      } catch (_) {
        rawData = {'data': payloadString};
      }

      // Extraire le JWT brut — miroir de authSlice.ts ligne 61 :
      // const token = typeof rawData.data === "string" ? rawData.data
      //             : (rawData.data?.access_token || rawData.data?.token || action.payload);
      String? token;
      final dataField = rawData['data'];
      if (dataField is String && dataField.trim().isNotEmpty) {
        // data est déjà un JWT brut
        token = dataField.trim();
      } else if (dataField is Map) {
        // data est un objet — chercher access_token ou token
        token = dataField['access_token']?.toString() ??
                dataField['token']?.toString() ??
                dataField['jwt']?.toString();
      } else {
        // Fallback : peut-être que rawData lui-même est le token ou contient access_token
        token = rawData['access_token']?.toString() ??
                rawData['token']?.toString();
      }

      if (token == null || token.trim().isEmpty) {
        debugPrint('AuthProvider.login : impossible d\'extraire le JWT depuis : $payloadString');
        return;
      }
      token = token.trim();

      _isActivated = (rawData['isActivated'] as bool?) ?? true;

      // Stocker le JWT brut (et non un JSON wrappé)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setBool('isActivated', _isActivated);
      _accessToken = token;

      // Décoder le payload JWT pour peupler _user
      try {
        final parts = token.split('.');
        if (parts.length > 1) {
          final normalized = base64Url.normalize(parts[1]);
          final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
          _user = TokenPayload.fromJson(Map<String, dynamic>.from(payload));
        }
        _isAuthenticated = true;
      } catch (e) {
        debugPrint('AuthProvider.login : erreur d\'analyse du JWT : $e');
        _isAuthenticated = true; // auth acceptée même si le décodage échoue
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur login : $e');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _user = null;
    _isAuthenticated = false;
    _isActivated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('isActivated');
    await prefs.remove('roles');

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final isActivatedBool = prefs.getBool('isActivated') ?? false;
    _isActivated = isActivatedBool;

    if (token != null && token.isNotEmpty) {
      try {
        // Résoudre le vrai token (peut être un JSON wrappé ou une chaîne directe)
        String resolvedToken = token;
        try {
          final parsed = jsonDecode(token);
          if (parsed is String && parsed.trim().isNotEmpty) {
            resolvedToken = parsed.trim();
          } else if (parsed is Map) {
            final candidate = parsed['access_token'] ?? parsed['token'];
            if (candidate is String && candidate.trim().isNotEmpty) {
              resolvedToken = candidate.trim();
            }
          }
        } catch (_) {
          // token est déjà une chaîne brute JWT
          resolvedToken = token.trim();
        }

        if (resolvedToken.isNotEmpty) {
          _accessToken = resolvedToken;

          // Décoder le payload JWT pour extraire l'utilisateur et vérifier l'expiration
          try {
            final parts = resolvedToken.split('.');
            if (parts.length > 1) {
              final normalized = base64Url.normalize(parts[1]);
              final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
              final exp = payload['exp'] as int? ?? 0;
              final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

              if (exp > 0 && exp < now) {
                // Token expiré : nettoyer la session
                _accessToken = null;
                _isAuthenticated = false;
                await prefs.remove('access_token');
                await prefs.remove('isActivated');
                await prefs.remove('roles');
                _isInitialized = true;
                notifyListeners();
                return;
              }

              _user = TokenPayload.fromJson(Map<String, dynamic>.from(payload));
            }
          } catch (decodeError) {
            debugPrint('restoreSession :: JWT decode error (non-fatal): $decodeError');
          }

          _isAuthenticated = true;
        }
      } catch (e) {
        debugPrint('restoreSession :: error: $e');
        await prefs.remove('access_token');
      }
    }

    _isInitialized = true;
    notifyListeners();
  }
}