// lib/models/collecte_model.dart

class Observation {
  final int id;
  final String contenu;
  final int idTerritoireVisiter;

  Observation({required this.id, required this.contenu, required this.idTerritoireVisiter});

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: int.tryParse(json['id'].toString()) ?? 0,
      contenu: json['contenu'] ?? '',
      idTerritoireVisiter: int.tryParse(json['idTerritoireVisiter'].toString()) ?? 0,
    );
  }
}

class Doleance {
  final int idDoleance;
  final String description;
  final int idTerritoireVisiter;

  Doleance({required this.idDoleance, required this.description, required this.idTerritoireVisiter});

  factory Doleance.fromJson(Map<String, dynamic> json) {
    return Doleance(
      idDoleance: int.tryParse(json['id'].toString()) ?? 0,
      description: json['contenu'] ?? '', 
      idTerritoireVisiter: int.tryParse(json['idTerritoireVisiter'].toString()) ?? 0,
    );
  }
}

class ActionCollecte { 
  final int id;
  final String description;
  final int idTerritoireVisiter;

  ActionCollecte({required this.id, required this.description, required this.idTerritoireVisiter});

  factory ActionCollecte.fromJson(Map<String, dynamic> json) {
    return ActionCollecte(
      id: int.tryParse(json['id'].toString()) ?? 0,
      description: json['description'] ?? '',
      idTerritoireVisiter: int.tryParse(json['idTerritoireVisiter'].toString()) ?? 0,
    );
  }
}