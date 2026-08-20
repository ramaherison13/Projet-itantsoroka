import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service Territoire V2 (Fokotany) API Endpoints (liste_des_services.txt) :
/// SERVICES TERRITOIRE-V2:
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/communes/{id} (Commune par ID avec fokotanys)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/districts/{formattedId} (District avec région)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/regions/{formattedId} (Région avec province)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/communes/district/{districtId} (Communes par district)
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/arrondissements/district/{districtId}
/// - GET    https://gateway.tsirylab.com/serviceterritoire-v2/arrondissements/commune/{communeId}
class FokotanyApiService {
  final String _apiBase;
  final Dio _dio = Dio();

  FokotanyApiService({String apiUrl = 'https://gateway.tsirylab.com'})
      : _apiBase = '$apiUrl/serviceterritoire-v2';

  Future<dynamic> getTerritoireByCommune(int municipalityId) async {
    try {
      final response = await _dio.get('$_apiBase/communes/$municipalityId');
      final fokotanys = response.data['fokotanys'];
      final district = response.data['district'];

      debugPrint("🏘️ District : $district");
      debugPrint("📍 Fokotanys récupérés : $fokotanys");

      final districtRes = await _dio.get('$_apiBase/districts/${district['formatted_id']}');
      final region = districtRes.data['region'];

      debugPrint("🌍 Région : $region");

      final regionRes = await _dio.get('$_apiBase/regions/${region['formatted_id']}');
      final province = regionRes.data['region']['province']['name'];

      debugPrint("🗺️ Province : $province");

      final communes = await _dio.get('$_apiBase/communes/district/${district['formatted_id']}');
      debugPrint("🏘️ Communes dans le district : ${communes.data}");

      final arrondissementByDistrict = await _dio.get('$_apiBase/arrondissements/district/${district['formatted_id']}');
      debugPrint("Arrondissement by district : $arrondissementByDistrict");

      final arrondissementByCommune = await _dio.get('$_apiBase/arrondissements/commune/$municipalityId');
      debugPrint("Arrondissement by commune : $arrondissementByCommune");

      dynamic arrondissement;
      if (communes.data is List && (communes.data as List).length == 1) {
        arrondissement = arrondissementByCommune.data;
      } else {
        arrondissement = arrondissementByDistrict.data;
      }
      debugPrint("Arrondissement final : $arrondissement");

      final territoireData = {
        'province': province,
        'region': region,
        'district': district,
        'communes': communes.data,
        'fokotanys': fokotanys,
        'arrondissement': arrondissement,
      };

      // Sauvegarde dans SharedPreferences (équivalent localStorage)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('territoireData', jsonEncode(territoireData));

      return territoireData;
    } catch (error) {
      debugPrint("Erreur getTerritoireByCommune : $error");
      return [];
    }
  }
}