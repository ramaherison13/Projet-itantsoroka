import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

import 'cache_manager.dart';

/// Service Monographies API Endpoints (liste_des_services.txt) :
/// MONOGRAPHIE :
/// - POST   https://gateway.tsirylab.com/servicemonographies/monographies (Créer une monographie avec upload de fichier)
/// - GET    https://gateway.tsirylab.com/servicemonographies/monographies (Récupérer toutes les monographies)
/// - GET    https://gateway.tsirylab.com/servicemonographies/monographies/{id} (Récupérer une monographie par ID)
/// - PUT    https://gateway.tsirylab.com/servicemonographies/monographies/{id} (Mettre à jour une monographie avec upload)
/// - DELETE https://gateway.tsirylab.com/servicemonographies/monographies/{id} (Supprimer une monographie)
/// - GET    https://gateway.tsirylab.com/servicemonographies/monographiesCode/{formattedId} (Récupérer par formattedid)
class TerritoireService {
  static const String baseUrl = ApiConstants.serviceMonographies;
  static const String territoireBaseUrl = ApiConstants.serviceTerritoire;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<dynamic> getAllTerritoires(String territoire) async {
    final cacheKey = 'territoires_$territoire';
    final cached = await CacheManager.get(cacheKey);
    if (cached != null) {
      // Rafraîchir en arrière-plan
      _fetchTerritoiresFromNetwork(territoire, cacheKey).catchError((_) => null);
      return cached;
    }
    return await _fetchTerritoiresFromNetwork(territoire, cacheKey);
  }

  static Future<dynamic> _fetchTerritoiresFromNetwork(String territoire, String cacheKey) async {
    try {
      final response = await http
          .get(Uri.parse('$territoireBaseUrl/$territoire/basic?page=1&limit=10000'), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        await CacheManager.set(cacheKey, data, ttl: const Duration(hours: 1));
        return data;
      }
      return null;
    } catch (error) {
      debugPrint("Erreur lors de la récupération des communes : $error");
      return null;
    }
  }

  static Future<dynamic> createMonographie(http.MultipartRequest formData) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/monographies'));
      request.fields.addAll(formData.fields);
      request.files.addAll(formData.files);
      request.headers.addAll(formData.headers);
      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(resData['message'] ?? "Erreur lors de la création de la monographie");
      }
      await CacheManager.invalidate('all_monographies');
      return resData;
    } catch (error) {
      debugPrint("Erreur lors de la création de la monographie: $error");
      rethrow;
    }
  }

  static Future<List<dynamic>?> getAllMonographies() async {
    const cacheKey = 'all_monographies';
    final cached = await CacheManager.get(cacheKey);
    if (cached != null && cached is List) {
      _fetchMonographiesFromNetwork(cacheKey).catchError((_) => null);
      return cached;
    }
    return await _fetchMonographiesFromNetwork(cacheKey);
  }

  static Future<List<dynamic>?> _fetchMonographiesFromNetwork(String cacheKey) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/monographies'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        await CacheManager.set(cacheKey, data, ttl: const Duration(minutes: 30));
        return data;
      }
      return null;
    } catch (error) {
      debugPrint("Erreur lors de la récupération des monographies: $error");
      return null;
    }
  }

  static Future<dynamic> getMonographieById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/monographies/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (error) {
      debugPrint("Erreur lors de la récupération de la monographie $id: $error");
      return null;
    }
  }

  static Future<dynamic> getMonographieByFormattedId(String formattedId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/monographiesCode/$formattedId'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (error) {
      debugPrint("Erreur lors de la récupération de la monographie $formattedId: $error");
      return null;
    }
  }

  static Future<dynamic> updateMonographie(int id, http.MultipartRequest formData) async {
    try {
      final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/monographies/$id'));
      request.fields.addAll(formData.fields);
      request.files.addAll(formData.files);
      request.headers.addAll(formData.headers);
      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);
      final resData = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(resData['message'] ?? "Erreur lors de la mise à jour de la monographie");
      }
      return resData;
    } catch (error) {
      debugPrint("Erreur lors de la mise à jour de la monographie $id: $error");
      rethrow;
    }
  }

  static Future<bool> deleteMonographie(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/monographies/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (error) {
      debugPrint("Erreur lors de la suppression de la monographie $id: $error");
      return false;
    }
  }
}