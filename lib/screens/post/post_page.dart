import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/publication/blog_post_widget.dart';

// ─── Couleurs principales ────────────────────────────────────────────────────
const _kGreen = Color(0xFF098E00);
const _kGreenDark = Color(0xFF056E00);

// ─── Modèles de données ──────────────────────────────────────────────────────
class EventModel {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String? endDate;
  final String visibility;
  final String? imageUrl;
  final List<String> theme;
  final String communeId;
  final String eventType;
  final String? districtId;
  final String? langage;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.visibility,
    this.imageUrl,
    required this.theme,
    required this.communeId,
    required this.eventType,
    this.districtId,
    this.langage,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      visibility: json['visibility'] ?? '',
      imageUrl: json['imageUrl'],
      theme: json['theme'] != null ? List<String>.from(json['theme']) : [],
      communeId: json['communeId'] ?? '',
      eventType: json['eventType'] ?? '',
      districtId: json['districtId'],
      langage: json['langage'],
    );
  }
}

class TerritoryModel {
  final String formattedId;
  final String? name;
  final String? nom;

  TerritoryModel({required this.formattedId, this.name, this.nom});

  factory TerritoryModel.fromJson(Map<String, dynamic> json) {
    return TerritoryModel(
      formattedId: json['formatted_id'] ?? '',
      name: json['name'],
      nom: json['nom'],
    );
  }

  String get displayName => name ?? nom ?? '';
}

class PostPageWidget extends StatefulWidget {
  final String baseUrl;
  final Future<List<TerritoryModel>> Function() getCommunesBasic;
  final Future<List<TerritoryModel>> Function() getDistrictsBasic;

  const PostPageWidget({
    super.key,
    required this.baseUrl,
    required this.getCommunesBasic,
    required this.getDistrictsBasic,
  });

  @override
  State<PostPageWidget> createState() => _PostPageWidgetState();
}

