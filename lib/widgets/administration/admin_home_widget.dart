import 'package:flutter/material.dart';

// Modèle de données pour un élément de navigation
class NavItemModel {
  final String path;
  final String icon;
  final String nameKey;
  final String category;
  final List<String> requiredRoles;

  NavItemModel({
    required this.path,
    required this.icon,
    required this.nameKey,
    required this.category,
    this.requiredRoles = const [],
  });

  factory NavItemModel.fromJson(Map<String, dynamic> json) {
    var rolesFromJson = json['requiredRoles'] as List? ?? [];
    List<String> rolesList = rolesFromJson.map((r) => r.toString()).toList();

    return NavItemModel(
      path: json['path'] ?? '',
      icon: json['icon'] ?? 'FileText',
      nameKey: json['nameKey'] ?? '',
      category: json['category'] ?? 'Autres',
      requiredRoles: rolesList,
    );
  }
}

// Fonction pour obtenir les rôles de l'utilisateur sous forme de slugs
List<String> getUserRoleSlugs(Map<String, dynamic>? user) {
  if (user == null) return [];
  final directRoles = user['roles'] is List ? user['roles'] : [];
  final appUserRoles = user['appUserRoles'] is List ? user['appUserRoles'] : [];

  List<String> slugs = [];
  for (var r in directRoles) {
    if (r != null && r['role_slug'] != null) {
      slugs.add(r['role_slug'].toString());
    }
  }
  for (var ur in appUserRoles) {
    if (ur != null && ur['role'] != null && ur['role']['role_slug'] != null) {
      slugs.add(ur['role']['role_slug'].toString());
    }
  }
  return slugs.toSet().toList();
}

// Mapper les noms d'icônes Lucide vers les icônes Material de Flutter
IconData getIconByName(String name) {
  switch (name) {
    case 'KeyRound':
      return Icons.key_rounded;
    case 'FileText':
    default:
      return Icons.description;
  }
}

class AdminHomeWidget extends StatefulWidget {
  final Map<String, dynamic>? currentUser; // Simule l'utilisateur connecté (State / Redux)
  final Future<List<dynamic>> Function(String appId)? fetchNavigation; // Service de navigation

  const AdminHomeWidget({
    super.key,
    required this.currentUser,
    required this.fetchNavigation,
  });

  @override
  AdminHomeWidgetState createState() => AdminHomeWidgetState();
}

class AdminHomeWidgetState extends State<AdminHomeWidget> {
  bool _loading = true;
  List<NavItemModel> _menuItems = [];
  static const String appId = "YOUR_APP_ID"; // Remplacer par APP_ID constant

  @override
  void initState() {
    super.initState();
    _loadNavs();
  }

  Future<void> _loadNavs() async {
    if (widget.currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await widget.fetchNavigation!(appId);
      final userRoleSlugs = getUserRoleSlugs(widget.currentUser);

      List<NavItemModel> filteredNavs = [];
      for (var item in data) {
        final nav = NavItemModel.fromJson(item);
        bool hasAccess = nav.requiredRoles.any((role) => userRoleSlugs.contains(role));
        if (hasAccess) {
          filteredNavs.add(nav);
        }
      }

      setState(() {
        _menuItems = filteredNavs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Map<String, List<NavItemModel>> _groupByCategory(List<NavItemModel> items) {
    Map<String, List<NavItemModel>> groups = {};
    for (var item in items) {
      String category = item.category.isNotEmpty ? item.category : "Autres";
      if (!groups.containsKey(category)) {
        groups[category] = [];
      }
      groups[category]!.add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF00C21C);

    if (_loading) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        body: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text("Chargement...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Ajouter manuellement les liens admin si Super-Admin
    final userSlugs = getUserRoleSlugs(widget.currentUser);
    final List<NavItemModel> adminLinks = userSlugs.contains("Super-Admin")
        ? [
            NavItemModel(
              path: "/admin/passwords",
              icon: "KeyRound",
              nameKey: "Gestion des mots de passe",
              category: "admin",
            ),
          ]
        : [];

    final allItems = [..._menuItems, ...adminLinks];
    final grouped = _groupByCategory(allItems);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            String category = entry.key;
            List<NavItemModel> items = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la catégorie
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                // Grille des cartes
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () {
                        // Navigation vers item.path (ex: Navigator.pushNamed(context, item.path))
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                getIconByName(item.icon),
                                color: accentColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.nameKey,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.path,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}