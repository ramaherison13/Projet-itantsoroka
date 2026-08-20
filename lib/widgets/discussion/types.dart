class UserModel {
  final String? userId;
  final String? userPseudo;
  final String? userEmail;
  final String? userPhone;
  final String? idCitizen;
  final String? status;
  final String? lastSeen;

  UserModel({
    this.userId,
    this.userPseudo,
    this.userEmail,
    this.userPhone,
    this.idCitizen,
    this.status,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id']?.toString(),
      userPseudo: json['user_pseudo']?.toString(),
      userEmail: json['user_email']?.toString(),
      userPhone: json['user_phone']?.toString(),
      idCitizen: json['id_citizen']?.toString(),
      status: json['status']?.toString(),
      lastSeen: json['lastSeen']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_pseudo': userPseudo,
      'user_email': userEmail,
      'user_phone': userPhone,
      'id_citizen': idCitizen,
      'status': status,
      'lastSeen': lastSeen,
    };
  }
}

class CitoyenModel {
  final String? idCitizen;
  final String? citizenName;
  final String? citizenLastname;
  final String? citizenPhoto;
  final String? citizenNationalCardNumber;
  final String? citizenAdress;
  final String? createdAt;

  CitoyenModel({
    this.idCitizen,
    this.citizenName,
    this.citizenLastname,
    this.citizenPhoto,
    this.citizenNationalCardNumber,
    this.citizenAdress,
    this.createdAt,
  });

  factory CitoyenModel.fromJson(Map<String, dynamic> json) {
    return CitoyenModel(
      idCitizen: json['id_citizen']?.toString(),
      citizenName: json['citizen_name']?.toString(),
      citizenLastname: json['citizen_lastname']?.toString(),
      citizenPhoto: json['citizen_photo']?.toString(),
      citizenNationalCardNumber: json['citizen_national_card_number']?.toString(),
      citizenAdress: json['citizen_adress']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_citizen': idCitizen,
      'citizen_name': citizenName,
      'citizen_lastname': citizenLastname,
      'citizen_photo': citizenPhoto,
      'citizen_national_card_number': citizenNationalCardNumber,
      'citizen_adress': citizenAdress,
      'created_at': createdAt,
    };
  }
}

class User {
  final dynamic userPseudo;
  final String? userId;
  final UserModel? user;
  final CitoyenModel? citoyen;

  User({
    this.userPseudo,
    this.userId,
    this.user,
    this.citoyen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userPseudo: json['user_pseudo'],
      userId: json['user_id']?.toString(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      citoyen: json['citoyen'] != null ? CitoyenModel.fromJson(json['citoyen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_pseudo': userPseudo,
      'user_id': userId,
      'user': user?.toJson(),
      'citoyen': citoyen?.toJson(),
    };
  }
}