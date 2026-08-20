import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart';

/// Service Missions API Endpoints (liste_des_services.txt) :
/// SERVICES MISSIONS:
/// - POST   https://gateway.tsirylab.com/servicemission/mission (Créer une nouvelle mission)
/// - GET    https://gateway.tsirylab.com/servicemission/mission (Lister toutes les missions)
/// - GET    https://gateway.tsirylab.com/servicemission/mission/{id} (Récupérer une mission par ID)
/// - PUT    https://gateway.tsirylab.com/servicemission/mission/{id} (Mettre à jour une mission par ID)
/// - DELETE https://gateway.tsirylab.com/servicemission/mission/{id} (Supprimer une mission par ID)
/// - GET    https://gateway.tsirylab.com/servicemission/mission/bydistrict/{district} (Récupérer les missions par district)
/// - GET    https://gateway.tsirylab.com/servicemission/missions/withDetails/{id} (Récupérer une mission avec détails)
/// - GET    https://gateway.tsirylab.com/servicemission/territoires-v (Récupère tous les territoires à visiter)
/// - GET    https://gateway.tsirylab.com/servicemission/territoires-v/status/{status} (Récupère par statut)
/// - GET    https://gateway.tsirylab.com/servicemission/territoires-v/mission/{idMission} (Récupère par mission)
/// - PUT    https://gateway.tsirylab.com/servicemission/territoires-v/{id} (Met à jour un territoire visité)
class MissionService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicemission";

  // Opérations CRUD sur les missions
  static Future<Map<String, dynamic>> createMission(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mission'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Erreur création mission : $error");
      rethrow;
    }
  }

  static Future<dynamic> updateMission(int missionId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/mission/$missionId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Erreur mise à jour mission : $error");
      rethrow;
    }
  }

  static Future<void> updateTerritoireVisite(int territoireId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/territoires-v/$territoireId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Erreur mise à jour territoire visité : $error");
      rethrow;
    }
  }

  static Future<List<dynamic>> getTerritoiresVisitesByMission(int missionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/territoires-v/mission/$missionId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Erreur récupération territoires visités : $error");
      rethrow;
    }
  }

  static Future<List<dynamic>> getTerritoiresByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/territoires-v/status/$status'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Impossible de charger les territoires par status");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint('Erreur récupération des territoires avec le status "$status" : $error');
      rethrow;
    }
  }

  static Future<List<dynamic>> getMissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mission'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Impossible de charger les missions");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Erreur récupération missions : $error");
      rethrow;
    }
  }

  static Future<List<dynamic>> getMissionByDistrict(String district) async {
    final endpoint = '$baseUrl/mission/bydistrict/$district';
    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Erreur récupération missions: $error");
      rethrow;
    }
  }

  // Utilitaires
  static Map<String, dynamic> moveMission(Map<String, dynamic> mission, DateTime newDate) {
    final startDateStr = mission['date_debut_mission'];
    final endDateStr = mission['date_fin_mission'];

    final diff = (endDateStr != null && startDateStr != null)
        ? DateTime.parse(endDateStr).difference(DateTime.parse(startDateStr)).inMilliseconds
        : 0;

    String formatLocalDate(int year, int month, int day) {
      final m = month.toString().padLeft(2, '0');
      final d = day.toString().padLeft(2, '0');
      return '$year-$m-$d';
    }

    final newDateDebut = formatLocalDate(
      newDate.year,
      newDate.month,
      newDate.day,
    );

    String? newDateFin;
    if (diff > 0) {
      final calculatedEnd = newDate.add(Duration(milliseconds: diff));
      newDateFin = formatLocalDate(
        calculatedEnd.year,
        calculatedEnd.month,
        calculatedEnd.day,
      );
    }

    return {
      'date_debut_mission': newDateDebut,
      'date_fin_mission': newDateFin,
    };
  }

  static Map<String, dynamic> prepareMissionPayload({
    required List<dynamic> territoires,
    required List<dynamic> participants,
    required String? startDate,
    required String? endDate,
    required String titre,
    int? id,
  }) {
    final start = startDate != null ? DateTime.parse(startDate) : null;
    final end = endDate != null ? DateTime.parse(endDate) : null;

    String formatLocalDate(DateTime date) {
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '${date.year}-$m-$d';
    }

    return {
      'id': id ?? 0,
      'date_debut_mission': start != null ? formatLocalDate(start) : "",
      'date_fin_mission': end != null ? formatLocalDate(end) : "",
      'territoire_visiter': territoires.map((t) => t).toList(),
      'accompagnant': participants.map((p) => {
        'user_id': p['user_id'],
        'user_pseudo': p['user_pseudo'],
        'user_email': p['user_email'],
        'user_phone': p['user_phone'],
        'id_citizen': p['id_citizen'],
        'municipality_id': p['municipality_id'],
      }).toList(),
      'titre': titre,
      'status': "En cours",
      'userID': "5",
    };
  }

  // 🔹 Extraire les districts disponibles à partir d'une liste de missions
  static List<Map<String, String>> extractDistricts(List<dynamic> missions) {
    final districtsSet = <String>{};
    for (var m in missions) {
      if (m['district'] != null) {
        final name = getDisplayName(m);
        districtsSet.add(name);
      }
    }
    return districtsSet.map((name) => {'id': name, 'name': name}).toList();
  }

  // 🔹 Fonction utilitaire déplacée dans MissionService
  static String getDisplayName(dynamic obj) {
    if (obj == null || obj is! Map) return "Inconnu";
    if (obj['name'] != null) return obj['name'].toString();
    
    for (var value in obj.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return "Sans nom";
  }
}

