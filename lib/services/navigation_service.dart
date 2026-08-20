import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service Navigation API Endpoints (liste_des_services.txt) :
/// - POST   https://gateway.tsirylab.com/serviceauth/navigation (Créer une nouvelle navigation)
/// - GET    https://gateway.tsirylab.com/serviceauth/navigation (Récupérer toutes les navigations formatées)
/// - GET    https://gateway.tsirylab.com/serviceauth/navigation/{id} (Récupérer une navigation par ID)
/// - PATCH  https://gateway.tsirylab.com/serviceauth/navigation/{id} (Mettre à jour une navigation)
/// - DELETE https://gateway.tsirylab.com/serviceauth/navigation/{id} (Supprimer une navigation)
/// - POST   https://gateway.tsirylab.com/serviceauth/navigation/bulk (Créer plusieurs navigations)
/// - GET    https://gateway.tsirylab.com/serviceauth/navigation/by-app/{app_id} (Récupérer toutes les navigations d'une application)
/// - POST   https://gateway.tsirylab.com/serviceauth/navigation/add-role (Ajouter un rôle à une navigation)
class NavigationService {
  static const String baseUrl = "https://gateway.tsirylab.com/serviceauth";

  static Future<dynamic> getAppNavigationForAnUser(int appId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/navigation/by-app/$appId'));
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Get navigation error: $error");
      return null;
    }
  }

  static Future<dynamic> createNavigation(Map<String, dynamic> nav) async {
    try {
      debugPrint(nav.toString());
      final response = await http.post(
        Uri.parse('$baseUrl/navigation'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(nav),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Get navigation error: $error");
      return null;
    }
  }

  static Future<dynamic> updateNavigation(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/navigation/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Update navigation error: $error");
      rethrow;
    }
  }

  static Future<dynamic> deleteNavigation(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/navigation/$id'));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Delete navigation error: $error");
      rethrow;
    }
  }
}