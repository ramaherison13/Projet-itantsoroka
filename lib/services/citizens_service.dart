import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:itantsoroka/constants/api_constants.dart';

class CitizenModel {
  final String idCitizen;
  final String citizenName;
  final String citizenLastname;
  final String? citizenDateOfBirth;
  final String? citizenLocationOfBirth;
  final String citizenPhoto;
  final int citizenNationalCardNumber;
  final String citizenAdress;
  final String? citizenCity;
  final String? citizenWork;
  final int fokotanyId;
  final String? citizenFather;
  final String? citizenMother;
  final String citizenNationalCardLocation;
  final String citizenNationalCardDate;

  CitizenModel({
    required this.idCitizen,
    required this.citizenName,
    required this.citizenLastname,
    this.citizenDateOfBirth,
    this.citizenLocationOfBirth,
    required this.citizenPhoto,
    required this.citizenNationalCardNumber,
    required this.citizenAdress,
    this.citizenCity,
    this.citizenWork,
    required this.fokotanyId,
    this.citizenFather,
    this.citizenMother,
    required this.citizenNationalCardLocation,
    required this.citizenNationalCardDate,
  });

  factory CitizenModel.fromJson(Map<String, dynamic> json) {
    return CitizenModel(
      idCitizen: json['id_citizen'] ?? '',
      citizenName: json['citizen_name'] ?? '',
      citizenLastname: json['citizen_lastname'] ?? '',
      citizenDateOfBirth: json['citizen_date_of_birth'],
      citizenLocationOfBirth: json['citizen_location_of_birth'],
      citizenPhoto: json['citizen_photo'] ?? '',
      citizenNationalCardNumber: json['citizen_national_card_number'] ?? 0,
      citizenAdress: json['citizen_adress'] ?? '',
      citizenCity: json['citizen_city'],
      citizenWork: json['citizen_work'],
      fokotanyId: json['fokotany_id'] ?? 0,
      citizenFather: json['citizen_father'],
      citizenMother: json['citizen_mother'],
      citizenNationalCardLocation: json['citizen_national_card_location'] ?? '',
      citizenNationalCardDate: json['citizen_national_card_date'] ?? '',
    );
  }
}

/// Service Citoyens API Endpoints (liste_des_services.txt) :
/// SERVICES CITOYEN:
/// - GET    https://gateway.tsirylab.com/servicecitoyen/citizens/{id} (Récupérer un citoyen par ID de carte)
/// - GET    https://gateway.tsirylab.com/servicecitoyen/citizens/getCitizenById/{citizenId} (Par ID citoyen)
/// - GET    https://gateway.tsirylab.com/servicecitoyen/citizens (Lister tous les citoyens)
/// - POST   https://gateway.tsirylab.com/servicecitoyen/citizens (Créer un citoyen)
/// - PUT    https://gateway.tsirylab.com/servicecitoyen/citizens/{id} (Mettre à jour un citoyen)
/// - DELETE https://gateway.tsirylab.com/servicecitoyen/citizens/{id} (Supprimer un citoyen)
class CitizensService {
  static const String baseUrl = "https://gateway.tsirylab.com/servicecitoyen";
  static const String authBaseUrl = "https://gateway.tsirylab.com/serviceauth";

