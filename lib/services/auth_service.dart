import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'role_service.dart'; // Assurez-vous d'importer le service des rôles

class UpdateProfileData {
  final String? userPseudo;
  final String? userEmail;
  final String? userPhone;
  final String? userPassword;

  UpdateProfileData({
    this.userPseudo,
    this.userEmail,
    this.userPhone,
    this.userPassword,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (userPseudo != null) data['user_pseudo'] = userPseudo;
    if (userEmail != null) data['user_email'] = userEmail;
    if (userPhone != null) data['user_phone'] = userPhone;
    if (userPassword != null) data['user_password'] = userPassword;
    return data;
  }
}

/// Service Auth API Endpoints (liste_des_services.txt) :
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/login (Connexion utilisateur)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/sso/token (Étape 1 - Vérifier l'utilisateur SSO et générer un JWT applicatif)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/sso/register (Étape 2 - Inscription SSO simplifiée)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/sso/register-complete (Étape 3 - Inscription SSO complète)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/keycloak-webhook (Webhook Keycloak)
/// - GET    https://gateway.tsirylab.com/serviceauth/auth/profile (Obtenir le profil utilisateur)
/// - PATCH  https://gateway.tsirylab.com/serviceauth/auth/profile (Mettre à jour le profil utilisateur)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/verify-token (Vérifier le token JWT)
/// - GET    https://gateway.tsirylab.com/serviceauth/auth/app-autorise (Obtenir les applications autorisées)
/// - GET    https://gateway.tsirylab.com/serviceauth/auth/app-autorise-agvm (Obtenir les applications autorisées avec affiliation AGVM)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/logout (Déconnexion utilisateur)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/forgot-password (Demande de réinitialisation de mot de passe)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/reset-password (Réinitialiser le mot de passe avec le code reçu)
/// - POST   https://gateway.tsirylab.com/serviceauth/auth/reset-password-without-token (Réinitialiser le mot de passe sans token)
/// - POST   https://gateway.tsirylab.com/serviceauth/users/register-with-citizen-short (Créer utilisateur + citoyen)
class AuthService {
  static const String baseUrl = "https://gateway.tsirylab.com/serviceauth";

  static Future<String> _resolveAccessToken({bool debug = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString("access_token");

    if (rawValue == null || rawValue.isEmpty) {
      throw Exception("Token non trouvé");
    }

    if (debug) {
      debugPrint("🔍 resolveAccessToken :: valeur brute (type): ${rawValue.runtimeType}");
      debugPrint("🔍 resolveAccessToken :: valeur brute (début): ${rawValue.substring(0, rawValue.length > 100 ? 100 : rawValue.length)}");
    }

    try {
      final parsed = jsonDecode(rawValue);

      if (debug) {
        debugPrint("🔍 resolveAccessToken :: valeur parsée (type): ${parsed.runtimeType}");
        debugPrint("🔍 resolveAccessToken :: valeur parsée: $parsed");
      }

      if (parsed is String && parsed.trim().isNotEmpty) {
        return parsed.trim();
      }

      if (parsed is Map) {
        final candidate = parsed['access_token'] ?? parsed['token'];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }

        if (debug) {
          debugPrint("🔍 resolveAccessToken :: objet sans access_token valide: $parsed");
        }
      }
    } catch (parseError) {
      if (debug) {
        debugPrint("🔍 resolveAccessToken :: JSON.parse a échoué, utilisation directe");
      }

      if (rawValue.trim().isNotEmpty) {
        return rawValue.trim();
      }

      throw Exception("Le token brut est vide");
    }

    throw Exception("Impossible d'extraire un access_token valide");
  }

  static Future<Map<String, dynamic>> loginUser(Map<String, dynamic> credentials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingToken = prefs.getString("access_token");
      if (existingToken != null) {
        return {
          "data": null,
          "message": "Une session est déjà active",
          "isActivated": false,
          "sessionLocked": true,
        };
      }

      List intersection = [];
      bool isActivated = false;

      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(credentials),
      );

      final resData = jsonDecode(res.body);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(resData['message'] ?? "Erreur de connexion");
      }

      // Récupération des rôles (nécessite roleService converti)
      final allRolesResponse = await RoleService.getAllRolesForLogin();
      final roles = (allRolesResponse['roles'] as List).map((role) => role['role_id']).toList();

      // Décodage du JWT
      final accessToken = resData['access_token'];
      List userRoles = []; 
      try {
        final parts = accessToken.split('.');
        if (parts.length > 1) {
          String normalized = base64Url.normalize(parts[1]);
          String utf8Payload = utf8.decode(base64Url.decode(normalized));
          Map<String, dynamic> decodedPayload = jsonDecode(utf8Payload);
          userRoles = (decodedPayload['roles'] as List).map((role) => role['role_id']).toList();
        }
      } catch (e) {
        debugPrint("Erreur décodage token: $e");
      }

      intersection = userRoles.where((value) => roles.contains(value)).toList();
      if (intersection.length >= 2) {
        isActivated = true;
      }

      if (userRoles.any((el) => roles.contains(el))) {
        return {"data": resData, "message": "Connecté avec succès", "isActivated": isActivated};
      } else {
        return {
          "data": null,
          "message": "Vous n'avez pas les droits d'accès, veuillez contacter un administrateur.",
        };
      }
    } catch (error) {
      debugPrint("Login error: $error");
      return {"data": null, "message": "Veuillez vérifier vos identifiants."};
    }
  }

  static Future<dynamic> registerUser(http.MultipartRequest formData) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/register-with-citizen-short'));
      request.fields.addAll(formData.fields);
      request.files.addAll(formData.files);
      request.headers.addAll(formData.headers);
      var streamedResponse = await request.send();
      var res = await http.Response.fromStream(streamedResponse);
      final resData = jsonDecode(res.body);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(resData);
      }
      return resData;
    } catch (error) {
      debugPrint("Register error: $error");
      rethrow;
    }
  }

  static Future<dynamic> updateProfile(UpdateProfileData profileData) async {
    try {
      final token = await _resolveAccessToken();

      final res = await http.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(profileData.toJson()),
      );

      final resData = jsonDecode(res.body);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(resData);
      }
      return resData;
    } catch (error) {
      debugPrint("Update profile error: $error");
      rethrow;
    }
  }

  static Future<dynamic> resetUserPassword(String userId, String newPassword) async {
    try {
      final token = await _resolveAccessToken();

      final res = await http.post(
        Uri.parse('$baseUrl/auth/change-password-via-admin'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "user_id": userId,
          "newPassword": newPassword,
        }),
      );

      final resData = jsonDecode(res.body);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(resData);
      }
      return resData;
    } catch (error) {
      debugPrint("Reset password error: $error");
      rethrow;
    }
  }

  static Future<dynamic> adminChangeUserPassword(String userKeycloakId, String newPassword) async {
    try {
      final keycloakToken = await _resolveAccessToken(debug: true);

      debugPrint("✅ Token final:");
      debugPrint("Keycloak ID utilisateur: $userKeycloakId");
      debugPrint("Type du token: ${keycloakToken.runtimeType}");
      debugPrint("Token Keycloak (début): ${keycloakToken.substring(0, keycloakToken.length > 50 ? 50 : keycloakToken.length)}...");
      debugPrint("Longueur du token: ${keycloakToken.length}");

      final payload = {
        "user_id": userKeycloakId,
        "newPassword": newPassword,
      };

      debugPrint("🚀 Payload envoyé à l'API: $payload");

      final res = await http.post(
        Uri.parse('$baseUrl/auth/change-password-via-admin'),
        headers: {
          "Authorization": "Bearer $keycloakToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      debugPrint("✅ Mot de passe changé avec succès");
      debugPrint("📬 Réponse backend - status: ${res.statusCode}");
      debugPrint("📬 Réponse backend - data: ${res.body}");

      final resData = jsonDecode(res.body);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (res.statusCode == 401) {
          throw Exception(resData['message'] ?? "Erreur 401: Token Keycloak invalide ou permissions insuffisantes");
        }
        throw Exception(resData);
      }

      return resData;
    } catch (error) {
      debugPrint("❌ Erreur complète: $error");
      rethrow;
    }
  }
}