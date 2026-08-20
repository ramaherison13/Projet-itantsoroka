import 'package:flutter/material.dart';

// Modèle de données pour les actualités
class Actualite {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String? endDate;
  final String visibility;
  final List<String> themeId;
  final String communeId;
  final String eventTypeId;
  final String? image;

  Actualite({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.visibility,
    required this.themeId,
    required this.communeId,
    required this.eventTypeId,
    this.image,
  });

  factory Actualite.fromJson(Map<String, dynamic> json) {
    return Actualite(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      visibility: json['visibility'] ?? '',
      themeId: json['themeId'] != null ? List<String>.from(json['themeId']) : [],
      communeId: json['communeId'] ?? '',
      eventTypeId: json['eventTypeId'] ?? '',
      image: json['image'],
    );
  }
}

class MonographieAfficheActu extends StatefulWidget {
  final double? height;
  final String? types;
  final String? territoires;
  final String? id;
  final Map<String, dynamic>? territoireStore;
  final Future<List<dynamic>> Function(String communeId) getAllActualitesByCommune;

  const MonographieAfficheActu({
    super.key,
    this.height,
    this.types,
    this.territoires,
    this.id,
    this.territoireStore,
    required this.getAllActualitesByCommune,
  });

  @override
  MonographieAfficheActuState createState() => MonographieAfficheActuState();
}

class MonographieAfficheActuState extends State<MonographieAfficheActu> {
  List<Actualite> _actualites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchActualites();
  }

  String? _getCommuneId() {
    if (widget.territoireStore != null) {
      return widget.types == "communes"
          ? widget.territoireStore!['commune_id']
          : widget.territoireStore!['district_id'];
    }
    if (widget.id != null && widget.id!.isNotEmpty) {
      return widget.id;
    }
    return null;
  }

  String _getTerritoireName() {
    if (widget.territoireStore != null && widget.territoireStore!['name'] != null) {
      return widget.territoireStore!['name'];
    }
    if (widget.territoires != null && widget.territoires!.isNotEmpty) {
      return Uri.decodeComponent(widget.territoires!);
    }
    return "District";
  }

  Future<void> _fetchActualites() async {
    final communeId = _getCommuneId();

    if (communeId == null || communeId.isEmpty) {
      setState(() {
        _error = "ID de commune non trouvé";
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.getAllActualitesByCommune(communeId);
      final List<Actualite> loadedActualites = data.map((item) => Actualite.fromJson(item)).toList();
      
      if (mounted) {
        setState(() {
          _actualites = loadedActualites;
          _loading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = "Erreur lors du chargement des actualités";
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return 'Date non disponible';
    }
  }

  String _truncateText(String text, {int maxLength = 150}) {
    if (text.isEmpty) return "Description non disponible";
    if (text.length <= maxLength) return text;
    return "${text.substring(0, maxLength)}...";
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final communeName = _getTerritoireName();
    final isCommune = widget.types == "communes";

    if (_loading) {
      return Container(
        height: widget.height,
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF098E00)),
              SizedBox(width: 12),
              Text("Chargement des actualités..."),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: widget.height,
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.2),
              border: Border.all(color: Colors.red.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Erreur! $_error",
              style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF008713),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "E",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Expertises STD présentes",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Breadcrumb
                Row(
                  children: [
                    Text(
                      "Service de District de la Santé Publique",
                      style: TextStyle(color: const Color(0xFF008713), fontSize: 14),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("/"),
                    ),
                    const Text(
                      "CISCO",
                      style: TextStyle(color: Color(0xFF008713), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  "Les actualités ${isCommune ? "de la commune" : "du district"} $communeName",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 32),

                // Content
                _actualites.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48.0),
                          child: Column(
                            children: [
                              Text(
                                "Aucune actualité disponible pour ${isCommune ? "cette commune" : "ce district"}.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "ID utilisé: ${_getCommuneId()}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _actualites.length,
                            itemBuilder: (context, index) {
                              final actualite = _actualites[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image Container
                                    SizedBox(
                                      height: 160,
                                      width: double.infinity,
                                      child: actualite.image != null && actualite.image!.isNotEmpty
                                          ? Image.network(
                                              actualite.image!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.blue, Colors.purple, Colors.pink],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    "${index + 1}",
                                                    style: TextStyle(
                                                      fontSize: 48,
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Colors.blue, Colors.purple, Colors.pink],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                "${index + 1}",
                                                style: TextStyle(
                                                  fontSize: 48,
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                    // Card Body
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              actualite.title.isNotEmpty ? actualite.title : "Actualité ${index + 1}",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _formatDate(actualite.startDate),
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: Text(
                                                _truncateText(actualite.description),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF008713),
                                                    borderRadius: BorderRadius.circular(100),
                                                  ),
                                                  child: Text(
                                                    "${isCommune ? 'Commune' : 'District'} $communeName",
                                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange,
                                                    borderRadius: BorderRadius.circular(100),
                                                  ),
                                                  child: const Text(
                                                    "Actualité",
                                                    style: TextStyle(color: Colors.white, fontSize: 11),
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
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Text(
                            "${_actualites.length} actualité${_actualites.length > 1 ? 's' : ''} trouvée${_actualites.length > 1 ? 's' : ''} ${isCommune ? "pour cette commune" : "pour ce district"}",
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}