  static final Set<String> _invalidCitizenIds = {
    "",
    "00000000-0000-0000-0000-000000000000",
    "550e8400-e29b-41d4-a716-446655440000",
  };

  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<CitizenModel?> getCitizenByIdCard(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/citizens/$id'), headers: defaultHeaders).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return CitizenModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (error) {
      debugPrint("Erreur lors de la récupération du citoyen : $error");
      return null;
    }
  }

  /// Récupère les informations d'un citoyen à partir de son ID citoyen
  static Future<CitizenModel?> getCitizenById(String citizenId) async {
    final cleanId = citizenId.trim();
    if (cleanId.isEmpty || _invalidCitizenIds.contains(cleanId)) {
      return null;
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/citizens/getCitizenById/$cleanId'), headers: defaultHeaders).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return CitizenModel.fromJson(jsonDecode(res.body));
      } else if (res.statusCode >= 400) {
        _invalidCitizenIds.add(cleanId);
      }
      return null;
    } catch (error) {
      _invalidCitizenIds.add(cleanId);
      debugPrint("Erreur lors de la récupération du citoyen $citizenId: $error");
      return null;
    }
  }

  /// Récupère les informations d'un citoyen à partir de l'ID utilisateur
  static Future<CitizenModel?> getCitizenByUserId(String userId) async {
    try {
      final userRes = await http.get(Uri.parse('$authBaseUrl/users/$userId'), headers: defaultHeaders).timeout(const Duration(seconds: 5));
      if (userRes.statusCode < 200 || userRes.statusCode >= 300) return null;

      final userData = jsonDecode(userRes.body);

      // Si le citoyen est directement embarqué dans userData
      if (userData is Map) {
        final embeddedCitizen = userData['citizen'] ?? userData['citoyen'];
        if (embeddedCitizen is Map) {
          return CitizenModel.fromJson(Map<String, dynamic>.from(embeddedCitizen));
        }
      }

      if (userData == null || userData['id_citizen'] == null) {
        debugPrint("Utilisateur $userId n'a pas d'id_citizen associé");
        return null;
      }

      final idCitizen = userData['id_citizen']?.toString();
      if (idCitizen == null || _invalidCitizenIds.contains(idCitizen)) {
        return null;
      }

      return await getCitizenById(idCitizen);
    } catch (error) {
      debugPrint("Erreur lors de la récupération du citoyen pour l'utilisateur $userId: $error");
      return null;
    }
  }

  /// Récupère les informations d'un citoyen à partir d'un ID qui peut être soit un citizen_id, soit un user_id
  static Future<CitizenModel?> getCitizenByIdOrUserId(String id) async {
    try {
      final cleanId = id.trim();
      if (_invalidCitizenIds.contains(cleanId)) {
        return await getCitizenByUserId(cleanId);
      }

      final citizenResult = await getCitizenById(cleanId);
      if (citizenResult != null) {
        debugPrint("✅ Citoyen trouvé directement avec citizen_id $cleanId");
        return citizenResult;
      }

      debugPrint("🔄 Tentative de récupération avec user_id $cleanId");
      final userResult = await getCitizenByUserId(cleanId);
      if (userResult != null) {
        debugPrint("✅ Citoyen trouvé via user_id $cleanId");
        return userResult;
      }

      debugPrint("⚠️ Aucun citoyen trouvé pour l'ID $cleanId (ni comme citizen_id, ni comme user_id)");
      return null;
    } catch (error) {
      debugPrint("❌ Erreur lors de la récupération du citoyen pour l'ID $id: $error");
      return null;
    }
  }

  /// Récupère l'URL de l'avatar d'un utilisateur (version originale)
  static String? getCitizenAvatar(String? citizenPhoto) {
    if (citizenPhoto == null || citizenPhoto.isEmpty) return null;
    return citizenPhoto;
  }

  /// Récupère l'URL du preview de l'avatar (même logique que le code React original)
  /// React : API_URL + "/serviceupload/file/preview/hello" + citizen_photo.split("hello")[1].replace("/", "%2F")
  static String? getCitizenAvatarPreview(String? citizenPhoto) {
    if (citizenPhoto == null || citizenPhoto.trim().isEmpty) return null;
    final photo = citizenPhoto.trim();
    if (photo == 'null' || photo == 'undefined' || photo == 'none') return null;

    const uploadBase = '${ApiConstants.gatewayBaseUrl}/serviceupload/file/preview';

    if (photo.contains('/file/preview/')) return photo;

    if (photo.contains('/file/')) {
      final fileIndex = photo.indexOf('/file/');
      final baseUrl = photo.substring(0, fileIndex);
      final filePath = photo.substring(fileIndex + '/file/'.length);
      final encodedPath = filePath.replaceAll('/', '%2F');
      return '$baseUrl/file/preview/$encodedPath';
    }

    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    final clean = photo.startsWith('/') ? photo.substring(1) : photo;
    final encodedRelative = clean.replaceAll('/', '%2F');
    return '$uploadBase/$encodedRelative';
  }

  /// Récupère l'URL de l'avatar avec une image par défaut en fallback
  static String getCitizenAvatarWithFallback(
    String? citizenPhoto, {
    String defaultAvatar = '/public/logo.png',
    bool usePreview = true,
  }) {
    if (citizenPhoto == null || citizenPhoto.isEmpty) return defaultAvatar;
    return usePreview
        ? (getCitizenAvatarPreview(citizenPhoto) ?? defaultAvatar)
        : (getCitizenAvatar(citizenPhoto) ?? defaultAvatar);
  }
}