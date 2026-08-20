import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

// ========== MODÈLES DE DONNÉES ==========

class CategoryModel {
  final String categoryId;
  final String name;
  final String? label;

  CategoryModel({
    required this.categoryId,
    required this.name,
    this.label,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id']?.toString() ?? '',
      name: json['name'] ?? '',
      label: json['label'],
    );
  }
}

class ThemeModelFilter {
  final String themeId;
  final String name;
  final String? label;

  ThemeModelFilter({
    required this.themeId,
    required this.name,
    this.label,
  });

  factory ThemeModelFilter.fromJson(Map<String, dynamic> json) {
    return ThemeModelFilter(
      themeId: json['theme_id']?.toString() ?? '',
      name: json['name'] ?? '',
      label: json['label'],
    );
  }
}

class TypeModelFilter {
  final String typeId;
  final String name;
  final String category;

  TypeModelFilter({
    required this.typeId,
    required this.name,
    required this.category,
  });

  factory TypeModelFilter.fromJson(Map<String, dynamic> json) {
    return TypeModelFilter(
      typeId: json['type_id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class FilterDataResult {
  final List<CategoryModel> categories;
  final List<ThemeModelFilter> themes;
  final List<TypeModelFilter> types;

  FilterDataResult({
    required this.categories,
    required this.themes,
    required this.types,
  });
}

// ========== SERVICE DE FILTRAGE ==========

/// Service Thèmes API Endpoints (liste_des_services.txt) :
/// SERVICES THEMES:
/// - GET    https://gateway.tsirylab.com/servicetheme (Get servicetheme)
/// - POST   https://gateway.tsirylab.com/servicetheme/themes (Create a theme)
/// - GET    https://gateway.tsirylab.com/servicetheme/themes (Get all themes)
/// - GET    https://gateway.tsirylab.com/servicetheme/themes/{id} (Get a theme by ID)
/// - POST   https://gateway.tsirylab.com/servicetheme/type (Create a new type of DOCUMENT or EVENT)
/// - GET    https://gateway.tsirylab.com/servicetheme/type (Get all types with optional filter)
/// - POST   https://gateway.tsirylab.com/servicetheme/category (Create a new category)
/// - GET    https://gateway.tsirylab.com/servicetheme/category (Get all categories)
class FiltreService {
  static const String baseUrl = ApiConstants.serviceTheme;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Maps pour stocker les correspondances ID <-> nom
  static final Map<String, String> _categoriesMap = {};
  static final Map<String, String> _themesMap = {};
  static final Map<String, String> _typesMap = {};

  /// Récupère toutes les données de filtrage et initialise les maps
  static Future<FilterDataResult> initializeFilterData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/category'), headers: headers).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$baseUrl/themes'), headers: headers).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$baseUrl/type?category=DOCUMENT'), headers: headers).timeout(const Duration(seconds: 10)),
      ]);

      List catList = responses[0].statusCode == 200 ? jsonDecode(responses[0].body) : [];
      List themeList = responses[1].statusCode == 200 ? jsonDecode(responses[1].body) : [];
      List typeList = responses[2].statusCode == 200 ? jsonDecode(responses[2].body) : [];

      List<CategoryModel> categories = catList.map((e) => CategoryModel.fromJson(e)).toList();
      List<ThemeModelFilter> themes = themeList.map((e) => ThemeModelFilter.fromJson(e)).toList();
      List<TypeModelFilter> types = typeList.map((e) => TypeModelFilter.fromJson(e)).toList();

      // Initialiser les maps de correspondance
      _categoriesMap.clear();
      _themesMap.clear();
      _typesMap.clear();

      debugPrint('📋 Catégories chargées: ${categories.length}');
      for (var cat in categories) {
        _categoriesMap[cat.categoryId] = cat.name;
        _categoriesMap[cat.name] = cat.name;
        debugPrint('  - ${cat.categoryId} → ${cat.name}');
      }

      debugPrint('🎨 Thèmes chargés: ${themes.length}');
      for (var theme in themes) {
        _themesMap[theme.themeId] = theme.name;
        _themesMap[theme.name] = theme.name;
        debugPrint('  - ${theme.themeId} → ${theme.name}');
      }

      debugPrint('📄 Types chargés: ${types.length}');
      for (var type in types) {
        _typesMap[type.typeId] = type.name;
        _typesMap[type.name] = type.name;
        debugPrint('  - ${type.typeId} → ${type.name}');
      }

      return FilterDataResult(categories: categories, themes: themes, types: types);
    } catch (error) {
      debugPrint("Erreur lors du chargement des données de filtrage : $error");
      rethrow;
    }
  }

  /// Résout un ID de catégorie en nom lisible
  static String resolveCategoryName(String categoryId) {
    final resolved = _categoriesMap[categoryId] ?? categoryId;
    debugPrint('🏷️ Résolution catégorie: $categoryId → $resolved (Map size: ${_categoriesMap.length})');
    return resolved;
  }

  /// Résout un ID de thème en nom lisible
  static String resolveThemeName(String themeId) {
    final resolved = _themesMap[themeId] ?? themeId;
    debugPrint('🎨 Résolution thème: $themeId → $resolved (Map size: ${_themesMap.length})');
    return resolved;
  }

  /// Résout un ID de type en nom lisible
  static String resolveTypeName(String typeId) {
    final resolved = _typesMap[typeId] ?? typeId;
    debugPrint('📋 Résolution type: $typeId → $resolved (Map size: ${_typesMap.length})');
    return resolved;
  }

  /// Parse les thèmes depuis les données du backend
  /// Les thèmes peuvent être sous forme de JSON string ou tableau d'IDs
  static List<String> parseThemes(List<dynamic> themeData) {
    if (themeData.isEmpty) return [];

    List<String> parsedThemes = [];

    for (var themeItem in themeData) {
      try {
        if (themeItem is String) {
          // Si c'est un JSON string, le parser
          if (themeItem.startsWith('[') || themeItem.startsWith('"')) {
            String cleanItem = themeItem.replaceAll(RegExp(r'^"|"$'), '');

            if (cleanItem.startsWith('[')) {
              List<dynamic> themes = jsonDecode(cleanItem);
              for (var theme in themes) {
                String cleanTheme = theme is String ? theme.replaceAll(RegExp(r'^"|"$'), '') : theme.toString();
                String resolvedTheme = resolveThemeName(cleanTheme);
                parsedThemes.add(resolvedTheme);
              }
            } else {
              String resolvedTheme = resolveThemeName(cleanItem);
              parsedThemes.add(resolvedTheme);
            }
          } else {
            String resolvedTheme = resolveThemeName(themeItem);
            parsedThemes.add(resolvedTheme);
          }
        } else if (themeItem != null) {
          String resolvedTheme = resolveThemeName(themeItem.toString());
          parsedThemes.add(resolvedTheme);
        }
      } catch (error) {
        debugPrint('Erreur lors du parsing du thème: $themeItem, $error');
        String cleanTheme = themeItem is String ? themeItem.replaceAll(RegExp(r'^"|"$'), '') : themeItem.toString();
        String resolvedTheme = resolveThemeName(cleanTheme);
        parsedThemes.add(resolvedTheme);
      }
    }

    return parsedThemes;
  }
}
// ========== MODÈLE DE FILTRES ==========

