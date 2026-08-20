import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Couleurs ────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF098E00);

class BlogPostWidget extends StatefulWidget {
  final String id;
  final String titre;
  final String date;
  final String description;
  final List<String> theme;
  final String? image;
  final String? eventType;
  final String baseUrl;

  const BlogPostWidget({
    super.key,
    required this.id,
    required this.titre,
    required this.date,
    required this.description,
    required this.theme,
    this.image,
    this.eventType,
    required this.baseUrl,
  });

  @override
  State<BlogPostWidget> createState() => _BlogPostWidgetState();
}

class _BlogPostWidgetState extends State<BlogPostWidget> {
  bool _isHovered = false;

  String _formatDate(String dateStr) {
    try {
      final parsedDate = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy', 'fr').format(parsedDate);
    } catch (e) {
      return 'Date non disponible';
    }
  }

  int _getReadingTime(String text) {
    final wordCount = text.split(' ').length;
    final time = (wordCount / 200).ceil();
    return time < 1 ? 1 : time;
  }

  String? _getImageUrl() {
    if (widget.image == null || widget.image!.trim().isEmpty) return null;
    final img = widget.image!.trim();
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return img;
    }
    final formatted = img.replaceAll('/', '%2F');
    return '${widget.baseUrl}/serviceupload/file/preview/$formatted';
  }

  Color _themeColor(String theme) {
    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFF7C3AED),
      const Color(0xFFEA580C),
      const Color(0xFF0D9488),
      const Color(0xFFDB2777),
      _kGreen,
    ];
    return colors[theme.hashCode.abs() % colors.length];
  }

  void _openDetailsModal(BuildContext context) {
    final themeNames = widget.theme;
    final imageUrl = _getImageUrl();
    final readingTime = _getReadingTime(widget.description);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 900,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header modal ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.article_rounded,
                                color: _kGreen,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Détail de l\'article',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey.shade300
                                    : const Color(0xFF475569),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : const Color(0xFF64748B),
                                size: 20,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),

                      // ── Contenu scrollable ────────────────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Hero
                              if (imageUrl != null)
                                Stack(
                                  children: [
                                    Image.network(
                                      imageUrl,
                                      height: 380,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                height: 200,
                                                color: isDarkMode
                                                    ? const Color(0xFF334155)
                                                    : Colors.grey.shade100,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image_rounded,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                    ),
                                    // Dégradé bas de l'image
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              (isDarkMode
                                                      ? const Color(0xFF1E293B)
                                                      : Colors.white)
                                                  .withValues(alpha: 0.95),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (themeNames.isNotEmpty)
                                      Positioned(
                                        top: 16,
                                        left: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _themeColor(themeNames[0]),
                                                _themeColor(
                                                  themeNames[0],
                                                ).withValues(alpha: 0.8),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _themeColor(
                                                  themeNames[0],
                                                ).withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            themeNames[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                              Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Métadonnées
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 8,
                                      children: [
                                        _metaChip(
                                          Icons.calendar_today_rounded,
                                          _formatDate(widget.date),
                                          isDarkMode,
                                        ),
                                        _metaChip(
                                          Icons.access_time_rounded,
                                          '$readingTime min de lecture',
                                          isDarkMode,
                                        ),
                                        if (widget.eventType != null)
                                          _metaChip(
                                            Icons.tag_rounded,
                                            widget.eventType!,
                                            isDarkMode,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    // Titre
                                    Text(
                                      widget.titre,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Tags thèmes
                                    if (themeNames.isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: themeNames.map((t) {
                                          final color = _themeColor(t);
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: color.withValues(
                                                  alpha: 0.25,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              t,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    const SizedBox(height: 28),

                                    // Séparateur
                                    Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _kGreen.withValues(alpha: 0.4),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    // Corps de l'article
                                    ...widget.description
                                        .split('\n')
                                        .where((p) => p.trim().isNotEmpty)
                                        .map(
                                          (paragraph) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: Text(
                                              paragraph,
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.7,
                                                color: isDarkMode
                                                    ? Colors.grey.shade300
                                                    : const Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ],
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
            ),
          ),
        );
      },
    );
  }

  Widget _metaChip(IconData icon, String label, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder(bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 36,
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNames = widget.theme;
    final imageUrl = _getImageUrl();
    final readingTime = _getReadingTime(widget.description);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget buildImageWidget({required double? height, required double? width}) {
      return SizedBox(
        height: height,
        width: width,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _imagePlaceholder(isDarkMode),
              )
            : _imagePlaceholder(isDarkMode),
      );
    }

    Widget buildContentWidget() {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Métadonnées
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _metaChip(
                  Icons.calendar_today_rounded,
                  _formatDate(widget.date),
                  isDarkMode,
                ),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                _metaChip(
                  Icons.access_time_rounded,
                  '$readingTime min de lecture',
                  isDarkMode,
                ),
                if (widget.eventType != null) ...[
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  _metaChip(
                    Icons.tag_rounded,
                    widget.eventType!,
                    isDarkMode,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Titre
            Text(
              widget.titre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 16 : 19,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              widget.description,
              maxLines: isMobile ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 12.5 : 13.5,
                color: isDarkMode
                    ? Colors.grey.shade300
                    : const Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),

            // Footer : tags + lien lire
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: themeNames.take(2).map((t) {
                      final color = _themeColor(t);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? _kGreen
                        : _kGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isHovered
                          ? Colors.transparent
                          : _kGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lire',
                        style: TextStyle(
                          color: _isHovered ? Colors.white : _kGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: _isHovered ? Colors.white : _kGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? _kGreen.withValues(alpha: 0.3)
                : (isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? _kGreen.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.04),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openDetailsModal(context),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: buildImageWidget(
                          height: 180,
                          width: double.infinity,
                        ),
                      ),
                      buildContentWidget(),
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(18),
                          ),
                          child: buildImageWidget(height: null, width: 220),
                        ),
                        Expanded(child: buildContentWidget()),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}