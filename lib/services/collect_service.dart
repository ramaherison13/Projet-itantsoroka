import 'dart:convert';
import 'package:http/http.dart' as http;

class ObservationModel {
  final int id;
  final String contenu;
  final int? idTerritoireVisiter;

  ObservationModel({
    required this.id,
    required this.contenu,
    this.idTerritoireVisiter,
  });

  factory ObservationModel.fromJson(Map<String, dynamic> json) {
    return ObservationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      contenu: json['contenu'] ?? '',
      idTerritoireVisiter: json['idTerritoireVisiter'] != null
          ? int.tryParse(json['idTerritoireVisiter'].toString())
          : null,
    );
  }
}

class DoleanceModel {
  final int idDoleance;
  final String description;
  final int? idTerritoireVisiter;

  DoleanceModel({
    required this.idDoleance,
    required this.description,
    this.idTerritoireVisiter,
  });

  factory DoleanceModel.fromJson(Map<String, dynamic> json) {
    return DoleanceModel(
      idDoleance: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      description: json['contenu'] ?? '',
      idTerritoireVisiter: json['idTerritoireVisiter'] != null
          ? int.tryParse(json['idTerritoireVisiter'].toString())
          : null,
    );
  }
}

class ActionModel {
  final int id;
  final String description;
  final int? idTerritoireVisiter;

  ActionModel({
    required this.id,
    required this.description,
    this.idTerritoireVisiter,
  });

  factory ActionModel.fromJson(Map<String, dynamic> json) {
    return ActionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      description: json['description'] ?? '',
      idTerritoireVisiter: json['idTerritoireVisiter'] != null
          ? int.tryParse(json['idTerritoireVisiter'].toString())
          : null,
    );
  }
}

/// Service Collect (Observations/Faits, Actions & Doléances) API Endpoints (liste_des_services.txt) :
/// SERVICES MISSIONS (FAITS & ACTIONS) :
/// - POST   https://gateway.tsirylab.com/servicemission/fait (Créer une observation/fait)
/// - GET    https://gateway.tsirylab.com/servicemission/fait (Lister toutes les observations)
/// - PATCH  https://gateway.tsirylab.com/servicemission/fait/{id} (Mettre à jour une observation)
/// - DELETE https://gateway.tsirylab.com/servicemission/fait/{id} (Supprimer une observation)
/// - POST   https://gateway.tsirylab.com/servicemission/actions (Créer une nouvelle action)
/// - GET    https://gateway.tsirylab.com/servicemission/actions (Lister toutes les actions)
/// - PATCH  https://gateway.tsirylab.com/servicemission/actions/{id} (Mettre à jour une action)
/// - DELETE https://gateway.tsirylab.com/servicemission/actions/{id} (Supprimer une action)
/// SERVICES DOLEANCES:
/// - GET    https://gateway.tsirylab.com/servicedoleance/doleances (Lister toutes les doléances)
/// - PATCH  https://gateway.tsirylab.com/servicedoleance/doleances/{id} (Mettre à jour une doléance)
/// - DELETE https://gateway.tsirylab.com/servicedoleance/doleances/{id} (Supprimer une doléance)
class CollectService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicemission";
  static const String doleanceBaseUrl = "https://gateway.tsirylab.com/servicedoleance";

  // 🔹 Récupérer toutes les observations
  static Future<List<ObservationModel>> fetchObservations(int idTerritoireVisiter) async {
    final response = await http.get(Uri.parse('$baseUrl/fait'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    List observationsArray = [];

    if (data is List) {
      observationsArray = data;
    } else if (data is Map) {
      observationsArray = [data];
    }

    return observationsArray
        .where((item) => int.tryParse(item['idTerritoireVisiter']?.toString() ?? '0') == idTerritoireVisiter)
        .map((item) => ObservationModel.fromJson(item))
        .toList();
  }

  // 🔹 Ajouter une observation
  static Future<dynamic> createObservation(int idTerritoireVisiter, String contenu) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fait'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idTerritoireVisiter": idTerritoireVisiter, "contenu": contenu}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }

  // 🔹 Modifier une observation
  static Future<dynamic> updateObservation(int observationId, int idTerritoireVisiter, String contenu) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/fait/$observationId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idTerritoireVisiter": idTerritoireVisiter, "contenu": contenu}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }

  // 🔹 Supprimer une observation
  static Future<dynamic> deleteObservation(int observationId) async {
    final response = await http.delete(Uri.parse('$baseUrl/fait/$observationId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }

  // 🔹 Récupérer toutes les doleances
  static Future<List<DoleanceModel>> fetchDoleance(int idTerritoireVisiter) async {
    final response = await http.get(Uri.parse('$doleanceBaseUrl/doleances'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    List doleanceArray = [];

    if (data is List) {
      doleanceArray = data;
    } else if (data is Map) {
      doleanceArray = [data];
    }

    return doleanceArray
        .where((item) => int.tryParse(item['idTerritoireVisiter']?.toString() ?? '0') == idTerritoireVisiter)
        .map((item) => DoleanceModel.fromJson(item))
        .toList();
  }

  // 🔹 Modifier une doléance
  static Future<dynamic> updateDoleance(int doleanceId, int idTerritoireVisiter, String description) async {
    final response = await http.patch(
      Uri.parse('$doleanceBaseUrl/doleances/$doleanceId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idTerritoireVisiter": idTerritoireVisiter, "contenu": description}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }

  // 🔹 Supprimer une doléance
  static Future<dynamic> deleteDoleance(int doleanceId) async {
    final response = await http.delete(Uri.parse('$doleanceBaseUrl/doleances/$doleanceId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }

  // 🔹 Récupérer toutes les actions
  static Future<List<ActionModel>> fetchActions(int idTerritoireVisiter) async {
    final response = await http.get(Uri.parse('$baseUrl/actions'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    List actionsArray = [];

    if (data is List) {
      actionsArray = data;
    } else if (data is Map) {
      actionsArray = [data];
    }

    return actionsArray
        .where((item) => int.tryParse(item['idTerritoireVisiter']?.toString() ?? '0') == idTerritoireVisiter)
        .map((item) => ActionModel.fromJson(item))
        .toList();
  }

  // 🔹 Ajouter une action
  static Future<dynamic> createAction(int idTerritoireVisiter, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/actions'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idTerritoireVisiter": idTerritoireVisiter, "description": text}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }

  // 🔹 Modifier une action
  static Future<dynamic> updateAction(int actionId, int idTerritoireVisiter, String text) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/actions/$actionId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idTerritoireVisiter": idTerritoireVisiter, "contenu": text}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }

  // 🔹 Supprimer une action
  static Future<dynamic> deleteAction(int actionId) async {
    final response = await http.delete(Uri.parse('$baseUrl/actions/$actionId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur HTTP: ${response.statusCode}");
    }
    return jsonDecode(response.body);
  }
}