class DocumentFilterParams {
  final String? selectedType;
  final String? selectedCategory;
  final String? selectedTheme;
  final String? selectedStatus;
  final String? selectedCommune;
  final String? searchTerm;

  DocumentFilterParams({
    this.selectedType,
    this.selectedCategory,
    this.selectedTheme,
    this.selectedStatus,
    this.selectedCommune,
    this.searchTerm,
  });
}

// Extension ou méthode complémentaire pour `FiltreService` pour gérer le filtrage des documents
extension FiltreServiceDocumentExtension on FiltreService {
  
  static bool documentMatchesFilters(dynamic document, DocumentFilterParams filters) {
    final selectedType = filters.selectedType;
    final selectedCategory = filters.selectedCategory;
    final selectedTheme = filters.selectedTheme;
    final selectedStatus = filters.selectedStatus;
    final selectedCommune = filters.selectedCommune;
    final searchTerm = filters.searchTerm;

    debugPrint('🔍 Filtrage document: ID=${document['id']}, Title=${document['title']}');

    // Filtre par terme de recherche
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final searchLower = searchTerm.toLowerCase();
      final title = (document['title'] ?? '').toString().toLowerCase();
      final description = (document['description'] ?? '').toString().toLowerCase();
      
      final titleMatch = title.contains(searchLower);
      final descMatch = description.contains(searchLower);
      if (!titleMatch && !descMatch) {
        debugPrint('❌ Exclu par recherche');
        return false;
      }
    }

