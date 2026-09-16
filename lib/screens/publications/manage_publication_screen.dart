import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';

// ── Modèles de données ───────────────────────────────────────────────────────

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
      id: json['id']?.toString() ?? json['event_id']?.toString() ?? '',
      title: json['title'] is String
          ? json['title']
          : (json['title']?['fr'] ?? json['title']?['mg'] ?? 'Sans titre'),
      description: json['description'] is String
          ? json['description']
          : (json['description']?['fr'] ?? json['description']?['mg'] ?? ''),
      startDate: json['startDate']?.toString() ?? json['start_date']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? json['end_date']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? 'public',
      themeId: json['themeId']?.toString() ?? json['theme_id']?.toString() ?? '',
      communeId: json['communeId']?.toString() ?? json['commune_id']?.toString() ?? '',
      eventTypeId: json['eventTypeId']?.toString() ?? json['event_type_id']?.toString() ?? '',
      image: json['image'] ?? json['imageUrl'],
    );
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String status;
  final String startDate;
  final String endDate;
  final String deadline;
  final double budget;
  final List<String> partenaire;
  final List<String> files;
  final String themeName;
  final String communeId;
  final String communeName;
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
    required this.communeName,
  });

  static String _extractString(dynamic val) {
    if (val == null) return "";
    if (val is String) return val;
    if (val is Map) {
      return val['fr']?.toString() ?? val['mg']?.toString() ?? val.values.firstOrNull?.toString() ?? "";
    }
    return val.toString();
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id']?.toString() ?? json['project_id']?.toString() ?? '',
      name: _extractString(json['name']),
      description: _extractString(json['description']),
      status: _extractString(json['status']),
      startDate: json['startDate']?.toString() ?? json['start_date']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? json['end_date']?.toString() ?? '',
      deadline: json['deadline']?.toString() ?? '',
      budget: double.tryParse(json['budget']?.toString() ?? '0') ?? 0.0,
      partenaire: json['partenaire'] is List
          ? List<String>.from(json['partenaire'])
          : [],
      files: json['files'] is List ? List<String>.from(json['files']) : [],
      themeName: json['theme_name']?.toString() ?? '',
      communeId: json['commune_id']?.toString() ?? '',
      communeName: json['commune_name']?.toString() ?? json['commune_id']?.toString() ?? '',
    );
  }
}

// ── Appels API Réels ──────────────────────────────────────────────────────────

Future<List<dynamic>> getEvents() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConstants.servicePublication}/events?limit=200'),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['data'] is List) {
        return data['data'];
      }
      if (data is List) return data;
    }
  } catch (e) {
    debugPrint("Erreur getEvents: $e");
  }
  return [];
}

Future<List<dynamic>> getProjects() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConstants.serviceProjet}/projects?limit=200'),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['data'] is List) {
        return data['data'];
      }
      if (data is List) return data;
    }
  } catch (e) {
    debugPrint("Erreur getProjects: $e");
  }
  return [];
}

