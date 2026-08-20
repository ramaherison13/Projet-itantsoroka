import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cache_manager.dart';

// --- Modèles de Données ---

class DocumentModel {
  final int id;
  final String filename;
  final String title;
  final String date;
  final String description;
  final String category;
  final List<String> theme;
  final String? type;
  final String status;
  final String? fileFormat;
  final String? communeId;
  final String? fileId;
  final String? langage;

  DocumentModel({
    required this.id,
    required this.filename,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
    required this.theme,
    this.type,
    required this.status,
    this.fileFormat,
    this.communeId,
    this.fileId,
    this.langage,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    var rawTheme = json['theme'];
    List<String> parsedTheme = [];
    if (rawTheme is List) {
      parsedTheme = rawTheme.map((e) => e.toString()).toList();
    } else if (rawTheme != null) {
      parsedTheme = [rawTheme.toString()];
    }

    return DocumentModel(
      id: json['id'] ?? 0,
      filename: json['filename'] ?? json['fileId'] ?? 'document-${json['id']}',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      theme: parsedTheme,
      type: json['type'],
      status: json['status'] ?? 'Public',
      fileFormat: json['fileFormat'],
      communeId: json['communeId'],
      fileId: json['fileId'],
      langage: json['langage'],
    );
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String? label;

  CategoryModel({
    required this.id,
    required this.name,
    this.label,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      label: json['label'],
    );
  }
}

class DocumentPayload {
  final File? file;
  final String title;
  final String description;
  final String category;
  final String type;
  final String theme; // JSON string contenant un tableau d'IDs
  final String date;
  final String status;
  final String? communeId;

  DocumentPayload({
    this.file,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.theme,
    required this.date,
    required this.status,
    this.communeId,
  });
}

class FetchDocumentsParams {
  final int limit;
  final String searchTerm;
  final String selectedType;
  final String selectedCategory;
  final String selectedTheme;
  final String selectedStatus;
  final String selectedCommune;

  FetchDocumentsParams({
    this.limit = 100,
    this.searchTerm = "",
    this.selectedType = "",
    this.selectedCategory = "",
    this.selectedTheme = "",
    this.selectedStatus = "",
    this.selectedCommune = "",
  });
}

class FetchDocumentsResponse {
  final List<DocumentModel> documents;
  final int totalItems;
  final int totalPages;

  FetchDocumentsResponse({
    required this.documents,
    required this.totalItems,
    required this.totalPages,
  });
}

// --- Service ---

/// Service Biblio (Documents & Ressources) API Endpoints (liste_des_services.txt) :
/// SERVICES BIBLIO:
/// - GET    https://gateway.tsirylab.com/servicebiblio (Get servicebiblio)
/// - POST   https://gateway.tsirylab.com/servicebiblio/resources (Upload a new resource)
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources (Retrieve all resources with pagination)
/// - PATCH  https://gateway.tsirylab.com/servicebiblio/resources/{id} (Update status, themes, category by ID)
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources/{id} (Retrieve a specific resource by ID)
/// - DELETE https://gateway.tsirylab.com/servicebiblio/resources/{id} (Delete a resource and file by ID)
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources/commune/{communeId}
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources/theme/juridique
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources/filter
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources/search
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources/{id}/file (Download resource file)
/// - GET    https://gateway.tsirylab.com/servicebiblio/resources/{id}/preview (Preview resource file)
class DocumentService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicebiblio";

  /// Service pour ajouter un document
  static Future<String> addDocument(DocumentPayload data) async {
    debugPrint("data to send: ${data.title}");

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/resources'),
    );

    if (data.file != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', data.file!.path),
      );
    }

