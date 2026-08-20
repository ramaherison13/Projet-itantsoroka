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
    var rolesList = (json['roles'] as List?)?.map((r) => Role.fromJson(r)).toList() ?? [];
    return TokenPayload(
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'] ?? '',
      userPseudo: json['user_pseudo'] ?? '',
      roles: rolesList,
      municipalityName: json['municipality_name'] ?? '',
      municipalityId: json['municipality_id'],
      districtId: json['district_id'],
      exp: json['exp'] ?? 0,
      iat: json['iat'] ?? 0,
    );
  }
}

class AuthProvider with ChangeNotifier {
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

  Future<void> login(String payloadString) async {
    try {
      final data = jsonDecode(payloadString);
      final token = jsonEncode(data['data']);
      _accessToken = token;
      _isActivated = data['isActivated'] ?? false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setBool('isActivated', _isActivated);

      try {
        // Décodage JWT (vous pouvez utiliser une bibliothèque comme `jwt_decode` pour Flutter)
        // Map<String, dynamic> decodedMap = JwtDecoder.decode(token);
        // _user = TokenPayload.fromJson(decodedMap);
        // await prefs.setString('roles', jsonEncode(_user?.roles));
        _isAuthenticated = true;
      } catch (e) {
        _user = null;
        _accessToken = null;
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur login : $e");
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