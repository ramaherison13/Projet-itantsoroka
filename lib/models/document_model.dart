// lib/models/document_model.dart

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
    return DocumentModel(
      id: json['id'],
      filename: json['filename'] ?? json['fileId'] ?? "document-${json['id']}",
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      theme: json['theme'] is List 
          ? List<String>.from(json['theme']) 
          : (json['theme'] != null ? [json['theme'].toString()] : []),
      type: json['type'],
      status: json['status'] ?? 'Public',
      fileFormat: json['fileFormat'],
      communeId: json['communeId']?.toString(),
      fileId: json['fileId'],
      langage: json['langage'],
    );
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String? label;

  CategoryModel({required this.id, required this.name, this.label});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      label: json['label'],
    );
  }
}