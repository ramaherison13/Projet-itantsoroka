import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/event_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final bool isAuthenticated = false;
  final bool isActivated = false;

  final PageController _newsPageController = PageController(viewportFraction: 0.92);
  int _currentNewsPage = 0;
  bool _loadingNews = false;
  int _newsTotal = 0;
  List<Map<String, dynamic>> _newsItems = [];

  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Monographie Territoriale',
      'description': 'Fiches synthétiques et statistiques par district, région et commune.',
      'icon': Icons.map_outlined,
      'color': const Color(0xFF098E00),
      'gradient': [const Color(0xFF098E00), const Color(0xFF0dba00)],
      'path': '/monographie',
    },
    {
      'title': 'Gestion Documentaire',
      'description': 'Consultez, téléchargez et gérez les arrêtés et ressources officielles.',
      'icon': Icons.description_outlined,
      'color': const Color(0xFF1565C0),
      'gradient': [const Color(0xFF1565C0), const Color(0xFF1976D2)],
      'path': '/document',
    },
    {
      'title': 'Office des Projets',
      'description': 'Suivi des budgets, des livrables et des impacts de chaque projet.',
      'icon': Icons.business_center_outlined,
      'color': const Color(0xFF6A1B9A),
      'gradient': [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
      'path': '/officeprojet',
    },
    {
      'title': 'Contrôle de Légalité',
      'description': 'Soumettez, vérifiez et archivez les actes administratifs locaux.',
      'icon': Icons.gavel_outlined,
      'color': const Color(0xFFE65100),
      'gradient': [const Color(0xFFE65100), const Color(0xFFEF6C00)],
      'path': '/das',
    },
  ];

  final List<Map<String, dynamic>> _stats = [
    {'label': 'Districts', 'value': '119', 'icon': Icons.location_city_outlined},
    {'label': 'Communes', 'value': '1695', 'icon': Icons.account_balance_outlined},
    {'label': 'Documents', 'value': '3.2k+', 'icon': Icons.folder_outlined},
    {'label': 'Projets suivis', 'value': '250+', 'icon': Icons.trending_up},
  ];

  final List<Map<String, dynamic>> _partners = [
    {
      'name': 'Ministère de l\'Intérieur',
      'initials': 'MI',
      'image': 'assets/images/LogoMinistereInterieur.jpg',
      'fallbacks': ['assets/images/logo_ministere.jpg'],
    },
    {
      'name': 'Mionjo',
      'initials': 'MJ',
      'image': 'assets/images/logo2.png',
      'fallbacks': [],
    },
    {
      'name': 'Dispositif District',
      'initials': 'DD',
      'image': 'assets/images/logo_dd_v3.png',
      'fallbacks': ['assets/images/logo_dd.png', 'assets/images/DD.png'],
    },
    {
      'name': 'PNUD',
      'initials': 'PN',
      'image': 'assets/images/PNUD-Logo-Blue.png',
      'fallbacks': ['assets/images/logo_pnud_blue.png', 'assets/images/logo_pnud.png', 'assets/images/LOGO-PNUD.png'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context, isDarkMode),
          const SizedBox(height: 18),
          _buildShortcutSection(context, isDarkMode),
          const SizedBox(height: 24),
          _buildNewsSection(context, isDarkMode),
          const SizedBox(height: 24),
          _buildModuleSection(context, isDarkMode, screenWidth),
          const SizedBox(height: 24),
          _buildStatsSection(context, isDarkMode),
          const SizedBox(height: 24),
          _buildActionCard(context),
          const SizedBox(height: 24),
          _buildPartnersSection(context, isDarkMode),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF0b120e), const Color(0xFF112216)]
              : [const Color(0xFF0d7817), const Color(0xFF15a035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -22,
            right: -14,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bonjour, bienvenue',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Itantsoroka',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.smartphone, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Application Mobile',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Plateforme unifiée de suivi territorial, données et pilotage.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 15,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildHeroChip(Icons.analytics_outlined, 'Statistiques'),
                  _buildHeroChip(Icons.map_outlined, 'Cartographie'),
                  _buildHeroChip(Icons.shield_outlined, 'Sécurité'),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;
                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0d7817),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => context.go('/monographie'),
                          child: const Text(
                            'Accéder à la monographie',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => context.go('/officeprojet'),
                          child: const Text('Voir les projets'),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0d7817),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => context.go('/monographie'),
                          child: const Text(
                            'Accéder à la monographie',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => context.go('/officeprojet'),
                        child: const Text('Voir les projets'),
                      ),
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

  Widget _buildShortcutSection(BuildContext context, bool isDarkMode) {
    final shortcuts = [
      {
        'title': 'Derniers indicateurs',
        'subtitle': 'Voir les statistiques récentes de la plateforme',
        'icon': Icons.show_chart,
        'color': const Color(0xFF0D7817),
        'path': '/das',
      },
      {
        'title': 'Rapports à imprimer',
        'subtitle': 'Générez les rapports de suivi et de contrôle en PDF',
        'icon': Icons.picture_as_pdf,
        'color': const Color(0xFF1565C0),
        'path': '/document',
      },
      {
        'title': 'Aide et support',
        'subtitle': 'Consultez les actualités et ressources utiles',
        'icon': Icons.support_agent,
        'color': const Color(0xFF6A1B9A),
        'path': '/actualites',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Raccourcis',
          'Accédez rapidement aux actions les plus utiles',
          isDarkMode,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shortcuts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = shortcuts[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.go(item['path'] as String),
                child: Container(
                  width: 224,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (item['color'] as Color).withValues(alpha: 0.16),
                        (item['color'] as Color).withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (item['color'] as Color).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (item['color'] as Color).withValues(alpha: 0.22),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: item['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : const Color(0xFF0f0f23),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String? _getNewsImageUrl(dynamic rawImg) {
    if (rawImg == null) return null;
    final img = rawImg.toString().trim();
    if (img.isEmpty || img == 'null') return null;
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return img;
    }
    final cleanPath = img.startsWith('/') ? img.substring(1) : img;
    return 'https://gateway.tsirylab.com/serviceupload/file/preview/${cleanPath.replaceAll('/', '%2F')}';
  }

  String _cleanNewsText(dynamic raw) {
    if (raw == null) return "";
    String text = raw.toString();
    text = text.replaceAll("|||LANG|||", "").trim();
    text = text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
    if (text.contains("---MALAGASY---")) {
      text = text.split("---MALAGASY---").first.trim();
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatNewsDate(String dateStr) {
    if (dateStr.isEmpty) return 'Date non précisée';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildNewsImageFallback(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
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
              size: 38,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
            ),
            const SizedBox(height: 6),
            Text(
              "Dispositif District",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection(BuildContext context, bool isDarkMode) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Actualités',
          _loadingNews
              ? 'Chargement des dernières actualités...'
              : '${_newsTotal > 0 ? _newsTotal : 'Pas'} actualités disponibles',
          isDarkMode,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isSmallScreen ? 250 : 230,
          child: _loadingNews
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white : const Color(0xFF098E00),
                  ),
                )
              : _newsItems.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune actualité disponible pour le moment.',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.grey.shade700,
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _newsPageController,
                      itemCount: _newsItems.length,
                      onPageChanged: (index) {
                        setState(() => _currentNewsPage = index);
                      },
                      itemBuilder: (context, index) {
                        final item = _newsItems[index];
                        final rawTitle = item['title'] ?? item['titre'] ?? 'Sans titre';
                        final rawDesc = item['description'] ?? item['description_actu'] ?? '';
                        final rawDate = item['startDate'] ?? item['date'] ?? '';
                        final rawImg = item['imageUrl'] ?? item['image'] ?? item['file'] ?? item['filepath'];

                        final title = _cleanNewsText(rawTitle);
                        final finalTitle = title.isEmpty ? 'Sans titre' : title;
                        final description = _cleanNewsText(rawDesc);
                        final dateStr = _cleanNewsText(rawDate);
                        final formattedDate = _formatNewsDate(dateStr);
                        final imgUrl = _getNewsImageUrl(rawImg);

                        return Padding(
                          padding: EdgeInsets.only(right: index == _newsItems.length - 1 ? 0 : 14),
                          child: InkWell(
                            onTap: () => context.push('/actualites'),
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF111827) : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE0E7FF),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                children: [
                                  // Conteneur de l'image de l'actualité
                                  SizedBox(
                                    width: isSmallScreen ? 110 : 200,
                                    height: double.infinity,
                                    child: imgUrl != null
                                        ? Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildNewsImageFallback(isDarkMode),
                                          )
                                        : _buildNewsImageFallback(isDarkMode),
                                  ),
                                  // Contenu texte
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF098E00).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "ACTUALITÉ",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF098E00),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            finalTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Expanded(
                                            child: Text(
                                              description.isEmpty
                                                  ? 'Aucune description supplémentaire'
                                                  : description,
                                              maxLines: isSmallScreen ? 2 : 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: isDarkMode ? Colors.white60 : Colors.grey.shade700,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Lire plus',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              Container(
                                                width: 32,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF098E00),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
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
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _newsItems.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentNewsPage == index ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentNewsPage == index
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

  Future<void> _fetchNews() async {
    setState(() {
      _loadingNews = true;
    });

    try {
      final response = await EventService.getEvents(page: 1, limit: 5);
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final items = data is List ? data : [];
        setState(() {
          _newsItems = List<Map<String, dynamic>>.from(items.map((item) => Map<String, dynamic>.from(item)));
          _newsTotal = response['total'] is int ? response['total'] as int : _newsItems.length;
        });
      } else if (response is List) {
        setState(() {
          _newsItems = List<Map<String, dynamic>>.from(response.map((item) => Map<String, dynamic>.from(item)));
          _newsTotal = _newsItems.length;
        });
      } else {
        setState(() {
          _newsItems = [];
          _newsTotal = 0;
        });
      }
    } catch (error) {
      debugPrint('Erreur chargement actualités : $error');
      setState(() {
        _newsItems = [];
        _newsTotal = 0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingNews = false;
        });
      }
    }
  }

  Widget _buildModuleSection(BuildContext context, bool isDarkMode, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Modules rapides',
          'Accédez directement aux principales fonctionnalités',
          isDarkMode,
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _modules.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _ModuleCard(
                module: _modules[index],
                isDarkMode: isDarkMode,
                width: screenWidth < 560 ? 240 : 280,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'En chiffres',
          'Quelques indicateurs clés de la plateforme',
          isDarkMode,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _stats.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _StatCard(stat: _stats[index], isDarkMode: isDarkMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context) {
    if (!isAuthenticated) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF098E00), Color(0xFF056B00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF098E00).withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 18),
            const Text(
              'Rejoignez la plateforme',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Créez un compte et obtenez un accès complet aux données, aux projets et aux rapports territoriaux.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildBenefitChip(Icons.check_circle_outline, 'Accès complet'),
                _buildBenefitChip(Icons.security_outlined, 'Sécurité renforcée'),
                _buildBenefitChip(Icons.sync_alt, 'Mises à jour rapides'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF098E00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.go('/auth/check-id-card'),
                    child: const Text(
                      'S\'inscrire maintenant',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Se connecter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isActivated) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF098E00), Color(0xFF0dba00)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Votre compte est activé. Accédez dès maintenant aux modules et aux données territoriales.',
                style: TextStyle(color: Colors.white, fontSize: 15, height: 1.55),
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
              child: const Text('Modules', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFb88700), Color(0xFFd0a900)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Votre compte est en attente d\'activation. Veuillez patienter pendant l\'approbation.',
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Partenaires',
          'Institutions et organismes soutenant la plateforme',
          isDarkMode,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _partners.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final partner = _partners[index];
              return _PartnerCard(
                name: partner['name'].toString(),
                initials: partner['initials'].toString(),
                image: partner['image'].toString(),
                fallbacks: (partner['fallbacks'] as List?)
                    ?.map((e) => e.toString())
                    .toList(),
                color: _partnerColor(index),
                isDarkMode: isDarkMode,
              );
            },
          ),
        ),
      ],
    );
  }

  Color _partnerColor(int index) {
    final colors = [
      const Color(0xFF098E00),
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
    ];
    return colors[index % colors.length];
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    bool isDarkMode, {
    bool centered = false,
  }) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : const Color(0xFF0f0f23),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  final bool isDarkMode;
  final double width;

  const _ModuleCard({
    required this.module,
    required this.isDarkMode,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = module['gradient'] as List<Color>;
    final color = module['color'] as Color;
    return Material(
      color: isDarkMode ? const Color(0xFF12181f) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.go(module['path'] as String),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF1f2937) : const Color(0xFFe5e7eb),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  module['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                module['title'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? Colors.white : const Color(0xFF0f0f23),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  module['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? const Color(0xFFcbd5e1) : const Color(0xFF6b7280),
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Accéder',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  final bool isDarkMode;

  const _StatCard({required this.stat, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF098E00).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF098E00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat['icon'] as IconData,
                color: const Color(0xFF098E00), size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat['value'] as String,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : const Color(0xFF0f0f23),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat['label'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : const Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final String name;
  final String initials;
  final String image;
  final List<String>? fallbacks;
  final Color color;
  final bool isDarkMode;

  const _PartnerCard({
    required this.name,
    required this.initials,
    required this.image,
    this.fallbacks,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Center(
          child: Image.asset(
            image,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, _) {
              if (fallbacks != null && fallbacks!.isNotEmpty) {
                return Image.asset(
                  fallbacks!.first,
                  fit: BoxFit.contain,
                  errorBuilder: (c2, e2, s2) => _buildInitialsCircle(),
                );
              }
              return _buildInitialsCircle();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsCircle() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}
