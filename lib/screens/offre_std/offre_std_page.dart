import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/territory_service.dart';

// Modèles de données
class Offre {
  final dynamic id;
  final String nom;
  final String? description;
  final dynamic stdId;
  final Map<String, dynamic>? std;

  Offre({
    required this.id,
    required this.nom,
    this.description,
    required this.stdId,
    this.std,
  });

  factory Offre.fromJson(Map<String, dynamic> json) {
    return Offre(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'],
      stdId: json['stdId'],
      std: json['std'],
    );
  }
}

class Std {
  final dynamic id;
  final String nom;
  final String? description;
  final int entiteId;
  final bool actif;
  final List<dynamic>? territoires;
  final Map<String, dynamic>? entite;

  Std({
    required this.id,
    required this.nom,
    this.description,
    required this.entiteId,
    required this.actif,
    this.territoires,
    this.entite,
  });

  factory Std.fromJson(Map<String, dynamic> json) {
    return Std(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'],
      entiteId: json['entiteId'] ?? 0,
      actif: json['actif'] ?? true,
      territoires: json['territoires'],
      entite: json['entite'],
    );
  }
}

class OffreStdPage extends StatefulWidget {
  final String baseUrl;
  final Map<String, dynamic> currentUser;

  const OffreStdPage({
    super.key,
    required this.baseUrl,
    required this.currentUser,
  });

  @override
  State<OffreStdPage> createState() => _OffreStdPageState();
}

class _OffreStdPageState extends State<OffreStdPage> {
  List<Offre> _offres = [];
  List<Offre> _filteredOffres = [];
  List<Std> _stds = [];
  List<Map<String, dynamic>> _districts = [];

  bool _loading = true;
  bool _isCreating = false;

  // Filtres
  String _searchQuery = '';
  String _secteurFilter = 'all';
  String _districtFilter = 'all';

  // Contrôleurs formulaire création
  final TextEditingController _newOffreNameController = TextEditingController();
  final TextEditingController _newOffreDescriptionController = TextEditingController();

