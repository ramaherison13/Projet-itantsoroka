import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'document_card_widget.dart'; // Assurez-vous d'importer votre carte de document

class TousDocumentsWidget extends StatefulWidget {
  final String? initialTheme;
  final String baseUrl;

  const TousDocumentsWidget({
    super.key,
    this.initialTheme,
    required this.baseUrl,
  });

  @override
  State<TousDocumentsWidget> createState() => _TousDocumentsWidgetState();
}

class _TousDocumentsWidgetState extends State<TousDocumentsWidget> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _loading = true;
  String? _error;
  List<dynamic> _documents = [];
  
  List<dynamic> _categories = [];
  bool _categoriesLoading = true;

  List<dynamic> _themes = [];
  bool _themesLoading = true;

  bool _showMobileFilters = false;

  // États des filtres de date
  String _filterYear = "";
  String _filterMonth = "";
  String _filterDay = "";

  String? _selectedLetter;
  final List<String> _selectedCategories = [];
  List<String> _selectedThemes = [];

  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  @override
  void initState() {
    super.initState();
    if (widget.initialTheme != null) {
      _selectedThemes = [widget.initialTheme!];
    }
    _initData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadCategories(),
      _loadThemes(),
    ]);
    await _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<dynamic> allDocuments = [];
      Set<int> seenIds = {};

      if (_selectedThemes.isEmpty && _selectedCategories.isEmpty) {
        int currentPage = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          final url = '${widget.baseUrl}/servicebiblio/resources/filter?page=$currentPage&limit=100';
          final response = await http.get(Uri.parse(url));

          if (response.statusCode != 200) {
            throw Exception('Erreur lors de la récupération des documents.');
          }

          final data = json.decode(response.body);
          final List<dynamic>? docsList = data['data'];

          if (docsList != null && docsList.isNotEmpty) {
            for (var doc in docsList) {
              int id = doc['id'] ?? 0;
              if (!seenIds.contains(id)) {
                allDocuments.add(doc);
                seenIds.add(id);
              }
            }
            currentPage++;
            if (docsList.length < 100) hasMorePages = false;
          } else {
            hasMorePages = false;
          }
        }
      } else {
        List<Map<String, String>> combinations = [];

        if (_selectedThemes.isNotEmpty && _selectedCategories.isNotEmpty) {
          for (var th in _selectedThemes) {
            for (var cat in _selectedCategories) {
              combinations.add({'theme': th, 'category': cat});
            }
          }
        } else if (_selectedThemes.isNotEmpty) {
          for (var th in _selectedThemes) {
            combinations.add({'theme': th});
          }
        } else {
          for (var cat in _selectedCategories) {
            combinations.add({'category': cat});
          }
        }

        for (var combo in combinations) {
          int currentPage = 1;
          bool hasMorePages = true;

          while (hasMorePages) {
            final uri = Uri.parse('${widget.baseUrl}/servicebiblio/resources/filter').replace(
              queryParameters: {
                'page': currentPage.toString(),
                'limit': '100',
                if (combo['theme'] != null) 'theme': combo['theme']!,
                if (combo['category'] != null) 'category': combo['category']!,
              },
            );

            final response = await http.get(uri);
            if (response.statusCode != 200) {
              throw Exception('Erreur lors de la récupération des documents.');
            }

            final data = json.decode(response.body);
            final List<dynamic>? docsList = data['data'];

            if (docsList != null && docsList.isNotEmpty) {
              for (var doc in docsList) {
                int id = doc['id'] ?? 0;
                if (!seenIds.contains(id)) {
                  allDocuments.add(doc);
                  seenIds.add(id);
                }
              }
              currentPage++;
              if (docsList.length < 100) hasMorePages = false;
            } else {
              hasMorePages = false;
            }
          }
        }
      }

      setState(() {
        _documents = allDocuments;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('${widget.baseUrl}/servicetheme/category'));
      if (response.statusCode != 200) throw Exception('Erreur catégories');
      if (!mounted) return;
      setState(() {
        _categories = json.decode(response.body);
        _categoriesLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesLoading = false;
        });
      }
    }
  }

  Future<void> _loadThemes() async {
    setState(() {
      _themesLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('${widget.baseUrl}/servicetheme/themes'));
      if (response.statusCode != 200) throw Exception('Erreur thèmes');
      if (!mounted) return;
      setState(() {
        _themes = json.decode(response.body);
        _themesLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _themesLoading = false;
        });
      }
    }
  }

  void _handleCategoryChange(String catName) {
    setState(() {
      if (_selectedCategories.contains(catName)) {
        _selectedCategories.remove(catName);
      } else {
        _selectedCategories.add(catName);
      }
    });
    _loadDocuments();
  }

  void _handleThemeChange(String themeName) {
    setState(() {
      if (_selectedThemes.contains(themeName)) {
        _selectedThemes.remove(themeName);
      } else {
        _selectedThemes.add(themeName);
      }
    });
    _loadDocuments();
  }

  bool _matchesDateFilter(String docDate) {
    if (_filterYear.isEmpty && _filterMonth.isEmpty && _filterDay.isEmpty) return true;
    final dateObj = DateTime.tryParse(docDate);
    if (dateObj == null) return false;

    if (_filterYear.isNotEmpty && dateObj.year != int.parse(_filterYear)) return false;
    if (_filterMonth.isNotEmpty && _filterYear.isNotEmpty && dateObj.month != int.parse(_filterMonth)) return false;
    if (_filterDay.isNotEmpty && _filterMonth.isNotEmpty && _filterYear.isNotEmpty && dateObj.day != int.parse(_filterDay)) return false;

    return true;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedThemes.clear();
      _selectedCategories.clear();
      _selectedLetter = null;
      _searchController.clear();
      _filterYear = "";
      _filterMonth = "";
      _filterDay = "";
    });
    _loadDocuments();
  }

  int get _activeFiltersCount {
    int count = _selectedThemes.length + _selectedCategories.length;
    if (_selectedLetter != null) count++;
    if (_filterYear.isNotEmpty || _filterMonth.isNotEmpty || _filterDay.isNotEmpty) count++;
    return count;
  }

  int _getDaysInMonth(String month, String year) {
    if (month.isEmpty || year.isEmpty) return 31;
    return DateTime(int.parse(year), int.parse(month) + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 1999, (i) => currentYear - i);

    // Filtrage et tri local
    final filteredDocuments = _documents.where((doc) {
      final title = doc['title']?.toString().toLowerCase() ?? '';
      final matchesSearch = title.contains(_searchController.text.toLowerCase());
      final matchesDate = _matchesDateFilter(doc['date'] ?? '');

      if (_selectedLetter != null) {
        final firstChar = title.isNotEmpty ? title[0].toUpperCase() : '';
        if (_selectedLetter == '#') {
          return matchesSearch && !_alphabet.contains(firstChar) && matchesDate;
        } else {
          return matchesSearch && firstChar == _selectedLetter && matchesDate;
        }
      }
      return matchesSearch && matchesDate;
    }).toList();

    if (_selectedLetter != null) {
      filteredDocuments.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
    } else {
      filteredDocuments.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: Row(
        children: [
          // Sidebar de filtres (Desktop) / Drawer (Mobile)
          if (MediaQuery.of(context).size.width >= 1024 || _showMobileFilters)
            Material(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              child: SizedBox(
                width: 320,
                child: Column(
                children: [
                  if (MediaQuery.of(context).size.width < 1024)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Filtres", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _showMobileFilters = false),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Recherche modernisée
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un document...',
                              hintStyle: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF098E00)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF098E00), width: 1.5),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // En-tête filtre & reset
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tune, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                const Text("Filtres", style: TextStyle(fontWeight: FontWeight.bold)),
                                if (_activeFiltersCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                                    child: Text('$_activeFiltersCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                  ),
                                ],
                              ],
                            ),
                            if (_activeFiltersCount > 0)
                              TextButton(
                                onPressed: _clearAllFilters,
                                child: const Text("Effacer", style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                          ],
                        ),
                        const Divider(),

                        // Section Date
                        const Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _filterYear.isEmpty ? null : _filterYear,
                                hint: const Text('Année', style: TextStyle(fontSize: 12)),
                                items: years.map((y) => DropdownMenuItem(value: y.toString(), child: Text('$y', style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) => setState(() {
                                  _filterYear = val ?? '';
                                  if (_filterYear.isEmpty) { _filterMonth = ""; _filterDay = ""; }
                                }),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _filterMonth.isEmpty ? null : _filterMonth,
                                hint: const Text('Mois', style: TextStyle(fontSize: 12)),
                                items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m.toString(), child: Text('$m', style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: _filterYear.isEmpty ? null : (val) => setState(() {
                                  _filterMonth = val ?? '';
                                  if (_filterMonth.isEmpty) _filterDay = "";
                                }),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _filterDay.isEmpty ? null : _filterDay,
                                hint: const Text('Jour', style: TextStyle(fontSize: 12)),
                                items: List.generate(_getDaysInMonth(_filterMonth, _filterYear), (i) => i + 1).map((d) => DropdownMenuItem(value: d.toString(), child: Text('$d', style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (_filterYear.isEmpty || _filterMonth.isEmpty) ? null : (val) => setState(() => _filterDay = val ?? ''),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section Catégories
                        const Text("Catégorie", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        _categoriesLoading
                            ? const Text("Chargement...", style: TextStyle(fontSize: 12))
                            : Column(
                                children: _categories.map((cat) {
                                  final name = cat['name'] ?? '';
                                  return Material(
                                    color: Colors.transparent,
                                    child: CheckboxListTile(
                                      title: Text(cat['label'] ?? name, style: const TextStyle(fontSize: 12)),
                                      value: _selectedCategories.contains(name),
                                      onChanged: (val) => _handleCategoryChange(name),
                                      dense: true,
                                      activeColor: const Color(0xFF098E00),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 16),

                        // Section Thèmes
                        const Text("Thème", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        _themesLoading
                            ? const Text("Chargement...", style: TextStyle(fontSize: 12))
                            : Column(
                                children: _themes.map((th) {
                                  final name = th['name'] ?? '';
                                  return Material(
                                    color: Colors.transparent,
                                    child: CheckboxListTile(
                                      title: Text(name, style: const TextStyle(fontSize: 12)),
                                      value: _selectedThemes.contains(name),
                                      onChanged: (val) => _handleThemeChange(name),
                                      dense: true,
                                      activeColor: const Color(0xFF098E00),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 16),

                        // Ordre alphabétique
                        const Text("Ordre alphabétique", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            ..._alphabet.map((letter) {
                              final isSelected = _selectedLetter == letter;
                              return SizedBox(
                                width: 30,
                                height: 30,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedLetter = isSelected ? null : letter),
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF098E00)
                                          : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF098E00).withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDarkMode ? Colors.grey.shade300 : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: InkWell(
                                onTap: () => setState(() => _selectedLetter = _selectedLetter == '#' ? null : '#'),
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: _selectedLetter == '#'
                                        ? const Color(0xFF098E00)
                                        : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _selectedLetter == '#'
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF098E00).withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '#',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedLetter == '#'
                                          ? Colors.white
                                          : (isDarkMode ? Colors.grey.shade300 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu Principal
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: Text(_selectedThemes.length == 1 ? _selectedThemes.first : "Tous les documents"),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  actions: [
                    if (MediaQuery.of(context).size.width < 1024)
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => setState(() => _showMobileFilters = true),
                      ),
                  ],
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)))
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.folder_copy_rounded, size: 16, color: Color(0xFF098E00)),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${filteredDocuments.length} document(s)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_activeFiltersCount > 0) ...[
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: _clearAllFilters,
                                          icon: const Icon(Icons.clear_rounded, size: 16),
                                          label: const Text("Réinitialiser"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade50,
                                            foregroundColor: Colors.red.shade700,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: filteredDocuments.isEmpty
                                        ? const Center(child: Text("Aucun document trouvé"))
                                        : LayoutBuilder(
                                            builder: (context, constraints) {
                                              int crossAxisCount = 1;
                                              if (constraints.maxWidth >= 1400) {
                                                crossAxisCount = 4;
                                              } else if (constraints.maxWidth >= 960) {
                                                crossAxisCount = 3;
                                              } else if (constraints.maxWidth >= 600) {
                                                crossAxisCount = 2;
                                              }

                                              return GridView.builder(
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: crossAxisCount,
                                                  crossAxisSpacing: 16,
                                                  mainAxisSpacing: 16,
                                                  mainAxisExtent: 220,
                                                ),
                                                itemCount: filteredDocuments.length,
                                                itemBuilder: (context, index) {
                                                  final doc = filteredDocuments[index];
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
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}