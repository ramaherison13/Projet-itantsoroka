import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart'; // Assurez-vous d'importer vos services

/// Service Planification Mission API Endpoints (liste_des_services.txt) :
/// - POST https://gateway.tsirylab.com/servicemission/mission (Créer une nouvelle mission)
/// - GET  https://gateway.tsirylab.com/servicemission/mission/bydistrict/{district} (Missions par district)
/// - GET  https://gateway.tsirylab.com/servicemission/missions/withDetails/{id} (Mission avec détails)
class PlanificationMissionService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicemission";
  static const String territoireBaseUrl = "https://gateway.tsirylab.com/serviceterritoire-v2";

  // ✅ POST d'une mission avec auto-remplissage du district
  static Future<http.Response> createMission(Map<String, dynamic> missionData, int? municipalityId) async {
    try {
      // 🔸 Récupération du district de l'utilisateur connecté
      final communeUser = await getCommuneUser(municipalityId);
      final districtFormattedId = communeUser?['data']?['district']?['formatted_id'];
      final districtName = communeUser?['data']?['district']?['name'];

      if (districtFormattedId == null) {
        throw Exception("Impossible de récupérer le district.formatted_id");
      }

      // 🔸 Prépare le payload
      final payload = {
        ...missionData,
        'district': districtFormattedId,
        'districtName': districtName,
      };

      // 🔸 Envoi au backend
      final endpoint = Uri.parse('$baseUrl/mission');
      final response = await http.post(
        endpoint,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      // 🔸 Récupère toutes les missions du district
      await getMissionByDistrict(districtFormattedId);

      return response;
    } catch (error) {
      debugPrint("❌ Erreur création mission: $error");
      rethrow;
    }
  }

  // GET existants
  static Future<Map<String, dynamic>?> getCommuneUser(int? municipalityId) async {
    if (municipalityId == null) return null;
    final endpoint = Uri.parse('$territoireBaseUrl/serviceterritoire/get-code/$municipalityId');
    try {
      final response = await http.get(endpoint);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'data': jsonDecode(response.body), 'statusCode': response.statusCode};
      }
      return null;
    } catch (error) {
      debugPrint("erreur: $error");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getCommuneUserNonConnected(dynamic user) async {
    final municipalityId = user?['municipality_id'];
    if (municipalityId == null) return null;
    final endpoint = Uri.parse('$territoireBaseUrl/serviceterritoire/get-code/$municipalityId');
    try {
      final response = await http.get(endpoint);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'data': jsonDecode(response.body), 'statusCode': response.statusCode};
      }
      return null;
    } catch (error) {
      debugPrint("erreur: $error");
      rethrow;
    }
  }

  // MISSION
  static Future<List<dynamic>> getMissionByDistrict(String district) async {
    final endpoint = Uri.parse('$baseUrl/mission/bydistrict/$district');
    try {
      final response = await http.get(endpoint);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception("Erreur HTTP: ${response.statusCode}");
    } catch (error) {
      debugPrint("Erreur récupération missions: $error");
      rethrow;
    }
  }

  // GET mission with details
  static Future<dynamic> getMissionWithDetails(int missionId) async {
    final endpoint = Uri.parse('$baseUrl/missions/withDetails/$missionId');
    try {
      final response = await http.get(endpoint);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception("Erreur HTTP: ${response.statusCode}");
    } catch (error) {
      debugPrint("Erreur récupération mission details: $error");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getCommuneByDistrict(String data) async {
    final endpoint2 = Uri.parse('$territoireBaseUrl/communes/district/$data');
    try {
      final response = await http.get(endpoint2);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'data': jsonDecode(response.body), 'statusCode': response.statusCode};
      }
      return null;
    } catch (error) {
      debugPrint("erreur: $error");
      rethrow;
    }
  }

  static Future<List<dynamic>> getAllUser(int? municipalityId) async {
    try {
      final communeUser = await getCommuneUser(municipalityId);
      final district = communeUser?['data']?['district']?['formatted_id'];
      if (district == null) {
        debugPrint("⚠️ communeUser invalide, impossible de filtrer les utilisateurs");
        return [];
      }

      final allUsers = await UserService.getAllUsersByApplicationRole() ?? [];
      return allUsers;
    } catch (err) {
      debugPrint("❌ Erreur getAlluser: $err");
      return [];
    }
  }
}