  Map<String, dynamic>? _userStdAffiliation;
  bool _isStdRole = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadInitialData();
  }

  void _checkUserRole() {
    final roles = widget.currentUser['roles'] as List<dynamic>?;
    if (roles != null) {
      _isStdRole = roles.any((role) => role['role_slug'] == 'STD');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('access_token');
    if (raw == null) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map && parsed.containsKey('access_token')) {
        return parsed['access_token'];
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // 1. Charger l'affiliation STD
      if (_isStdRole && widget.currentUser['user_id'] != null) {
        try {
          final affUrl = Uri.parse('${widget.baseUrl}/serviceaffiliation/affiliation-std/user/${widget.currentUser['user_id']}');
          final affRes = await http.get(affUrl, headers: headers).timeout(const Duration(seconds: 10));
          if (affRes.statusCode == 200) {
            final data = jsonDecode(affRes.body);
            if (data != null && data['stdId'] != null && mounted) {
              setState(() {
                _userStdAffiliation = {
                  'stdId': data['stdId'].toString(),
                  'stdName': data['std']?['nom'],
                };
              });
            }
          }
        } catch (e) {
          debugPrint('Erreur affiliation STD : $e');
        }
      }

      // 2. Charger les districts
      try {
        final dists = await TerritoryService.getDistrictsBasic();
        if (dists != null && mounted) {
          setState(() {
            _districts = dists.map((d) {
              if (d is Map<String, dynamic>) return d;
              if (d is Map) return Map<String, dynamic>.from(d);
              return <String, dynamic>{};
            }).toList();
          });
        }
      } catch (e) {
        debugPrint('Erreur chargement districts : $e');
      }

      // 3. Charger les STDs
      List<Std> activeStds = [];
      try {
        final stdUrl = Uri.parse('${widget.baseUrl}/serviceaffiliation/stds');
        final stdRes = await http.get(stdUrl, headers: headers).timeout(const Duration(seconds: 10));
        if (stdRes.statusCode == 200) {
          final List data = jsonDecode(stdRes.body);
          activeStds = data.map((s) => Std.fromJson(s)).where((s) => s.actif).toList();
          if (mounted) {
            setState(() => _stds = activeStds);
          }
        }
      } catch (e) {
        debugPrint('Erreur STDs : $e');
      }

      // 4. Charger les offres
      try {
        final offreUrl = Uri.parse('${widget.baseUrl}/serviceaffiliation/offres');
        final offreRes = await http.get(offreUrl, headers: headers).timeout(const Duration(seconds: 10));
        if (offreRes.statusCode == 200) {
          final List data = jsonDecode(offreRes.body);
          final activeStdIds = activeStds.map((s) => s.id.toString()).toSet();

          List<Offre> loadedOffres = data
              .map((o) => Offre.fromJson(o))
              .where((o) => activeStdIds.contains(o.stdId.toString()))
              .map((o) {
                final std = activeStds.firstWhereOrNull((s) => s.id.toString() == o.stdId.toString());
                return Offre(
                  id: o.id,
                  nom: o.nom,
                  description: o.description,
                  stdId: o.stdId,
                  std: std != null
                      ? {
                          'nom': std.nom,
                          'entiteId': std.entiteId,
                          'entite': std.entite,
                          'territoires': std.territoires,
                        }
                      : null,
                );
              })
              .toList();

          if (mounted) {
            setState(() {
              _offres = loadedOffres;
              _filteredOffres = loadedOffres;
            });
          }
        }
      } catch (e) {
        debugPrint('Erreur offres : $e');
      }
    } catch (e) {
      debugPrint('Erreur globale chargement : $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Filtrage local des offres
  void _filterOffres() {
    List<Offre> temp = List.from(_offres);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      temp = temp.where((o) {
        final nom = o.nom.toLowerCase();
        final desc = (o.description ?? '').toLowerCase();
        final stdNom = (o.std?['nom'] ?? '').toLowerCase();
        final entiteNom = (o.std?['entite']?['nom'] ?? '').toLowerCase();
        return nom.contains(query) || desc.contains(query) || stdNom.contains(query) || entiteNom.contains(query);
      }).toList();
    }

    if (_secteurFilter != 'all') {
      temp = temp.where((o) => o.std?['entiteId'].toString() == _secteurFilter).toList();
    }

    if (_districtFilter != 'all') {
      temp = temp.where((o) {
        final territoires = o.std?['territoires'] as List<dynamic>?;
        if (territoires == null) return false;
        return territoires.any((t) {
          final id = t['formatted_id']?.toString() ?? t['id']?.toString() ?? t['code']?.toString() ?? '';
          return id == _districtFilter;
        });
      }).toList();
    }

    setState(() => _filteredOffres = temp);
  }

  Future<void> _createOffre() async {
    if (_newOffreNameController.text.trim().isEmpty) {
      _showSnackBar("Veuillez saisir le nom de l'offre", Colors.red);
      return;
    }

    if (_userStdAffiliation == null || _userStdAffiliation!['stdId'] == null) {
      _showSnackBar("Impossible de déterminer votre affiliation STD", Colors.red);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final token = await _getToken();
      final url = Uri.parse('${widget.baseUrl}/serviceaffiliation/offres');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nom': _newOffreNameController.text.trim(),
          'description': _newOffreDescriptionController.text.trim(),
          'stdId': _userStdAffiliation!['stdId'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Offre créée avec succès !", Colors.green);
        _newOffreNameController.clear();
        _newOffreDescriptionController.clear();
        if (!mounted) return;
        Navigator.pop(context);
        _loadInitialData();
      } else {
        _showSnackBar("Erreur lors de la création de l'offre", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Erreur réseau : $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Récupérer les secteurs uniques pour le filtre
  List<Map<String, dynamic>> get _secteursList {
    final Map<int, Map<String, dynamic>> map = {};
    for (var std in _stds) {
      if (std.entiteId != 0 && std.entite != null) {
        map[std.entiteId] = {
          'id': std.entiteId,
          'nom': std.entite!['nom'] ?? 'Entité ${std.entiteId}',
        };
      }
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF098E00).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.layers_rounded, color: Color(0xFF098E00), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Offres d'appui",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Découvrez les services et le support technique disponibles",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isStdRole)
                  ElevatedButton.icon(
                    onPressed: _openCreateModal,
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    label: const Text("Ajouter une offre", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF098E00),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Carte Filtres ─────────────────────────────────────────────
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
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list_rounded, size: 20, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        "Filtres",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isDesktop = constraints.maxWidth > 768;
                      return Column(
                        children: [
                          if (isDesktop)
                            Row(
                              children: [
                                Expanded(child: _buildSearchField(isDarkMode)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSecteurDropdown(isDarkMode)),
                              ],
                            )
                          else ...[
                            _buildSearchField(isDarkMode),
                            const SizedBox(height: 14),
                            _buildSecteurDropdown(isDarkMode),
                          ],
                          const SizedBox(height: 14),
                          _buildDistrictDropdown(isDarkMode),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "${_filteredOffres.length} offre(s) trouvée(s)",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF098E00)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Liste des Offres (Grille) ──────────────────────────────────
            _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: CircularProgressIndicator(color: Color(0xFF098E00)),
                    ),
                  )
                : _filteredOffres.isEmpty
                    ? Center(
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
                                child: const Icon(Icons.layers_clear_rounded, size: 40, color: Color(0xFF098E00)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Aucune offre disponible",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Modifiez vos critères de recherche",
                                style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          mainAxisExtent: 260,
                        ),
                        itemCount: _filteredOffres.length,
                        itemBuilder: (context, index) {
                          final offre = _filteredOffres[index];
                          final stdData = offre.std;
                          final stdNom = stdData?['nom'] ?? 'STD';
                          final entiteNom = stdData?['entite']?['nom'] ?? 'Ministère de la Santé';

                          return InkWell(
                            onTap: () => _openDetailModal(offre, isDarkMode),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                                    offre.nom,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    offre.description ?? 'Aucune description fournie.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  // STD Section
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.layers_rounded, size: 16, color: Color(0xFF098E00)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "STD",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              stdNom,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // SECTEUR Section
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF3B82F6)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "SECTEUR",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              entiteNom,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 13, color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF94A3B8)),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Cliquez pour plus de détails",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
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
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return TextField(
      onChanged: (val) {
        setState(() => _searchQuery = val);
        _filterOffres();
      },
      decoration: InputDecoration(
        hintText: "Rechercher...",
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

  Widget _buildSecteurDropdown(bool isDarkMode) {
    return DropdownButtonFormField<String>(
      initialValue: _secteurFilter,
      isExpanded: true,
      dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
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
        DropdownMenuItem(value: 'all', child: Text("Tous les secteurs", overflow: TextOverflow.ellipsis)),
        ..._secteursList.map((sec) => DropdownMenuItem(
              value: sec['id'].toString(),
              child: Text(sec['nom'].toString(), overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _secteurFilter = val);
          _filterOffres();
        }
      },
    );
  }

  Widget _buildDistrictDropdown(bool isDarkMode) {
    return DropdownButtonFormField<String>(
      initialValue: _districtFilter,
      isExpanded: true,
      dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
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
        DropdownMenuItem(value: 'all', child: Text("Tous les districts", overflow: TextOverflow.ellipsis)),
        ..._districts.map((d) {
          final id = d['formatted_id']?.toString() ?? d['id']?.toString() ?? d['name']?.toString() ?? '';
          final name = d['name']?.toString() ?? id;
          return DropdownMenuItem(
            value: id,
            child: Text(name, overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _districtFilter = val);
          _filterOffres();
        }
      },
    );
  }

  void _openCreateModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.add_box, color: Color(0xFF098E00)),
            SizedBox(width: 8),
            Text("Créer une nouvelle offre"),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_userStdAffiliation != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF098E00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF098E00).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.layers, color: Color(0xFF098E00), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "STD : ${_userStdAffiliation!['stdName'] ?? 'ID ${_userStdAffiliation!['stdId']}'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF098E00)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newOffreNameController,
                  decoration: InputDecoration(
                    labelText: "Nom de l'offre *",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newOffreDescriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Description de l'offre",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: _isCreating ? null : _createOffre,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF098E00)),
            child: _isCreating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Créer l'offre", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Modal Détails de l'Offre (Screenshot 2) ─────────────────────────
  void _openDetailModal(Offre offre, bool isDarkMode) {
    final stdData = offre.std;
    final stdNom = stdData?['nom'] ?? 'STD SANTE 1';
    final entiteData = stdData?['entite'];
    final entiteNom = entiteData?['nom'] ?? 'Ministère de la Santé';
    final entiteDesc = entiteData?['description'] ?? 'Gestion de la santé publique';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 580,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bouton Fermer X en haut à droite
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Block 1: Offre d'Appui (Vert) ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF098E00).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_rounded, color: Color(0xFF098E00), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Offre d'Appui",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "NOM DE L'OFFRE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offre.nom,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "DESCRIPTION",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offre.description ?? 'Aucune description fournie.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Block 2: Service Technique Déconcentré (Bleu) ────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.layers_rounded, color: Color(0xFF3B82F6), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Service Technique Déconcentré (STD)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "NOM DU STD",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stdNom,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.account_balance_rounded, size: 14, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          "SECTEUR / MINISTÈRE",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Inner Secteur Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entiteNom,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entiteDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}