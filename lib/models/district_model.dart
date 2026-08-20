class TerritoireItem {
  final int id;
  final String name;

  TerritoireItem({
    required this.id,
    required this.name,
  });

  factory TerritoireItem.fromJson(Map<String, dynamic> json) {
    return TerritoireItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Districts {
  final int districtId;
  final String name;
  final List<TerritoireItem> region;
  final List<TerritoireItem> communes;
  final List<TerritoireItem> arrondissement;

  Districts({
    required this.districtId,
    required this.name,
    required this.region,
    required this.communes,
    required this.arrondissement,
  });

  factory Districts.fromJson(Map<String, dynamic> json) {
    return Districts(
      districtId: json['district_id'] ?? 0,
      name: json['name'] ?? '',
      region: json['region'] != null
          ? (json['region'] as List)
              .map((r) => TerritoireItem.fromJson(r))
              .toList()
          : [],
      communes: json['communes'] != null
          ? (json['communes'] as List)
              .map((c) => TerritoireItem.fromJson(c))
              .toList()
          : [],
      arrondissement: json['arrondissement'] != null
          ? (json['arrondissement'] as List)
              .map((a) => TerritoireItem.fromJson(a))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'district_id': districtId,
      'name': name,
      'region': region.map((r) => r.toJson()).toList(),
      'communes': communes.map((c) => c.toJson()).toList(),
      'arrondissement': arrondissement.map((a) => a.toJson()).toList(),
    };
  }
}