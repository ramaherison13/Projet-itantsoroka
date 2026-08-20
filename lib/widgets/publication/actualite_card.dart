import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ActualiteCard extends StatefulWidget {
  final String titre;
  final String date;
  final String description;
  final List<String> theme;
  final String? image;
  final String? endDate;
  final String baseUrl;

  const ActualiteCard({
    super.key,
    required this.titre,
    required this.date,
    required this.description,
    required this.theme,
    this.image,
    this.endDate,
    required this.baseUrl,
  });

  @override
  State<ActualiteCard> createState() => _ActualiteCardState();
}

class _ActualiteCardState extends State<ActualiteCard> {
  List<String> _themeNames = [];


  @override
  void initState() {
    super.initState();
    if (widget.theme.isNotEmpty) {
      _fetchThemes();
    }
  }

  Future<void> _fetchThemes() async {
    try {
      final dio = Dio();
      final names = await Future.wait(
        widget.theme.map((themeId) async {
          final res = await dio.get('${widget.baseUrl}/servicetheme/themes/$themeId');
          return res.data['name'].toString();
        }),
      );
      if (mounted) {
        setState(() {
          _themeNames = names;
        });
      }
    } catch (e) {
      debugPrint("Erreur récupération thèmes : $e");
    }
  }

  String _formatDate(String dateStr) {
    try {
      final parsedDate = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy', 'fr_FR').format(parsedDate);
    } catch (e) {
      return "Date non disponible";
    }
  }

  String? _getImageUrl() {
    if (widget.image == null || widget.image!.trim().isEmpty) return null;
    final img = widget.image!.trim();
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return img;
    }
    final cleanPath = img.startsWith('/') ? img.substring(1) : img;
    return '${widget.baseUrl}/serviceupload/file/preview/$cleanPath';
  }

  void _openDetailsModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 768,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image principale du modal
                        if (_getImageUrl() != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: Image.network(
                              _getImageUrl()!,
                              height: 320,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 320,
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                              ),
                            ),
                          ),
                        
                        // Contenu du modal
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.titre,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(widget.date),
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  if (widget.endDate != null && widget.endDate!.isNotEmpty) ...[
                                    const Text(" → ", style: TextStyle(color: Colors.grey)),
                                    Text(
                                      _formatDate(widget.endDate!),
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Tags thèmes
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _themeNames.map((name) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFE98C21), Color(0xFFF39C41)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              
                              // Description complète
                              Text(
                                widget.description,
                                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 12),
                              Text(
                                "Pour plus d'informations, contactez votre ${widget.titre.toLowerCase().contains("commune") ? "commune" : "district"}.",
                                style: const TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton de fermeture positionné en haut à droite
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();

    return InkWell(
      onTap: () => _openDetailsModal(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 384, // max-w-[24rem]
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Text(
                        "Pas d'image",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                      ),
                    ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.endDate != null && widget.endDate!.isNotEmpty
                              ? "${_formatDate(widget.date)} → ${_formatDate(widget.endDate!)}"
                              : _formatDate(widget.date),
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            ..._themeNames.take(2).map((themeName) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE98C21), Color(0xFFF39C41)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  themeName,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              );
                            }),
                            if (_themeNames.length > 2)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "+${_themeNames.length - 2}",
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: const [
                          Text(
                            "Lire",
                            style: TextStyle(
                              color: Color(0xFF098E00),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16, color: Color(0xFF098E00)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}