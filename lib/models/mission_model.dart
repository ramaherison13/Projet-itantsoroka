class Participant {
  final String userId;
  final String userPseudo;
  final String userEmail;
  final String userPhone;
  final String idCitizen;
  final String municipalityId;
  final String? currentHashedRefreshToken;
  final List<AppUserRole>? appUserRoles;

  Participant({
    required this.userId,
    required this.userPseudo,
    required this.userEmail,
    required this.userPhone,
    required this.idCitizen,
    required this.municipalityId,
    this.currentHashedRefreshToken,
    this.appUserRoles,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['user_id'] ?? '',
      userPseudo: json['user_pseudo'] ?? '',
      userEmail: json['user_email'] ?? '',
      userPhone: json['user_phone'] ?? '',
      idCitizen: json['id_citizen'] ?? '',
      municipalityId: json['municipality_id'] ?? '',
      currentHashedRefreshToken: json['currentHashedRefreshToken'],
      appUserRoles: json['appUserRoles'] != null
          ? (json['appUserRoles'] as List)
              .map((r) => AppUserRole.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_pseudo': userPseudo,
      'user_email': userEmail,
      'user_phone': userPhone,
      'id_citizen': idCitizen,
      'municipality_id': municipalityId,
      'currentHashedRefreshToken': currentHashedRefreshToken,
      'appUserRoles': appUserRoles?.map((r) => r.toJson()).toList(),
    };
  }
}

class AppUserRole {
  final String roleId;
  final String roleName;

  AppUserRole({
    required this.roleId,
    required this.roleName,
  });

  factory AppUserRole.fromJson(Map<String, dynamic> json) {
    return AppUserRole(
      roleId: json['role_id'] ?? '',
      roleName: json['role_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': roleId,
      'role_name': roleName,
    };
  }
}

class Territoire {
  final String formattedId;
  final String name;

  Territoire({
    required this.formattedId,
    required this.name,
  });

  factory Territoire.fromJson(Map<String, dynamic> json) {
    return Territoire(
      formattedId: json['formatted_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formatted_id': formattedId,
      'name': name,
    };
  }
}

class MissionSummary {
  final int id;
  final String titre;
  final String dateDebutMission;
  final String? dateFinMission;
  final String? district;
  final String districtName;
  final List<Participant> accompagnant;
  final String status;
  final String? userId;

  MissionSummary({
    required this.id,
    required this.titre,
    required this.dateDebutMission,
    this.dateFinMission,
    this.district,
    required this.districtName,
    required this.accompagnant,
    required this.status,
    this.userId,
  });

  factory MissionSummary.fromJson(Map<String, dynamic> json) {
    return MissionSummary(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      dateDebutMission: json['date_debut_mission'] ?? '',
      dateFinMission: json['date_fin_mission'],
      district: json['district'],
      districtName: json['districtName'] ?? '',
      accompagnant: json['accompagnant'] != null
          ? (json['accompagnant'] as List)
              .map((p) => Participant.fromJson(p))
              .toList()
          : [],
      status: json['status'] ?? '',
      userId: json['userID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'date_debut_mission': dateDebutMission,
      'date_fin_mission': dateFinMission,
      'district': district,
      'districtName': districtName,
      'accompagnant': accompagnant.map((p) => p.toJson()).toList(),
      'status': status,
      'userID': userId,
    };
  }
}

class TerritoireVisite {
  final int id;
  final int idMission;
  final String codeTerritoire;
  final String name;
  final String status;
  final String dateVisite;
  final List<Participant> accompagnant;
  final MissionSummary? mission;

  TerritoireVisite({
    required this.id,
    required this.idMission,
    required this.codeTerritoire,
    required this.name,
    required this.status,
    required this.dateVisite,
    required this.accompagnant,
    this.mission,
  });

  factory TerritoireVisite.fromJson(Map<String, dynamic> json) {
    return TerritoireVisite(
      id: json['id'] ?? 0,
      idMission: json['idMission'] ?? 0,
      codeTerritoire: json['code_territoire'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      dateVisite: json['date_visite'] ?? '',
      accompagnant: json['accompagnant'] != null
          ? (json['accompagnant'] as List)
              .map((p) => Participant.fromJson(p))
              .toList()
          : [],
      mission: json['mission'] != null
          ? MissionSummary.fromJson(json['mission'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idMission': idMission,
      'code_territoire': codeTerritoire,
      'name': name,
      'status': status,
      'date_visite': dateVisite,
      'accompagnant': accompagnant.map((p) => p.toJson()).toList(),
      'mission': mission?.toJson(),
    };
  }
}

class Mission {
  final int id;
  final String titre;
  final String dateDebutMission;
  final String? dateFinMission;
  final String? district;
  final String? districtName;
  final List<Territoire> territoireVisiter;
  final List<Participant> accompagnant;
  final String status;
  final String? userId;
  final List<TerritoireVisite>? territoiresVisites;

  Mission({
    required this.id,
    required this.titre,
    required this.dateDebutMission,
    this.dateFinMission,
    this.district,
    this.districtName,
    required this.territoireVisiter,
    required this.accompagnant,
    required this.status,
    this.userId,
    this.territoiresVisites,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      dateDebutMission: json['date_debut_mission'] ?? '',
      dateFinMission: json['date_fin_mission'],
      district: json['district'],
      districtName: json['districtName'],
      territoireVisiter: json['territoire_visiter'] != null
          ? (json['territoire_visiter'] as List)
              .map((t) => Territoire.fromJson(t))
              .toList()
          : [],
      accompagnant: json['accompagnant'] != null
          ? (json['accompagnant'] as List)
              .map((p) => Participant.fromJson(p))
              .toList()
          : [],
      status: json['status'] ?? '',
      userId: json['userID'],
      territoiresVisites: json['territoiresVisites'] != null
          ? (json['territoiresVisites'] as List)
              .map((tv) => TerritoireVisite.fromJson(tv))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'date_debut_mission': dateDebutMission,
      'date_fin_mission': dateFinMission,
      'district': district,
      'districtName': districtName,
      'territoire_visiter': territoireVisiter.map((t) => t.toJson()).toList(),
      'accompagnant': accompagnant.map((p) => p.toJson()).toList(),
      'status': status,
      'userID': userId,
      'territoiresVisites': territoiresVisites?.map((tv) => tv.toJson()).toList(),
    };
  }
}