    request.fields['title'] = data.title;
    request.fields['description'] = data.description;
    request.fields['category'] = data.category;
    request.fields['type'] = data.type;
    request.fields['date'] = data.date;
    request.fields['status'] = data.status;
    if (data.communeId != null) {
      request.fields['communeId'] = data.communeId!;
    }
    request.fields['theme'] = data.theme;
    request.fields['langage'] = 'fr';

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    var result = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(result['message'] ?? "Erreur lors de l'ajout du document");
    }

    return "result";
  }

  /// Service pour récupérer les documents avec pagination optimisée et cache
  static Future<FetchDocumentsResponse> fetchDocuments({
    int limit = 100,
    String searchTerm = "",
    String selectedType = "",
    String selectedCategory = "",
    String selectedTheme = "",
    String selectedStatus = "",
    String selectedCommune = "",
  }) async {
    final cacheKey = 'docs_${limit}_${searchTerm}_${selectedType}_${selectedCategory}_${selectedTheme}_${selectedStatus}_$selectedCommune';

    // 1. Retour immédiat du cache si disponible (< 15ms)
    final cached = await CacheManager.get(cacheKey);
    if (cached != null && cached is Map) {
      try {
        final List cachedList = cached['documents'] ?? [];
        final docs = cachedList.map((item) => DocumentModel.fromJson(Map<String, dynamic>.from(item))).toList();
        final totalItems = cached['totalItems'] as int? ?? docs.length;
        final totalPages = cached['totalPages'] as int? ?? 1;

        // Rafraîchir silencieusement le cache en arrière-plan
        _fetchDocumentsFromNetwork(cacheKey, limit, searchTerm, selectedType, selectedCategory, selectedTheme, selectedStatus, selectedCommune).catchError((_) => FetchDocumentsResponse(documents: docs, totalItems: totalItems, totalPages: totalPages));

        return FetchDocumentsResponse(
          documents: docs,
          totalItems: totalItems,
          totalPages: totalPages,
        );
      } catch (e) {
        debugPrint("Erreur décodage cache documents: $e");
      }
    }

    // 2. Si aucun cache disponible, exécuter le chargement réseau
    return await _fetchDocumentsFromNetwork(cacheKey, limit, searchTerm, selectedType, selectedCategory, selectedTheme, selectedStatus, selectedCommune);
  }

  static Future<FetchDocumentsResponse> _fetchDocumentsFromNetwork(
    String cacheKey,
    int limit,
    String searchTerm,
    String selectedType,
    String selectedCategory,
    String selectedTheme,
    String selectedStatus,
    String selectedCommune,
  ) async {
    try {
      String buildUrl(int page) {
        String urlStr = '$baseUrl/resources?page=$page&limit=$limit';
        if (searchTerm.isNotEmpty) urlStr += '&search=${Uri.encodeComponent(searchTerm)}';
        if (selectedType.isNotEmpty) urlStr += '&type=${Uri.encodeComponent(selectedType)}';
        if (selectedCategory.isNotEmpty) urlStr += '&category=${Uri.encodeComponent(selectedCategory)}';
        if (selectedTheme.isNotEmpty) urlStr += '&theme=${Uri.encodeComponent(selectedTheme)}';
        if (selectedStatus.isNotEmpty) urlStr += '&status=${Uri.encodeComponent(selectedStatus)}';
        if (selectedCommune.isNotEmpty) urlStr += '&communeId=${Uri.encodeComponent(selectedCommune)}';
        return urlStr;
      }

      // Première page
      final firstRes = await http.get(Uri.parse(buildUrl(1)));
      final firstData = jsonDecode(firstRes.body);

      if (firstRes.statusCode < 200 || firstRes.statusCode >= 300) {
        throw Exception(firstData['message'] ?? "Erreur lors de la récupération des données.");
      }

      List dataList = List.from(firstData['data'] ?? []);
      int totalItems = int.tryParse(firstData['total']?.toString() ?? '') ?? dataList.length;
      int totalPages = (totalItems / limit).ceil();

      // Si plusieurs pages, les charger en parallèle avec Future.wait au lieu d'une boucle séquentielle
      if (totalPages > 1 && dataList.length >= limit) {
        final futures = List.generate(totalPages - 1, (index) {
          final pageNum = index + 2;
          return http.get(Uri.parse(buildUrl(pageNum)));
        });

        final responses = await Future.wait(futures);
        for (var res in responses) {
          if (res.statusCode == 200) {
            final pageData = jsonDecode(res.body);
            List pageItems = pageData['data'] ?? [];
            dataList.addAll(pageItems);
          }
        }
      }

      List<DocumentModel> allDocuments = dataList
          .map((item) => DocumentModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // Sauvegarder dans le cache local
      final rawListToCache = dataList.map((item) => Map<String, dynamic>.from(item)).toList();
      await CacheManager.set(cacheKey, {
        'documents': rawListToCache,
        'totalItems': totalItems,
        'totalPages': totalPages,
      });

      return FetchDocumentsResponse(
        documents: allDocuments,
        totalItems: totalItems,
        totalPages: totalPages,
      );
    } catch (error) {
      debugPrint("Erreur réseau chargement documents: $error");
      rethrow;
    }
  }

  /// Service pour récupérer les catégories de documents
  static Future<List<CategoryModel>> fetchCategories() async {
    final response = await http.get(
      Uri.parse("https://gateway.tsirylab.com/servicetheme/category"),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur lors de la récupération des catégories");
    }

    List dataList = jsonDecode(response.body);
    List<CategoryModel> categories = dataList
        .map((item) => CategoryModel.fromJson(item))
        .toList();

    return categories;
  }
}