Future<bool> deleteEvent(String id) async {
  try {
    final res = await http.delete(
      Uri.parse('${ApiConstants.servicePublication}/events/$id'),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (e) {
    return false;
  }
}

Future<bool> deleteProject(String id) async {
  try {
    final res = await http.delete(
      Uri.parse('${ApiConstants.serviceProjet}/projects/$id'),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (e) {
    return false;
  }
}

// ── Écran Principal : ManagePublicationScreen ────────────────────────────────

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
  String selectedStatus = "";
  String selectedType = "";
  bool showFilters = false;
  bool loading = true;
  String? error;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        getEvents(),
        getProjects(),
      ]);

      final eventsRaw = results[0];
      final projectsRaw = results[1];

      final List<EventModel> events = eventsRaw
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final List<ProjectModel> projects = projectsRaw
          .map((p) => ProjectModel.fromJson(p as Map<String, dynamic>))
          .toList();

      final List<dynamic> all = [...events, ...projects];

      setState(() {
        publications = all;
        filteredPublications = all;
        loading = false;
      });
    } catch (err) {
      debugPrint("Erreur chargement publications: $err");
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
      final q = searchTerm.toLowerCase();
      filtered = filtered.where((pub) {
        final title = (pub is EventModel ? pub.title : (pub as ProjectModel).name).toLowerCase();
        final desc = pub.description.toLowerCase();
        return title.contains(q) || desc.contains(q);
      }).toList();
    }

    if (selectedType.isNotEmpty) {
      filtered = filtered.where((pub) => pub.type == selectedType).toList();
    }

    if (selectedCommune.isNotEmpty) {
      filtered = filtered.where((pub) {
        final cId = pub is EventModel ? pub.communeId : (pub as ProjectModel).communeId;
        return cId == selectedCommune;
      }).toList();
    }

    if (selectedStatus.isNotEmpty) {
      filtered = filtered.where((pub) {
        if (pub is ProjectModel) {
          return pub.status.toLowerCase().contains(selectedStatus.toLowerCase());
        }
        return true;
      }).toList();
    }

    setState(() {
      filteredPublications = filtered;
    });
  }

  Future<void> _handleDelete(dynamic pub) async {
    final String pubId = pub.id;
    final String pubType = pub.type;
    final String title = pub is EventModel ? pub.title : (pub as ProjectModel).name;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation de suppression"),
        content: Text("Voulez-vous vraiment supprimer « $title » ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = false;
      if (pubType == "event") {
        success = await deleteEvent(pubId);
      } else {
        success = await deleteProject(pubId);
      }

      if (success) {
        setState(() {
          publications.removeWhere((p) => p.id == pubId);
          _filterPublications();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Publication supprimée avec succès !"), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de la suppression de la publication"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleEdit(dynamic pub) {
    context.go('/itantsorika/editPublication/${pub.type}/${pub.id}');
  }

  // Calcul du budget total formaté
  String _formatTotalBudget() {
    double total = 0.0;
    for (final pub in publications) {
      if (pub is ProjectModel) {
        total += pub.budget;
      }
    }
    if (total >= 1000000) {
      return "${(total / 1000000).toStringAsFixed(1)}M MGA";
    } else if (total >= 1000) {
      return "${(total / 1000).toStringAsFixed(1)}k MGA";
    }
    return "${total.toStringAsFixed(0)} MGA";
  }

  // Formatage propre des dates
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "-";
    try {
      final dt = DateTime.parse(dateStr);
      final months = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;
    final bool isTablet = screenWidth >= 700 && screenWidth < 1100;

    final eventCount = publications.whereType<EventModel>().length;
    final projectCount = publications.whereType<ProjectModel>().length;
    final inProgressProjectCount = publications.whereType<ProjectModel>().where((p) => p.status.toLowerCase().contains("en_cours") || p.status.toLowerCase().contains("planning") || p.status.toLowerCase().contains("in_progress")).length;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1C2541) : Colors.white,
                border: Border(bottom: BorderSide(color: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/itantsorika-services'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFF8FAFC),
                      foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      side: BorderSide(color: isDarkMode ? const Color(0xFF5BC0BE) : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Retour aux services I-Tantsoroka", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                    onPressed: loading ? null : _fetchData,
                    tooltip: "Actualiser",
                  ),
                ],
              ),
            ),

            // ── Zone de contenu principal scrollable ────────────────────────
            Expanded(
              child: loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF16A34A)),
                          SizedBox(height: 16),
                          Text("Chargement des publications...", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête Titre + Bouton Nouvelle Publication
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Gestion des Publications",
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : 28,
                                        fontWeight: FontWeight.w800,
                                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      children: [
                                        Text(
                                          "Gérez vos événements et projets en un seul endroit",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                        Text("•", style: TextStyle(color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                        Text(
                                          "${publications.length} publications au total",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/itantsorika/publier'),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: isMobile ? const SizedBox.shrink() : const Text("Nouvelle Publication"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── 4 Cartes Métriques (Top Statistics) ────────────
                          GridView.count(
                            crossAxisCount: isMobile ? 2 : (isTablet ? 2 : 4),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isMobile ? 1.6 : 2.2,
                            children: [
                              _buildMetricCard(
                                title: "Événements et actualité",
                                value: "$eventCount",
                                icon: Icons.calendar_month_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                isDarkMode: isDarkMode,
                              ),
                              _buildMetricCard(
                                title: "Projets",
                                value: "$projectCount",
                                icon: Icons.folder_copy_rounded,
                                iconColor: const Color(0xFF16A34A),
                                isDarkMode: isDarkMode,
                              ),
                              _buildMetricCard(
                                title: "Projet en cours",
                                value: "$inProgressProjectCount",
                                icon: Icons.bolt_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                isDarkMode: isDarkMode,
                              ),
                              _buildMetricCard(
                                title: "Budget total",
                                value: _formatTotalBudget(),
                                icon: Icons.account_balance_wallet_rounded,
                                iconColor: const Color(0xFF8B5CF6),
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Barre de recherche & Bouton Filtres ────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1C2541) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                        onChanged: (val) {
                                          searchTerm = val;
                                          _filterPublications();
                                        },
                                        decoration: InputDecoration(
                                          hintText: "Rechercher par titre ou description...",
                                          hintStyle: TextStyle(color: isDarkMode ? const Color(0xFF64748B) : Colors.grey),
                                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                                          filled: true,
                                          fillColor: isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => setState(() => showFilters = !showFilters),
                                      icon: const Icon(Icons.filter_list_rounded, size: 18),
                                      label: const Text("Filtres"),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        foregroundColor: showFilters ? const Color(0xFF16A34A) : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                                        side: BorderSide(color: showFilters ? const Color(0xFF16A34A) : (isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFCBD5E1))),
                                        backgroundColor: showFilters ? const Color(0xFF16A34A).withValues(alpha: 0.1) : Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),

                                // Panneau des filtres avancés
                                if (showFilters) ...[
                                  const SizedBox(height: 16),
                                  Divider(color: isDarkMode ? const Color(0xFF3A506B) : Colors.grey.shade200),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: selectedType.isEmpty ? null : selectedType,
                                          dropdownColor: isDarkMode ? const Color(0xFF1C2541) : Colors.white,
                                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 13),
                                          decoration: InputDecoration(
                                            labelText: "Type de publication",
                                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                                            filled: true,
                                            fillColor: isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: "", child: Text("Tous les types")),
                                            DropdownMenuItem(value: "event", child: Text("Événements")),
                                            DropdownMenuItem(value: "project", child: Text("Projets")),
                                          ],
                                          onChanged: (val) {
                                            setState(() => selectedType = val ?? "");
                                            _filterPublications();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Titre Liste des Publications ────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Publications (${filteredPublications.length})",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "$eventCount événements • $projectCount projets",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Grille des Publications (3 cols desktop, 2 tablet, 1 mobile)
                          filteredPublications.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(40),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF1C2541) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_rounded, size: 48, color: isDarkMode ? Colors.white30 : Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Aucune publication trouvée",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    mainAxisExtent: 170,
                                  ),
                                  itemCount: filteredPublications.length,
                                  itemBuilder: (context, index) {
                                    final pub = filteredPublications[index];
                                    return _buildPublicationCard(pub, isDarkMode);
                                  },
                                ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Carte Métrique (Top 4 Stat Cards) ───────────────────────────────────────

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Carte de Publication (Événement / Projet) ───────────────────────────────

  Widget _buildPublicationCard(dynamic pub, bool isDarkMode) {
    final bool isEvent = pub is EventModel;
    final String title = isEvent ? pub.title : (pub as ProjectModel).name;
    final String commune = isEvent
        ? (pub.communeId.isNotEmpty ? pub.communeId : "Commune non spécifiée")
        : (pub.communeName.isNotEmpty ? pub.communeName : pub.communeId);
    final String dates = isEvent
        ? "${_formatDate(pub.startDate)} - ${_formatDate(pub.endDate)}"
        : "${_formatDate(pub.startDate)} - ${_formatDate(pub.deadline)}";

    final Color badgeBg = isEvent ? const Color(0xFF3B82F6) : const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne supérieure : Badge (ÉVÉNEMENT / PROJET) + Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEvent ? Icons.calendar_today_rounded : Icons.folder_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEvent ? "ÉVÉNEMENT" : "PROJET",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _handleEdit(pub),
                    icon: Icon(Icons.edit_outlined, size: 16, color: isDarkMode ? Colors.white60 : Colors.grey.shade600),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: "Modifier",
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _handleDelete(pub),
                    icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: "Supprimer",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Titre de la publication
          Text(
            title.isNotEmpty ? title : "Sans titre",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),

          // Informations secondaires (Commune & Dates)
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  commune,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dates,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}