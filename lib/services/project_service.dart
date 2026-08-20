import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'cache_manager.dart';

/// Service Projets API Endpoints (liste_des_services.txt) :
/// SERVICES PROJETS:
/// - POST   https://gateway.tsirylab.com/serviceprojet/projects (Créer un nouveau projet avec fichiers)
/// - GET    https://gateway.tsirylab.com/serviceprojet/projects (Lister tous les projets avec pagination)
/// - GET    https://gateway.tsirylab.com/serviceprojet/projects/{id} (Récupérer un projet par ID)
/// - PATCH  https://gateway.tsirylab.com/serviceprojet/projects/{id} (Mettre à jour un projet par ID)
/// - DELETE https://gateway.tsirylab.com/serviceprojet/projects/{id} (Supprimer un projet par ID)
/// - GET    https://gateway.tsirylab.com/serviceprojet/projects/commune/{communeId} (Projets par commune)
/// - GET    https://gateway.tsirylab.com/serviceprojet/projects/status/{status} (Projets par statut)
class ProjectService {
  static const String baseUrl = "https://gateway.tsirylab.com/serviceprojet";

  // Créer un nouveau projet avec uploads de fichiers
  static Future<dynamic> createProject(http.MultipartRequest formData) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/projects'));
      request.fields.addAll(formData.fields);
      request.files.addAll(formData.files);
      request.headers.addAll(formData.headers);
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(resData['message'] ?? "Erreur lors de la création du projet");
      }
      await CacheManager.clearAll();
      return resData;
    } catch (error) {
      debugPrint("Create project error: $error");
      rethrow;
    }
  }

  // Récupérer une liste de projets (tri A-Z + pagination)
  static Future<Map<String, dynamic>> getProjects({
    int page = 1,
    int limit = 12,
    String sortBy = "name",
  }) async {
    final cacheKey = 'projects_${page}_${limit}_$sortBy';
    final cached = await CacheManager.get(cacheKey);
    if (cached != null && cached is Map) {
      _fetchProjectsFromNetwork(cacheKey, page, limit, sortBy).catchError((_) => <String, dynamic>{'projects': [], 'pagination': null});
      return Map<String, dynamic>.from(cached);
    }
    return await _fetchProjectsFromNetwork(cacheKey, page, limit, sortBy);
  }

  static Future<Map<String, dynamic>> _fetchProjectsFromNetwork(
    String cacheKey,
    int page,
    int limit,
    String sortBy,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects?page=$page&limit=$limit&sortBy=$sortBy'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      final resData = jsonDecode(response.body);
      Map<String, dynamic> result = {'projects': [], 'pagination': null};

      if (resData is Map && resData['data'] is Map && resData['data']['data'] is List) {
        result = {
          'projects': resData['data']['data'],
          'pagination': resData['data']['pagination'],
        };
      } else if (resData is Map && resData['data'] is List) {
        result = {
          'projects': resData['data'],
          'pagination': resData['pagination'],
        };
      } else if (resData is Map && resData['projects'] is List) {
        result = {
          'projects': resData['projects'],
          'pagination': resData['pagination'],
        };
      } else if (resData is List) {
        result = {
          'projects': resData,
          'pagination': null,
        };
      }

      await CacheManager.set(cacheKey, result, ttl: const Duration(minutes: 15));
      return result;
    } catch (error) {
      debugPrint("Get projects error: $error");
      rethrow;
    }
  }

  // Récupérer un projet par son ID
  static Future<dynamic> getProjectById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$id'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      final resData = jsonDecode(response.body);
      return (resData is Map && resData['data'] != null) ? resData['data'] : resData;
    } catch (error) {
      debugPrint("Get project by ID error: $error");
      rethrow;
    }
  }

  // Mettre à jour un projet
  static Future<dynamic> updateProject(String id, Map<String, dynamic> projectData) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/projects/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(projectData),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final resData = jsonDecode(response.body);
        throw Exception(resData['message'] ?? "Erreur HTTP: ${response.statusCode}");
      }

      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Update project error: $error");
      rethrow;
    }
  }

  // Supprimer un projet
  static Future<dynamic> deleteProject(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$id'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      return jsonDecode(response.body);
    } catch (error) {
      debugPrint("Delete project error: $error");
      rethrow;
    }
  }

  // Récupérer les projets par commune
  static Future<dynamic> getProjectsByCommune(String communeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/commune/$communeId'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      final resData = jsonDecode(response.body);
      return (resData is Map && resData['data'] != null) ? resData['data'] : resData;
    } catch (error) {
      debugPrint("Get projects by commune error: $error");
      rethrow;
    }
  }

  // Récupérer les projets par statut avec pagination
  static Future<Map<String, dynamic>> getProjectsByStatus(
    String status, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/status/$status?page=$page&limit=$limit'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Erreur HTTP: ${response.statusCode}");
      }

      final resData = jsonDecode(response.body);

      if (resData is Map && resData['data'] is Map && resData['data']['data'] is List) {
        return {
          'projects': resData['data']['data'],
          'pagination': resData['data']['pagination'],
        };
      }
      return {
        'projects': (resData is Map && resData['data'] != null) ? resData['data'] : [],
        'pagination': null,
      };
    } catch (error) {
      debugPrint("Get projects by status error: $error");
      rethrow;
    }
  }
}