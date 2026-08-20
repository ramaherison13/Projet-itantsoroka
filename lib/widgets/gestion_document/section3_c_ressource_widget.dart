import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'document_card_widget.dart'; // Assurez-vous d'importer votre carte de document

class Section3Widget extends StatefulWidget {
  final String baseUrl;

  const Section3Widget({
    super.key,
    required this.baseUrl,
  });

  @override
  State<Section3Widget> createState() => _Section3WidgetState();
}

class _Section3WidgetState extends State<Section3Widget> {
  bool _loading = true;
  String? _error;
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('${widget.baseUrl}/servicebiblio/resources'));
      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la récupération des documents.');
      }
      final data = json.decode(response.body);
      
      setState(() {
        _documents = data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navigateToDocumentPage() {
    // Gérez la navigation vers la page de consultation avec le filtre de type "guide"
    debugPrint("Navigation vers la liste avec le filtre guide");
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filtrer les documents de type "guide" et limiter à 3
    final guideDocuments = _documents
        .where((doc) => doc['type']?.toString().toLowerCase() == 'guide')
        .take(3)
        .toList();

    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et titre
          Padding(
            padding: const EdgeInsets.only(top: 17.0, bottom: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/centreRessource/etude.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.menu_book, color: Colors.green, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Guides pratiques",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade100 : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // États de chargement, erreur ou liste
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_error != null)
            Center(
              child: Text(
                'Erreur lors du chargement des documents',
                style: TextStyle(color: Colors.red.shade600),
              ),
            )
          else if (guideDocuments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aucun guide disponible pour le moment',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 16),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: guideDocuments.length,
              itemBuilder: (context, index) {
                final doc = guideDocuments[index];
                return DocumentCardWidget(
                  id: doc['id'] ?? 0,
                  filename: doc['filename'] ?? '',
                  title: doc['title'] ?? '',
                  date: doc['date'] ?? '',
                  description: doc['description'] ?? '',
                  type: doc['type'] ?? '',
                  category: '',
                  baseUrl: widget.baseUrl,
                );
              },
            ),

          // Bouton "Voir plus"
          if (guideDocuments.isNotEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _navigateToDocumentPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008713),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Voir plus d'articles",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}