class _PostPageWidgetState extends State<PostPageWidget>
    with SingleTickerProviderStateMixin {
  List<EventModel> events = [];
  bool loading = false;
  String searchTerm = '';
  String selectedCommune = '';
  String selectedDistrict = '';
  String selectedTheme = '';
  String selectedDateFilter = '';

  String districtSearch = '';
  String communeSearch = '';
  String themeSearch = '';
  bool showDistrictDropdown = false;
  bool showCommuneDropdown = false;
  bool showThemeDropdown = false;

  String customStartDate = '';
  String customEndDate = '';
  bool showCustomDateInputs = false;

  int page = 1;
  int total = 0;
  final int limit = 12;
  bool showFilters = false;

  List<TerritoryModel> communes = [];
  List<TerritoryModel> districts = [];
  List<String> themes = [];
  bool loadingFilters = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _fetchFilterData();
    _fetchEvents();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFilterData() async {
    setState(() => loadingFilters = true);
    try {
      final communesData = await widget.getCommunesBasic();
      final districtsData = await widget.getDistrictsBasic();

      Set<String> allThemes = {};
      try {
        final res = await http.get(
          Uri.parse(
            '${widget.baseUrl}/servicepublication/events/dispositif-district?limit=100&page=1',
          ),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          List eventsList = data['data'] ?? [];
          for (var e in eventsList) {
            if (e['theme'] is List) {
              for (var t in e['theme']) {
                allThemes.add(t.toString());
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Erreur thèmes: $e');
      }

      if (!mounted) return;
      setState(() {
        communes = communesData;
        districts = districtsData;
        themes = allThemes.toList()..sort();
      });
    } catch (e) {
      debugPrint('Erreur chargement filtres: $e');
    } finally {
      if (mounted) {
        setState(() => loadingFilters = false);
      }
    }
  }

  Future<void> _fetchEvents() async {
    setState(() => loading = true);
    try {
      String url =
          '${widget.baseUrl}/servicepublication/events/dispositif-district?limit=$limit&page=$page';
      if (searchTerm.isNotEmpty) url += '&search=$searchTerm';
      if (selectedCommune.isNotEmpty) url += '&communeId=$selectedCommune';
      if (selectedDistrict.isNotEmpty) url += '&districtId=$selectedDistrict';
      if (selectedTheme.isNotEmpty) url += '&theme=$selectedTheme';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List eventsList = data['data'] ?? [];
        List<EventModel> fetchedEvents =
            eventsList.map((e) => EventModel.fromJson(e)).toList();

        fetchedEvents.sort(
          (a, b) => DateTime.parse(b.startDate).compareTo(
            DateTime.parse(a.startDate),
          ),
        );

        if (!mounted) return;
        setState(() {
          events = fetchedEvents;
          total = data['total'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement événements: $e');
      if (mounted) {
        setState(() => events = []);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  List<EventModel> _filterByDate(List<EventModel> eventList) {
    if (selectedDateFilter.isEmpty &&
        customStartDate.isEmpty &&
        customEndDate.isEmpty) {
      return eventList;
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    return eventList.where((event) {
      DateTime eventDate = DateTime.parse(event.startDate);
      eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);

      if (selectedDateFilter == 'custom') {
        if (customStartDate.isNotEmpty && customEndDate.isNotEmpty) {
          DateTime start = DateTime.parse(customStartDate);
          DateTime end = DateTime.parse(customEndDate);
          end = DateTime(end.year, end.month, end.day, 23, 59, 59);
          return eventDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              eventDate.isBefore(end.add(const Duration(seconds: 1)));
        } else if (customStartDate.isNotEmpty) {
          DateTime start = DateTime.parse(customStartDate);
          return eventDate.isAfter(start.subtract(const Duration(seconds: 1)));
        } else if (customEndDate.isNotEmpty) {
          DateTime end = DateTime.parse(customEndDate);
          end = DateTime(end.year, end.month, end.day, 23, 59, 59);
          return eventDate.isBefore(end.add(const Duration(seconds: 1)));
        }
      }

      if (selectedDateFilter == 'week') {
        return eventDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      } else if (selectedDateFilter == 'month') {
        return eventDate.isAfter(
          startOfMonth.subtract(const Duration(days: 1)),
        );
      } else if (selectedDateFilter == 'today') {
        return eventDate.year == now.year &&
            eventDate.month == now.month &&
            eventDate.day == now.day;
      }
      return true;
    }).toList();
  }

  void _clearAllFilters() {
    setState(() {
      selectedCommune = '';
      selectedDistrict = '';
      selectedTheme = '';
      selectedDateFilter = '';
      districtSearch = '';
      communeSearch = '';
      themeSearch = '';
      customStartDate = '';
      customEndDate = '';
      showCustomDateInputs = false;
      page = 1;
    });
    _fetchEvents();
  }

  bool get hasActiveFilters =>
      selectedDistrict.isNotEmpty ||
      selectedCommune.isNotEmpty ||
      selectedTheme.isNotEmpty ||
      selectedDateFilter.isNotEmpty;



  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredEvents = _filterByDate(events);
    final filteredDistricts = districts
        .where(
          (d) => d.displayName.toLowerCase().contains(
                districtSearch.toLowerCase(),
              ),
        )
        .toList();
    final filteredCommunes = communes
        .where(
          (c) => c.displayName.toLowerCase().contains(
                communeSearch.toLowerCase(),
              ),
        )
        .toList();
    final filteredThemes = themes
        .where(
          (t) => t.toLowerCase().contains(themeSearch.toLowerCase()),
        )
        .toList();

    return FadeTransition(
      opacity: _fadeIn,
      child: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kGreen, _kGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.newspaper_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actualités & Événements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Informations, annonces officielles et initiatives',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Barre de recherche flottante
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => searchTerm = val);
                        _fetchEvents();
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une actualité...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _kGreen,
                          size: 22,
                        ),
                        suffixIcon: searchTerm.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => searchTerm = '');
                                  _fetchEvents();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Barre Filtres & Compteur ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Bouton Filtres avec animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: showFilters
                            ? const LinearGradient(
                                colors: [_kGreen, _kGreenDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: showFilters
                            ? null
                            : (isDarkMode
                                ? const Color(0xFF1E293B)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: showFilters
                              ? Colors.transparent
                              : (isDarkMode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                        ),
                        boxShadow: showFilters
                            ? [
                                BoxShadow(
                                  color: _kGreen.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              setState(() => showFilters = !showFilters),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: showFilters
                                      ? Colors.white
                                      : (isDarkMode
                                          ? Colors.grey.shade300
                                          : const Color(0xFF475569)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  showFilters ? 'Masquer' : 'Filtres',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: showFilters
                                        ? Colors.white
                                        : (isDarkMode
                                            ? Colors.grey.shade300
                                            : const Color(0xFF475569)),
                                  ),
                                ),
                                if (hasActiveFilters) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: showFilters
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : _kGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      [
                                            selectedDistrict.isNotEmpty,
                                            selectedCommune.isNotEmpty,
                                            selectedTheme.isNotEmpty,
                                            selectedDateFilter.isNotEmpty,
                                          ]
                                          .where((b) => b)
                                          .length
                                          .toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _clearAllFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Réinitialiser',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(width: 16),

                    // Compteur de résultats
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.article_rounded,
                            size: 14,
                            color: _kGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$total article${total > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.grey.shade300
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Panneau Filtres ──────────────────────────────────────────────────
          if (showFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: _kGreen,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Filtres avancés',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Filtre Date
                        _filterLabel('Période', Icons.calendar_today_rounded),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _dateChip('Aujourd\'hui', 'today'),
                            _dateChip('Cette semaine', 'week'),
                            _dateChip('Ce mois', 'month'),
                            _dateChip('Personnalisé', 'custom'),
                            if (selectedDateFilter.isNotEmpty)
                              _dateChip('Toutes les dates', ''),
                          ],
                        ),
                        if (showCustomDateInputs) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _modernTextField(
                                  label: 'Du (AAAA-MM-JJ)',
                                  onChanged: (val) =>
                                      setState(() => customStartDate = val),
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _modernTextField(
                                  label: 'Au (AAAA-MM-JJ)',
                                  onChanged: (val) =>
                                      setState(() => customEndDate = val),
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Filtre District
                        _filterLabel('District', Icons.location_city_rounded),
                        const SizedBox(height: 8),
                        _modernTextField(
                          label: selectedDistrict.isNotEmpty
                              ? districts
                                    .where((d) =>
                                        d.formattedId == selectedDistrict)
                                    .firstOrNull
                                    ?.displayName ??
                                  'Rechercher un district...'
                              : 'Rechercher un district...',
                          onChanged: (val) {
                            setState(() {
                              districtSearch = val;
                              selectedDistrict = '';
                            });
                          },
                          isDarkMode: isDarkMode,
                        ),
                        if (districtSearch.isNotEmpty &&
                            filteredDistricts.isNotEmpty)
                          _dropdownList(
                            items: filteredDistricts
                                .map((d) => d.displayName)
                                .toList(),
                            onSelect: (i) {
                              setState(() {
                                selectedDistrict =
                                    filteredDistricts[i].formattedId;
                                districtSearch = '';
                              });
                              _fetchEvents();
                            },
                            isDarkMode: isDarkMode,
                          ),
                        const SizedBox(height: 16),

                        // Filtre Commune
                        _filterLabel('Commune', Icons.place_rounded),
                        const SizedBox(height: 8),
                        _modernTextField(
                          label: selectedCommune.isNotEmpty
                              ? communes
                                    .where((c) =>
                                        c.formattedId == selectedCommune)
                                    .firstOrNull
                                    ?.displayName ??
                                  'Rechercher une commune...'
                              : 'Rechercher une commune...',
                          onChanged: (val) {
                            setState(() {
                              communeSearch = val;
                              selectedCommune = '';
                            });
                          },
                          isDarkMode: isDarkMode,
                        ),
                        if (communeSearch.isNotEmpty &&
                            filteredCommunes.isNotEmpty)
                          _dropdownList(
                            items: filteredCommunes
                                .map((c) => c.displayName)
                                .toList(),
                            onSelect: (i) {
                              setState(() {
                                selectedCommune =
                                    filteredCommunes[i].formattedId;
                                communeSearch = '';
                              });
                              _fetchEvents();
                            },
                            isDarkMode: isDarkMode,
                          ),
                        const SizedBox(height: 16),

                        // Filtre Thème
                        _filterLabel('Thème', Icons.label_rounded),
                        const SizedBox(height: 8),
                        _modernTextField(
                          label: selectedTheme.isNotEmpty
                              ? selectedTheme
                              : 'Rechercher un thème...',
                          onChanged: (val) {
                            setState(() {
                              themeSearch = val;
                              selectedTheme = '';
                            });
                          },
                          isDarkMode: isDarkMode,
                        ),
                        if (themeSearch.isNotEmpty && filteredThemes.isNotEmpty)
                          _dropdownList(
                            items: filteredThemes,
                            onSelect: (i) {
                              setState(() {
                                selectedTheme = filteredThemes[i];
                                themeSearch = '';
                              });
                              _fetchEvents();
                            },
                            isDarkMode: isDarkMode,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Chips filtres actifs ─────────────────────────────────────────────
          if (hasActiveFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (selectedDistrict.isNotEmpty)
                      _activeFilterChip(
                        'District: ${districts.where((d) => d.formattedId == selectedDistrict).firstOrNull?.displayName ?? selectedDistrict}',
                        () => setState(() => selectedDistrict = ''),
                      ),
                    if (selectedCommune.isNotEmpty)
                      _activeFilterChip(
                        'Commune: ${communes.where((c) => c.formattedId == selectedCommune).firstOrNull?.displayName ?? selectedCommune}',
                        () => setState(() => selectedCommune = ''),
                      ),
                    if (selectedTheme.isNotEmpty)
                      _activeFilterChip(
                        'Thème: $selectedTheme',
                        () => setState(() => selectedTheme = ''),
                      ),
                    if (selectedDateFilter.isNotEmpty)
                      _activeFilterChip(
                        'Date: ${_dateFilterLabel(selectedDateFilter)}',
                        () => setState(() {
                          selectedDateFilter = '';
                          showCustomDateInputs = false;
                        }),
                      ),
                  ],
                ),
              ),
            ),

          // ── Liste des Événements ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kGreen, _kGreenDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.newspaper_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    filteredEvents.isNotEmpty
                        ? '$total actualité${total > 1 ? 's' : ''} trouvée${total > 1 ? 's' : ''}'
                        : 'Actualités',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (loading && page == 1)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _kGreen),
                    SizedBox(height: 14),
                    Text(
                      'Chargement des actualités...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredEvents.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune actualité trouvée',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Essayez de modifier vos critères de recherche',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = filteredEvents[index];
                    return BlogPostWidget(
                      id: event.id,
                      titre: event.title,
                      date: event.startDate,
                      description: event.description,
                      theme: event.theme,
                      image: event.imageUrl,
                      eventType: event.eventType.isNotEmpty ? event.eventType : null,
                      baseUrl: widget.baseUrl,
                    );
                  },
                  childCount: filteredEvents.length,
                ),
              ),
            ),

          // ── Bouton Voir Plus ─────────────────────────────────────────────────
          if (filteredEvents.isNotEmpty && filteredEvents.length < total)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [_kGreen, _kGreenDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kGreen.withValues(alpha: 0.3),
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
                      onTap: loading
                          ? null
                          : () {
                              setState(() => page++);
                              _fetchEvents();
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.expand_more_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Voir plus d\'articles',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }



  // ─── Helpers UI ──────────────────────────────────────────────────────────────
  Widget _filterLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kGreen),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kGreen,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _dateChip(String label, String value) {
    final selected = selectedDateFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDateFilter = value;
          showCustomDateInputs = value == 'custom';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kGreen : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _modernTextField({
    required String label,
    required Function(String) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _dropdownList({
    required List<String> items,
    required Function(int) onSelect,
    required bool isDarkMode,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  items[index],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kGreen,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: _kGreen),
          ),
        ],
      ),
    );
  }

  String _dateFilterLabel(String filter) {
    switch (filter) {
      case 'today':
        return 'Aujourd\'hui';
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'custom':
        return 'Personnalisé';
      default:
        return filter;
    }
  }
}