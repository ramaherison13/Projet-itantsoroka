import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'document_card_widget.dart'; // Assurez-vous d'importer votre widget de carte de document

class Section2Widget extends StatefulWidget {
  final String baseUrl;

  const Section2Widget({
    super.key,
    required this.baseUrl,
  });

  @override
  State<Section2Widget> createState() => _Section2WidgetState();
}

class _Section2WidgetState extends State<Section2Widget> {
  bool _loading = true;
  String? _error;
  List<dynamic> _documents = [];
  List<dynamic> _themes = [];
  bool _showAllThemes = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<dynamic> allDocuments = [];
      int currentPage = 1;
      bool hasMorePages = true;

      // Récupération paginée des documents
      while (hasMorePages) {
        final docsResponse = await http.get(
          Uri.parse('${widget.baseUrl}/servicebiblio/resources/filter?page=$currentPage&limit=100'),
        );

        if (docsResponse.statusCode != 200) {
          throw Exception("Erreur lors de la récupération des documents: ${docsResponse.statusCode}");
        }

        final docsData = json.decode(docsResponse.body);
        final List<dynamic>? dataList = docsData['data'];

        if (dataList != null && dataList.isNotEmpty) {
          final publicDocuments = dataList.where((doc) {
            final status = doc['status']?.toString().toLowerCase() ?? '';
            return status == 'public';
          }).map((doc) {
            return {
              ...doc,
              'theme': doc['theme'] ?? [],
              'filename': doc['filename'] ?? doc['fileId'] ?? 'document-${doc['id']}',
            };
          }).toList();

          allDocuments.addAll(publicDocuments);
          currentPage++;

          if (dataList.length < 100) {
            hasMorePages = false;
          }
        } else {
          hasMorePages = false;
        }
      }

      // Récupération des thèmes
      final themesResponse = await http.get(Uri.parse('${widget.baseUrl}/servicetheme/themes'));
      if (themesResponse.statusCode != 200) {
        throw Exception("Erreur lors de la récupération des thèmes: ${themesResponse.statusCode}");
      }
      final List<dynamic> themesData = json.decode(themesResponse.body);

      setState(() {
        _documents = allDocuments;
        _themes = themesData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navigateToTheme(String themeName) {
    // Gérez la navigation vers la page de consultation globale avec le filtre de thème
    debugPrint("Navigation vers le thème: $themeName");
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Grouper les documents par thème
    final Map<String, Map<String, dynamic>> documentsByTheme = {};
    for (var theme in _themes) {
      final themeName = theme['name']?.toString() ?? '';
      if (themeName.isEmpty) continue;

      final docsForTheme = _documents.where((doc) {
        final themesList = doc['theme'] as List<dynamic>? ?? [];
        return themesList.any((t) => t.toString().toLowerCase().contains(themeName.toLowerCase()));
      }).toList();

      // Tri par date décroissante et limitation à 3 documents
      docsForTheme.sort((a, b) {
        final dateA = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      final limitedDocs = docsForTheme.take(3).toList();

      if (limitedDocs.isNotEmpty) {
        documentsByTheme[themeName] = {
          'theme': theme,
          'documents': limitedDocs,
        };
      }
    }

    final themeEntries = documentsByTheme.entries.toList();
    final themesToDisplay = _showAllThemes ? themeEntries : themeEntries.take(3).toList();
    final totalThemes = themeEntries.length;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            isDarkMode ? Colors.grey.shade800 : Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Titre de la section
          const Text(
            "Documents",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Chargement / Erreur / Contenu
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF098E00))))
          else if (_error != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Erreur lors du chargement des documents", style: TextStyle(color: Colors.red.shade700)),
              ),
            )
          else if (themesToDisplay.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text("Aucun document disponible pour le moment", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              ),
            )
          else
            Column(
              children: [
                ...themesToDisplay.map((entry) {
                  final List<dynamic> themeDocs = entry.value['documents'];
                  final themeName = entry.key;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre du thème avec icône
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF098E00),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.folder, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                themeName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Grille des documents du thème
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: themeDocs.length,
                          itemBuilder: (context, docIndex) {
                            final doc = themeDocs[docIndex];
                            return DocumentCardWidget(
                              id: doc['id'] ?? 0,
                              filename: doc['fileId'] ?? '',
                              title: doc['title'] ?? '',
                              date: doc['date'] ?? '',
                              description: doc['description'] ?? '',
                              type: doc['type'] ?? '',
                              category: doc['category'] ?? '',
                              baseUrl: widget.baseUrl,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Bouton "Voir plus" pour ce thème
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _navigateToTheme(themeName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D5D5D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Voir plus"),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Bouton pour afficher tous les thèmes si > 3
                if (totalThemes > 3) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C21C), Color(0xFF098E00)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showAllThemes = !_showAllThemes),
                        icon: Icon(_showAllThemes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
                        label: Text(_showAllThemes ? "Voir moins de thèmes" : "Voir tous les thèmes ($totalThemes)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}