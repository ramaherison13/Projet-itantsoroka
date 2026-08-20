import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class BlogListWidget extends StatefulWidget {
  final String baseUrl;
  final Widget Function(Map<String, dynamic> post) buildBlogPost;

  const BlogListWidget({
    super.key,
    required this.baseUrl,
    required this.buildBlogPost,
  });

  @override
  State<BlogListWidget> createState() => _BlogListWidgetState();
}

class _BlogListWidgetState extends State<BlogListWidget> {
  List<dynamic> _posts = [];
  bool _loading = true;
  String _searchQuery = "";
  final String _selectedTheme = "all";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final dio = Dio();
      final response = await dio.get('${widget.baseUrl}/actualites');
      setState(() {
        _posts = response.data is List ? response.data : [];
      });
    } catch (e) {
      debugPrint("Erreur de chargement: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF098e00),
          ),
        ),
      );
    }

    final filteredPosts = _posts.where((post) {
      final titre = (post['titre'] ?? post['title'] ?? '').toString().toLowerCase();
      final themes = post['theme'] is List ? List<String>.from(post['theme']) : <String>[];
      
      final matchesSearch = titre.contains(_searchQuery.toLowerCase());
      final matchesTheme = _selectedTheme == "all" || themes.contains(_selectedTheme);

      return matchesSearch && matchesTheme;
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FAFB), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1152), // max-w-6xl
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête du blog
                    const Padding(
                      padding: EdgeInsets.only(bottom: 48.0),
                      child: Column(
                        children: [
                          Text(
                            "Nos Actualités",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Restez informé des dernières nouvelles et événements",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Barre de recherche et filtres
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() => _searchQuery = value),
                                decoration: const InputDecoration(
                                  hintText: "Rechercher un article...",
                                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list, color: Colors.black87),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Liste des articles
                    filteredPosts.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index];
                              return widget.buildBlogPost(post);
                            },
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 64.0),
                            child: Center(
                              child: Text(
                                "Aucun article trouvé",
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          ),

                    // Pagination
                    Padding(
                      padding: const EdgeInsets.only(top: 48.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF098e00),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Text("2", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Text("3", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}