import 'dart:developer';
import 'package:dio/dio.dart';

class MonographieEventService {
  final Dio _dio;
  final String baseUrl;

  MonographieEventService({
    Dio? dio,
    required this.baseUrl,
  }) : _dio = dio ?? Dio();

  // Récupère 8 actualités d'une commune
  Future<List<dynamic>> getActualitesByCommune(String comFormattedId, {int limit = 8}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/servicepublication/events/dispositif-district',
        queryParameters: {
          'limit': limit,
          'page': 1,
          'communeId': comFormattedId,
        },
      );

      return response.data['data'] ?? [];
    } catch (e) {
      log("Erreur lors de la récupération des actualités de la commune : $e");
      return [];
    }
  }

  // Récupère TOUTES les actualités d'une commune (pagination complète)
  Future<List<dynamic>> getAllActualitesByCommune(String comFormattedId) async {
    try {
      final firstRes = await _dio.get(
        '$baseUrl/servicepublication/events/dispositif-district',
        queryParameters: {
          'limit': 10,
          'page': 1,
          'communeId': comFormattedId,
        },
      );

      final responseData = firstRes.data;
      final int limit = responseData['limit'] ?? 10;
      final int total = responseData['total'] ?? 0;
      final List<dynamic> firstPageEvents = responseData['data'] ?? [];
      
      final int numberOfPages = (total / limit).ceil();
      final int totalPages = numberOfPages < 1 ? 1 : numberOfPages;

      if (totalPages == 1) {
        return firstPageEvents;
      }

      final List<Future<Response>> requests = [];
      for (int i = 2; i <= totalPages; i++) {
        requests.add(
          _dio.get(
            '$baseUrl/servicepublication/events/dispositif-district',
            queryParameters: {
              'limit': 10,
              'page': i,
              'communeId': comFormattedId,
            },
          ),
        );
      }

      final responses = await Future.wait(requests);

      List<dynamic> allEvents = [...firstPageEvents];
      for (var res in responses) {
        allEvents.addAll(res.data['data'] ?? []);
      }

      log("Total actualités commune $comFormattedId: ${allEvents.length}");
      return allEvents;
    } catch (e) {
      log("Erreur lors de la récupération de toutes les actualités de la commune : $e");
      return [];
    }
  }

  // Récupère 8 actualités d'un district
  Future<List<dynamic>> getActualitesByDistrict(String distFormattedId, {int limit = 8}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/servicepublication/events/dispositif-district',
        queryParameters: {
          'limit': limit,
          'page': 1,
          'districtId': distFormattedId,
        },
      );

      return response.data['data'] ?? [];
    } catch (e) {
      log("Erreur lors de la récupération des actualités du district : $e");
      return [];
    }
  }

  // Récupère TOUTES les actualités d'un district (pagination complète)
  Future<List<dynamic>> getAllActualitesByDistrict(String distFormattedId) async {
    try {
      final firstRes = await _dio.get(
        '$baseUrl/servicepublication/events/dispositif-district',
        queryParameters: {
          'limit': 10,
          'page': 1,
          'districtId': distFormattedId,
        },
      );

      final responseData = firstRes.data;
      final int limit = responseData['limit'] ?? 10;
      final int total = responseData['total'] ?? 0;
      final List<dynamic> firstPageEvents = responseData['data'] ?? [];

      final int numberOfPages = (total / limit).ceil();
      final int totalPages = numberOfPages < 1 ? 1 : numberOfPages;

      if (totalPages == 1) {
        return firstPageEvents;
      }

      final List<Future<Response>> requests = [];
      for (int i = 2; i <= totalPages; i++) {
        requests.add(
          _dio.get(
            '$baseUrl/servicepublication/events/dispositif-district',
            queryParameters: {
              'limit': 10,
              'page': i,
              'districtId': distFormattedId,
            },
          ),
        );
      }

      final responses = await Future.wait(requests);

      List<dynamic> allEvents = [...firstPageEvents];
      for (var res in responses) {
        allEvents.addAll(res.data['data'] ?? []);
      }

      log("Total actualités district $distFormattedId: ${allEvents.length}");
      return allEvents;
    } catch (e) {
      log("Erreur lors de la récupération de toutes les actualités du district : $e");
      return [];
    }
  }
}