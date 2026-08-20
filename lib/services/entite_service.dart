import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class EntiteModel {
  final int id;
  final String nom;
  final String description;
  final String categorie;
  final String status;
  final String? logo;
  final String? logoFilename;

  EntiteModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.categorie,
    required this.status,
    this.logo,
    this.logoFilename,
  });

  factory EntiteModel.fromJson(Map<String, dynamic> json) {
    return EntiteModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? '',
      status: json['status'] ?? '',
      logo: json['logo'],
      logoFilename: json['logoFilename'],
    );
  }
}

/// Service Affiliations API Endpoints (liste_des_services.txt) :
/// SERVICES AFFILIATIONS:
/// - POST   https://gateway.tsirylab.com/serviceaffiliation/entites (Créer une entité)
/// - GET    https://gateway.tsirylab.com/serviceaffiliation/entites (Lister toutes les entités)
/// - GET    https://gateway.tsirylab.com/serviceaffiliation/entites/categorie/{categorie} (Lister par catégorie)
/// - GET    https://gateway.tsirylab.com/serviceaffiliation/entites/{id} (Récupérer une entité)
/// - PUT    https://gateway.tsirylab.com/serviceaffiliation/entites/{id} (Mettre à jour une entité)
/// - DELETE https://gateway.tsirylab.com/serviceaffiliation/entites/{id} (Supprimer une entité)
/// - GET    https://gateway.tsirylab.com/serviceaffiliation/affiliations (Récupérer toutes les affiliations)
/// - GET    https://gateway.tsirylab.com/serviceaffiliation/stds (Récupérer tous les STDs)
/// - GET    https://gateway.tsirylab.com/serviceaffiliation/offres (Récupérer toutes les offres)
class EntiteService {
  static const String baseUrl = ApiConstants.serviceAffiliation;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<List<EntiteModel>> getEntites() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/entites'), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      List dataList = jsonDecode(response.body);
      return dataList.map((item) => EntiteModel.fromJson(item)).toList();
    } catch (error) {
      debugPrint('Erreur lors de la récupération des entités: $error');
      rethrow;
    }
  }

  static Future<List<EntiteModel>> getMinisteres() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/entites/categorie/ministere'), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      List dataList = jsonDecode(response.body);
      return dataList.map((item) => EntiteModel.fromJson(item)).toList();
    } catch (error) {
      debugPrint('Erreur lors de la récupération des ministères: $error');
      rethrow;
    }
  }

  static Future<EntiteModel?> getEntiteById(String id) async {
    try {
      final entites = await getEntites();
      return entites.firstWhere(
        (entite) => entite.id.toString() == id,
        orElse: () => throw Exception('Entité non trouvée'),
      );
    } catch (error) {
      debugPrint('Erreur lors de la récupération de l\'entité: $error');
      return null;
    }
  }
}