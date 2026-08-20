import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service Auth Roles & Permissions API Endpoints (liste_des_services.txt) :
/// RÔLES :
/// - POST   https://gateway.tsirylab.com/serviceauth/roles (Créer un rôle)
/// - GET    https://gateway.tsirylab.com/serviceauth/roles (Lister les rôles)
/// - GET    https://gateway.tsirylab.com/serviceauth/roles/{id} (Obtenir un rôle)
/// - PUT    https://gateway.tsirylab.com/serviceauth/roles/{id} (Mettre à jour un rôle)
/// - DELETE https://gateway.tsirylab.com/serviceauth/roles/{id} (Supprimer un rôle)
/// - POST   https://gateway.tsirylab.com/serviceauth/roles/{id}/permissions (Assigner des permissions à un rôle)
/// - GET    https://gateway.tsirylab.com/serviceauth/roles/{id}/permissions (Obtenir les permissions d'un rôle)
/// - POST   https://gateway.tsirylab.com/serviceauth/roles/bulk (Créer plusieurs rôles)
/// - GET    https://gateway.tsirylab.com/serviceauth/roles/application/{app_id} (Récupérer tous les rôles par app_id)
/// PERMISSIONS:
/// - POST   https://gateway.tsirylab.com/serviceauth/permissions (Créer une permission)
/// - GET    https://gateway.tsirylab.com/serviceauth/permissions (Lister toutes les permissions)
/// - GET    https://gateway.tsirylab.com/serviceauth/permissions/{id} (Obtenir une permission)
/// - PUT    https://gateway.tsirylab.com/serviceauth/permissions/{id} (Mettre à jour une permission)
/// - DELETE https://gateway.tsirylab.com/serviceauth/permissions/{id} (Supprimer une permission)
/// - GET    https://gateway.tsirylab.com/serviceauth/permissions/by-application/{app_id} (Lister les permissions d'une application)
class RoleService {
  static const String baseUrl = "https://gateway.tsirylab.com/serviceauth";
  static const int appId = 1; 
  static const int defaultRoleId = 0;

  static Future<dynamic> getAllRoles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/application/$appId'));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      
      if (data != null && data['roles'] is List) {
        List roles = data['roles'];
        data['roles'] = roles.where((role) => role['role_id'] != defaultRoleId).toList();
      }

      return data;
    } catch (error) {
      debugPrint("Erreur lors de la récupération des roles : $error");
      return null;
    }
  }

  static Future<dynamic> getAllRolesForLogin() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/application/$appId'));

      if (response.statusCode != 200) return null;

      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Erreur lors de la récupération des roles pour login : $error");
      return null;
    }
  }

  static Future<dynamic> getAllRolesWithPermission() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/roles/application/$appId?limit=1000&page=1'));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      // Fallback 1: GET /serviceauth/application/1
      final resApp = await http.get(Uri.parse('$baseUrl/application/$appId'));
      if (resApp.statusCode >= 200 && resApp.statusCode < 300) {
        return jsonDecode(resApp.body);
      }

      // Fallback 2: GET /serviceauth/roles
      final resRoles = await http.get(Uri.parse('$baseUrl/roles'));
      if (resRoles.statusCode >= 200 && resRoles.statusCode < 300) {
        return jsonDecode(resRoles.body);
      }

      return null;
    } catch (error) {
      debugPrint("Erreur lors de la récupération des roles : $error");
      return null;
    }
  }

  static Future<dynamic> getAllPermission() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/permissions/by-application/$appId'));
      
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      debugPrint(data['data']?.toString());
      return data;
    } catch (error) {
      debugPrint("Erreur lors de la récupération des permission : $error");
      return null;
    }
  }

  static Future<dynamic> assignRoleToAnUser(String userId, List<int> roles) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/roles'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"role_ids": roles}),
      );
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Erreur lors de l'assignations de role: $e");
      return null;
    }
  }

  static Future<dynamic> removeRoleToAnUser(String userId, List<int> roles) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/roles'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"role_ids": roles}),
      );
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Erreur lors de l'assignations de role: $e");
      return null;
    }
  }

  static Future<dynamic> createRole(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/roles'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Erreur lors de la création du role: $e");
      return null;
    }
  }

  static Future<dynamic> updateRole(int roleId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/roles/$roleId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour du role: $e");
      return null;
    }
  }

  static Future<bool> deleteRole(int roleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/roles/$roleId'),
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint("Erreur lors de la suppression du role: $e");
      return false;
    }
  }
}