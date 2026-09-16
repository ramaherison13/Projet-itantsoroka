import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:itantsoroka/constants/api_constants.dart';
import 'document_card_widget.dart';

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
  List<dynamic> _allDocuments = [];

  // Filtres
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = "";
  String _selectedCategory = "";
  String _selectedType = "";

  List<dynamic> _categories = [];
  List<dynamic> _types = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _loadFilterData();
    await _loadDocuments();
  }

  Future<void> _loadFilterData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConstants.gatewayBaseUrl}/servicetheme/category')),
        http.get(Uri.parse('${ApiConstants.gatewayBaseUrl}/servicetheme/type?category=DOCUMENT')),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          _categories = json.decode(responses[0].body);
          _types = json.decode(responses[1].body);
        });
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
      final cleanBaseUrl = widget.baseUrl.endsWith('/servicebiblio')
          ? widget.baseUrl
          : '${ApiConstants.gatewayBaseUrl}/servicebiblio';
      final response = await http.get(Uri.parse('$cleanBaseUrl/resources?limit=200'));

      if (response.statusCode != 200) {
        throw Exception("Erreur lors de la récupération des documents (${response.statusCode})");
      }

      final bodyData = json.decode(response.body);
      List<dynamic> rawDocs = [];

      if (bodyData is Map && bodyData['data'] is List) {
        rawDocs = bodyData['data'];
      } else if (bodyData is List) {
        rawDocs = bodyData;
      }

      setState(() {
        _allDocuments = rawDocs;
        _documents = rawDocs;
        _loading = false;
      });

      _applyFilters();
    } catch (e) {
      debugPrint("Erreur chargement documents: $e");
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final search = _searchController.text.toLowerCase();
    setState(() {
      _documents = _allDocuments.where((doc) {
        final title = (doc['title'] ?? '').toString().toLowerCase();
        final description = (doc['description'] ?? '').toString().toLowerCase();

        if (search.isNotEmpty && !title.contains(search) && !description.contains(search)) {
          return false;
        }
        if (_selectedStatus.isNotEmpty &&
            (doc['status'] ?? '').toString().toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
        if (_selectedCategory.isNotEmpty &&
            (doc['category'] ?? '').toString().toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
        if (_selectedType.isNotEmpty &&
            (doc['type'] ?? '').toString().toLowerCase() != _selectedType.toLowerCase()) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _handleDelete(int docId, String title) async {
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
      try {
        final res = await http.delete(
          Uri.parse('${ApiConstants.gatewayBaseUrl}/servicebiblio/resources/$docId'),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          setState(() {
            _allDocuments.removeWhere((d) => d['id'] == docId);
            _applyFilters();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Document supprimé avec succès !"), backgroundColor: Colors.green),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur de suppression (Code ${res.statusCode})"), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur réseau: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  List<String> _cleanThemes(dynamic themeRaw) {
    List<String> result = [];

    void extract(dynamic item) {
      if (item == null) return;
      if (item is List) {
        for (var sub in item) {
          extract(sub);
        }
      } else if (item is String) {
        final trimmed = item.trim();
        if (trimmed.startsWith('[') || trimmed.startsWith('"')) {
          try {
            final decoded = jsonDecode(trimmed);
            extract(decoded);
            return;
          } catch (_) {}
        }
        if (trimmed.isNotEmpty) {
          result.add(trimmed);
        }
      } else {
        result.add(item.toString());
      }
    }

    extract(themeRaw);
    return result.toSet().toList();
  }

  Future<void> _handleEdit(Map<String, dynamic> doc) async {
    final int docId = doc['id'] is int
        ? doc['id']
        : int.tryParse(doc['id'].toString()) ?? 0;
    final titleController =
        TextEditingController(text: doc['title']?.toString() ?? '');
    final descController =
        TextEditingController(text: doc['description']?.toString() ?? '');

    String selectedCat = doc['category']?.toString() ?? '';
    String selectedTyp = doc['type']?.toString() ?? '';
    String selectedStat = doc['status']?.toString() ?? 'Public';

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final catNames = _categories.map((c) => c['name'].toString()).toList();
            final typeNames = _types.map((t) => t['name'].toString()).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 560,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Modal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF098E00)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: Color(0xFF098E00),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Modifier le document",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              hoverColor: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Titre
                      Text(
                        "Titre du document *",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "Titre du document",
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "Description détaillée...",
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Catégorie & Type
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Catégorie",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.grey.shade300
                                        : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: catNames.contains(selectedCat)
                                      ? selectedCat
                                      : (catNames.isNotEmpty ? catNames.first : null),
                                  isExpanded: true,
                                  dropdownColor: isDarkMode
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: catNames.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setModalState(
                                      () => selectedCat = val ?? ''),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Type",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.grey.shade300
                                        : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: typeNames.contains(selectedTyp)
                                      ? selectedTyp
                                      : (typeNames.isNotEmpty ? typeNames.first : null),
                                  isExpanded: true,
                                  dropdownColor: isDarkMode
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: typeNames.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Text(t, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setModalState(
                                      () => selectedTyp = val ?? ''),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Boutons d'action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Annuler"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final newTitle = titleController.text.trim();
                                    if (newTitle.isEmpty) return;

                                    final nav = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(context);
                                    setModalState(() => isSaving = true);
                                    try {
                                      final cleanBaseUrl = widget.baseUrl.endsWith('/servicebiblio')
                                          ? widget.baseUrl
                                          : '${ApiConstants.gatewayBaseUrl}/servicebiblio';

                                      final themeList = _cleanThemes(doc['theme']);

                                      final payloadMap = <String, dynamic>{
                                        'title': newTitle,
                                        'description': descController.text.trim(),
                                        'category': selectedCat,
                                        'theme': themeList,
                                      };
                                      final payload = jsonEncode(payloadMap);
                                      debugPrint("PATCH /servicebiblio/resources/$docId payload: $payload");

                                      http.Response res = await http.patch(
                                        Uri.parse('$cleanBaseUrl/resources/$docId'),
                                        headers: {'Content-Type': 'application/json'},
                                        body: payload,
                                      );
                                      debugPrint("PATCH /servicebiblio/resources/$docId response (${res.statusCode}): ${res.body}");

                                      if (res.statusCode == 404 || res.statusCode == 405) {
                                        res = await http.put(
                                          Uri.parse('$cleanBaseUrl/resources/$docId'),
                                          headers: {'Content-Type': 'application/json'},
                                          body: payload,
                                        );
                                        debugPrint("PUT /servicebiblio/resources/$docId response (${res.statusCode}): ${res.body}");
                                      }

                                      if (res.statusCode >= 200 && res.statusCode < 300) {
                                        setState(() {
                                          doc['title'] = newTitle;
                                          doc['description'] = descController.text.trim();
                                          doc['category'] = selectedCat;
                                          doc['type'] = selectedTyp;
                                          doc['status'] = selectedStat;
                                          _applyFilters();
                                        });
                                        if (mounted) {
                                          nav.pop();
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text("Document modifié avec succès !"),
                                              backgroundColor: Color(0xFF098E00),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text("Erreur de modification (${res.statusCode}): ${res.body}"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint("Erreur modification document: $e");
                                    } finally {
                                      setModalState(() => isSaving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF098E00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: Text(
                                isSaving ? "Enregistrement..." : "Enregistrer"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;
    final bool isTablet = screenWidth >= 700 && screenWidth < 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                border: Border(bottom: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/itantsorika-services'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                        side: BorderSide(color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text("Retour aux services", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                    onPressed: _loading ? null : _loadDocuments,
                    tooltip: "Actualiser",
                  ),
                ],
              ),
            ),

            // ── Zone de contenu principal ───────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF10B981)),
                          SizedBox(height: 16),
                          Text("Chargement des documents...", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(isMobile ? 16 : 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Header Titre & Bouton Nouveau Document ────────
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Gestion des Documents",
                                        style: TextStyle(
                                          fontSize: isMobile ? 20 : 28,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${_allDocuments.length} Document(s) au total",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => context.go('/itantsorika/ajoutdocument'),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text("Nouveau document", style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Barre de recherche & Bouton Filtres ─────────
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                                    if (isMobile) ...[
                                      TextField(
                                        controller: _searchController,
                                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                        onChanged: (_) => _applyFilters(),
                                        decoration: InputDecoration(
                                          hintText: "Rechercher par titre ou description...",
                                          hintStyle: TextStyle(color: isDarkMode ? const Color(0xFF64748B) : Colors.grey),
                                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                                          filled: true,
                                          fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => setState(() => _showFilters = !_showFilters),
                                              icon: const Icon(Icons.filter_list_rounded, size: 18),
                                              label: const Text("Filtres"),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                foregroundColor: _showFilters ? const Color(0xFF10B981) : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                                                side: BorderSide(color: _showFilters ? const Color(0xFF10B981) : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                                backgroundColor: _showFilters ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.transparent,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _applyFilters,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2563EB),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                              ),
                                              child: const Text("Debug Filtres", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                              onChanged: (_) => _applyFilters(),
                                              decoration: InputDecoration(
                                                hintText: "Rechercher par titre ou description...",
                                                hintStyle: TextStyle(color: isDarkMode ? const Color(0xFF64748B) : Colors.grey),
                                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                                                filled: true,
                                                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          OutlinedButton.icon(
                                            onPressed: () => setState(() => _showFilters = !_showFilters),
                                            icon: const Icon(Icons.filter_list_rounded, size: 18),
                                            label: const Text("Filtres"),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              foregroundColor: _showFilters ? const Color(0xFF10B981) : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                                              side: BorderSide(color: _showFilters ? const Color(0xFF10B981) : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                              backgroundColor: _showFilters ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.transparent,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: _applyFilters,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2563EB),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              elevation: 0,
                                            ),
                                            child: const Text("Debug Filtres", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),

                                    // Panneau de filtres dépliable
                                    if (_showFilters) ...[
                                      const SizedBox(height: 16),
                                      Divider(color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
                                              dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 13),
                                              decoration: InputDecoration(
                                                labelText: "Catégorie",
                                                labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                                                filled: true,
                                                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              items: [
                                                const DropdownMenuItem(value: "", child: Text("Toutes les catégories")),
                                                ..._categories.map((cat) => DropdownMenuItem(
                                                      value: cat['name']?.toString() ?? '',
                                                      child: Text(cat['name']?.toString() ?? ''),
                                                    )),
                                              ],
                                              onChanged: (val) {
                                                setState(() => _selectedCategory = val ?? "");
                                                _applyFilters();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              initialValue: _selectedType.isEmpty ? null : _selectedType,
                                              dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 13),
                                              decoration: InputDecoration(
                                                labelText: "Type de document",
                                                labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                                                filled: true,
                                                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              items: [
                                                const DropdownMenuItem(value: "", child: Text("Tous les types")),
                                                ..._types.map((t) => DropdownMenuItem(
                                                      value: t['name']?.toString() ?? '',
                                                      child: Text(t['name']?.toString() ?? ''),
                                                    )),
                                              ],
                                              onChanged: (val) {
                                                setState(() => _selectedType = val ?? "");
                                                _applyFilters();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              initialValue: _selectedStatus.isEmpty ? null : _selectedStatus,
                                              dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 13),
                                              decoration: InputDecoration(
                                                labelText: "Statut",
                                                labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                                                filled: true,
                                                fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              items: const [
                                                DropdownMenuItem(value: "", child: Text("Tous les statuts")),
                                                DropdownMenuItem(value: "public", child: Text("Public")),
                                                DropdownMenuItem(value: "private", child: Text("Privé")),
                                              ],
                                              onChanged: (val) {
                                                setState(() => _selectedStatus = val ?? "");
                                                _applyFilters();
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

                              // ── Grille des cartes de documents (3 cols desktop, 2 tablet, 1 mobile)
                              _documents.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(40),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            _error != null ? Icons.error_outline_rounded : Icons.folder_off_rounded,
                                            size: 48,
                                            color: _error != null ? Colors.red : (isDarkMode ? Colors.white30 : Colors.grey.shade400),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _error != null ? "Erreur: $_error" : "Aucun document trouvé",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _error != null ? Colors.red : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
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
                                        crossAxisSpacing: 18,
                                        mainAxisSpacing: 18,
                                        mainAxisExtent: 310,
                                      ),
                                      itemCount: _documents.length,
                                      itemBuilder: (context, index) {
                                        final doc = _documents[index];
                                        final docId = doc['id'] is int ? doc['id'] : int.tryParse(doc['id'].toString()) ?? 0;
                                        final title = doc['title']?.toString() ?? 'Sans titre';

                                        return DocumentCardWidget(
                                          id: docId,
                                          filename: doc['fileId']?.toString() ?? doc['filename']?.toString() ?? '',
                                          title: title,
                                          date: doc['date']?.toString() ?? '',
                                          description: doc['description']?.toString() ?? '',
                                          type: doc['type']?.toString() ?? '',
                                          category: doc['category']?.toString() ?? '',
                                          theme: doc['theme'] is List ? doc['theme'] : [],
                                          baseUrl: widget.baseUrl,
                                          onEdit: () => _handleEdit(doc),
                                          onDelete: () => _handleDelete(docId, title),
                                        );
                                      },
                                    ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}