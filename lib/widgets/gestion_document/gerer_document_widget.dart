import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'document_card_widget.dart'; // Assurez-vous d'importer votre carte de document

class GererDocumentWidget extends StatefulWidget {
  final String baseUrl;
  final String? municipalityId;

  const GererDocumentWidget({
    super.key,
    required this.baseUrl,
    this.municipalityId,
  });

  @override
  State<GererDocumentWidget> createState() => _GererDocumentWidgetState();
}

class _GererDocumentWidgetState extends State<GererDocumentWidget> {
  bool _loading = true;
  String? _error;
  List<dynamic> _documents = [];
  int _totalItems = 0;

  // Filtres
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = "";
  String _selectedCategory = "";
  String _selectedType = "";

  // Listes de données pour les filtres
  List<dynamic> _categories = [];
  List<dynamic> _types = [];

  @override
  void initState() {
    super.initState();
    _initFilterDataAndDocuments();
    _searchController.addListener(() {
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initFilterDataAndDocuments() async {
    await _loadFilterData();
    await _loadDocuments();
  }

  Future<void> _loadFilterData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('https://gateway.tsirylab.com/servicetheme/category')),
        http.get(Uri.parse('https://gateway.tsirylab.com/servicetheme/themes')),
        http.get(Uri.parse('https://gateway.tsirylab.com/servicetheme/type?category=DOCUMENT')),
      ]);

      if (responses[0].statusCode == 200 &&
          responses[1].statusCode == 200 &&
          responses[2].statusCode == 200) {
        setState(() {
          _categories = json.decode(responses[0].body);
          _types = json.decode(responses[2].body);
        });
      }

      // Simulation des communes si nécessaire
      if (widget.municipalityId != null) {
        // Charger les communes de la région si API disponible
      }
    } catch (e) {
      debugPrint("Erreur chargement filtres : $e");
    }
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Appel API pour récupérer les documents (ajustez l'endpoint selon votre service)
      final response = await http.get(Uri.parse('${widget.baseUrl}/servicebiblio/resources'));

      if (response.statusCode != 200) {
        throw Exception("Erreur lors de la récupération des documents");
      }

      List<dynamic> allDocs = json.decode(response.body);

      // Application des filtres côté client
      List<dynamic> filtered = allDocs.where((doc) {
        final title = doc['title']?.toString().toLowerCase() ?? '';
        final description = doc['description']?.toString().toLowerCase() ?? '';
        final search = _searchController.text.toLowerCase();

        if (search.isNotEmpty && !title.contains(search) && !description.contains(search)) {
          return false;
        }
        if (_selectedStatus.isNotEmpty && doc['status'] != _selectedStatus) {
          return false;
        }
        if (_selectedCategory.isNotEmpty && doc['category'] != _selectedCategory) {
          return false;
        }
        if (_selectedType.isNotEmpty && doc['type'] != _selectedType) {
          return false;
        }
        return true;
      }).toList();

      setState(() {
        _documents = filtered;
        _totalItems = filtered.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = "";
      _selectedCategory = "";
      _selectedType = "";
      _searchController.clear();
    });
    _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion des Documents',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalItems Document(s) au total',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigation vers la page d'ajout
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Zone filtre et recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          hintText: 'Rechercher par titre ou description...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('Filtres'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),

                if (_showFilters) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                    ),
                    children: [
                      // Statut
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus.isEmpty ? null : _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 'Public', child: Text('Public')),
                          DropdownMenuItem(value: 'Private', child: Text('Privé')),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val ?? ''),
                        decoration: InputDecoration(labelText: 'Statut', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      // Catégorie
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
                        items: _categories.map<DropdownMenuItem<String>>((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['name'].toString(),
                            child: Text(cat['name'].toString()),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val ?? ''),
                        decoration: InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      // Type
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType.isEmpty ? null : _selectedType,
                        items: _types.map<DropdownMenuItem<String>>((type) {
                          return DropdownMenuItem<String>(
                            value: type['name'].toString(),
                            child: Text(type['name'].toString()),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedType = val ?? ''),
                        decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Réinitialiser les filtres', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Liste des documents
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_error != null)
            Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)))
          else if (_documents.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Aucun document trouvé')))
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
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return DocumentCardWidget(
                  id: doc['id'] ?? 0,
                  filename: doc['filename'] ?? '',
                  title: doc['title'] ?? '',
                  date: doc['date'] ?? '',
                  description: doc['description'] ?? '',
                  type: doc['type'] ?? '',
                  category: doc['category'] ?? '',
                  baseUrl: widget.baseUrl,
                );
              },
            ),
        ],
      ),
    );
  }
}