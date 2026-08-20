import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EventModel {
  final dynamic id;
  final String? titre;
  final String? description;
  final String? date;
  final String? lieu;
  final String? image;
  final String? imageFilename;

  EventModel({
    required this.id,
    this.titre,
    this.description,
    this.date,
    this.lieu,
    this.image,
    this.imageFilename,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      titre: json['titre'] ?? json['title'],
      description: json['description'],
      date: json['date'],
      lieu: json['lieu'] ?? json['location'],
      image: json['image'],
      imageFilename: json['imageFilename'],
    );
  }
}

class EventTypeModel {
  final dynamic id;
  final String nom;

  EventTypeModel({required this.id, required this.nom});

  factory EventTypeModel.fromJson(Map<String, dynamic> json) {
    return EventTypeModel(
      id: json['id'],
      nom: json['nom'] ?? json['name'] ?? '',
    );
  }
}

class ThemeModel {
  final dynamic id;
  final String nom;

  ThemeModel({required this.id, required this.nom});

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'],
      nom: json['nom'] ?? json['name'] ?? '',
    );
  }
}

class CommunesBasicModel {
  final dynamic id;
  final String nom;

  CommunesBasicModel({required this.id, required this.nom});

  factory CommunesBasicModel.fromJson(Map<String, dynamic> json) {
    return CommunesBasicModel(
      id: json['id'] ?? json['formatted_id'],
      nom: json['nom'] ?? json['name'] ?? '',
    );
  }
}

class DistrictBasicModel {
  final dynamic id;
  final String nom;

  DistrictBasicModel({required this.id, required this.nom});

  factory DistrictBasicModel.fromJson(Map<String, dynamic> json) {
    return DistrictBasicModel(
      id: json['id'] ?? json['formatted_id'],
      nom: json['nom'] ?? json['name'] ?? '',
    );
  }
}

/// Service Events & Publications API Endpoints (liste_des_services.txt) :
/// PUBLICATIONS:
/// - POST   https://gateway.tsirylab.com/servicepublication/events (Create a new event)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/dispositif-district (Get events with Dispositif District theme)
/// - GET    https://gateway.tsirylab.com/servicepublication/events/{id} (Get an event by ID)
/// - PATCH  https://gateway.tsirylab.com/servicepublication/events/{id} (Partially update an event by ID)
/// - DELETE https://gateway.tsirylab.com/servicepublication/events/{id} (Delete an event by ID)
class EventService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicepublication";
  static const String themeBaseUrl = "https://gateway.tsirylab.com/servicetheme";
  static const String territoireBaseUrl = "https://gateway.tsirylab.com/serviceterritoire-v2";

  static Future<dynamic> createEvent(http.MultipartRequest formData) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/events'));
      request.fields.addAll(formData.fields);
      request.files.addAll(formData.files);
      request.headers.addAll(formData.headers);
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(resData['message'] ?? "Erreur lors de la création de l'événement");
      }
      return resData;
    } catch (error) {
      debugPrint("Create event error: $error");
      rethrow;
    }
  }

  static Future<dynamic> getEvents({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/dispositif-district?page=$page&limit=$limit'));
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Get events error: $error");
      rethrow;
    }
  }

  static Future<dynamic> getEventById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$id'));
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Get event by ID error: $error");
      rethrow;
    }
  }

  static Future<dynamic> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Update event error: $error");
      rethrow;
    }
  }

  static Future<dynamic> deleteEvent(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/events/$id'));
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Delete event error: $error");
      rethrow;
    }
  }

  static Future<dynamic> getTypes() async {
    try {
      final response = await http.get(Uri.parse('$themeBaseUrl/type'));
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Get event types error: $error");
      rethrow;
    }
  }

  static Future<dynamic> getThemes() async {
    try {
      final response = await http.get(Uri.parse('$themeBaseUrl/themes'));
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Get themes error: $error");
      rethrow;
    }
  }

  static Future<dynamic> getCommunes() async {
    try {
      final response = await http.get(Uri.parse('$territoireBaseUrl/communes/basic?page=1&limit=10000'));
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Get communes error: $error");
      rethrow;
    }
  }

  static Future<dynamic> getdistrict() async {
    try {
      final response = await http.get(Uri.parse('$territoireBaseUrl/districts'));
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }
      return resData;
    } catch (error) {
      debugPrint("Get districts error: $error");
      rethrow;
    }
  }
}