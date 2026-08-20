import 'package:flutter/material.dart';

class MonographieSearchWidget extends StatefulWidget {
  final Future<List<dynamic>> Function(String type) getAllTerritoires;
  final void Function(dynamic territoire, String searchType) onSelectTerritoire;

  const MonographieSearchWidget({
    super.key,
    required this.getAllTerritoires,
    required this.onSelectTerritoire,
  });

  @override
  State<MonographieSearchWidget> createState() =>
      _MonographieSearchWidgetState();
}

class _MonographieSearchWidgetState extends State<MonographieSearchWidget> {
  List<dynamic> _territoires = [];
  String _searchTerm = "";
  String _searchType = "districts"; // 'districts' ou 'communes'
  bool _loading = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTerritoires();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTerritoires() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await widget.getAllTerritoires(_searchType);
      if (mounted) {
        setState(() {
          _territoires = data;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement territoires: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onTypeChanged(String? newType) {
    if (newType != null && newType != _searchType) {
      setState(() {
        _searchType = newType;
        _searchTerm = "";
        _searchController.clear();
      });
      _fetchTerritoires();
    }
  }

  void _scrollGrid(double offset) {
    if (_gridScrollController.hasClients) {
      final target = (_gridScrollController.offset + offset).clamp(
        0.0,
        _gridScrollController.position.maxScrollExtent,
      );
      _gridScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filteredTerritoires = _territoires.where((item) {
      final name =
          (item['nom'] ??
                  item['name'] ??
                  item['libelle'] ??
                  item['title'] ??
                  '')
              .toString()
              .toLowerCase();
      final code = (item['code'] ?? item['formatted_id'] ?? item['id'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(_searchTerm.toLowerCase()) ||
          code.contains(_searchTerm.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Titre exactement comme sur la maquette Image 3
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'sans-serif',
                    color: isDarkMode ? Colors.white : const Color(0xFF1B1B1B),
                  ),
                  children: const [
                    TextSpan(text: "Rechercher une monographie de\n"),
                    TextSpan(
                      text: "District ",
                      style: TextStyle(color: Color(0xFF098E00)),
                    ),
                    TextSpan(text: "ou "),
                    TextSpan(
                      text: "Commune",
                      style: TextStyle(color: Color(0xFF098E00)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Rechercher efficacement les districts et les communes ayant une monographie",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Barre de recherche avec sélecteur Dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchTerm = val),
                        decoration: const InputDecoration(
                          hintText: "Rechercher une monographie(ex- Ambalavao)",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _searchType,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black87,
                          ),
                          dropdownColor: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.white,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'districts',
                              child: Text('District'),
                            ),
                            DropdownMenuItem(
                              value: 'communes',
                              child: Text('Commune'),
                            ),
                          ],
                          onChanged: _onTypeChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Zone d'affichage des résultats en 2 colonnes avec boutons de défilement vert
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFF098E00)),
                )
              else if (filteredTerritoires.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "Aucun territoire trouvé",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 240,
                        child: GridView.builder(
                          controller: _gridScrollController,
                          itemCount: filteredTerritoires.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 4.5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 12,
                              ),
                          itemBuilder: (context, index) {
                            final item = filteredTerritoires[index];
                            final String name =
                                item['nom'] ??
                                item['name'] ??
                                item['libelle'] ??
                                item['title'] ??
                                item['formatted_id'] ??
                                item['code'] ??
                                'Territoire';
                            return InkWell(
                              onTap: () =>
                                  widget.onSelectTerritoire(item, _searchType),
                              borderRadius: BorderRadius.circular(6),
                              hoverColor: const Color(
                                0xFF098E00,
                              ).withValues(alpha: 0.08),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Flèches vertes de défilement comme sur l'Image 3
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        InkWell(
                          onTap: () => _scrollGrid(-120),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 16,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF098E00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.arrow_drop_up,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        InkWell(
                          onTap: () => _scrollGrid(120),
                          borderRadius: BorderRadius.circular(12),
                          child: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF098E00),
                            size: 24,
                          ),
                        ),
                      ],
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
