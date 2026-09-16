import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localization.dart';
import '../../providers/auth_provider.dart';
import '../../services/entite_service.dart';
import '../../services/event_service.dart';
import '../../services/project_service.dart';
import '../../services/territory_service.dart';
import '../../services/user_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/home/home_alerts_banner.dart'; // Étape 3 : widget isolé
import '../../widgets/weather/modern_weather_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Système de Breakpoints Responsive ────────────────────────────────────────
class _Bp {
  static bool isMobileSmall(double w) => w < 380;
  static bool isMobile(double w) => w < 600;
  static bool isTablet(double w) => w >= 600 && w < 1024;
  static bool isDesktop(double w) => w >= 1024;

  static double hPad(double w) {
    if (isMobileSmall(w)) return 14;
    if (isMobile(w)) return 18;
    if (isTablet(w)) return 28;
    return 40;
  }

  static double vPad(double w) {
    if (isMobile(w)) return 18;
    if (isTablet(w)) return 24;
    return 32;
  }

  static double sectionGap(double w) {
    if (isMobile(w)) return 20;
    return 28;
  }

  static double quickCardW(double w) {
    if (isMobileSmall(w)) return (w - 28 - 12);
    if (isMobile(w)) return (w - 36 - 12) * 0.72;
    if (isTablet(w)) return 220;
    return 230;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // ── Actualités ─────────────────────────────────────────────────────────────
  final PageController _newsPageController = PageController(
    viewportFraction: 0.93,
  );
  int _currentNewsPage = 0;
  bool _loadingNews = false;
  int _newsTotal = 0;
  List<Map<String, dynamic>> _newsItems = [];
  Timer? _newsTimer;

  // ── Recherche Globale ─────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSearchFilter = 'Tous';

  // ── Alertes & Notifications ────────────────────────────────────────────────
  // ÉTAPE 3 : Les alertes sont maintenant gérées par HomeAlertsBanner (widget isolé)
  // Plus besoin de _showAlertBanner, _currentAlertIndex, _alertTimer ici

  // ── Statistiques Réelles ───────────────────────────────────────────────────
  int _communesCount = 1695;
  int _districtsCount = 119;
  int _usersCount = 4850;
  int _entitesCount = 320;
  int _documentsCount = 3240;
  bool _loadingStats = true;

  // ── Météo & Régions ────────────────────────────────────────────────────────
  String _selectedRegion = 'Analamanga';
  final Map<String, Map<String, dynamic>> _regionalInfos = {
    'Analamanga': {
      'temp': '24°C',
      'weather': 'Ensoleillé',
      'icon': Icons.wb_sunny_outlined,
      'communes': '137',
      'chefLieu': 'Antananarivo',
      'humi': '65%',
      'wind': '14 km/h',
      'actesValides': '98.5%',
    },
    'Vakinankaratra': {
      'temp': '21°C',
      'weather': 'Partiellement nuageux',
      'icon': Icons.cloud_outlined,
      'communes': '90',
      'chefLieu': 'Antsirabe',
      'humi': '70%',
      'wind': '18 km/h',
      'actesValides': '96.2%',
    },
    'Itasy': {
      'temp': '23°C',
      'weather': 'Ensoleillé',
      'icon': Icons.wb_sunny_rounded,
      'communes': '51',
      'chefLieu': 'Miarinarivo',
      'humi': '62%',
      'wind': '11 km/h',
      'actesValides': '97.8%',
    },
    'Bongolava': {
      'temp': '26°C',
      'weather': 'Beau temps',
      'icon': Icons.wb_sunny_outlined,
      'communes': '26',
      'chefLieu': 'Tsiroanomandidy',
      'humi': '58%',
      'wind': '15 km/h',
      'actesValides': '95.1%',
    },
    'Atsinanana': {
      'temp': '27°C',
      'weather': 'Averses modérées',
      'icon': Icons.grain_outlined,
      'communes': '82',
      'chefLieu': 'Toamasina',
      'humi': '82%',
      'wind': '22 km/h',
      'actesValides': '94.8%',
    },
    'Analanjirofo': {
      'temp': '28°C',
      'weather': 'Pluie tropicale',
      'icon': Icons.water_drop_outlined,
      'communes': '63',
      'chefLieu': 'Fenoarivo Atsinanana',
      'humi': '85%',
      'wind': '20 km/h',
      'actesValides': '93.9%',
    },
    'Alaotra-Mangoro': {
      'temp': '25°C',
      'weather': 'Nuageux',
      'icon': Icons.cloud_outlined,
      'communes': '82',
      'chefLieu': 'Ambatondrazaka',
      'humi': '75%',
      'wind': '13 km/h',
      'actesValides': '96.5%',
    },
    'Boeny': {
      'temp': '31°C',
      'weather': 'Très ensoleillé',
      'icon': Icons.wb_sunny_rounded,
      'communes': '43',
      'chefLieu': 'Mahajanga',
      'humi': '58%',
      'wind': '12 km/h',
      'actesValides': '97.1%',
    },
    'Sofia': {
      'temp': '30°C',
      'weather': 'Ensoleillé',
      'icon': Icons.wb_sunny_outlined,
      'communes': '108',
      'chefLieu': 'Antsohihy',
      'humi': '60%',
      'wind': '14 km/h',
      'actesValides': '94.2%',
    },
    'Betsiboka': {
      'temp': '33°C',
      'weather': 'Chaud & Clair',
      'icon': Icons.wb_sunny_rounded,
      'communes': '36',
      'chefLieu': 'Maevatanana',
      'humi': '48%',
      'wind': '10 km/h',
      'actesValides': '95.6%',
    },
    'Melaky': {
      'temp': '29°C',
      'weather': 'Beau temps',
      'icon': Icons.brightness_5_outlined,
      'communes': '32',
      'chefLieu': 'Maintirano',
      'humi': '62%',
      'wind': '16 km/h',
      'actesValides': '92.7%',
    },
    'Diana': {
      'temp': '28°C',
      'weather': 'Brise marine',
      'icon': Icons.wb_twilight_outlined,
      'communes': '60',
      'chefLieu': 'Antsiranana',
      'humi': '68%',
      'wind': '25 km/h',
      'actesValides': '98.0%',
    },
    'Sava': {
      'temp': '27°C',
      'weather': 'Averses dispersées',
      'icon': Icons.grain_outlined,
      'communes': '78',
      'chefLieu': 'Sambava',
      'humi': '80%',
      'wind': '19 km/h',
      'actesValides': '96.4%',
    },
    'Haute Matsiatra': {
      'temp': '20°C',
      'weather': 'Frais & Venteux',
      'icon': Icons.air_rounded,
      'communes': '84',
      'chefLieu': 'Fianarantsoa',
      'humi': '72%',
      'wind': '24 km/h',
      'actesValides': '97.5%',
    },
    'Amoron\'i Mania': {
      'temp': '22°C',
      'weather': 'Nuages épars',
      'icon': Icons.cloud_queue_rounded,
      'communes': '53',
      'chefLieu': 'Ambositra',
      'humi': '68%',
      'wind': '16 km/h',
      'actesValides': '96.0%',
    },
    'Vatovavy': {
      'temp': '26°C',
      'weather': 'Pluies légères',
      'icon': Icons.grain_outlined,
      'communes': '58',
      'chefLieu': 'Mananjary',
      'humi': '84%',
      'wind': '21 km/h',
      'actesValides': '93.5%',
    },
    'Fitovinany': {
      'temp': '26°C',
      'weather': 'Humide & Venteux',
      'icon': Icons.air_outlined,
      'communes': '76',
      'chefLieu': 'Manakara',
      'humi': '83%',
      'wind': '23 km/h',
      'actesValides': '94.0%',
    },
    'Atsimo-Atsinanana': {
      'temp': '25°C',
      'weather': 'Pluie modérée',
      'icon': Icons.water_drop_outlined,
      'communes': '90',
      'chefLieu': 'Farafangana',
      'humi': '86%',
      'wind': '22 km/h',
      'actesValides': '92.8%',
    },
    'Ihorombe': {
      'temp': '25°C',
      'weather': 'Ensoleillé',
      'icon': Icons.wb_sunny_outlined,
      'communes': '27',
      'chefLieu': 'Ihosy',
      'humi': '55%',
      'wind': '17 km/h',
      'actesValides': '95.0%',
    },
    'Menabe': {
      'temp': '30°C',
      'weather': 'Chaud & Sec',
      'icon': Icons.wb_sunny_rounded,
      'communes': '51',
      'chefLieu': 'Morondava',
      'humi': '52%',
      'wind': '18 km/h',
      'actesValides': '96.1%',
    },
    'Atsimo-Andrefana': {
      'temp': '29°C',
      'weather': 'Clair & Sec',
      'icon': Icons.brightness_5_outlined,
      'communes': '105',
      'chefLieu': 'Toliara',
      'humi': '50%',
      'wind': '16 km/h',
      'actesValides': '95.4%',
    },
    'Androy': {
      'temp': '28°C',
      'weather': 'Vent chaud & Sec',
      'icon': Icons.air_rounded,
      'communes': '51',
      'chefLieu': 'Ambovombe',
      'humi': '45%',
      'wind': '26 km/h',
      'actesValides': '91.8%',
    },
    'Anosy': {
      'temp': '26°C',
      'weather': 'Vents forts',
      'icon': Icons.air_outlined,
      'communes': '64',
      'chefLieu': 'Taolagnaro',
      'humi': '74%',
      'wind': '30 km/h',
      'actesValides': '94.5%',
    },
  };

  List<Map<String, dynamic>> _getModules(BuildContext context) => [
    {
      'title': context.tr('mod_monographie_title'),
      'description': context.tr('mod_monographie_desc'),
      'icon': Icons.map_outlined,
      'color': const Color(0xFF098E00),
      'gradient': [const Color(0xFF098E00), const Color(0xFF0dba00)],
      'path': '/monographie',
    },
    {
      'title': context.tr('mod_documentaire_title'),
      'description': context.tr('mod_documentaire_desc'),
      'icon': Icons.description_outlined,
      'color': const Color(0xFF1565C0),
      'gradient': [const Color(0xFF1565C0), const Color(0xFF1976D2)],
      'path': '/document',
    },
    {
      'title': context.tr('mod_projets_title'),
      'description': context.tr('mod_projets_desc'),
      'icon': Icons.business_center_outlined,
      'color': const Color(0xFF6A1B9A),
      'gradient': [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
      'path': '/officeprojet',
    },
    {
      'title': context.tr('mod_legalite_title'),
      'description': context.tr('mod_legalite_desc'),
      'icon': Icons.gavel_outlined,
      'color': const Color(0xFFE65100),
      'gradient': [const Color(0xFFE65100), const Color(0xFFEF6C00)],
      'path': '/das',
    },
  ];

  final List<Map<String, dynamic>> _partners = [
    {
      'name': 'Ministère de l\'Intérieur',
      'initials': 'MI',
      'image': 'assets/images/LogoMinistereInterieur.jpg',
      'fallbacks': ['assets/images/logo_ministere.jpg'],
      'url': 'https://mid.gov.mg/',
    },
    {
      'name': 'Mionjo',
      'initials': 'MJ',
      'image': 'assets/images/mionjo_logo.png',
      'fallbacks': ['assets/images/mionjo.png'],
      'url': 'https://mionjo.mg/',
    },
    {
      'name': 'Dispositif District',
      'initials': 'DD',
      'image': 'assets/images/logo_dd_v3.png',
      'fallbacks': ['assets/images/logo_dd.png', 'assets/images/DD.png'],
      'url': 'https://mid.gov.mg/',
    },
    {
      'name': 'PNUD',
      'initials': 'PN',
      'image': 'assets/images/PNUD-Logo-Blue.png',
      'fallbacks': [
        'assets/images/logo_pnud_blue.png',
        'assets/images/logo_pnud.png',
        'assets/images/LOGO-PNUD.png',
      ],
      'url': 'https://www.undp.org/fr/madagascar',
    },
    {
      'name': 'Université de Fianarantsoa',
      'initials': 'UF',
      'image': 'assets/images/logo universite.png',
      'fallbacks': ['assets/images/logo2.png'],
      'url': 'https://www.univ-fianarantsoa.mg/',
    },
  ];

  Future<void> _openPartnerUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Impossible d'ouvrir l'URL du partenaire: $url ($e)");
    }
  }

