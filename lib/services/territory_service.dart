import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// Service Territoire V2 API Endpoints (liste_des_services.txt) :
/// SERVICES TERRITOIRE-V2:
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/communes/sans-form (Communes sans formation)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/communes/basic (Communes basiques paginées)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/communes/district/{districtId} (Communes par district)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/communes/{id} (Commune par ID)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/regions (Toutes les régions)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/regions/basic (Régions basiques paginées)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/districts (Tous les districts)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/districts/basic (Districts basiques paginés)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/serviceterritoire/get-code/{id} (Territoire par code)
class TerritoryService {
  static const String baseUrl = ApiConstants.serviceTerritoire;
  static const Map<String, String> headers = {
    'Accept': 'application/json',
  };

  // Cache statique en mémoire pour éviter le téléchargement répété des territoires
  static List<dynamic>? _cachedRegions;
  static List<dynamic>? _cachedDistricts;
  static List<dynamic>? _cachedCommunes;

  static void clearCache() {
    _cachedRegions = null;
    _cachedDistricts = null;
    _cachedCommunes = null;
  }

  static String _endpoint(String path) => '$baseUrl$path';

  static Future<List<dynamic>?> getAllCommunes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCommunes != null && _cachedCommunes!.isNotEmpty) {
      return _cachedCommunes;
    }
    try {
      final response = await http
          .get(Uri.parse(_endpoint('/communes/sans-form')), headers: headers)
          .timeout(const Duration(seconds: 10));
      debugPrint("COMMUNES: ${response.body}");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is List) ? decoded : _extractArray(decoded);
        if (list != null && list.isNotEmpty) {
          _cachedCommunes = list;
        }
        return list;
      }
      return _cachedCommunes;
    } catch (error) {
      debugPrint("Erreur lors de la récupération des communes: $error");
      return _cachedCommunes;
    }
  }

  static List<dynamic>? _extractArray(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map<String, dynamic>) {
      if (payload['data'] is List) return payload['data'];
      if (payload['data'] is Map && payload['data']['data'] is List) {
        return payload['data']['data'];
      }
      if (payload['results'] is List) return payload['results'];
      if (payload['items'] is List) return payload['items'];
    }
    return null;
  }

  static Future<List<dynamic>?> _fetchTerritoryList(String path, String contextLabel, {String? fallbackPath}) async {
    Future<List<dynamic>?> tryPath(String p) async {
      try {
        final response = await http
            .get(Uri.parse(_endpoint(p)), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) return null;
        final decoded = jsonDecode(response.body);
        final data = _extractArray(decoded);
        return data;
      } catch (_) {
        return null;
      }
    }

    final result = await tryPath(path);
    if (result != null) return result;
    if (fallbackPath != null) {
      return tryPath(fallbackPath);
    }
    return null;
  }

  static Future<List<dynamic>?> getAllRegions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRegions != null && _cachedRegions!.isNotEmpty) {
      return _cachedRegions;
    }
    final res = await _fetchTerritoryList('/regions', "des régions");
    if (res != null && res.isNotEmpty) {
      _cachedRegions = res;
    }
    return res ?? _cachedRegions;
  }

  static Future<List<dynamic>?> getAllDistricts({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDistricts != null && _cachedDistricts!.isNotEmpty) {
      return _cachedDistricts;
    }
    final res = await _fetchTerritoryList('/districts', "des districts");
    if (res != null && res.isNotEmpty) {
      _cachedDistricts = res;
    }
    return res ?? _cachedDistricts;
  }

  static Future<dynamic> getTerritoryByFormattedId(String? id) async {
    if (id == null) return null;
    try {
      final response = await http
          .get(Uri.parse(_endpoint('/serviceterritoire/get-code/$id')), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (error) {
      debugPrint("Erreur lors de la récupération des districts: $error");
      return null;
    }
  }

  static Future<List<dynamic>?> getRegionsBasic({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRegions != null && _cachedRegions!.isNotEmpty) {
      return _cachedRegions;
    }
    final res = await _fetchTerritoryList(
      '/regions',
      "des régions",
      fallbackPath: '/regions/basic?page=1&limit=24',
    );
    if (res != null && res.isNotEmpty) {
      _cachedRegions = res;
    }
    return res ?? _cachedRegions;
  }

  /// Récupère la liste des districts.
  static Future<List<dynamic>?> getDistrictsBasic({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDistricts != null && _cachedDistricts!.isNotEmpty) {
      return _cachedDistricts;
    }
    final res = await _fetchTerritoryList(
      '/districts',
      "des districts",
      fallbackPath: '/districts/sans-form',
    );
    if (res != null && res.isNotEmpty) {
      _cachedDistricts = res;
    }
    return res ?? _cachedDistricts;
  }

  /// Récupère les communes. Essaie d'abord /communes/sans-form (pas de pagination)
  /// puis /communes/basic en fallback.
  static Future<List<dynamic>?> getCommunesBasic({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCommunes != null && _cachedCommunes!.isNotEmpty) {
      return _cachedCommunes;
    }
    final res = await _fetchTerritoryList(
      '/communes/sans-form',
      "des communes",
      fallbackPath: '/communes/basic?page=1&limit=1579',
    );
    if (res != null && res.isNotEmpty) {
      _cachedCommunes = res;
    }
    return res ?? _cachedCommunes;
  }

  static Future<List<dynamic>?> getCommunesByDistrict(String districtFormattedId) async {
    return _fetchTerritoryList('/communes/district/$districtFormattedId', "des communes du district $districtFormattedId");
  }
}