import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ========== MODÈLES DE DONNÉES ==========

class ActeModel {
  final String id;
  final String titre;
  final String? description;
  final List<String> typeIds;
  final List<String> sousTypeIds;
  final String communeId;
  final String districtId;
  final String auteurId;
  final String statut;
  final String? fichier;
  final String? fichierUrl;
  final String? fichierName;
  final String? dateCreation;
  final String? dateModification;
  final String? createdAt;
  final String? updatedAt;
  final String? horodatage;
  final String? dateLimite;
  final int? delaiJours;
  final String? communeName;
  final String? districtName;
  final List<String>? typeNames;
  final List<String>? sousTypeNames;

  ActeModel({
    required this.id,
    required this.titre,
    this.description,
    required this.typeIds,
    required this.sousTypeIds,
    required this.communeId,
    required this.districtId,
    required this.auteurId,
    required this.statut,
    this.fichier,
    this.fichierUrl,
    this.fichierName,
    this.dateCreation,
    this.dateModification,
    this.createdAt,
    this.updatedAt,
    this.horodatage,
    this.dateLimite,
    this.delaiJours,
    this.communeName,
    this.districtName,
    this.typeNames,
    this.sousTypeNames,
  });

  factory ActeModel.fromJson(Map<String, dynamic> json) {
    return ActeModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? '',
      description: json['description'],
      typeIds: json['type_ids'] != null ? List<String>.from(json['type_ids']) : [],
      sousTypeIds: json['sous_type_ids'] != null ? List<String>.from(json['sous_type_ids']) : [],
      communeId: json['commune_id']?.toString() ?? '',
      districtId: json['district_id']?.toString() ?? '',
      auteurId: json['auteur_id']?.toString() ?? '',
      statut: json['statut'] ?? 'en_cours',
      fichier: json['fichier'],
      fichierUrl: json['fichier_url'],
      fichierName: json['fichier_name'],
      dateCreation: json['date_creation'],
      dateModification: json['date_modification'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      horodatage: json['horodatage'],
      dateLimite: json['date_limite'],
      delaiJours: json['delai_jours'],
      communeName: json['commune_name'],
      districtName: json['district_name'],
      typeNames: json['type_names'] != null ? List<String>.from(json['type_names']) : null,
      sousTypeNames: json['sous_type_names'] != null ? List<String>.from(json['sous_type_names']) : null,
    );
  }
}

class ObservationLegaliteModel {
  final int id;
  final String acteId;
  final String observateurId;
  final String contenu;
  final String? gravite;
  final List<String>? fichiers;
  final String numeroSuivi;
  final String dateCreation;
  final String dateModification;
  final bool estActive;
  final String? observateurNom;
  final String? observateurEmail;
  final String? observateurPhoto;
  final String? acteTitre;

  ObservationLegaliteModel({
    required this.id,
    required this.acteId,
    required this.observateurId,
    required this.contenu,
    this.gravite,
    this.fichiers,
    required this.numeroSuivi,
    required this.dateCreation,
    required this.dateModification,
    required this.estActive,
    this.observateurNom,
    this.observateurEmail,
    this.observateurPhoto,
    this.acteTitre,
  });

  factory ObservationLegaliteModel.fromJson(Map<String, dynamic> json) {
    return ObservationLegaliteModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      acteId: json['acte_id']?.toString() ?? '',
      observateurId: json['observateur_id']?.toString() ?? '',
      contenu: json['contenu'] ?? '',
      gravite: json['gravite'],
      fichiers: json['fichiers'] != null ? List<String>.from(json['fichiers']) : null,
      numeroSuivi: json['numero_suivi'] ?? '',
      dateCreation: json['date_creation'] ?? '',
      dateModification: json['date_modification'] ?? '',
      estActive: json['est_active'] ?? true,
      observateurNom: json['observateur_nom'],
      observateurEmail: json['observateur_email'],
      observateurPhoto: json['observateur_photo'],
      acteTitre: json['acte_titre'],
    );
  }
}

class TypeActeModel {
  final String id;
  final String nom;
  final String? description;
  final String? dateCreation;
  final bool? estActif;

  TypeActeModel({
    required this.id,
    required this.nom,
    this.description,
    this.dateCreation,
    this.estActif,
  });

  factory TypeActeModel.fromJson(Map<String, dynamic> json) {
    return TypeActeModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      dateCreation: json['date_creation'],
      estActif: json['est_actif'],
    );
  }
}

class SousTypeActeModel {
  final String id;
  final String nom;
  final String? description;
  final String typeActeId;
  final int? delaiTraitementJours;
  final bool estActif;
  final String? dateCreation;

