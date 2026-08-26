import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

// ── Modèles DTO ──────────────────────────────────────────────────────────────

class EntiteDto {
  final int? id;
  final String nom;
  final String? description;
  final String categorie; // 'ministere' | 'ptf'
  final String? status;
  final String? logo;

  EntiteDto({
    this.id,
    required this.nom,
    this.description,
    required this.categorie,
    this.status,
    this.logo,
  });

  factory EntiteDto.fromJson(Map<String, dynamic> json) {
    return EntiteDto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      nom: json['nom'] ?? '',
      description: json['description'],
      categorie: json['categorie'] ?? 'ministere',
      status: json['status'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nom': nom,
        'categorie': categorie,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
      };
}

class StdDto {
  final String? id;
  final String nom;
  final String? description;
  final int entiteId;
  final List<dynamic>? territoires;

  StdDto({
    this.id,
    required this.nom,
    this.description,
    required this.entiteId,
    this.territoires,
  });

  factory StdDto.fromJson(Map<String, dynamic> json) {
    return StdDto(
      id: json['id']?.toString(),
      nom: json['nom'] ?? '',
      description: json['description'],
      entiteId: json['entiteId'] is int
          ? json['entiteId']
          : int.tryParse(json['entiteId']?.toString() ?? '0') ?? 0,
      territoires: json['territoires'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nom': nom,
        'entiteId': entiteId,
        if (description != null) 'description': description,
        if (territoires != null) 'territoires': territoires,
      };
}

class AffiliationDto {
  final int? id;
  final String userId;
  final int entiteId;
  final String? dateAffiliation;

  AffiliationDto({
    this.id,
    required this.userId,
    required this.entiteId,
    this.dateAffiliation,
  });

  factory AffiliationDto.fromJson(Map<String, dynamic> json) {
    return AffiliationDto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      entiteId: json['entiteId'] is int
          ? json['entiteId']
          : int.tryParse(json['entiteId']?.toString() ?? '0') ?? 0,
      dateAffiliation: json['dateAffiliation'] ?? json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'entiteId': entiteId,
      };
}

class UserTerritoireDto {
  final int? id;
  final String userId;
  final String formattedId;
  final String? territoireType;

  UserTerritoireDto({
    this.id,
    required this.userId,
    required this.formattedId,
    this.territoireType,
  });

  factory UserTerritoireDto.fromJson(Map<String, dynamic> json) {
    return UserTerritoireDto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      formattedId: json['formatted_id']?.toString() ?? json['formattedId']?.toString() ?? '',
      territoireType: json['territoireType'] ?? json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'formatted_id': formattedId,
      };
}

class OffreDto {
  final String? id;
  final String titre;
  final String? description;
  final String? stdId;

  OffreDto({
    this.id,
    required this.titre,
    this.description,
    this.stdId,
  });

  factory OffreDto.fromJson(Map<String, dynamic> json) {
    return OffreDto(
      id: json['id']?.toString(),
      titre: json['titre'] ?? json['nom'] ?? '',
      description: json['description'],
      stdId: json['stdId']?.toString() ?? json['std_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'titre': titre,
        if (description != null) 'description': description,
        if (stdId != null) 'stdId': stdId,
      };
}

class AffiliationStdDto {
  final int? id;
  final String userId;
  final String stdId;

  AffiliationStdDto({
    this.id,
    required this.userId,
    required this.stdId,
  });

  factory AffiliationStdDto.fromJson(Map<String, dynamic> json) {
    return AffiliationStdDto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      stdId: json['stdId']?.toString() ?? json['std_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'stdId': stdId,
      };
}

// ── Service Affiliation ───────────────────────────────────────────────────────

class AffiliationService {
  static const String baseUrl = ApiConstants.serviceAffiliation;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // --- ENTITÉS ---

  static Future<List<dynamic>> listEntites() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/entites'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listEntites: $e');
      return [];
    }
  }

  static Future<dynamic> getEntite(int id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/entites/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint('AffiliationService.getEntite: $e');
      return null;
    }
  }

  static Future<List<dynamic>> listEntitesByCategorie(String categorie) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/entites/categorie/$categorie'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listEntitesByCategorie: $e');
      return [];
    }
  }

  static Future<dynamic> createEntite(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/entites'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.createEntite: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateEntite(int id, Map<String, dynamic> payload) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/entites/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.updateEntite: $e');
      rethrow;
    }
  }

  static Future<dynamic> deleteEntite(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/entites/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.deleteEntite: $e');
      rethrow;
    }
  }

  static Future<dynamic> disableEntite(int id) async {
    try {
      final res = await http.patch(Uri.parse('$baseUrl/entites/$id/disable'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.disableEntite: $e');
      rethrow;
    }
  }

  static Future<dynamic> enableEntite(int id) async {
    try {
      final res = await http.patch(Uri.parse('$baseUrl/entites/$id/enable'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.enableEntite: $e');
      rethrow;
    }
  }

  // --- STDS ---

  static Future<List<dynamic>> listStds() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stds'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listStds: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listStdsByMinistere(int entiteId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stds/ministere/$entiteId'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listStdsByMinistere: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listStdsByTerritoire(String territoireType, dynamic formattedId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stds/territoire/$territoireType/$formattedId'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listStdsByTerritoire: $e');
      return [];
    }
  }

  static Future<dynamic> getStd(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stds/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint('AffiliationService.getStd: $e');
      return null;
    }
  }

  static Future<List<dynamic>> listStdTerritoires(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stds/$id/territoires'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listStdTerritoires: $e');
      return [];
    }
  }

  static Future<dynamic> createStd(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/stds'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.createStd: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateStd(String id, Map<String, dynamic> payload) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/stds/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.updateStd: $e');
      rethrow;
    }
  }

  static Future<dynamic> deleteStd(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/stds/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.deleteStd: $e');
      rethrow;
    }
  }

  // --- AFFILIATIONS ---

  static Future<List<dynamic>> listAffiliations() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/affiliations'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listAffiliations: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listAffiliationsByUser(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/affiliations/user/$userId'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listAffiliationsByUser: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listAffiliationsByEntite(int entiteId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/affiliations/entite/$entiteId'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listAffiliationsByEntite: $e');
      return [];
    }
  }

  static Future<dynamic> createAffiliation(String userId, int entiteId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/affiliations'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'entiteId': entiteId}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.createAffiliation: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateAffiliation(int id, String userId, int entiteId) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/affiliations/$id'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'entiteId': entiteId}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.updateAffiliation: $e');
      rethrow;
    }
  }

  static Future<dynamic> deleteAffiliation(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/affiliations/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.deleteAffiliation: $e');
      rethrow;
    }
  }

  // --- USER-TERRITOIRES ---

  static Future<List<dynamic>> listUserTerritoires() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/user-territoires'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listUserTerritoires: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listUserTerritoiresByUser(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/user-territoires/user/$userId'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listUserTerritoiresByUser: $e');
      return [];
    }
  }

  static Future<dynamic> createUserTerritoire(String userId, String formattedId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/user-territoires'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'formatted_id': formattedId}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.createUserTerritoire: $e');
      rethrow;
    }
  }

  static Future<dynamic> deleteUserTerritoire(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/user-territoires/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.deleteUserTerritoire: $e');
      rethrow;
    }
  }

  // --- OFFRES ---

  static Future<List<dynamic>> listOffres() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/offres'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listOffres: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listOffresByStd(String stdId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/offres/std/$stdId'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listOffresByStd: $e');
      return [];
    }
  }

  static Future<dynamic> createOffre(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/offres'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.createOffre: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateOffre(String id, Map<String, dynamic> payload) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/offres/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.updateOffre: $e');
      rethrow;
    }
  }

  static Future<dynamic> deleteOffre(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/offres/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.deleteOffre: $e');
      rethrow;
    }
  }

  // --- AFFILIATION-STD ---

  static Future<List<dynamic>> listAffiliationStds() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/affiliation-std'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('AffiliationService.listAffiliationStds: $e');
      return [];
    }
  }

  static Future<dynamic> createAffiliationStd(String userId, String stdId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/affiliation-std'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'stdId': stdId}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.createAffiliationStd: $e');
      rethrow;
    }
  }

  static Future<dynamic> getAffiliationStdByUser(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/affiliation-std/user/$userId'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint('AffiliationService.getAffiliationStdByUser: $e');
      return null;
    }
  }

  static Future<dynamic> deleteAffiliationStd(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/affiliation-std/$id'), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(res.body);
    } catch (e) {
      debugPrint('AffiliationService.deleteAffiliationStd: $e');
      rethrow;
    }
  }
}