//Service pour les participants
class ParticipantService {
  static Future<List<dynamic>> getAvailableParticipants() async {
    try {
      final users = await UserService.getAllUsersByApplicationRole();
      if (users == null) return [];
      return users.map((u) => u['user']).where((u) => u != null).toList();
    } catch (error) {
      debugPrint("Erreur récupération participants : $error");
      return [];
    }
  }
}

/// Service Notifications API Endpoints (liste_des_services.txt) :
/// SERVICES NOTIFICATIONS:
/// - POST   https://gateway.tsirylab.com/servicenotification/email/send (Send a basic email)
/// - POST   https://gateway.tsirylab.com/servicenotification/email/send-with-file (Send an email with a file attachment)
/// - POST   https://gateway.tsirylab.com/servicenotification/notifications/broadcast (Broadcast notification to user)
/// - GET    https://gateway.tsirylab.com/servicenotification/notifications (Get all notifications)
class NotificationService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicenotification";

  static Future<void> sendMissionNotification(
    Map<String, dynamic> missionData,
    String adminEmail,
    List<String> participantEmails,
  ) async {
    try {
      final subject = "Nouvelle mission créée: ${missionData['titre']}";
      
      final territoiresList = (missionData['territoire_visiter'] as List? ?? [])
          .map((t) => '<li>${t['name'] ?? ''}</li>')
          .join('');

      final participantsList = (missionData['accompagnant'] as List? ?? [])
          .map((p) => '<li>${p['user_email'] ?? p['email'] ?? ''}</li>')
          .join('');

      final body = '''
        <h2>Nouvelle mission créée</h2>
        <p><strong>Titre:</strong> ${missionData['titre']}</p>
        <p><strong>Date de début:</strong> ${missionData['date_debut_mission']}</p>
        <p><strong>Date de fin:</strong> ${missionData['date_fin_mission']}</p>
        <p><strong>Territoires visités:</strong></p>
        <ul>$territoiresList</ul>
        <p><strong>Participants:</strong></p>
        <ul>$participantsList</ul>
        <p>Cette mission a été créée et nécessite votre attention.</p>
      ''';

      // Envoyer à l'administrateur commune
      await http.post(
        Uri.parse('$baseUrl/email/send-with-file'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "to": adminEmail,
          "subject": subject,
          "body": body,
          "file": null,
        }),
      );

      // Envoyer aux participants
      for (final participantEmail in participantEmails) {
        await http.post(
          Uri.parse('$baseUrl/email/send-with-file'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "to": participantEmail,
            "subject": subject,
            "body": body,
            "file": null,
          }),
        );
      }

      debugPrint("Notifications envoyées avec succès");
    } catch (error) {
      debugPrint("Erreur lors de l'envoi des notifications: $error");
      rethrow;
    }
  }

  static Future<String?> getCommuneAdminEmail(String communeFormattedId) async {
    try {
      final communeAdmins = await UserService.getAllUsersBySpecificRole('ADMIN_COMMUNE');

      if (communeAdmins == null || communeAdmins.isEmpty) {
        debugPrint("Aucun administrateur de commune trouvé");
        return null;
      }
      final admin = communeAdmins[0];
      if (admin['user'] != null && admin['user']['user_email'] != null) {
        debugPrint("Admin trouvé pour commune: $communeFormattedId, ${admin['user']['user_email']}");
        return admin['user']['user_email'];
      }

      return null;
    } catch (error) {
      debugPrint("Erreur récupération admin commune: $error");
      return null;
    }
  }
}