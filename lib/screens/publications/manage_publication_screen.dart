import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Modèles de données ---

class EventModel {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String visibility;
  final String themeId;
  final String communeId;
  final String eventTypeId;
  final String? image;
  final String type = "event";

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.visibility,
    required this.themeId,
    required this.communeId,
    required this.eventTypeId,
    this.image,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      visibility: json['visibility'] ?? '',
      themeId: json['themeId']?.toString() ?? '',
      communeId: json['communeId']?.toString() ?? '',
      eventTypeId: json['eventTypeId']?.toString() ?? '',
      image: json['image'],
    );
  }
}

class ProjectModel {
  final String id;
  final dynamic name;
  final dynamic description;
  final dynamic status;
  final String startDate;
  final String endDate;
  final String deadline;
  final double budget;
  final List<String> partenaire;
  final List<String> files;
  final String themeName;
  final String communeId;
  final String type = "project";

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.deadline,
    required this.budget,
    required this.partenaire,
    required this.files,
    required this.themeName,
    required this.communeId,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name'],
      description: json['description'],
      status: json['status'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      deadline: json['deadline'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      partenaire: List<String>.from(json['partenaire'] ?? []),
      files: List<String>.from(json['files'] ?? []),
      themeName: json['theme_name'] ?? '',
      communeId: json['commune_id']?.toString() ?? '',
    );
  }
}

// --- Services simulés (À adapter selon vos services réels) ---

Future<dynamic> getEvents(int page, int limit) async {
  await Future.delayed(const Duration(seconds: 1));
  return [];
}

Future<dynamic> getProjects(int page, int limit) async {
  await Future.delayed(const Duration(seconds: 1));
  return [];
}

// --- Écran Principal : ManagePublicationScreen ---

class ManagePublicationScreen extends StatefulWidget {
  const ManagePublicationScreen({super.key});

  @override
  State<ManagePublicationScreen> createState() => _ManagePublicationScreenState();
}

class _ManagePublicationScreenState extends State<ManagePublicationScreen> {
  List<dynamic> publications = [];
  List<dynamic> filteredPublications = [];