  @override
  void initState() {
    super.initState();
    // ── ÉTAPE 2 : Lancer d'abord la météo par défaut immédiatement ──────────
    // On affiche la météo de la région par défaut sans attendre GPS/IP (~0ms)
    // puis on lance la géolocalisation en arrière-plan.
    _initWeatherFast();
    // Lancer toutes les autres opérations en parallèle
    _fetchNews();
    _fetchRealKeyStats();
    // ÉTAPE 3 : _startAlertTimer() supprimé → géré par HomeAlertsBanner
    _loadCommuneCounts();
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    _searchController.dispose();
    _newsTimer?.cancel();
    // ÉTAPE 3 : _alertTimer supprimé → géré par HomeAlertsBanner
    super.dispose();
  }

  // ── Weather / Location ────────────────────────────────────────────────────
  Map<String, dynamic>? _weatherData;
  bool _loadingWeather = false;
  String _weatherLocationLabel = '';
  // Per-region commune counts fetched from TerritoryService
  Map<String, int> _communeCountsByRegion = {};

  Future<void> _fetchWeatherForRegion(String regionName) async {
    if (!mounted) return;
    setState(() => _loadingWeather = true);

    double? lat;
    double? lon;
    String label = regionName;

    final coords = WeatherService.regionCoordinates[regionName];
    if (coords != null) {
      lat = coords['lat'];
      lon = coords['lon'];
    }

    if (lat != null && lon != null) {
      final w = await WeatherService.getWeatherForCoords(lat, lon);
      if (mounted) {
        setState(() {
          _weatherData = w;
          _weatherLocationLabel = label;
          _loadingWeather = false;
        });
        return;
      }
    }

    if (mounted) setState(() => _loadingWeather = false);
  }

