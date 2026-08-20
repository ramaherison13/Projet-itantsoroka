class Role {
  final int roleId;
  final String roleName;
  final String roleSlug;

  const Role({
    required this.roleId,
    required this.roleName,
    required this.roleSlug,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['role_id'] is int ? json['role_id'] : int.tryParse(json['role_id']?.toString() ?? '0') ?? 0,
      roleName: json['role_name']?.toString() ?? '',
      roleSlug: json['role_slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'role_id': roleId,
        'role_name': roleName,
        'role_slug': roleSlug,
      };
}

class NavigationItem {
  final int? navigationId;
  final String navigationLabelKey;
  final String navigationPath;
  final String navigationIcon;
  final List<dynamic> requiredRoles;
  final String? navigationComponent;
  final bool? navigationShow;
  final String? navigationCategory;
  final String? navigationCategoryLabelKey;
  final int? navigationOrder;
  final int appId;

  const NavigationItem({
    this.navigationId,
    required this.navigationLabelKey,
    required this.navigationPath,
    required this.navigationIcon,
    required this.requiredRoles,
    this.navigationComponent,
    this.navigationShow,
    this.navigationCategory,
    this.navigationCategoryLabelKey,
    this.navigationOrder,
    required this.appId,
  });

  factory NavigationItem.fromJson(Map<String, dynamic> json) {
    return NavigationItem(
      navigationId: json['navigation_id'] != null ? int.tryParse(json['navigation_id'].toString()) : null,
      navigationLabelKey: json['navigation_label_key']?.toString() ?? '',
      navigationPath: json['navigation_path']?.toString() ?? '',
      navigationIcon: json['navigation_icon']?.toString() ?? '',
      requiredRoles: json['requiredRoles'] != null ? List<dynamic>.from(json['requiredRoles']) : [],
      navigationComponent: json['navigation_component']?.toString(),
      navigationShow: json['navigation_show'] as bool?,
      navigationCategory: json['navigation_category']?.toString(),
      navigationCategoryLabelKey: json['navigation_category_label_key']?.toString(),
      navigationOrder: json['navigation_order'] != null ? int.tryParse(json['navigation_order'].toString()) : null,
      appId: json['app_id'] is int ? json['app_id'] : int.tryParse(json['app_id']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (navigationId != null) 'navigation_id': navigationId,
        'navigation_label_key': navigationLabelKey,
        'navigation_path': navigationPath,
        'navigation_icon': navigationIcon,
        'requiredRoles': requiredRoles,
        if (navigationComponent != null) 'navigation_component': navigationComponent,
        if (navigationShow != null) 'navigation_show': navigationShow,
        if (navigationCategory != null) 'navigation_category': navigationCategory,
        if (navigationCategoryLabelKey != null) 'navigation_category_label_key': navigationCategoryLabelKey,
        if (navigationOrder != null) 'navigation_order': navigationOrder,
        'app_id': appId,
      };
}

typedef ValidationErrors = Map<String, String>;

class SelectOption {
  final String value;
  final String label;

  const SelectOption({
    required this.value,
    required this.label,
  });

  factory SelectOption.fromJson(Map<String, dynamic> json) {
    return SelectOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
      };
}