  SousTypeActeModel({
    required this.id,
    required this.nom,
    this.description,
    required this.typeActeId,
    this.delaiTraitementJours,
    required this.estActif,
    this.dateCreation,
  });

  factory SousTypeActeModel.fromJson(Map<String, dynamic> json) {
    return SousTypeActeModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      typeActeId: json['type_acte_id']?.toString() ?? '',
      delaiTraitementJours: json['delai_traitement_jours'],
      estActif: json['est_actif'] ?? true,
      dateCreation: json['date_creation'],
    );
  }
}

class PaginationResponse<T> {
  final List<T> data;
  final String message;
  final int statusCode;
  final PaginationInfo pagination;

  PaginationResponse({
    required this.data,
    required this.message,
    required this.statusCode,
    required this.pagination,
  });

  factory PaginationResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    var rawData = json['data'] ?? [];
    List<T> listData = [];
    if (rawData is List) {
      listData = rawData.map((item) => fromJsonT(item)).toList();
    }

    return PaginationResponse(
      data: listData,
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 200,
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginationInfo({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class CommuneLocation {
  final String name;
  final String formattedId;

  CommuneLocation({required this.name, required this.formattedId});

  factory CommuneLocation.fromJson(Map<String, dynamic> json) {
    return CommuneLocation(
      name: json['name'] ?? '',
      formattedId: json['formatted_id'] ?? '',
    );
  }
}

class DistrictLocation {
  final String id;
  final String name;
  final String formattedId;

  DistrictLocation({required this.id, required this.name, required this.formattedId});

  factory DistrictLocation.fromJson(Map<String, dynamic> json) {
    return DistrictLocation(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      formattedId: json['formatted_id'] ?? '',
    );
  }
}

class UserLocationDataModel {
  final CommuneLocation userCommune;
  final DistrictLocation district;
  final List<CommuneLocation> communesInDistrict;

  UserLocationDataModel({
    required this.userCommune,
    required this.district,
    required this.communesInDistrict,
  });
}

/// SERVICES CONTROL DE LEGALITE API Endpoints (liste_des_services.txt) :
/// ACTE:
/// - POST   https://gateway.tsirylab.com/servicecontroldelegalite/actes (Créer un nouvel acte)
/// - GET    https://gateway.tsirylab.com/servicecontroldelegalite/actes (Récupérer tous les actes avec filtres)
/// - PUT    https://gateway.tsirylab.com/servicecontroldelegalite/actes/{id} (Modifier un acte)
/// - GET    https://gateway.tsirylab.com/servicecontroldelegalite/actes/{id} (Récupérer un acte par ID)
/// - DELETE https://gateway.tsirylab.com/servicecontroldelegalite/actes/{id} (Supprimer un acte)
/// STATISTIQUES:
/// - GET    https://gateway.tsirylab.com/servicecontroldelegalite/stats/general (Statistiques générales du système)
/// - GET    https://gateway.tsirylab.com/servicecontroldelegalite/stats/actes (Statistiques des actes)
/// OBSERVATION:
/// - POST   https://gateway.tsirylab.com/servicecontroldelegalite/observations (Créer une nouvelle observation)
/// - GET    https://gateway.tsirylab.com/servicecontroldelegalite/observations (Récupérer toutes les observations)
/// NOTIFICATIONS:
/// - POST   https://gateway.tsirylab.com/servicecontroldelegalite/notifications/creer
/// TYPE-ACTES / SOUS-TYPE-ACTES:
/// - GET/POST https://gateway.tsirylab.com/servicecontroldelegalite/acte-types
/// - GET/POST https://gateway.tsirylab.com/servicecontroldelegalite/acte-sous-types
/// HISTORIQUES:
/// - POST   https://gateway.tsirylab.com/servicecontroldelegalite/historique/create
class ControlLegaliteService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicecontroledelegalite";
  static const String basePath = '';

  // --- ACTES ---

  static Future<ActeModel> createActe(http.MultipartRequest formData) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$basePath/actes'));
    request.fields.addAll(formData.fields);
    request.files.addAll(formData.files);
    request.headers.addAll(formData.headers);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final resData = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(resData['message'] ?? "Erreur lors de la création de l'acte");
    }
    return ActeModel.fromJson(resData);
  }

  static Future<PaginationResponse<ActeModel>> getAllActes({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes$queryStr'));
    final resData = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(resData['message'] ?? "Erreur lors de la récupération des actes");
    }
    return PaginationResponse.fromJson(resData, (json) => ActeModel.fromJson(json));
  }

  static Future<ActeModel> getActeById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/$id'));
    final resData = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(resData['message'] ?? "Erreur");
    }
    return ActeModel.fromJson(resData);
  }

  static Future<ActeModel> updateActe(String id, http.MultipartRequest formData) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl$basePath/actes/$id'));
    request.fields.addAll(formData.fields);
    request.files.addAll(formData.files);
    request.headers.addAll(formData.headers);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final resData = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(resData['message'] ?? "Erreur lors de la mise à jour");
    }
    return ActeModel.fromJson(resData);
  }

  static Future<void> deleteActe(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl$basePath/actes/$id'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur lors de la suppression");
    }
  }

  static Future<PaginationResponse<ActeModel>> getAllActesSimple({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/all$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ActeModel.fromJson(json));
  }

  static Future<PaginationResponse<ActeModel>> getActesByCommune(String communeId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/commune/$communeId$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ActeModel.fromJson(json));
  }

  static Future<PaginationResponse<ActeModel>> getActesByDistrict(String districtId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/district/$districtId$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ActeModel.fromJson(json));
  }

  static Future<PaginationResponse<ActeModel>> getActesByType(String typeId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/type/$typeId$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ActeModel.fromJson(json));
  }

  static Future<PaginationResponse<ActeModel>> getActesBySousType(String sousTypeId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/sous-type/$sousTypeId$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ActeModel.fromJson(json));
  }

  static Future<PaginationResponse<ActeModel>> getActesByAuteur(String auteurId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/auteur/$auteurId$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ActeModel.fromJson(json));
  }

  // --- STATISTIQUES ---

  static Future<dynamic> getActesStatsSummary() async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/actes/stats/summary'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getGeneralStats() async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/general'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getActesStats({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/actes$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getDistrictStats(String districtId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/actes/district/$districtId$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getCommuneStats(String communeId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/actes/commune/$communeId$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getObservationsStats({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/observations$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getTemporalStats(String periode, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/temporel/$periode$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getPerformanceStats({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/performance$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getDelaisStats({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/delais$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getTableauBord({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/stats/tableau-bord$queryStr'));
    return jsonDecode(response.body);
  }

  // --- OBSERVATIONS ---

  static Future<ObservationLegaliteModel> createObservation(http.MultipartRequest formData) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$basePath/observations'));
    request.fields.addAll(formData.fields);
    request.files.addAll(formData.files);
    request.headers.addAll(formData.headers);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final resData = jsonDecode(response.body);
    return ObservationLegaliteModel.fromJson(resData);
  }

  static Future<PaginationResponse<ObservationLegaliteModel>> getAllObservations({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/observations$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ObservationLegaliteModel.fromJson(json));
  }

  static Future<ObservationLegaliteModel> getObservationById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/observations/$id'));
    return ObservationLegaliteModel.fromJson(jsonDecode(response.body));
  }

  static Future<ObservationLegaliteModel> updateObservation(int id, http.MultipartRequest formData) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl$basePath/observations/$id'));
    request.fields.addAll(formData.fields);
    request.files.addAll(formData.files);
    request.headers.addAll(formData.headers);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return ObservationLegaliteModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteObservation(int id) async {
    await http.delete(Uri.parse('$baseUrl$basePath/observations/$id'));
  }

  static Future<ObservationLegaliteModel> getObservationByNumeroSuivi(String numeroSuivi) async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/observations/numero-suivi/$numeroSuivi'));
    return ObservationLegaliteModel.fromJson(jsonDecode(response.body));
  }

  static Future<PaginationResponse<ObservationLegaliteModel>> getObservationsByActe(String acteId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/observations/acte/$acteId$queryStr'));
    final resData = jsonDecode(response.body);
    return PaginationResponse.fromJson(resData, (json) => ObservationLegaliteModel.fromJson(json));
  }

  // --- TYPES D'ACTES ---

  static Future<TypeActeModel> createTypeActe(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$basePath/acte-types'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return TypeActeModel.fromJson(jsonDecode(response.body));
  }

  static Future<List<TypeActeModel>> getAllTypesActes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$basePath/acte-types'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resData = jsonDecode(response.body);
        List list = resData is List ? resData : (resData['data'] ?? []);
        return list.map((item) => TypeActeModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<TypeActeModel> getTypeActeById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/acte-types/$id'));
    return TypeActeModel.fromJson(jsonDecode(response.body));
  }

  static Future<TypeActeModel> updateTypeActe(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$basePath/acte-types/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return TypeActeModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteTypeActe(String id) async {
    await http.delete(Uri.parse('$baseUrl$basePath/acte-types/$id'));
  }

  static Future<void> deleteTypeActeForce(String id) async {
    await http.delete(Uri.parse('$baseUrl$basePath/acte-types/$id/force'));
  }

  // --- SOUS-TYPES D'ACTES ---

  static Future<SousTypeActeModel> createSousTypeActe(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$basePath/acte-sous-types'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return SousTypeActeModel.fromJson(jsonDecode(response.body));
  }

  static Future<List<SousTypeActeModel>> getAllSousTypesActes() async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/acte-sous-types'));
    final resData = jsonDecode(response.body);
    List list = resData is List ? resData : (resData['data'] ?? []);
    return list.map((item) => SousTypeActeModel.fromJson(item)).toList();
  }

  static Future<List<SousTypeActeModel>> getSousTypesActesByType(String typeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$basePath/acte-sous-types/by-type/$typeId'));
      debugPrint('Réponse API sous-types: ${response.body}');
      final resData = jsonDecode(response.body);
      List list = resData is List ? resData : (resData['data'] ?? []);
      return list.map((item) => SousTypeActeModel.fromJson(item)).toList();
    } catch (error) {
      debugPrint('Erreur API getSousTypesActesByType: $error');
      rethrow;
    }
  }

  static Future<SousTypeActeModel> getSousTypeActeById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/acte-sous-types/$id'));
    return SousTypeActeModel.fromJson(jsonDecode(response.body));
  }

  static Future<SousTypeActeModel> updateSousTypeActe(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$basePath/acte-sous-types/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return SousTypeActeModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteSousTypeActe(String id) async {
    await http.delete(Uri.parse('$baseUrl$basePath/acte-sous-types/$id'));
  }

  static Future<List<SousTypeActeModel>> getActiveSousTypesActes() async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/acte-sous-types/active/list'));
    final resData = jsonDecode(response.body);
    List list = resData is List ? resData : (resData['data'] ?? []);
    return list.map((item) => SousTypeActeModel.fromJson(item)).toList();
  }

  static Future<SousTypeActeModel> activateSousTypeActe(String id) async {
    final response = await http.put(Uri.parse('$baseUrl$basePath/acte-sous-types/$id/activate'));
    return SousTypeActeModel.fromJson(jsonDecode(response.body));
  }

  static Future<SousTypeActeModel> deactivateSousTypeActe(String id) async {
    final response = await http.put(Uri.parse('$baseUrl$basePath/acte-sous-types/$id/deactivate'));
    return SousTypeActeModel.fromJson(jsonDecode(response.body));
  }

  // --- HISTORIQUE ---

  static Future<dynamic> getRecentActivities({Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/historique/recent$queryStr'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getHistoriqueStats() async {
    final response = await http.get(Uri.parse('$baseUrl$basePath/historique/stats'));
    return jsonDecode(response.body);
  }

  static Future<dynamic> getHistoriqueByActe(String acteId, {Map<String, dynamic>? params}) async {
    String queryStr = _buildQueryString(params);
    final response = await http.get(Uri.parse('$baseUrl$basePath/historique/acte/$acteId$queryStr'));
    return jsonDecode(response.body);
  }

  // --- LOCALISATION ---

  static Future<UserLocationDataModel> getUserLocationData(String municipalityId) async {
    try {
      final communeResponse = await http.get(Uri.parse('$baseUrl/serviceterritoire-v2/communes/noForm/$municipalityId'));
      final userCommuneData = jsonDecode(communeResponse.body);

      final communeLocation = CommuneLocation(
        name: userCommuneData['name'] ?? '',
        formattedId: userCommuneData['formatted_id'] ?? '',
      );
      debugPrint("commune de l'utilisateur connecté : ${communeLocation.name}");

      final districtData = userCommuneData['district'] ?? {};
      final districtLocation = DistrictLocation(
        id: '',
        name: districtData['name'] ?? '',
        formattedId: districtData['formatted_id'] ?? '',
      );
      debugPrint("District de l'utilisateur connecté : ${districtLocation.name}");

      final communesResponse = await http.get(Uri.parse('$baseUrl/serviceterritoire-v2/communes/district/${districtLocation.formattedId}'));
      List communesList = jsonDecode(communesResponse.body);
      List<CommuneLocation> communesInDistrict = communesList.map((commune) => CommuneLocation(
        name: commune['name'] ?? '',
        formattedId: commune['formatted_id'] ?? '',
      )).toList();

      debugPrint("Communes dans le district de l'utilisateur connecté : ${communesInDistrict.length}");

      return UserLocationDataModel(
        userCommune: communeLocation,
        district: districtLocation,
        communesInDistrict: communesInDistrict,
      );
    } catch (error) {
      debugPrint("Erreur lors de la récupération des données de localisation : $error");
      rethrow;
    }
  }

  // --- UTILITAIRE ---

  static String _buildQueryString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    List<String> queryParams = [];
    params.forEach((key, value) {
      if (value != null) {
        queryParams.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}');
      }
    });
    return queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
  }
}