  String searchTerm = "";
  String selectedCommune = "";
  String selectedPartenaire = "";
  String selectedStatus = "";
  String selectedType = "";
  bool showFilters = false;
  bool loading = true;
  String? error;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _partenaireController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _partenaireController.dispose();
    super.dispose();
  }

  void _navigateToPublishPage() {
    context.go('/itantsorika/publier');
  }

  Future<void> _fetchData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        getEvents(1, 100),
        getProjects(1, 100),
      ]);

      final eventsResponse = results[0];
      final projectsResponse = results[1];

      final eventsRaw = eventsResponse is List
          ? eventsResponse
          : eventsResponse?['events'] ??
            eventsResponse?['data']?['data'] ??
            eventsResponse?['data'] ??
            [];

      final projectsRaw = projectsResponse is List
          ? projectsResponse
          : projectsResponse?['projects'] ??
            projectsResponse?['data']?['data'] ??
            projectsResponse?['data'] ??
            [];

      final List<EventModel> eventsWithType = (eventsRaw as List)
          .map((e) => EventModel.fromJson(e))
          .toList();

      final List<ProjectModel> projectsWithType = (projectsRaw as List)
          .map((p) => ProjectModel.fromJson(p))
          .toList();

      final List<dynamic> allPublications = [...eventsWithType, ...projectsWithType];

      setState(() {
        publications = allPublications;
        filteredPublications = allPublications;
        loading = false;
      });
    } catch (err) {
      debugPrint("Erreur lors du chargement des données: $err");
      setState(() {
        error = err.toString();
        publications = [];
        filteredPublications = [];
        loading = false;
      });
    }
  }

  void _filterPublications() {
    List<dynamic> filtered = publications;

    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((pub) {
        final rawTitle = pub is EventModel ? pub.title : pub.name;
        final title = rawTitle is String ? rawTitle : "";
        final description = pub.description is String ? pub.description : "";

        return title.toLowerCase().contains(searchTerm.toLowerCase()) ||
            description.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    }

    if (selectedCommune.isNotEmpty) {
      filtered = filtered.where((pub) {
        final communeId = pub is EventModel ? pub.communeId : pub.communeId;
        return communeId == selectedCommune;
      }).toList();
    }

    if (selectedPartenaire.isNotEmpty && selectedType == "project") {
      filtered = filtered.where((pub) {
        if (pub is ProjectModel) {
          return pub.partenaire.any((p) =>
              p.toLowerCase().contains(selectedPartenaire.toLowerCase()));
        }
        return true;
      }).toList();
    }

    if (selectedStatus.isNotEmpty && selectedType == "project") {
      filtered = filtered.where((pub) {
        if (pub is ProjectModel) {
          return pub.status == selectedStatus;
        }
        return true;
      }).toList();
    }

    if (selectedType.isNotEmpty) {
      filtered = filtered.where((pub) {
        return pub.type == selectedType;
      }).toList();
    }

    setState(() {
      filteredPublications = filtered;
    });
  }

  Future<void> _handleDelete(String id, String type) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Êtes-vous sûr de vouloir supprimer cette publication ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (type == "event") {
          // await deleteEvent(id);
        } else {
          // await deleteProject(id);
        }

        setState(() {
          publications.removeWhere((pub) => pub.id == id);
          _filterPublications();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Publication supprimée avec succès !")),
          );
        }
      } catch (error) {
        debugPrint("Erreur lors de la suppression: $error");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de la suppression de la publication")),
          );
        }
      }
    }
  }

  void _handleEdit(String id, String type) {
    context.go('/itantsorika/editPublication/$type/$id');
  }


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text("Chargement des publications", style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Gestion des Publications",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              const Text("Gérez vos événements et projets en un seul endroit", style: TextStyle(color: Colors.grey)),
                              const Text("•", style: TextStyle(color: Colors.grey)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${publications.length}",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text("publications au total"),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _navigateToPublishPage,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text("Nouvelle Publication"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Statistiques (Placeholder du composant StatisticsCards)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text("Total: "),
                        Text("${publications.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filtres Redesignés
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    searchTerm = value;
                                  });
                                  _filterPublications();
                                },
                                decoration: InputDecoration(
                                  hintText: "Rechercher par titre ou description...",
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  showFilters = !showFilters;
                                });
                              },
                              icon: const Icon(Icons.filter_list, size: 20),
                              label: const Text("Filtres"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                side: BorderSide(
                                  color: showFilters ? Colors.green : Colors.grey.shade300,
                                ),
                                backgroundColor: showFilters ? Colors.green.shade50 : Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),

                        // Filtres Avancés
                        if (showFilters) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text("Type", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: selectedType.isEmpty ? null : selectedType,
                                              hint: const Text("Tous les types"),
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.grey.shade50,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              items: const [
                                                DropdownMenuItem(value: "", child: Text("Tous les types")),
                                                DropdownMenuItem(value: "event", child: Text("Événements")),
                                                DropdownMenuItem(value: "project", child: Text("Projets")),
                                              ],
                                              onChanged: (val) {
                                                setState(() {
                                                  selectedType = val ?? "";
                                                });
                                                _filterPublications();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text("Commune", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: selectedCommune.isEmpty ? null : selectedCommune,
                                              hint: const Text("Toutes les communes"),
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.grey.shade50,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              items: const [
                                                DropdownMenuItem(value: "", child: Text("Toutes les communes")),
                                                DropdownMenuItem(value: "antananarivo", child: Text("Antananarivo")),
                                                DropdownMenuItem(value: "fianarantsoa", child: Text("Fianarantsoa")),
                                                DropdownMenuItem(value: "toamasina", child: Text("Toamasina")),
                                                DropdownMenuItem(value: "mahajanga", child: Text("Mahajanga")),
                                              ],
                                              onChanged: (val) {
                                                setState(() {
                                                  selectedCommune = val ?? "";
                                                });
                                                _filterPublications();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (selectedType == "project") ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Statut", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue: selectedStatus.isEmpty ? null : selectedStatus,
                                                hint: const Text("Tous les statuts"),
                                                isExpanded: true,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: Colors.grey.shade50,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                items: const [
                                                  DropdownMenuItem(value: "", child: Text("Tous les statuts")),
                                                  DropdownMenuItem(value: "planifie", child: Text("Planifié")),
                                                  DropdownMenuItem(value: "en_cours", child: Text("En cours")),
                                                  DropdownMenuItem(value: "termine", child: Text("Terminé")),
                                                  DropdownMenuItem(value: "annule", child: Text("Annulé")),
                                                ],
                                                onChanged: (val) {
                                                  setState(() {
                                                    selectedStatus = val ?? "";
                                                  });
                                                  _filterPublications();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Partenaire", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                              const SizedBox(height: 6),
                                              TextField(
                                                controller: _partenaireController,
                                                onChanged: (val) {
                                                  setState(() {
                                                    selectedPartenaire = val;
                                                  });
                                                  _filterPublications();
                                                },
                                                decoration: InputDecoration(
                                                  hintText: "Rechercher un partenaire...",
                                                  filled: true,
                                                  fillColor: Colors.grey.shade50,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Liste des Publications (PublicationsList équivalent)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPublications.length,
                    itemBuilder: (context, index) {
                      final pub = filteredPublications[index];
                      final isEvent = pub is EventModel;
                      final title = isEvent ? pub.title : pub.name.toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(pub.description?.toString() ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _handleEdit(pub.id, pub.type),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _handleDelete(pub.id, pub.type),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}