  // ── ÉTAPE 2 : Météo rapide sans blocage au démarrage ──────────────────────
  // Phase 1 : charge immédiatement la météo de la région par défaut (Analamanga)
  // Phase 2 : tente la géolocalisation GPS/IP en arrière-plan et met à jour
  Future<void> _initWeatherFast() async {
    if (!mounted) return;

    // Phase 1 — Affichage immédiat avec la région par défaut (0 délai)
    final defaultCoords = WeatherService.regionCoordinates[_selectedRegion];
    if (defaultCoords != null) {
      if (mounted) setState(() => _loadingWeather = true);
      final w = await WeatherService.getWeatherForCoords(
        defaultCoords['lat']!,
        defaultCoords['lon']!,
      );
      if (mounted) {
        setState(() {
          _weatherData = w;
          _weatherLocationLabel = _selectedRegion;
          _loadingWeather = false;
        });
      }
    }

    // Phase 2 — Géolocalisation en arrière-plan (n'affecte plus le chargement initial)
    _detectAndRefineLocation();
  }

  // Détection de la vraie position en arrière-plan (GPS ou IP), sans bloquer l'UI
  Future<void> _detectAndRefineLocation() async {
    double? lat;
    double? lon;
    String? label;

    // Tentative GPS (timeout réduit à 4s au lieu de 5s)
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,   // low = plus rapide
          timeLimit: const Duration(seconds: 4),
        );
        lat = pos.latitude;
        lon = pos.longitude;
        final nearestRegion = WeatherService.getNearestRegionName(lat, lon);
        if (_regionalInfos.containsKey(nearestRegion)) {
          label = '📍 $nearestRegion';
          if (mounted && _selectedRegion != nearestRegion) {
            setState(() => _selectedRegion = nearestRegion);
          }
        } else {
          label = '📍 Position GPS';
        }
      }
    } catch (_) {
      // GPS indisponible : on tente l'IP géolocalisation
    }

    // Fallback IP géolocalisation si pas de GPS
    if (lat == null || lon == null) {
      try {
        final ipRes = await WeatherService.ipGeolocation();
        if (ipRes != null) {
          if (ipRes.containsKey('latitude') && ipRes.containsKey('longitude')) {
            lat = (ipRes['latitude'] is num)
                ? (ipRes['latitude'] as num).toDouble()
                : double.tryParse(ipRes['latitude'].toString());
            lon = (ipRes['longitude'] is num)
                ? (ipRes['longitude'] as num).toDouble()
                : double.tryParse(ipRes['longitude'].toString());
          } else if (ipRes.containsKey('loc')) {
            final parts = (ipRes['loc'] as String).split(',');
            if (parts.length == 2) {
              lat = double.tryParse(parts[0]);
              lon = double.tryParse(parts[1]);
            }
          }
          if (lat != null && lon != null) {
            final nearestRegion = WeatherService.getNearestRegionName(lat, lon);
            if (_regionalInfos.containsKey(nearestRegion) &&
                mounted &&
                _selectedRegion != nearestRegion) {
              setState(() => _selectedRegion = nearestRegion);
            }
            label = ipRes['city']?.toString() ?? 'Localisation IP';
          }
        }
      } catch (_) {}
    }

    // Mettre à jour la météo avec la vraie position trouvée
    if (lat != null && lon != null && mounted) {
      final w = await WeatherService.getWeatherForCoords(lat, lon);
      if (mounted) {
        setState(() {
          _weatherData = w;
          _weatherLocationLabel = label ?? _selectedRegion;
        });
      }
    }
  }

  // Méthode conservée pour le changement de région manuel (dropdown)
  Future<void> _initWeather() async {
    await _initWeatherFast();
  }

  Future<void> _loadCommuneCounts() async {
    try {
      final communes = await TerritoryService.getCommunesBasic();
      if (communes == null) return;
      final Map<String, int> counts = {};
      for (final c in communes) {
        if (c == null) continue;
        String? regionName;
        if (c is Map) {
          // Try common keys that may contain region label
          regionName =
              c['region']?.toString() ??
              c['regionName']?.toString() ??
              c['region_label']?.toString() ??
              c['regionFormatted']?.toString();
          // Some services embed region as object
          if (regionName == null && c['region'] is Map) {
            regionName =
                (c['region'] as Map)['name']?.toString() ??
                (c['region'] as Map)['label']?.toString();
          }
        }
        if (regionName == null) continue;
        regionName = regionName.trim();
        counts[regionName] = (counts[regionName] ?? 0) + 1;
      }
      if (mounted) setState(() => _communeCountsByRegion = counts);
    } catch (e) {
      debugPrint('Erreur chargement communes par région: $e');
    }
  }



  // ── Helpers de traduction dynamique ─────────────────────────────────────
  String _translateSearchFilter(BuildContext context, String label) {
    if (label == 'Tous') return context.tr('search_tous');
    if (label == 'Territoires') return context.tr('search_territoires');
    if (label == 'Documents') return context.tr('search_documents');
    if (label == 'Entités') return context.tr('search_entites');
    if (label == 'Offres') return context.tr('search_offres');
    return label;
  }


  // ── ÉTAPE 3 : Timer alertes déplacé dans HomeAlertsBanner ─────────────────

  // ── Auto-défilement Actualités ─────────────────────────────────────────────
  void _startNewsAutoScroll() {
    _newsTimer?.cancel();
    if (_newsItems.length <= 1) return;
    _newsTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final nextPage = (_currentNewsPage + 1) % _newsItems.length;
      _newsPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // ── Récupération stats réelles (parallèle) ─────────────────────────────────
  Future<void> _fetchRealKeyStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    try {
      final results = await Future.wait([
        TerritoryService.getTerritoryCountsOnly(),
        UserService.getUsersCountOnly(),
        EntiteService.getEntites(),
        ProjectService.getProjects(limit: 1),
      ]);

      final territoireCounts = results[0] as Map<String, int>;
      final usersCount = results[1] as int;
      final entites = results[2] as List;
      final projectsRes = results[3] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          if ((territoireCounts['communes'] ?? 0) > 0) {
            _communesCount = territoireCounts['communes']!;
          }
          if ((territoireCounts['districts'] ?? 0) > 0) {
            _districtsCount = territoireCounts['districts']!;
          }
          if (usersCount > 0) _usersCount = usersCount;
          if (entites.isNotEmpty) _entitesCount = entites.length;
          final pagination = projectsRes['pagination'];
          final projTotal =
              pagination?['total'] ??
              pagination?['totalCount'] ??
              (projectsRes['projects'] is List
                  ? (projectsRes['projects'] as List).length
                  : 0);
          if (projTotal is int && projTotal > 0) _documentsCount = projTotal;
        });
      }
    } catch (e) {
      debugPrint("Erreur chiffres clés: $e");
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  void _performGlobalSearch(BuildContext context, String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      context.go('/monographie');
    } else {
      context.go('/monographie?q=${Uri.encodeComponent(cleanQuery)}');
    }
  }

  void _handleQuickAction(
    BuildContext context,
    Map<String, dynamic> action,
    AuthProvider? auth,
  ) {
    final String path = action['path'] as String;
    final bool requiresAuth = action['requiresAuth'] as bool? ?? false;
    final bool requiresAdmin = action['requiresAdmin'] as bool? ?? false;
    final bool isAuthenticated = auth?.isAuthenticated ?? false;
    final bool isAdmin =
        isAuthenticated &&
        (auth?.hasAnyRole([
              'SUPER_ADMIN',
              'ADMIN',
              'ADMINISTRATEUR',
              'CHEF_DISTRICT',
            ]) ??
            false);

    if (requiresAuth && !isAuthenticated) {
      _showSecurityAlert(
        context,
        title: "Connexion requise",
        message:
            "Vous devez être connecté pour accéder à \"${action['title']}\".",
        actionLabel: "Se connecter",
        onConfirm: () => context.go('/auth/login'),
      );
      return;
    }
    if (requiresAdmin && !isAdmin) {
      _showSecurityAlert(
        context,
        title: "Accès restreint",
        message: "\"${action['title']}\" est réservé aux administrateurs.",
        actionLabel: "Compris",
        onConfirm: null,
      );
      return;
    }
    context.go(path);
  }

  void _showSecurityAlert(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.red, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer", style: TextStyle(color: Colors.grey)),
          ),
          if (onConfirm != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF098E00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ── BUILD PRINCIPAL ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double screenW = mq.size.width;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTablet = _Bp.isTablet(screenW);
    final bool isDesktop = _Bp.isDesktop(screenW);

    AuthProvider? auth;
    try {
      auth = Provider.of<AuthProvider>(context);
    } catch (_) {}
    final bool isAuthenticated = auth?.isAuthenticated ?? false;

    final double hPad = _Bp.hPad(screenW);
    final double vPad = _Bp.vPad(screenW);
    final double gap = _Bp.sectionGap(screenW);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero
          _buildHeroSection(context, isDark, auth, screenW),
          SizedBox(height: gap),

          // 2. Recherche globale
          _buildGlobalSearchBar(context, isDark, screenW),
          SizedBox(height: gap),

          // 3. Alertes (widget isolé — son timer ne reconstruit plus la HomePage)
          HomeAlertsBanner(isDark: isDark, screenW: screenW),
          const SizedBox(height: 20),

          // 4. Raccourcis Métiers
          _buildQuickActionsSection(context, isDark, auth, screenW),
          SizedBox(height: gap),

          // 5. Statistiques Clés (grille adaptive)
          _buildAnimatedStatsSection(context, isDark, screenW),
          SizedBox(height: gap),

          // 6. Météo & Régions
          _buildRegionalWidget(context, isDark, screenW),
          SizedBox(height: gap),

          // 7. Actualités
          _buildNewsSection(context, isDark, screenW),
          SizedBox(height: gap),

          // 8. Modules
          if (isTablet || isDesktop)
            _buildModuleGrid(context, isDark, screenW)
          else
            _buildModuleList(context, isDark, screenW),
          SizedBox(height: gap),

          // 9. CTA
          _buildActionCard(context, isAuthenticated, screenW),
          SizedBox(height: gap),

          // 10. Partenaires
          _buildPartnersSection(context, isDark, screenW),
          SizedBox(height: vPad),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. HERO SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(
    BuildContext context,
    bool isDark,
    AuthProvider? auth,
    double w,
  ) {
    final userName = auth?.user?.userPseudo ?? '';
    final isAuth = auth?.isAuthenticated ?? false;
    final bool isMobile = _Bp.isMobile(w);
    final bool isSmall = _Bp.isMobileSmall(w);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 18 : (isMobile ? 22 : 28)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0B120E), const Color(0xFF112216)]
              : [const Color(0xFF0D7817), const Color(0xFF15A035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Décorations circulaires (cachées sur très petits écrans)
          if (!isSmall) ...[
            Positioned(top: -20, right: -12, child: _circle(110, 0.07)),
            Positioned(bottom: -26, left: -18, child: _circle(80, 0.05)),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuth && userName.isNotEmpty
                              ? "Bienvenue, $userName 👋"
                              : context.tr('home_welcome'),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmall ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Itantsoroka',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 26 : (isMobile ? 30 : 36),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSmall)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('home_mobile_app'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('home_hero_desc'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: isSmall ? 13 : 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              // Chips — 1 ligne scrollable sur mobile
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _heroChip(
                      Icons.analytics_outlined,
                      context.tr('home_stats_chip'),
                    ),
                    const SizedBox(width: 8),
                    _heroChip(
                      Icons.map_outlined,
                      context.tr('home_carto_chip'),
                    ),
                    const SizedBox(width: 8),
                    _heroChip(
                      Icons.shield_outlined,
                      context.tr('home_secu_chip'),
                    ),
                  ],
                ),
              ),
              // Boutons CTA — adaptatifs (pleine largeur sur mobile, côte à côte sur grand écran)
              LayoutBuilder(
                builder: (context, heroConstraints) {
                  final bool isCompact = isMobile || heroConstraints.maxWidth < 460;
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _heroPrimaryBtn(context),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _heroSecondaryBtn(context),
                        ),
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _heroPrimaryBtn(context),
                      _heroSecondaryBtn(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );

  Widget _heroChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _heroPrimaryBtn(BuildContext context) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      shadowColor: Colors.black26,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0D7817),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    onPressed: () => context.go('/monographie'),
    icon: const Icon(Icons.map_outlined, size: 18),
    label: Text(
      context.tr('home_access_monog'),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  Widget _heroSecondaryBtn(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white70, width: 1.5),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    onPressed: () => context.go('/officeprojet'),
    icon: const Icon(Icons.business_center_outlined, size: 18),
    label: Text(
      context.tr('home_see_projects'),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 2. BARRE DE RECHERCHE GLOBALE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGlobalSearchBar(BuildContext context, bool isDark, double w) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF098E00).withValues(alpha: isDark ? 0.3 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF098E00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF098E00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onSubmitted: (v) => _performGlobalSearch(context, v),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('home_search_placeholder'),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF098E00),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: _Bp.isMobile(w) ? 12 : 16,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  elevation: 0,
                ),
                onPressed: () =>
                    _performGlobalSearch(context, _searchController.text),
                child: Text(
                  _Bp.isMobile(w) ? "OK" : context.tr('home_search_btn'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Tous', 'Territoires', 'Documents', 'Entités', 'Offres'].map(
                    (label) {
                      final icons = [
                        Icons.apps_outlined,
                        Icons.map_outlined,
                        Icons.folder_outlined,
                        Icons.business_outlined,
                        Icons.work_outline,
                      ];
                      final idx = [
                        'Tous',
                        'Territoires',
                        'Documents',
                        'Entités',
                        'Offres',
                      ].indexOf(label);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _searchChip(label, icons[idx], isDark),
                      );
                    },
                  ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchChip(String label, IconData icon, bool isDark) {
    final selected = _selectedSearchFilter == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedSearchFilter = label);
        _performGlobalSearch(context, _searchController.text);
      },
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF098E00)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
            ),
            const SizedBox(width: 5),
            Text(
              _translateSearchFilter(context, label),
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. ALERTES — Voir widgets/home/home_alerts_banner.dart (HomeAlertsBanner)
  //    Timer isolé dans le widget → ne reconstruit plus toute la HomePage
  // ══════════════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════════════
  // 4. RACCOURCIS MÉTIERS — Responsive (grille 2 colonnes sur tablette)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActionsSection(
    BuildContext context,
    bool isDark,
    AuthProvider? auth,
    double w,
  ) {
    final actions = [
      {
        'title': context.tr('quick_affiliation_title'),
        'subtitle': context.tr('quick_affiliation_sub'),
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFF098E00),
        'path': '/admin/affiliation',
        'badge': 'Admin',
        'requiresAuth': true,
        'requiresAdmin': true,
      },
      {
        'title': context.tr('quick_territoire_title'),
        'subtitle': context.tr('quick_territoire_sub'),
        'icon': Icons.explore_rounded,
        'color': const Color(0xFF1565C0),
        'path': '/monographie',
        'badge': 'Territoire',
        'requiresAuth': false,
        'requiresAdmin': false,
      },
      {
        'title': context.tr('quick_offrestd_title'),
        'subtitle': context.tr('quick_offrestd_sub'),
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFF6A1B9A),
        'path': '/offrestd',
        'badge': 'STD',
        'requiresAuth': false,
        'requiresAdmin': false,
      },
      {
        'title': context.tr('quick_acte_title'),
        'subtitle': context.tr('quick_acte_sub'),
        'icon': Icons.gavel_rounded,
        'color': const Color(0xFFE65100),
        'path': '/soumission-acte',
        'badge': 'DAS',
        'requiresAuth': true,
        'requiresAdmin': false,
      },
      {
        'title': context.tr('quick_projet_title'),
        'subtitle': context.tr('quick_projet_sub'),
        'icon': Icons.campaign_rounded,
        'color': const Color(0xFF0284C7),
        'path': '/itantsorika/publier',
        'badge': 'Pub.',
        'requiresAuth': true,
        'requiresAdmin': false,
      },
      {
        'title': context.tr('quick_ged_title'),
        'subtitle': context.tr('quick_ged_sub'),
        'icon': Icons.folder_shared_rounded,
        'color': const Color(0xFF059669),
        'path': '/document',
        'badge': 'GED',
        'requiresAuth': false,
        'requiresAdmin': false,
      },
    ];

    final bool isTablet = _Bp.isTablet(w);
    final double cardW = _Bp.quickCardW(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context.tr('quick_actions_title'),
          context.tr('quick_actions_sub'),
          isDark,
          w,
        ),
        const SizedBox(height: 14),
        if (isTablet || _Bp.isDesktop(w))
          // Grille 3x2 sur tablette/desktop
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 120,
            ),
            itemCount: actions.length,
            itemBuilder: (ctx, i) => _quickActionCard(
              ctx,
              actions[i],
              auth,
              isDark,
              double.infinity,
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) =>
                  _quickActionCard(ctx, actions[i], auth, isDark, cardW),
            ),
          ),
      ],
    );
  }

  Widget _quickActionCard(
    BuildContext ctx,
    Map<String, dynamic> action,
    AuthProvider? auth,
    bool isDark,
    double cardW,
  ) {
    final Color color = action['color'] as Color;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: () => _handleQuickAction(ctx, action, auth),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: cardW == double.infinity ? null : cardW,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.3 : 0.16),
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      action['badge'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                action['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                action['subtitle'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. STATISTIQUES CLÉS — Grille Adaptive (2 colonnes mobile, 3 tablette, 5 desktop)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAnimatedStatsSection(
    BuildContext context,
    bool isDark,
    double w,
  ) {
    final stats = [
      {
        'label': context.tr('stats_communes_label'),
        'value': _communesCount.toDouble(),
        'suffix': '',
        'trend': 'Base API',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF098E00),
      },
      {
        'label': context.tr('stats_districts_label'),
        'value': _districtsCount.toDouble(),
        'suffix': '',
        'trend': '23 Régions',
        'icon': Icons.location_city_outlined,
        'color': const Color(0xFF1565C0),
      },
      {
        'label': context.tr('stats_users_label'),
        'value': _usersCount.toDouble(),
        'suffix': '',
        'trend': 'API Auth',
        'icon': Icons.people_outline_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'label': context.tr('stats_entites_label'),
        'value': _entitesCount.toDouble(),
        'suffix': '',
        'trend': 'STD & CTD',
        'icon': Icons.business_outlined,
        'color': const Color(0xFF6A1B9A),
      },
      {
        'label': context.tr('stats_documents_label'),
        'value': _documentsCount.toDouble(),
        'suffix': '',
        'trend': 'GED',
        'icon': Icons.folder_shared_outlined,
        'color': const Color(0xFFE65100),
      },
    ];

    int crossAxisCount = _Bp.isMobileSmall(w) ? 1 : (_Bp.isMobile(w) ? 2 : (_Bp.isTablet(w) ? 3 : 5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionHeader(
                context.tr('home_dashboard_title'),
                context.tr('home_dashboard_sub'),
                isDark,
                w,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF098E00),
                size: 20,
              ),
              onPressed: _fetchRealKeyStats,
              tooltip: context.tr('tooltip_refresh'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 125,
          ),
          itemCount: stats.length,
          itemBuilder: (ctx, i) {
            final stat = stats[i];
            final color = stat['color'] as Color;
            return RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            stat['icon'] as IconData,
                            color: color,
                            size: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            stat['trend'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_loadingStats)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF098E00),
                        ),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _AnimatedCounter(
                          endValue: stat['value'] as double,
                          suffix: stat['suffix'] as String,
                          style: TextStyle(
                            fontSize: _Bp.isMobileSmall(w) ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    Text(
                      stat['label'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. WIDGET MÉTÉO & RÉGIONS — Responsive plein écran
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRegionalWidget(BuildContext context, bool isDark, double w) {
    return Column(
      children: [
        ModernWeatherCard(
          weatherData: _weatherData,
          regionalFallback: _regionalInfos[_selectedRegion] ?? _regionalInfos['Analamanga']!,
          selectedRegion: _selectedRegion,
          availableRegions: _regionalInfos.keys.toList(),
          onRegionChanged: (v) {
            setState(() => _selectedRegion = v);
            _fetchWeatherForRegion(v);
          },
          onGpsPressed: () => _initWeather(),
          onRefreshPressed: () => _fetchWeatherForRegion(_selectedRegion),
          isLoading: _loadingWeather,
          locationLabel: _weatherLocationLabel,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _regionStats(
            _regionalInfos[_selectedRegion] ?? _regionalInfos['Analamanga']!,
          ),
        ),
      ],
    );
  }

  // legacy simple display removed (replaced by ModernWeatherCard)

  int? _findCommuneCountNormalized(String regionName) {
    final search = regionName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final entry in _communeCountsByRegion.entries) {
      final key = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (key == search || key.contains(search) || search.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  Widget _regionStats(Map<String, dynamic> data) {
    final dbCount = _communeCountsByRegion[_selectedRegion] ?? _findCommuneCountNormalized(_selectedRegion);
    final String communesDisplay = dbCount != null
        ? dbCount.toString()
        : (data['communes'] as String? ?? '0');

    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _regionStatItem(
          Icons.location_on_outlined,
          context.tr('chef_lieu'),
          data['chefLieu'] as String,
        ),
        _regionStatItem(
          Icons.home_work_outlined,
          context.tr('communes'),
          communesDisplay,
        ),
        _regionStatItem(
          Icons.verified_outlined,
          context.tr('actes_valides'),
          data['actesValides'] as String,
        ),
        _regionStatItem(
          Icons.water_drop_outlined,
          context.tr('humidite'),
          data['humi'] as String,
        ),
        _regionStatItem(Icons.air_outlined, context.tr('vent'), data['wind'] as String),
      ],
    );
  }

  Widget _regionStatItem(IconData icon, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 7. ACTUALITÉS — Hauteur adaptive + auto-défilement
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNewsSection(BuildContext context, bool isDark, double w) {
    final bool isMobile = _Bp.isMobile(w);
    final bool isSmall = _Bp.isMobileSmall(w);
    final double cardHeight = isSmall ? 170 : (isMobile ? 200 : 220);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _sectionHeader(
                context.tr('home_news_title'),
                _loadingNews
                    ? context.tr('home_news_loading')
                    : '${_newsTotal > 0 ? _newsTotal : 0} actualité(s)',
                isDark,
                w,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/actualites'),
              child: Text(
                context.tr('news_voir_tout'),
                style: TextStyle(
                  color: const Color(0xFF098E00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: cardHeight,
          child: _loadingNews
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDark ? Colors.white : const Color(0xFF098E00),
                    strokeWidth: 2.5,
                  ),
                )
              : _newsItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.newspaper_rounded,
                        size: 36,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('home_news_empty'),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : PageView.builder(
                  controller: _newsPageController,
                  itemCount: _newsItems.length,
                  onPageChanged: (i) => setState(() => _currentNewsPage = i),
                  itemBuilder: (ctx, i) {
                    final item = _newsItems[i];
                    final title = _cleanNewsText(
                      item['title'] ?? item['titre'] ?? 'Sans titre',
                    );
                    final desc = _cleanNewsText(
                      item['description'] ?? item['description_actu'] ?? '',
                    );
                    final dateStr = _cleanNewsText(
                      item['startDate'] ?? item['date'] ?? '',
                    );
                    final imgUrl = _getNewsImageUrl(
                      item['imageUrl'] ??
                          item['image'] ??
                          item['file'] ??
                          item['filepath'],
                    );

                    return Padding(
                      padding: EdgeInsets.only(
                        right: i == _newsItems.length - 1 ? 0 : 12,
                      ),
                      child: InkWell(
                        onTap: () => context.push('/actualites'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111827)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFE0E7FF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            children: [
                              // Image
                              SizedBox(
                                width: isSmall ? 90 : (isMobile ? 120 : 200),
                                height: double.infinity,
                                child: imgUrl != null
                                    ? Image.network(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _newsImgFallback(isDark),
                                      )
                                    : _newsImgFallback(isDark),
                              ),
                              // Contenu
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(isSmall ? 11 : 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF098E00,
                                              ).withValues(alpha: 0.13),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              context.tr('home_news_badge'),
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF098E00),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatNewsDate(dateStr),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        title.isEmpty ? context.tr('news_sans_titre') : title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: isSmall ? 13 : 14,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Expanded(
                                        child: Text(
                                          desc.isEmpty
                                              ? context.tr('home_news_no_desc')
                                              : desc,
                                          maxLines: isSmall ? 2 : 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.grey.shade600,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            context.tr('home_news_read_more'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Container(
                                            width: 28,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF098E00),
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (!_loadingNews && _newsItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _newsItems.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentNewsPage == i ? 10 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _currentNewsPage == i
                        ? const Color(0xFF0D7817)
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 8a. MODULES — ListView horizontal (mobile)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildModuleList(BuildContext context, bool isDark, double w) {
    final modules = _getModules(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context.tr('home_modules_title'),
          context.tr('home_modules_subtitle'),
          isDark,
          w,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) => _ModuleCard(
              module: modules[i],
              isDark: isDark,
              width: _Bp.isMobileSmall(w) ? 230 : 260,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 8b. MODULES — Grille 2×2 (tablette/desktop)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildModuleGrid(BuildContext context, bool isDark, double w) {
    final modules = _getModules(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context.tr('home_modules_title'),
          context.tr('home_modules_subtitle'),
          isDark,
          w,
        ),
        const SizedBox(height: 14),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _Bp.isDesktop(w) ? 4 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 155,
          ),
          itemCount: modules.length,
          itemBuilder: (ctx, i) => _ModuleCard(
            module: modules[i],
            isDark: isDark,
            width: double.infinity,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 9. CARTE D'ACTION / CTA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionCard(
    BuildContext context,
    bool isAuthenticated,
    double w,
  ) {
    final bool isSmall = _Bp.isMobileSmall(w);

    if (!isAuthenticated) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmall ? 18 : 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF098E00), Color(0xFF056B00)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF098E00).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 14 : 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1,
                size: isSmall ? 30 : 36,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmall ? 14 : 18),
            Text(
              context.tr('home_join_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmall ? 20 : 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('home_join_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.55,
                fontSize: isSmall ? 13 : 14,
              ),
            ),
            const SizedBox(height: 18),
            // Bénéfices — wrap automatique
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _benefitChip(
                  Icons.check_circle_outline,
                  context.tr('home_benefit_access'),
                ),
                _benefitChip(
                  Icons.security_outlined,
                  context.tr('home_benefit_security'),
                ),
                _benefitChip(
                  Icons.sync_alt,
                  context.tr('home_benefit_updates'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isSmall)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ctaPrimary(context),
                  const SizedBox(height: 10),
                  _ctaSecondary(context),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _ctaPrimary(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _ctaSecondary(context)),
                ],
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF098E00), Color(0xFF0DBA00)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: isSmall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('home_account_active'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF098E00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.go('/modules'),
                    child: Text(
                      context.tr('sidebar_modules'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.tr('home_account_active'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF098E00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.go('/modules'),
                  child: Text(
                    context.tr('sidebar_modules'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _ctaPrimary(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF098E00),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    onPressed: () => context.go('/auth/check-id-card'),
    child: Text(
      context.tr('home_signup_now'),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  Widget _ctaSecondary(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white70),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    onPressed: () => context.go('/auth/login'),
    child: Text(context.tr('se_connect')),
  );

  Widget _benefitChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 10. PARTENAIRES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPartnersSection(BuildContext context, bool isDark, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context.tr('home_partners_title'),
          context.tr('home_partners_subtitle'),
          isDark,
          w,
        ),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: List.generate(
              _partners.length,
              (i) => _partnerCard(i, isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _partnerCard(int i, bool isDark) {
    final partner = _partners[i];
    final colors = [
      const Color(0xFF098E00),
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
      const Color(0xFF0288D1),
    ];
    final color = colors[i % colors.length];
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openPartnerUrl(partner['url']?.toString()),
        child: Tooltip(
          message: '${partner['name']} — Visiter le site officiel',
          child: Container(
            width: 115,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Center(
              child: Image.asset(
                partner['image'].toString(),
                fit: BoxFit.contain,
                errorBuilder: (ctx, error, stackTrace) {
                  final fallbacks = (partner['fallbacks'] as List?)
                      ?.map((e) => e.toString())
                      .toList();
                  if (fallbacks != null && fallbacks.isNotEmpty) {
                    return Image.asset(
                      fallbacks.first,
                      fit: BoxFit.contain,
                      errorBuilder: (c2, error, stackTrace) =>
                          _initialsCircle(partner['initials'].toString(), color),
                    );
                  }
                  return _initialsCircle(partner['initials'].toString(), color);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _initialsCircle(String initials, Color color) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.12),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
    ),
  );

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, String subtitle, bool isDark, double w) {
    final bool isSmall = _Bp.isMobileSmall(w);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 18 : 21,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isSmall ? 12 : 13,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() => _loadingNews = true);
    try {
      final response = await EventService.getEvents(page: 1, limit: 5);
      if (!mounted) return;
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final items = data is List ? data : [];
        setState(() {
          _newsItems = List<Map<String, dynamic>>.from(
            items.map((e) => Map<String, dynamic>.from(e)),
          );
          _newsTotal = response['total'] is int
              ? response['total'] as int
              : _newsItems.length;
        });
      } else if (response is List) {
        setState(() {
          _newsItems = List<Map<String, dynamic>>.from(
            response.map((e) => Map<String, dynamic>.from(e)),
          );
          _newsTotal = _newsItems.length;
        });
      } else {
        setState(() {
          _newsItems = [];
          _newsTotal = 0;
        });
      }
    } catch (e) {
      debugPrint('Erreur actualités: $e');
      if (mounted) {
        setState(() {
          _newsItems = [];
          _newsTotal = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingNews = false);
        _startNewsAutoScroll();
      }
    }
  }

  Widget _newsImgFallback(bool isDark) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_rounded,
            size: 32,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            "Itantsoroka",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    ),
  );

  String? _getNewsImageUrl(dynamic rawImg) {
    if (rawImg == null) return null;
    final img = rawImg.toString().trim();
    if (img.isEmpty || img == 'null') return null;
    if (img.startsWith('http://') || img.startsWith('https://')) return img;
    final cleanPath = img.startsWith('/') ? img.substring(1) : img;
    return 'https://gateway.tsirylab.com/serviceupload/file/preview/${cleanPath.replaceAll('/', '%2F')}';
  }

  String _cleanNewsText(dynamic raw) {
    if (raw == null) return "";
    String t = raw
        .toString()
        .replaceAll("|||LANG|||", "")
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .trim();
    if (t.contains("---MALAGASY---")) {
      t = t.split("---MALAGASY---").first.trim();
    }
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatNewsDate(String d) {
    if (d.isEmpty) return 'Date N/A';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET : Compteur Animé
// ══════════════════════════════════════════════════════════════════════════════
class _AnimatedCounter extends StatelessWidget {
  final double endValue;
  final String suffix;
  final TextStyle style;

  const _AnimatedCounter({
    required this.endValue,
    this.suffix = '',
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: endValue),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final formatted = value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
        return Text('$formatted$suffix', style: style);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET : Carte Module (réutilisable)
// ══════════════════════════════════════════════════════════════════════════════
class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  final bool isDark;
  final double width;

  const _ModuleCard({
    required this.module,
    required this.isDark,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = module['gradient'] as List<Color>;
    final color = module['color'] as Color;
    return Material(
      color: isDark ? const Color(0xFF12181F) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(module['path'] as String),
        child: Container(
          width: width == double.infinity ? null : width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  module['icon'] as IconData,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                module['title'] as String,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  module['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    context.tr('home_access'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 14, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
