import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:itantsoroka/widgets/monographie/monographie_map_widget.dart';
import '../../l10n/app_localization.dart';

// ── Couleur verte principale ────────────────────────────────────────────────
const _kGreen = Color(0xFF00C853);

// ── Couleurs adaptatives selon le thème ─────────────────────────────────────
Color _bg(bool d)         => d ? const Color(0xFF0B1324) : const Color(0xFFF4F6F9);
Color _cardBg(bool d)     => d ? const Color(0xFF151F32) : Colors.white;
Color _border(bool d)     => d ? const Color(0xFF233048) : const Color(0xFFDDE3EC);
Color _textMuted(bool d)  => d ? const Color(0xFF8E9BAE) : const Color(0xFF6B7280);
Color _textMain(bool d)   => d ? Colors.white            : const Color(0xFF111827);

class MonographieScreen extends StatefulWidget {
  final String? territoire;
  final String? id;
  final String? type; // 'communes' ou 'districts'

  const MonographieScreen({
    super.key,
    this.territoire,
    this.id,
    this.type,
  });

  @override
  State<MonographieScreen> createState() => _MonographieScreenState();
}

class _MonographieScreenState extends State<MonographieScreen>
    with SingleTickerProviderStateMixin {
  final String apiUrl = "https://gateway.tsirylab.com";
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  // ── Données monographie ──────────────────────────────────────────────────────
  Map<String, dynamic> monographieData = {
    "file": "",
    "resume": "",
    "description": "",
    "formatted_id": "",
  };

  // ── États ────────────────────────────────────────────────────────────────────
  bool loadingActu = false;
  List<dynamic> actualites = [];

  List<dynamic> districtCommunes = [];
  bool loadingCommunes = false;
  String? communesError;

  Map<String, dynamic>? parentDistrict;
  bool loadingParentDistrict = false;
  String? parentDistrictError;

  List<dynamic> stdExpertises = [];
  bool loadingStdExpertises = false;
  String? stdExpertisesError;

  List<dynamic> projectResources = [];
  bool loadingProjects = false;
  String? projectsError;

  List<dynamic> documentResources = [];
  bool loadingDocuments = false;
  String? documentsError;

  // ── Ancres (GlobalKeys pour le défilement fluide) ───────────────────────────
  final GlobalKey _resumeKey = GlobalKey();
  final GlobalKey _monographieKey = GlobalKey();
  final GlobalKey _territoiresKey = GlobalKey();
  final GlobalKey _stdKey = GlobalKey();
  final GlobalKey _actuKey = GlobalKey();
  final GlobalKey _projKey = GlobalKey();
  final GlobalKey _docKey = GlobalKey();

  // ── Écran de liste / recherche ──────────────────────────────────────────────
  List<dynamic> allMonographies = [];
  bool loadingAllMonographies = false;
  String? allMonographiesError;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _territoryListScrollCtrl = ScrollController();
  String _searchTerm = "";
  String _filterType = "districts"; // 'districts' par défaut comme en React

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    if (widget.type != null && widget.type!.contains("commune")) {
      _filterType = "communes";
    }

    if (widget.id != null) {
      fetchMonographieData();
      fetchActualites();
      fetchProjects();
      fetchDocuments();
      if (widget.type?.contains("district") == true) {
        fetchCommunesForDistrict();
      } else if (widget.type?.contains("commune") == true) {
        fetchParentDistrict();
        fetchStdExpertises();
      }
    } else {
      fetchTerritoiresForSearch();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final q = GoRouterState.of(context).uri.queryParameters['q'];
      if (q != null && q.trim().isNotEmpty && _searchTerm != q.trim()) {
        setState(() {
          _searchTerm = q.trim();
          _searchCtrl.text = q.trim();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    _territoryListScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  String replaceLastSixWithZeros(String input) {
    if (input.length < 6) return input;
    return "${input.substring(0, input.length - 6)}000000";
  }

  String _getLocalizedText(dynamic text) {
    return context.trDynamic(text);
  }

  Future<dynamic> _getTerritoryByFormattedId(String? id) async {
    if (id == null) return null;
    try {
      final typePath = widget.type?.contains("commune") == true
          ? "communes"
          : "districts";
      final response = await http.get(
        Uri.parse('$apiUrl/serviceterritoire-v2/$typePath/$id'),
      );
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        final Map<String, dynamic> data = Map<String, dynamic>.from(resData['data'] ?? resData);

        // Récupération de la forme géométrique GeoJSON (MultiPolygon)
        if (data['form'] == null && data['geometry'] == null && data['geojson'] == null) {
          try {
            final formRes = await http.get(
              Uri.parse('$apiUrl/serviceterritoire-v2/$typePath/$id/form'),
            );
            if (formRes.statusCode == 200) {
              data['form'] = json.decode(formRes.body);
            }
          } catch (_) {}
        }

        return {
          widget.type?.contains("commune") == true ? 'commune' : 'district': data,
        };
      }
    } catch (e) {
      debugPrint("Erreur _getTerritoryByFormattedId: $e");
    }
    return null;
  }

  // ── API Fetchers ────────────────────────────────────────────────────────────
  Future<void> fetchTerritoiresForSearch() async {
    if (!mounted) return;
    setState(() {
      loadingAllMonographies = true;
      allMonographiesError = null;
    });
    try {
      final typePath = _filterType == "communes" ? "communes" : "districts";
      final response = await http
          .get(Uri.parse('$apiUrl/serviceterritoire-v2/$typePath/basic?page=1&limit=10000'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        final List<dynamic> data = resData['data'] is List ? resData['data'] : (resData is List ? resData : []);
        if (mounted) setState(() => allMonographies = data);
      } else {
        if (mounted) {
          setState(() => allMonographiesError = "Erreur serveur (code HTTP ${response.statusCode}).");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => allMonographiesError = "Échec de connexion au serveur.");
      }
    } finally {
      if (mounted) setState(() => loadingAllMonographies = false);
    }
  }

  Future<void> fetchMonographieData() async {
    try {
      final isCommune = widget.type?.contains("commune") == true;
      final typePath = isCommune ? 'communes' : 'districts';
      final widgetId = widget.id ?? '';
      final rawTerritoryName = widget.territoire ?? '';

      Map<String, dynamic>? territoryInfo;
      try {
        final terrRes = await http.get(
          Uri.parse('$apiUrl/serviceterritoire-v2/$typePath/$widgetId'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 6));
        if (terrRes.statusCode == 200) {
          final decoded = json.decode(terrRes.body);
          territoryInfo = decoded['data'] ?? decoded;
        }
      } catch (_) {}

      final String numericId = (isCommune
              ? (territoryInfo?['commune_id'] ?? territoryInfo?['id'])
              : (territoryInfo?['district_id'] ?? territoryInfo?['id']))
          ?.toString() ??
          '';

      final String territoryName = (territoryInfo?['name'] ??
              territoryInfo?['nom'] ??
              rawTerritoryName)
          .toString()
          .trim()
          .toLowerCase();

      final response = await http.get(
        Uri.parse('$apiUrl/servicemonographies/monographies'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> monographies = json.decode(response.body);
        Map<String, dynamic>? match;

        for (var m in monographies) {
          final code = (m['code'] ?? m['formatted_id'] ?? '').toString();
          final idCommune = (m['Id_commune'] ?? m['commune_id'] ?? '').toString();
          final idDistrict = (m['Id_district'] ?? m['district_id'] ?? '').toString();
          final mId = (m['id'] ?? '').toString();
          final mNom = _getLocalizedText(m['nom'] ?? m['name']).toLowerCase();

          if (widgetId.isNotEmpty && (code == widgetId || mId == widgetId)) {
            match = m as Map<String, dynamic>;
            break;
          }

          if (isCommune && idCommune.isNotEmpty && (idCommune == widgetId || (numericId.isNotEmpty && idCommune == numericId))) {
            match = m as Map<String, dynamic>;
            break;
          } else if (!isCommune && idDistrict.isNotEmpty && (idDistrict == widgetId || (numericId.isNotEmpty && idDistrict == numericId))) {
            match = m as Map<String, dynamic>;
            break;
          }

          if (territoryName.isNotEmpty && territoryName.length >= 3 && mNom.contains(territoryName)) {
            match = m as Map<String, dynamic>;
            break;
          }
        }

        if (match != null && mounted) {
          final m = match;
          setState(() {
            monographieData = {
              "file": m['file'] ?? m['lien'],
              "resume": m['resume'] ?? m['summary'],
              "description": m['description'],
              "formatted_id": m['formatted_id'] ?? m['code'] ?? widgetId,
              "nom": m['nom'] ?? m['name'] ?? territoryInfo?['name'] ?? rawTerritoryName,
              ...m,
            };
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur fetchMonographieData: $e');
    }
  }

  String _cleanText(dynamic raw) {
    String text = _getLocalizedText(raw);
    if (text.isEmpty) return "";
    text = text.replaceAll("|||LANG|||", "").trim();
    text = text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  Future<void> fetchActualites() async {
    if (!mounted) return;
    setState(() => loadingActu = true);
    try {
      final isCommune = widget.type?.contains("commune") == true;
      final ep = isCommune
          ? '$apiUrl/servicepublication/events?communeId=${widget.id}&limit=20'
          : '$apiUrl/servicepublication/events?districtId=${widget.id}&limit=20';

      final response = await http.get(
        Uri.parse(ep),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      List items = [];
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        final rawItems = resData['data'] is List
            ? resData['data']
            : (resData is List ? resData : []);

        // Filtrage strict : ne conserver QUE les actualités appartenant à ce territoire
        items = (rawItems as List).where((item) {
          final cId = (item['communeId'] ?? item['commune_id'] ?? '').toString();
          final dId = (item['districtId'] ?? item['district_id'] ?? '').toString();
          if (isCommune) {
            return cId == widget.id;
          } else {
            if (dId.isNotEmpty) {
              return dId == widget.id;
            }
            if (cId.isNotEmpty) {
              try {
                return replaceLastSixWithZeros(cId) == widget.id;
              } catch (_) {
                return false;
              }
            }
            return false;
          }
        }).take(8).toList();
      }

      if (mounted) setState(() => actualites = items);
    } catch (e) {
      debugPrint('Erreur fetchActualites: $e');
    } finally {
      if (mounted) setState(() => loadingActu = false);
    }
  }

  Future<void> fetchCommunesForDistrict() async {
    if (!mounted) return;
    setState(() {
      loadingCommunes = true;
      communesError = null;
    });
    try {
      final distRes = await http.get(
        Uri.parse('$apiUrl/serviceterritoire-v2/districts/${widget.id}'),
      ).timeout(const Duration(seconds: 8));

      List items = [];
      if (distRes.statusCode == 200) {
        final dData = json.decode(distRes.body);
        final rawCommunes = dData['communes'] ?? dData['data']?['communes'];
        if (rawCommunes is List && rawCommunes.isNotEmpty) {
          items = rawCommunes;
        }
      }

      if (items.isEmpty) {
        final response = await http.get(
          Uri.parse('$apiUrl/serviceterritoire-v2/communes/district/${widget.id}'),
        ).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final resData = json.decode(response.body);
          items = resData['data'] ?? (resData is List ? resData : []);
        }
      }

      if (mounted) {
        setState(() {
          districtCommunes = items;
        });
      }
    } catch (_) {
      if (mounted) setState(() => communesError = "Erreur chargement communes");
    } finally {
      if (mounted) setState(() => loadingCommunes = false);
    }
  }

  Future<void> fetchParentDistrict() async {
    if (!mounted) return;
    setState(() {
      loadingParentDistrict = true;
      parentDistrictError = null;
    });
    try {
      final districtId = replaceLastSixWithZeros(widget.id!);
      final response = await http.get(
        Uri.parse('$apiUrl/serviceterritoire-v2/districts/$districtId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final districtData = json.decode(response.body)['data'] ?? json.decode(response.body);
        if (mounted) {
          setState(() {
            parentDistrict = {
              "formatted_id": districtData['formatted_id'] ?? districtId,
              "name": districtData['nom'] ?? districtData['name'] ?? "District",
            };
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => parentDistrictError = "Erreur chargement district parent");
    } finally {
      if (mounted) setState(() => loadingParentDistrict = false);
    }
  }

  Future<void> fetchStdExpertises() async {
    if (!mounted) return;
    setState(() {
      loadingStdExpertises = true;
      stdExpertisesError = null;
    });
    try {
      final formattedIdWithZeros = replaceLastSixWithZeros(widget.id!);
      final primaryUrl = '$apiUrl/serviceaffiliation/stds/territoire/formatted-id-with-region/$formattedIdWithZeros';

      http.Response response = await http.get(
        Uri.parse(primaryUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      List items = [];
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        items = resData['data'] is List ? resData['data'] : (resData is List ? resData : []);
      }

      if (mounted) setState(() => stdExpertises = items);
    } catch (e) {
      debugPrint('Erreur fetchStdExpertises: $e');
    } finally {
      if (mounted) setState(() => loadingStdExpertises = false);
    }
  }

  Future<void> fetchProjects() async {
    if (!mounted) return;
    setState(() {
      loadingProjects = true;
      projectsError = null;
    });
    try {
      final isCommune = widget.type?.contains("commune") == true;
      final filterParam = isCommune ? 'communeId=${widget.id}' : 'districtId=${widget.id}';

      final response = await http.get(
        Uri.parse('$apiUrl/serviceprojet/projects?$filterParam&limit=50'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      List items = [];
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        items = resData['data'] is List
            ? resData['data']
            : resData['data']?['data'] is List
                ? resData['data']['data']
                : (resData is List ? resData : []);
      }

      final filtered = items.where((proj) {
        final cId = (proj['commune_id'] ?? proj['communeId'] ?? '').toString();
        final dId = (proj['district_id'] ?? proj['districtId'] ?? '').toString();
        if (isCommune) {
          return cId == widget.id;
        } else {
          if (dId.isNotEmpty && dId == widget.id) return true;
          if (cId.isNotEmpty) {
            try {
              return replaceLastSixWithZeros(cId) == widget.id;
            } catch (_) {
              return false;
            }
          }
          return false;
        }
      }).take(6).toList();

      if (mounted) {
        setState(() {
          projectResources = filtered;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetchProjects: $e');
      if (mounted) setState(() => projectsError = "Erreur chargement projets");
    } finally {
      if (mounted) setState(() => loadingProjects = false);
    }
  }

  Future<void> fetchDocuments() async {
    if (!mounted) return;
    setState(() {
      loadingDocuments = true;
      documentsError = null;
    });
    try {
      final isCommune = widget.type?.contains("commune") == true;
      final filterParam = isCommune ? 'communeId=${widget.id}' : 'districtId=${widget.id}';

      final response = await http.get(
        Uri.parse('$apiUrl/servicebiblio/resources?$filterParam&limit=50'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      List docs = [];
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        docs = resData['data'] is List ? resData['data'] : (resData is List ? resData : []);
      }

      final filtered = docs.where((doc) {
        final cId = (doc['commune_id'] ?? doc['communeId'] ?? '').toString();
        final dId = (doc['district_id'] ?? doc['districtId'] ?? '').toString();
        if (isCommune) {
          return cId == widget.id;
        } else {
          if (dId.isNotEmpty && dId == widget.id) return true;
          if (cId.isNotEmpty) {
            try {
              return replaceLastSixWithZeros(cId) == widget.id;
            } catch (_) {
              return false;
            }
          }
          return false;
        }
      }).take(6).toList();

      if (mounted) {
        setState(() {
          documentResources = filtered;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetchDocuments: $e');
      if (mounted) setState(() => documentsError = 'Erreur chargement documents');
    } finally {
      if (mounted) setState(() => loadingDocuments = false);
    }
  }

  Future<void> handleDownload() async {
    if (monographieData["file"].isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Aucun fichier disponible"),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final f = monographieData["file"].toString().trim();
      final cleanPath = f.startsWith('/') ? f.substring(1) : f;
      final downloadUrl = '$apiUrl/serviceupload/file/${cleanPath.replaceAll('/', '%2F')}';
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Téléchargement réussi"),
              ],
            ),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  // ── BUILD MAIN ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.id == null) {
      return _buildSearchPage(isDark);
    }
    return _buildDetailPage(widget.type?.contains("commune") == true, isDark);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PAGE RECHERCHE MONOGRAPHIES (GRID 2 COLONNES EXACTEMENT COMME LES CAPTURES 1 & 2)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSearchPage(bool isDark) {
    final query = _searchTerm.toLowerCase();
    final displayed = allMonographies.where((m) {
      final code = (m['code'] ?? m['formatted_id'] ?? '').toString().toLowerCase();
      final nom = (m['name'] ?? m['nom'] ?? m['territoire'] ?? '').toString().toLowerCase();

      return query.isEmpty || code.contains(query) || nom.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _textMain(isDark),
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: "${context.tr('rech_mono')} "),
                          TextSpan(text: "${context.tr('district')} ", style: const TextStyle(color: _kGreen)),
                          TextSpan(text: "${context.tr('ou')} "),
                          TextSpan(text: context.tr('commune'), style: const TextStyle(color: _kGreen)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.tr('rech_effic_com'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: _textMuted(isDark)),
                    ),
                    const SizedBox(height: 32),

                    // Barre de recherche avec sélecteur (District / Commune)
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 720),
                        decoration: BoxDecoration(
                          color: _cardBg(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border(isDark), width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _searchTerm = v),
                                style: TextStyle(color: _textMain(isDark), fontSize: 14.5),
                                decoration: InputDecoration(
                                  hintText: context.tr('rech_monog'),
                                  hintStyle: TextStyle(color: _textMuted(isDark), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchTerm.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.close, color: _textMuted(isDark), size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchTerm = "");
                                },
                              ),
                            Container(height: 28, width: 1, color: _border(isDark), margin: const EdgeInsets.symmetric(horizontal: 10)),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _filterType,
                                dropdownColor: _cardBg(isDark),
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                                style: TextStyle(color: _textMain(isDark), fontSize: 13.5, fontWeight: FontWeight.w500),
                                items: [
                                  DropdownMenuItem(value: "districts", child: Text(context.tr('district'))),
                                  DropdownMenuItem(value: "communes", child: Text(context.tr('commune'))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _filterType = val;
                                    });
                                    fetchTerritoiresForSearch();
                                  }
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
            ),

            if (loadingAllMonographies)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _kGreen),
                ),
              )
            else if (allMonographiesError != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(allMonographiesError!, style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (displayed.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _searchTerm.isNotEmpty ? "${context.tr('auc_resul')} \"$_searchTerm\"" : context.tr('aucun_resultat'),
                    style: TextStyle(color: _textMuted(isDark), fontSize: 15),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 860),
                      decoration: BoxDecoration(
                        color: _cardBg(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _border(isDark),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // En-tête de la liste avec compteur
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              border: Border(
                                bottom: BorderSide(color: _border(isDark)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _kGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.map_rounded, color: _kGreen, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "${displayed.length} ${context.tr('mono_dispo')}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _textMain(isDark),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _kGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _filterType == "districts" ? "Districts" : "Communes",
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: _kGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Liste défilante intégrée (Scrollable Container)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              return SizedBox(
                                height: 480,
                                child: Scrollbar(
                                  controller: _territoryListScrollCtrl,
                                  thumbVisibility: true,
                                  thickness: 6,
                                  radius: const Radius.circular(10),
                                  child: GridView.builder(
                                    controller: _territoryListScrollCtrl,
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isMobile ? 1 : 2,
                                      mainAxisExtent: 52,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: displayed.length,
                                    itemBuilder: (context, index) {
                                      final item = displayed[index];
                                      final String name = (item['name'] ?? item['nom'] ?? 'Territoire').toString().trim();
                                      final String formattedId = (item['formatted_id'] ?? item['code'] ?? item['id'] ?? '').toString();
                                      final isDistrict = _filterType == "districts";

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            final type = isDistrict ? 'districts' : 'communes';
                                            if (formattedId.isNotEmpty) {
                                              context.go('/monographie/$type/${Uri.encodeComponent(name)}/$formattedId');
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          hoverColor: _kGreen.withValues(alpha: 0.08),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _border(isDark)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isDistrict ? Icons.domain_rounded : Icons.location_city_rounded,
                                                  size: 18,
                                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: TextStyle(
                                                      color: _textMain(isDark),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  size: 12,
                                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // PAGE DÉTAIL TERRITOIRE (2 COLONNES exact d'après les captures 3, 4, 5)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDetailPage(bool isCommune, bool isDark) {
    final rawTitle = _getLocalizedText(widget.territoire);
    final title = rawTitle.isNotEmpty ? rawTitle.toUpperCase() : (isCommune ? context.tr('commune').toUpperCase() : context.tr('district').toUpperCase());
    final fileStr = _getLocalizedText(monographieData["file"]);
    final resumeStr = _getLocalizedText(monographieData["resume"]);
    final descStr = _getLocalizedText(monographieData["description"]);
    final codeStr = _getLocalizedText(monographieData["formatted_id"]);
    final displayCode = codeStr.isNotEmpty ? codeStr : (widget.id ?? "");
    final hasFile = fileStr.isNotEmpty;
    final hasResume = resumeStr.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg(isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: hasFile ? handleDownload : null,
        backgroundColor: hasFile ? _kGreen : Colors.grey.shade700,
        shape: const CircleBorder(),
        child: const Icon(Icons.download_rounded, color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;

            if (isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KeyedSubtree(key: _resumeKey, child: _buildTerritoryHeader(title, displayCode)),
                          const SizedBox(height: 24),
                          _buildContentSummarySection(hasResume, resumeStr, descStr),
                          const SizedBox(height: 24),
                          KeyedSubtree(key: _monographieKey, child: _buildDownloadButton(hasFile)),
                          const SizedBox(height: 36),
                          KeyedSubtree(
                            key: _territoiresKey,
                            child: isCommune ? _buildParentDistrictSection() : _buildCommunesAffilieesSection(),
                          ),
                          const SizedBox(height: 36),
                          KeyedSubtree(key: _stdKey, child: _buildStdExpertisesSection()),
                          const SizedBox(height: 36),
                          KeyedSubtree(key: _actuKey, child: _buildActualitesSection(isCommune)),
                          const SizedBox(height: 36),
                          KeyedSubtree(key: _projKey, child: _buildProjetsSection(isCommune)),
                          const SizedBox(height: 36),
                          KeyedSubtree(key: _docKey, child: _buildDocumentsSection(isCommune)),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),

                    const SizedBox(width: 32),

                    // Right Column: Leaflet Map + Anchors Box
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 320,
                              decoration: BoxDecoration(
                                color: _cardBg(isDark),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _border(isDark)),
                              ),
                              child: MonographieMapWidget(
                                types: widget.type,
                                id: widget.id,
                                height: 320,
                                heightDiv: 320,
                                getTerritoryByFormattedId: _getTerritoryByFormattedId,
                                territoireName: widget.territoire,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: _cardBg(isDark),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border(isDark)),
                            ),
                            child: Column(
                              children: [
                                _anchorMenuItem("# ${context.tr('desc')}", () => _scrollToKey(_resumeKey), isDark),
                                Divider(height: 1, color: _border(isDark)),
                                _anchorMenuItem("# ${context.tr('monograp')}", () => _scrollToKey(_monographieKey), isDark),
                                Divider(height: 1, color: _border(isDark)),
                                _anchorMenuItem(isCommune ? "# ${context.tr('district')}" : "# ${context.tr('stats_communes_label')}", () => _scrollToKey(_territoiresKey), isDark),
                                Divider(height: 1, color: _border(isDark)),
                                _anchorMenuItem("# ${context.tr('nav_bar.offres')}", () => _scrollToKey(_stdKey), isDark),
                                Divider(height: 1, color: _border(isDark)),
                                _anchorMenuItem("# ${context.tr('nav_bar.actualites')}", () => _scrollToKey(_actuKey), isDark),
                                Divider(height: 1, color: _border(isDark)),
                                _anchorMenuItem("# ${context.tr('nav_bar.projets')}", () => _scrollToKey(_projKey), isDark),
                                Divider(height: 1, color: _border(isDark)),
                                _anchorMenuItem("# ${context.tr('nav_bar.documents')}", () => _scrollToKey(_docKey), isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile Layout
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: _cardBg(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border(isDark)),
                      ),
                      child: MonographieMapWidget(
                        types: widget.type,
                        id: widget.id,
                        height: 220,
                        heightDiv: 220,
                        getTerritoryByFormattedId: _getTerritoryByFormattedId,
                        territoireName: widget.territoire,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTerritoryHeader(title, displayCode),
                  const SizedBox(height: 20),
                  _buildContentSummarySection(hasResume, resumeStr, descStr),
                  const SizedBox(height: 20),
                  _buildDownloadButton(hasFile),
                  const SizedBox(height: 32),
                  if (isCommune) _buildParentDistrictSection() else _buildCommunesAffilieesSection(),
                  const SizedBox(height: 32),
                  _buildStdExpertisesSection(),
                  const SizedBox(height: 32),
                  _buildActualitesSection(isCommune),
                  const SizedBox(height: 32),
                  _buildProjetsSection(isCommune),
                  const SizedBox(height: 32),
                  _buildDocumentsSection(isCommune),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers & Sub-widgets ───────────────────────────────────────────────────
  Widget _buildTerritoryHeader(String title, String displayCode) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E2C44) : const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kGreen, letterSpacing: 0.5),
          ),
          if (displayCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C273C) : const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF2B3A54) : const Color(0xFFC8E6C9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Code: ", style: TextStyle(fontSize: 13, color: _textMuted(isDark))),
                  Text(displayCode, style: TextStyle(fontFamily: 'monospace', fontSize: 13.5, fontWeight: FontWeight.bold, color: _textMain(isDark))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSummarySection(bool hasResume, String resumeStr, String descStr) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (hasResume) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border(isDark)),
        ),
        child: Text(
          resumeStr,
          style: TextStyle(fontSize: 14.5, height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
        ),
      );
    } else if (descStr.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border(isDark)),
        ),
        child: Text(
          descStr,
          style: TextStyle(fontSize: 14.5, height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text("Aucun detail", style: TextStyle(fontSize: 14, color: _textMuted(isDark), fontStyle: FontStyle.italic)),
      );
    }
  }

  Widget _buildDownloadButton(bool hasFile) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color disabledBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color disabledFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasFile ? _kGreen : disabledBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: hasFile ? handleDownload : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(hasFile ? Icons.download_rounded : Icons.lock_outline_rounded, color: hasFile ? Colors.white : disabledFg, size: 18),
                const SizedBox(width: 10),
                Text(
                  context.tr('tel_monog'),
                  style: TextStyle(color: hasFile ? Colors.white : disabledFg, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunesAffilieesSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 600;
    final bool isDesktop = w >= 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.account_balance_outlined, context.tr('stats_communes_label'), isDark),
        const SizedBox(height: 16),
        if (loadingCommunes)
          const CircularProgressIndicator(color: _kGreen)
        else if (communesError != null)
          Text(communesError!, style: const TextStyle(color: Colors.red))
        else if (districtCommunes.isEmpty)
          Text("Aucune commune affiliée.", style: TextStyle(color: _textMuted(isDark), fontSize: 13.5))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : (isDesktop ? 3 : 2),
              mainAxisExtent: 36,
              crossAxisSpacing: 16,
              mainAxisSpacing: 8,
            ),
            itemCount: districtCommunes.length,
            itemBuilder: (context, index) {
              final c = districtCommunes[index];
              final name = (c['name'] ?? c['nom'] ?? "Commune").toString().trim();
              final code = (c['formatted_id'] ?? c['code'] ?? c['id'] ?? '').toString();
              return Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    if (code.isNotEmpty) {
                      context.go('/monographie/communes/${Uri.encodeComponent(name)}/$code');
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: _kGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildParentDistrictSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.location_city_outlined, context.tr('district'), isDark),
        const SizedBox(height: 16),
        if (loadingParentDistrict)
          const CircularProgressIndicator(color: _kGreen)
        else if (parentDistrictError != null)
          Text(parentDistrictError!, style: const TextStyle(color: Colors.red))
        else if (parentDistrict != null)
          InkWell(
            onTap: () {
              final code = parentDistrict!["formatted_id"] ?? "";
              final name = parentDistrict!["name"] ?? "District";
              if (code.isNotEmpty) {
                context.go('/monographie/districts/${Uri.encodeComponent(name.toString())}/$code');
              }
            },
            child: Text(
              (parentDistrict!["name"] ?? "District").toString(),
              style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          )
        else
          Text("Aucun district parent disponible.", style: TextStyle(color: _textMuted(isDark), fontSize: 13.5)),
      ],
    );
  }

  String _buildFilteredUrl(String basePath) {
    if (widget.id == null || widget.id!.isEmpty) return basePath;

    final isCommune = widget.type?.contains("commune") == true;
    final nameParam = Uri.encodeComponent(widget.territoire ?? '');

    if (isCommune) {
      String url = '$basePath?communeId=${widget.id}&communeName=$nameParam';
      if (parentDistrict != null) {
        final pId = parentDistrict!['formatted_id']?.toString() ?? parentDistrict!['id']?.toString();
        if (pId != null && pId.isNotEmpty) {
          url += '&districtId=$pId';
        }
        final pName = parentDistrict!['name']?.toString() ?? parentDistrict!['nom']?.toString();
        if (pName != null && pName.isNotEmpty) {
          url += '&districtName=${Uri.encodeComponent(pName)}';
        }
      }
      return url;
    } else {
      return '$basePath?districtId=${widget.id}&districtName=$nameParam';
    }
  }

  Widget _buildStdExpertisesSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.layers_outlined, context.tr('nav_bar.offres'), isDark),
        const SizedBox(height: 16),
        if (loadingStdExpertises)
          const CircularProgressIndicator(color: _kGreen)
        else if (stdExpertises.isEmpty)
          Center(
            child: Column(
              children: [
                Text("Aucune expertise STD disponible pour ce territoire.", style: TextStyle(color: _textMuted(isDark), fontSize: 13.5, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                _greenActionBtn("Voir plus d'offres", () => context.go(_buildFilteredUrl('/offres-appui'))),
              ],
            ),
          )
        else
          Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stdExpertises.map((std) {
                  final name = _getLocalizedText(std['nom'] ?? std['name'] ?? std['title']);
                  final finalName = name.isEmpty ? 'STD' : name;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _cardBg(isDark),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border(isDark)),
                    ),
                    child: Text(finalName, style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Center(child: _greenActionBtn("Voir plus d'offres", () => context.go(_buildFilteredUrl('/offres-appui')))),
            ],
          ),
      ],
    );
  }

  Widget _buildActualitesSection(bool isCommune) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.rss_feed_rounded, context.tr('nav_bar.actualites'), isDark),
        const SizedBox(height: 20),
        if (loadingActu)
          const CircularProgressIndicator(color: _kGreen)
        else if (actualites.isEmpty)
          Center(
            child: Column(
              children: [
                Text("Aucune actualité disponible pour ce territoire.", style: TextStyle(color: _textMuted(isDark), fontSize: 13.5, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                _greenActionBtn("Voir plus d'articles", () => context.go(_buildFilteredUrl('/actualites'))),
              ],
            ),
          )
        else
          Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actualites.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _actuCard(actualites[i], isDark),
              ),
              const SizedBox(height: 16),
              Center(child: _greenActionBtn("Voir plus d'articles", () => context.go(_buildFilteredUrl('/actualites')))),
            ],
          ),
      ],
    );
  }

  Widget _buildProjetsSection(bool isCommune) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.inventory_2_outlined, context.tr('nav_bar.projets'), isDark),
        const SizedBox(height: 20),
        if (loadingProjects)
          const CircularProgressIndicator(color: _kGreen)
        else if (projectResources.isEmpty)
          Center(
            child: Column(
              children: [
                Text("Aucun projet disponible pour ce territoire.", style: TextStyle(color: _textMuted(isDark), fontSize: 13.5, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                _greenActionBtn("Voir plus de projets", () => context.go(_buildFilteredUrl('/officeprojet'))),
              ],
            ),
          )
        else
          Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectResources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _projectCard(projectResources[i], isDark),
              ),
              const SizedBox(height: 16),
              Center(child: _greenActionBtn("Voir plus de projets", () => context.go(_buildFilteredUrl('/officeprojet')))),
            ],
          ),
      ],
    );
  }

  Widget _buildDocumentsSection(bool isCommune) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.description_outlined, context.tr('nav_bar.documents'), isDark),
        const SizedBox(height: 20),
        if (loadingDocuments)
          const CircularProgressIndicator(color: _kGreen)
        else if (documentResources.isEmpty)
          Center(
            child: Column(
              children: [
                Text("Aucun document disponible pour ce territoire.", style: TextStyle(color: _textMuted(isDark), fontSize: 13.5, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                _greenActionBtn("Voir plus de documents", () => context.go(_buildFilteredUrl('/document'))),
              ],
            ),
          )
        else
          Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documentResources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _documentCard(documentResources[i], isDark),
              ),
              const SizedBox(height: 16),
              Center(child: _greenActionBtn("Voir plus de documents", () => context.go(_buildFilteredUrl('/document')))),
            ],
          ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textMain(isDark), letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _anchorMenuItem(String label, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: _textMain(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _greenActionBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
    );
  }

  Widget _actuCard(Map<String, dynamic> actu, bool isDark) {
    final title = _cleanText(actu['title'] ?? actu['titre']);
    final finalTitle = title.isEmpty ? 'Sans titre' : title;
    final desc = _cleanText(actu['description'] ?? actu['content'] ?? actu['contenu']);
    final category = _cleanText(actu['category'] ?? actu['type']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kGreen)),
            ),
            const SizedBox(height: 8),
          ],
          Text(finalTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textMain(isDark))),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: _textMuted(isDark), height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _projectCard(Map<String, dynamic> proj, bool isDark) {
    final rawName = proj['name'] ?? proj['nom'] ?? proj['title'];
    final name = _cleanText(rawName);
    final finalName = name.isEmpty ? 'Projet' : name;
    final status = _cleanText(proj['status'] ?? proj['statut']);
    final desc = _cleanText(proj['description'] ?? proj['resume']);
    final budget = (proj['budget'] ?? '').toString();
    final responsable = (proj['responsable'] ?? proj['manager'] ?? '').toString();
    final startDate = (proj['startDate'] ?? proj['date_debut'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: _kGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(finalName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textMain(isDark))),
              ),
              if (status.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ],
          ),
          if (startDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 13, color: _textMuted(isDark)),
                const SizedBox(width: 6),
                Text(startDate, style: TextStyle(fontSize: 12, color: _textMuted(isDark))),
              ],
            ),
          ],
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : Colors.black54, height: 1.4)),
          ],
          if (budget.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text("Budget : $budget", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kGreen)),
          ],
          if (responsable.isNotEmpty && responsable != "Non spécifié") ...[
            const SizedBox(height: 6),
            Text("Responsable: $responsable", style: TextStyle(fontSize: 12, color: _textMuted(isDark))),
          ],
        ],
      ),
    );
  }

  Widget _documentCard(Map<String, dynamic> doc, bool isDark) {
    final title = _cleanText(doc['title'] ?? doc['name'] ?? doc['nom']);
    final finalTitle = title.isEmpty ? 'Document sans titre' : title;
    final desc = _cleanText(doc['description'] ?? doc['resume']);
    final filename = (doc['filename'] ?? doc['filepath'] ?? doc['file'] ?? '').toString();
    final type = _cleanText(doc['type'] ?? doc['category']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: _kGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(finalTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textMain(isDark))),
              ),
              if (type.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _border(isDark), borderRadius: BorderRadius.circular(6)),
                  child: Text(type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _textMuted(isDark))),
                ),
              ],
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: _textMuted(isDark), height: 1.4)),
          ],
          if (filename.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final cleanPath = filename.startsWith('/') ? filename.substring(1) : filename;
                final downloadUrl = '$apiUrl/serviceupload/file/${cleanPath.replaceAll('/', '%2F')}';
                try {
                  final res = await http.get(Uri.parse(downloadUrl));
                  if (res.statusCode == 200 && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Téléchargement du document réussi"),
                        backgroundColor: _kGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (_) {}
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: 16, color: _kGreen),
                  SizedBox(width: 6),
                  Text("Télécharger le document", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kGreen)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