    // Filtre par type - gestion des noms et IDs (compatibilité)
    if (selectedType != null && selectedType.isNotEmpty) {
      final docType = document['type']?.toString() ?? '';
      
      if (docType.isEmpty) {
        debugPrint('❌ Exclu par type: document sans type');
        return false;
      }
      
      if (docType != selectedType) {
        final resolvedDocType = FiltreService.resolveTypeName(docType);
        if (resolvedDocType != selectedType) {
          debugPrint('❌ Exclu par type: $docType ($resolvedDocType) ≠ $selectedType');
          return false;
        }
      }
    }

    // Filtre par catégorie - gestion des noms et IDs (compatibilité)
    if (selectedCategory != null && selectedCategory.isNotEmpty) {
      final docCategory = document['category']?.toString() ?? '';
      
      if (selectedCategory == '__SANS_CATEGORIE__') {
        if (docCategory.isNotEmpty) {
          debugPrint('❌ Exclu par catégorie: document avec catégorie alors que "sans catégorie" sélectionné');
          return false;
        }
      } else {
        if (docCategory.isEmpty) {
          debugPrint('❌ Exclu par catégorie: document sans catégorie');
          return false;
        }
        
        if (docCategory != selectedCategory) {
          final resolvedDocCategory = FiltreService.resolveCategoryName(docCategory);
          if (resolvedDocCategory != selectedCategory) {
            debugPrint('❌ Exclu par catégorie: $docCategory ($resolvedDocCategory) ≠ $selectedCategory');
            return false;
          }
        }
      }
    }

    // Filtre par statut - gestion des variations (Public/public, Private/private)
    if (selectedStatus != null && selectedStatus.isNotEmpty) {
      final docStatus = document['status']?.toString() ?? 'Public';
      final normalizedDocStatus = docStatus.toLowerCase();
      final normalizedSelectedStatus = selectedStatus.toLowerCase();
      
      if (normalizedDocStatus != normalizedSelectedStatus) {
        debugPrint('❌ Exclu par statut: $docStatus ≠ $selectedStatus');
        return false;
      }
    }

    // Filtre par commune
    if (selectedCommune != null && selectedCommune.isNotEmpty) {
      if (document['communeId']?.toString() != selectedCommune) {
        debugPrint('❌ Exclu par commune: ${document['communeId']} ≠ $selectedCommune');
        return false;
      }
    }

    // Filtre par thème - gestion des noms et anciens formats JSON
    if (selectedTheme != null && selectedTheme.isNotEmpty) {
      List<String> documentThemes = [];
      var rawTheme = document['theme'];

      if (rawTheme is List) {
        if (rawTheme.isNotEmpty && rawTheme[0] is String && rawTheme[0].startsWith('[')) {
          documentThemes = FiltreService.parseThemes(rawTheme);
        } else {
          documentThemes = rawTheme.map((e) => e.toString()).toList();
        }
      } else if (rawTheme != null) {
        documentThemes = [rawTheme.toString()];
      }
      
      debugPrint('🏷️ Thèmes du document traités: $documentThemes');
      debugPrint('🏷️ Thème sélectionné: $selectedTheme');
      
      bool hasTheme = documentThemes.any((theme) {
        if (theme.toLowerCase() == selectedTheme.toLowerCase()) {
          debugPrint('✅ Thème trouvé (direct): $theme === $selectedTheme');
          return true;
        }
        
        final resolvedTheme = FiltreService.resolveThemeName(theme);
        if (resolvedTheme.toLowerCase() == selectedTheme.toLowerCase()) {
          debugPrint('✅ Thème trouvé (résolu): $theme → $resolvedTheme === $selectedTheme');
          return true;
        }
        
        return false;
      });
      
      if (!hasTheme) {
        debugPrint('❌ Exclu par thème - aucun thème ne correspond');
        return false;
      }
    }

    debugPrint('✅ Document accepté par tous les filtres');
    return true;
  }
}