// lib/models/entite_model.dart

class Entite {
  final int id;
  final String nom;
  final String description;
  final String categorie;
  final String status;
  final String? logo;
  final String? logoFilename;

  Entite({
    required this.id,
    required this.nom,
    required this.description,
    required this.categorie,
    required this.status,
    this.logo,
    this.logoFilename,
  });

  factory Entite.fromJson(Map<String, dynamic> json) {
    return Entite(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? '',
      status: json['status'] ?? '',
      logo: json['logo'],
      logoFilename: json['logoFilename'],
    );
  }
}