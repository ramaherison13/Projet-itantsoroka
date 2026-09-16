import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ThemeScreen extends StatefulWidget {
  final String themeId;

  const ThemeScreen({super.key, required this.themeId});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  final String apiUrl = "https://gateway.tsirylab.com";

  Map<String, dynamic>? theme;
  List<dynamic> documents = [];
  List<dynamic> publications = [];
  
  bool loadingDocuments = false;
  bool loadingPublications = false;

  // Pagination pour les documents
  int documentsPage = 1;
  int documentsTotal = 0;
  final int documentsLimit = 12;

  // Pagination pour les publications
  int publicationsPage = 1;
  int publicationsTotal = 0;
  final int publicationsLimit = 12;

  @override
  void initState() {
    super.initState();
    fetchTheme();
    fetchDocuments();
    fetchPublications();
  }

  // 1. Charger les informations du thème
  Future<void> fetchTheme() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/servicetheme/themes'));
      if (response.statusCode == 200) {
        List<dynamic> themes = json.decode(response.body);
        final foundTheme = themes.cast<Map<String, dynamic>?>().firstWhere(
          (t) => t != null && t['theme_id'].toString() == widget.themeId,
          orElse: () => null,
        );
        if (foundTheme != null) {
          setState(() {
            theme = foundTheme;
          });
        }
      }
    } catch (error) {
      debugPrint("Erreur lors du chargement du thème: $error");
    }
  }

  // 2. Charger les documents
  Future<void> fetchDocuments() async {
    setState(() {
      loadingDocuments = true;
    });

    try {
      // Essayer d'abord avec theme_id
      var response = await http.get(
        Uri.parse('$apiUrl/servicebiblio/resources/filter?theme=${widget.themeId}&page=$documentsPage&limit=$documentsLimit'),
      );

      var data = json.decode(response.body);
      List<dynamic> docs = data['data'] ?? [];

      // Si aucun résultat et qu'on a le nom du thème, essayer avec le nom
      if (docs.isEmpty && theme != null && theme!['name'] != null) {
        response = await http.get(
          Uri.parse('$apiUrl/servicebiblio/resources/filter?theme=${theme!['name']}&page=$documentsPage&limit=$documentsLimit'),
        );
        data = json.decode(response.body);
        docs = data['data'] ?? [];
      }

      setState(() {
        documents = docs;
        documentsTotal = data['total'] ?? 0;
      });
    } catch (error) {
      debugPrint("Erreur lors du chargement des documents: $error");
      setState(() {
        documents = [];
      });
    } finally {
      setState(() {
        loadingDocuments = false;
      });
    }
  }

  // 3. Charger les publications (Événements et Actualités combinés)
  Future<void> fetchPublications() async {
    setState(() {
      loadingPublications = true;
    });

    try {
      // Appeler les deux endpoints en parallèle
      final responses = await Future.wait([
        http.get(Uri.parse('$apiUrl/servicepublication/events?theme=${widget.themeId}&page=$publicationsPage&limit=$publicationsLimit')),
        http.get(Uri.parse('$apiUrl/servicepublication/events/dispositif-district?theme=${widget.themeId}&page=$publicationsPage&limit=$publicationsLimit')),
      ]);

      List<dynamic> combinedData = [];
      for (var res in responses) {
        if (res.statusCode == 200) {
          var data = json.decode(res.body);
          if (data['data'] != null) {
            combinedData.addAll(data['data']);
          }
        }
      }

      // Éliminer les doublons basés sur l'ID
      final Map<String, dynamic> uniqueMap = {};
      for (var pub in combinedData) {
        if (pub['id'] != null) {
          uniqueMap[pub['id'].toString()] = pub;
        }
      }

      setState(() {
        publications = uniqueMap.values.toList();
        publicationsTotal = publications.length;
      });
    } catch (error) {
      debugPrint("Erreur lors du chargement des publications: $error");
      setState(() {
        publications = [];
      });
    } finally {
      setState(() {
        loadingPublications = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Séparer événements et actualités
    final evenements = publications.where((pub) => pub['endDate'] != null).toList();
    final actualites = publications.where((pub) => pub['endDate'] == null).toList();

    int totalDocumentsPages = (documentsTotal / documentsLimit).ceil();
    int totalPublicationsPages = (publicationsTotal / publicationsLimit).ceil();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF098E00), Color(0xFF0A7000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text("Retour"),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      theme?['name'] ?? "Chargement...",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Découvrez tous les documents et publications liés à cette thématique",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatCard(Icons.insert_drive_file, "$documentsTotal", "Documents"),
                        _buildStatCard(Icons.newspaper, "${evenements.length}", "Événements"),
                        _buildStatCard(Icons.article, "${actualites.length}", "Actualités"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Corps de la page
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Événements
                  if (evenements.isNotEmpty) ...[
                    _buildSectionHeader("Événements", "Événements programmés avec dates de début et fin", Icons.event),
                    const SizedBox(height: 12),
                    loadingPublications
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF098E00)))
                        : _buildPublicationsGrid(evenements),
                    const SizedBox(height: 32),
                  ],

                  // Section Actualités
                  if (actualites.isNotEmpty) ...[
                    _buildSectionHeader("Actualités", "Nouvelles et informations ponctuelles", Icons.newspaper),
                    const SizedBox(height: 12),
                    loadingPublications
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF098E00)))
                        : _buildPublicationsGrid(actualites),
                    const SizedBox(height: 32),
                  ],

                  // Message si aucune publication
                  if (!loadingPublications && publications.isEmpty) ...[
                    _buildSectionHeader("Publications & Actualités", "", Icons.newspaper),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.newspaper_rounded, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text(
                                'Aucune publication disponible pour cette thématique',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Pagination Publications
                  if (publications.isNotEmpty && totalPublicationsPages > 1) ...[
                    _buildPagination(
                      currentPage: publicationsPage,
                      totalPages: totalPublicationsPages,
                      onPrevious: () => setState(() { publicationsPage--; fetchPublications(); }),
                      onNext: () => setState(() { publicationsPage++; fetchPublications(); }),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Section Documents & Ressources
                  _buildSectionHeader("Documents & Ressources", "Bibliothèque de documents relatifs au thème", Icons.book),
                  const SizedBox(height: 12),
                  loadingDocuments
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF098E00)))
                      : documents.isNotEmpty
                          ? Column(
                              children: [
                                ListView.builder(
                                   shrinkWrap: true,
                                   physics: const NeverScrollableScrollPhysics(),
                                   itemCount: documents.length,
                                   itemBuilder: (context, index) {
                                     final doc = documents[index];
                                     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                     return Container(
                                       margin: const EdgeInsets.only(bottom: 10),
                                       decoration: BoxDecoration(
                                         color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                         borderRadius: BorderRadius.circular(14),
                                         border: Border.all(
                                           color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                         ),
                                         boxShadow: [
                                           BoxShadow(
                                             color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.04),
                                             blurRadius: 10,
                                             offset: const Offset(0, 4),
                                           ),
                                         ],
                                       ),
                                       child: Material(
                                         color: Colors.transparent,
                                         borderRadius: BorderRadius.circular(14),
                                         child: InkWell(
                                           borderRadius: BorderRadius.circular(14),
                                           onTap: () {},
                                           child: Padding(
                                             padding: const EdgeInsets.all(14),
                                             child: Row(
                                               children: [
                                                 Container(
                                                   padding: const EdgeInsets.all(10),
                                                   decoration: BoxDecoration(
                                                     color: Colors.red.withValues(alpha: 0.1),
                                                     borderRadius: BorderRadius.circular(12),
                                                     border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                                                   ),
                                                   child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 22),
                                                 ),
                                                 const SizedBox(width: 14),
                                                 Expanded(
                                                   child: Column(
                                                     crossAxisAlignment: CrossAxisAlignment.start,
                                                     children: [
                                                       Text(
                                                         doc['title'] ?? '',
                                                         style: TextStyle(
                                                           fontWeight: FontWeight.bold,
                                                           fontSize: 14,
                                                           color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                                         ),
                                                       ),
                                                       if ((doc['description'] ?? '').isNotEmpty) ...[
                                                         const SizedBox(height: 4),
                                                         Text(
                                                           doc['description'],
                                                           maxLines: 2,
                                                           overflow: TextOverflow.ellipsis,
                                                           style: TextStyle(
                                                             fontSize: 12,
                                                             color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                           ),
                                                         ),
                                                       ],
                                                     ],
                                                   ),
                                                 ),
                                                 if ((doc['type'] ?? '').isNotEmpty)
                                                   Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                     decoration: BoxDecoration(
                                                       color: const Color(0xFF098E00).withValues(alpha: 0.1),
                                                       borderRadius: BorderRadius.circular(8),
                                                     ),
                                                     child: Text(
                                                       doc['type'],
                                                       style: const TextStyle(fontSize: 11, color: Color(0xFF098E00), fontWeight: FontWeight.w600),
                                                     ),
                                                   ),
                                               ],
                                             ),
                                           ),
                                         ),
                                       ),
                                     );
                                   },
                                 ),
                                const SizedBox(height: 16),
                                if (totalDocumentsPages > 1)
                                  _buildPagination(
                                    currentPage: documentsPage,
                                    totalPages: totalDocumentsPages,
                                    onPrevious: () => setState(() { documentsPage--; fetchDocuments(); }),
                                    onNext: () => setState(() { documentsPage++; fetchDocuments(); }),
                                  ),
                              ],
                            )
                          : Builder(
                              builder: (context) {
                                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Aucun document disponible pour cette thématique',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
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

  Widget _buildStatCard(IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF098E00),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicationsGrid(List<dynamic> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Mettre 2 ou plus si écran large
        mainAxisExtent: 140,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final pub = items[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                if (pub['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      pub['imageUrl'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 100, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pub['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        (pub['description'] ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      if (pub['startDate'] != null)
                        Text(
                          "Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(pub['startDate']))}",
                          style: const TextStyle(fontSize: 10, color: Colors.green),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination({required int currentPage, required int totalPages, required VoidCallback onPrevious, required VoidCallback onNext}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1 ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text("Page $currentPage sur $totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: currentPage < totalPages ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}