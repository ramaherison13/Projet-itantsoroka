import 'package:flutter/material.dart';
import '../../services/project_service.dart';
import '../../services/territory_service.dart';

class OfficeProjetScreen extends StatefulWidget {
  const OfficeProjetScreen({super.key});

  @override
  State<OfficeProjetScreen> createState() => _OfficeProjetScreenState();
}

class _OfficeProjetScreenState extends State<OfficeProjetScreen> {
  bool isLoading = true;
  String errorMessage = "";

  // Pagination states
  int currentPage = 1;
  int totalPages = 1;
  int totalProjects = 0;
  final int itemsPerPage = 12;

  // Modals & Filters states
  Map<String, dynamic>? selectedProject;
  bool isModalOpen = false;
  String search = "";
  String communeFilter = "all";
  String partenaireFilter = "all";

  // Data lists
  List<Map<String, dynamic>> allProjects = [];
  List<Map<String, dynamic>> communes = [];
  List<Map<String, dynamic>> partenairesEntites = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProjects(1),
      _loadCommunes(),
    ]);
  }

  Future<void> _loadProjects(int page) async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final res = await ProjectService.getProjects(
        page: page,
        limit: itemsPerPage,
      );

      final List<dynamic> rawProjects = res['projects'] ?? [];
      final Map<String, dynamic>? pagination = res['pagination'];

      final List<Map<String, dynamic>> parsedProjects = rawProjects.map((p) {
        if (p is Map<String, dynamic>) return p;
        if (p is Map) return Map<String, dynamic>.from(p);
        return <String, dynamic>{};
      }).toList();

      int total = parsedProjects.length;
      int tPages = 1;

      if (pagination != null) {
        total = pagination['total'] ?? pagination['totalItems'] ?? parsedProjects.length;
        tPages = pagination['totalPages'] ?? pagination['pages'] ?? ((total / itemsPerPage).ceil());
      } else {
        tPages = (total / itemsPerPage).ceil();
      }
      if (tPages < 1) tPages = 1;

      // Extrait dynamiquement les partenaires des projets chargés
      final Set<String> partnerSet = {};
      for (var p in parsedProjects) {
        final partners = p['partenaire'] ?? p['partenaires'] ?? p['partner'];
        if (partners is List) {
          for (var item in partners) {
            final cleaned = _cleanPartnerName(item.toString());
            if (cleaned.isNotEmpty) partnerSet.add(cleaned);
          }
        }
      }

      setState(() {
        allProjects = parsedProjects;
        totalProjects = total;
        totalPages = tPages;
        currentPage = page;
        if (partnerSet.isNotEmpty) {
          partenairesEntites = partnerSet.map((name) => {"nom": name}).toList();
        }
      });
    } catch (e) {
      debugPrint("Erreur lors de la récupération des projets: $e");
      setState(() {
        errorMessage = "Impossible de charger les projets de la base de données.";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCommunes() async {
    try {
      final list = await TerritoryService.getCommunesBasic();
      if (list != null && mounted) {
        setState(() {
          communes = list.map((c) {
            if (c is Map<String, dynamic>) return c;
            if (c is Map) return Map<String, dynamic>.from(c);
            return <String, dynamic>{};
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement communes: $e");
    }
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  String _cleanPartnerName(String partnerStr) {
    final trimmed = partnerStr.trim();
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length > 1 && int.tryParse(parts[0]) != null) {
        return parts.sublist(1).join(':').trim();
      }
    }
    return trimmed;
  }

  String _getLocalizedText(dynamic text) {
    if (text == null) return "";
    String result = "";
    if (text is String) {
      result = text;
    } else if (text is Map) {
      result = (text['fr'] ?? text['mg'] ?? text.values.first).toString();
    } else {
      result = text.toString();
    }
    return _stripHtml(result);
  }

  String _getCommuneDisplayName(Map<String, dynamic> project) {
    if (project['commune_name'] != null && project['commune_name'].toString().trim().isNotEmpty) {
      return project['commune_name'].toString().trim();
    }
    final comId = project['commune_id'] ?? project['commune'] ?? project['location'];
    if (comId != null && comId.toString().isNotEmpty) {
      final match = communes.firstWhere(
        (c) => c['formatted_id']?.toString() == comId.toString() ||
            c['id']?.toString() == comId.toString() ||
            c['name']?.toString().toLowerCase() == comId.toString().toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty && match['name'] != null) {
        return match['name'].toString();
      }
      return comId.toString();
    }
    return "";
  }

  String _formatBudget(dynamic budget) {
    if (budget == null) return "0";
    final numVal = int.tryParse(budget.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    if (numVal != null) {
      return numVal.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
    }
    return budget.toString();
  }

  Color _getStatusBorder(String statusText) {
    switch (statusText.toLowerCase()) {
      case 'actif':
        return const Color(0xFF098E00).withValues(alpha: 0.3);
      case 'en cours':
        return const Color(0xFFE98C21).withValues(alpha: 0.3);
      case 'terminé':
        return const Color(0xFF5D5D5D).withValues(alpha: 0.3);
      default:
        return const Color(0xFF098E00).withValues(alpha: 0.2);
    }
  }

  void _openModal(Map<String, dynamic> project) {
    setState(() {
      selectedProject = project;
      isModalOpen = true;
    });
  }

  void _closeModal() {
    setState(() {
      isModalOpen = false;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          selectedProject = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filtre local des projets chargés
    List<Map<String, dynamic>> filteredProjects = allProjects.where((p) {
      final searchTerm = search.trim().toLowerCase();
      final nameStr = _getLocalizedText(p['name']).toLowerCase();
      final descStr = _getLocalizedText(p['description']).toLowerCase();
      final respStr = (p['responsable'] ?? '').toString().toLowerCase();

      bool matchesSearch = searchTerm.isEmpty ||
          nameStr.contains(searchTerm) ||
          descStr.contains(searchTerm) ||
          respStr.contains(searchTerm);

      final comId = p['commune_id']?.toString() ?? p['commune']?.toString() ?? p['commune_name']?.toString() ?? '';
      bool matchesCommune = communeFilter == "all" || comId == communeFilter || _getCommuneDisplayName(p) == communeFilter;

      final partners = p['partenaire'] ?? p['partenaires'] ?? p['partner'];
      bool matchesPartenaire = partenaireFilter == "all";
      if (partenaireFilter != "all" && partners is List) {
        matchesPartenaire = partners.any((item) => _cleanPartnerName(item.toString()) == partenaireFilter);
      }

      return matchesSearch && matchesCommune && matchesPartenaire;
    }).toList();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête ──────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF098E00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.work_rounded, color: Color(0xFF098E00), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Projets",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Page $currentPage sur $totalPages • $totalProjects projets au total",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Onglets Tous les projets / Mes projets ──────────────────
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF098E00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text("Tous les projets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$totalProjects",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text("Mes projets affiliés", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "0",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Barre de Filtres ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 768) {
                        return Row(
                          children: [
                            Expanded(child: _buildSearchField(isDarkMode)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildCommuneDropdown(isDarkMode)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPartenaireDropdown(isDarkMode)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildSearchField(isDarkMode),
                            const SizedBox(height: 14),
                            _buildCommuneDropdown(isDarkMode),
                            const SizedBox(height: 14),
                            _buildPartenaireDropdown(isDarkMode),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // ── Liste des Projets ─────────────────────────────────────────
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: CircularProgressIndicator(color: Color(0xFF098E00)),
                    ),
                  )
                else if (errorMessage.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _loadProjects(1),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Réessayer"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF098E00),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filteredProjects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF098E00).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.folder_open_rounded, size: 40, color: Color(0xFF098E00)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Aucun projet trouvé",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Essayez de modifier vos critères de recherche",
                            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      mainAxisExtent: 270,
                    ),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      final statusInfo = project['status'];
                      final statusText = _getLocalizedText(statusInfo);
                      final communeName = _getCommuneDisplayName(project);
                      final budgetStr = _formatBudget(project['budget']);

                      return InkWell(
                        onTap: () => _openModal(project),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusBorder(statusText),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getLocalizedText(project['name']),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (project['description'] != null)
                                Text(
                                  _getLocalizedText(project['description']),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              const Spacer(),
                              if (communeName.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF098E00)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        communeName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money_rounded, size: 16, color: Color(0xFF098E00)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$budgetStr Ar",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF098E00),
                                    ),
                                  ),
                                ],
                              ),
                              _buildPartnersSection(project, isDarkMode),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // ── Barre de Pagination ────────────────────────────────────
                  _buildPaginationControls(isDarkMode),
                ],
              ],
            ),
          ),

          // ── Modal Détails Projet ─────────────────────────────────────────
          if (isModalOpen && selectedProject != null)
            Positioned.fill(
              child: Material(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 700,
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF098E00), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Modal Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF098E00), Color(0xFF056E00)],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getLocalizedText(selectedProject!['name']),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white),
                                onPressed: _closeModal,
                              ),
                            ],
                          ),
                        ),
                        // Modal Body
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedProject!['description'] != null) ...[
                                  const Text(
                                    "Description",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF098E00).withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF098E00).withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      _getLocalizedText(selectedProject!['description']),
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey.shade200 : const Color(0xFF334155),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    _buildDetailCard(
                                      "Localisation",
                                      _getCommuneDisplayName(selectedProject!),
                                      Icons.location_on_rounded,
                                      isDarkMode,
                                    ),
                                    if (selectedProject!['responsable'] != null)
                                      _buildDetailCard(
                                        "Responsable",
                                        selectedProject!['responsable'].toString(),
                                        Icons.person_rounded,
                                        isDarkMode,
                                      ),
                                    _buildDetailCard(
                                      "Budget",
                                      "${_formatBudget(selectedProject!['budget'])} Ar",
                                      Icons.attach_money_rounded,
                                      isDarkMode,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Modal Footer
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF098E00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _closeModal,
                            child: const Text("Fermer", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartnersSection(Map<String, dynamic> project, bool isDarkMode) {
    final partners = project['partenaire'] ?? project['partenaires'] ?? project['partner'];
    if (partners == null || partners is! List || partners.isEmpty) return const SizedBox.shrink();

    final cleanList = partners.map((p) => _cleanPartnerName(p.toString())).where((s) => s.isNotEmpty).toList();
    if (cleanList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.people_outline_rounded, size: 13, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              "Partenaires",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: cleanList.take(2).map((partner) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF098E00).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF098E00).withValues(alpha: 0.25)),
              ),
              child: Text(
                partner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF098E00),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(bool isDarkMode) {
    if (totalPages <= 1 && totalProjects <= itemsPerPage) return const SizedBox.shrink();

    final int startItem = totalProjects == 0 ? 0 : ((currentPage - 1) * itemsPerPage) + 1;
    final int endItem = (currentPage * itemsPerPage) > totalProjects ? totalProjects : (currentPage * itemsPerPage);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton Précédent
            ElevatedButton.icon(
              onPressed: currentPage > 1 ? () => _loadProjects(currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text("Précédent"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                foregroundColor: currentPage > 1 ? const Color(0xFF098E00) : Colors.grey,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Numéros de pages
            ...List.generate(totalPages, (index) {
              final pageNum = index + 1;
              final bool isSelected = pageNum == currentPage;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: ElevatedButton(
                  onPressed: () => _loadProjects(pageNum),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? const Color(0xFF098E00) : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
                    foregroundColor: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                    minimumSize: const Size(38, 38),
                    padding: EdgeInsets.zero,
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? const Color(0xFF098E00) : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                    ),
                  ),
                  child: Text("$pageNum", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }),
            const SizedBox(width: 8),
            // Bouton Suivant
            ElevatedButton(
              onPressed: currentPage < totalPages ? () => _loadProjects(currentPage + 1) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                foregroundColor: currentPage < totalPages ? const Color(0xFF098E00) : Colors.grey,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: const Row(
                children: [
                  Text("Suivant"),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Affichage de $startItem à $endItem sur $totalProjects projets",
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return TextField(
      onChanged: (val) => setState(() => search = val),
      decoration: InputDecoration(
        hintText: "Rechercher un projet...",
        hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF098E00)),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF098E00), width: 2),
        ),
      ),
    );
  }

  Widget _buildCommuneDropdown(bool isDarkMode) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: communeFilter,
      dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF098E00), width: 2),
        ),
      ),
      items: [
        const DropdownMenuItem(value: "all", child: Text("Toutes les communes", overflow: TextOverflow.ellipsis)),
        ...communes.map((c) {
          final id = c['formatted_id']?.toString() ?? c['id']?.toString() ?? c['name']?.toString() ?? '';
          final name = c['name']?.toString() ?? id;
          return DropdownMenuItem(
            value: id,
            child: Text(name, overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: (val) {
        if (val != null) setState(() => communeFilter = val);
      },
    );
  }

  Widget _buildPartenaireDropdown(bool isDarkMode) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: partenaireFilter,
      dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF098E00), width: 2),
        ),
      ),
      items: [
        const DropdownMenuItem(value: "all", child: Text("Tous les partenaires", overflow: TextOverflow.ellipsis)),
        ...partenairesEntites.map((p) => DropdownMenuItem(
              value: p['nom'].toString(),
              child: Text(p['nom'].toString(), overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (val) {
        if (val != null) setState(() => partenaireFilter = val);
      },
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, bool isDarkMode) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF098E00)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}