import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service Publications API Endpoints (liste_des_services.txt) :
/// PUBLICATIONS:
/// - GET    https://gateway.tsirylab.com/servicepublication (Get servicepublication)
/// - POST   https://gateway.tsirylab.com/servicepublication/events (Create a new event with optional image)
/// - GET    https://gateway.tsirylab.com/servicepublication/events (Get all events with pagination)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/back-office-criv (Get all events with pagination)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/commune/{communeID} (Get events by commune ID)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/juridique (Get events with Juridique theme)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/dispositif-district (Get events with Dispositif District theme)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/themes (Get available themes)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/{id} (Get event by ID)
/// - PATCH  https://gateway.tsirylab.com/servicepublication/events/{id} (Partially update event by ID)
/// - DELETE https://gateway.tsirylab.com/servicepublication/events/{id} (Delete event by ID)
class ActuService {
  // URL de base de votre passerelle de publication
  static const String baseUrl = 'https://gateway.tsirylab.com/servicepublication';

  static Future<Map<String, dynamic>> createActu(Map<String, dynamic> formData) async {
    try {
      final uri = Uri.parse('$baseUrl/events'); // Ajustez l'endpoint exact si besoin (ex: /actu ou /events)
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // Ajoutez ici un token d'authentification si votre API en exige un :
          // 'Authorization': 'Bearer $token',
        },
        body: json.encode(formData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          "success": true,
          "message": "Actualité créée avec succès !",
          "data": data,
        };
      } else {
        return {
          "success": false,
          "message": "Erreur serveur (${response.statusCode}) : ${response.body}",
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau lors de la création de l'actualité : $e");
      return {
        "success": false,
        "message": "Erreur de connexion : $e",
      };
    }
  }
}