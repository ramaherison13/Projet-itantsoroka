import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_preview.dart';
import 'mobile_document_preview.dart';
import 'package:itantsoroka/constants/api_constants.dart';

class DocumentCardWidget extends StatefulWidget {
  final int id;
  final String filename;
  final String title;
  final String date;
  final String description;
  final String type;
  final String category;
  final List<dynamic> theme;
  final String baseUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DocumentCardWidget({
    super.key,
    required this.id,
    required this.filename,
    required this.title,
    required this.date,
    required this.description,
    required this.type,
    required this.category,
    this.theme = const [],
    required this.baseUrl,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<DocumentCardWidget> createState() => _DocumentCardWidgetState();
}

class _DocumentCardWidgetState extends State<DocumentCardWidget> {
  bool _isHovered = false;

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "S/D";
    try {
      final parsedDate = DateTime.parse(dateStr);
      final months = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre"
      ];
      return "${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}";
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  String _getFileExtension() {
    if (widget.filename.isEmpty) return 'PDF';
    final parts = widget.filename.split('.');
    if (parts.length <= 1) return 'PDF';
    return parts.last.toUpperCase();
  }

  IconData _getIconForExtension(String ext) {
    switch (ext.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'DOC':
      case 'DOCX':
        return Icons.article_rounded;
      case 'XLS':
      case 'XLSX':
      case 'CSV':
        return Icons.table_chart_rounded;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow_rounded;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
      case 'GIF':
      case 'WEBP':
        return Icons.image_rounded;
      case 'ZIP':
      case 'RAR':
      case '7Z':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  List<Color> _getHeaderGradient(String ext) {
    switch (ext.toUpperCase()) {
      case 'PDF':
        return [const Color(0xFFE11D48), const Color(0xFFF43F5E)]; // Rose / Red
      case 'DOC':
      case 'DOCX':
        return [const Color(0xFF2563EB), const Color(0xFF3B82F6)]; // Blue
      case 'XLS':
      case 'XLSX':
      case 'CSV':
        return [const Color(0xFF059669), const Color(0xFF10B981)]; // Emerald
      case 'ZIP':
      case 'RAR':
        return [const Color(0xFFD97706), const Color(0xFFF59E0B)]; // Amber
      default:
        return [const Color(0xFF0D9488), const Color(0xFF14B8A6)]; // Teal / Green
    }
  }

  String _getReadableFileName() {
    final ext = _getFileExtension().toLowerCase();
    final rawTitle = widget.title.trim();
    if (rawTitle.isEmpty) {
      final cleanPath = widget.filename.startsWith('/') ? widget.filename.substring(1) : widget.filename;
      return cleanPath.split('/').last;
    }
    String safeName = rawTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final dotExt = '.$ext';
    if (!safeName.toLowerCase().endsWith(dotExt)) {
      safeName = '$safeName$dotExt';
    }
    return safeName;
  }

  Future<Directory> _getStorageDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null && await downloadsDir.exists()) {
          return downloadsDir;
        }
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          return publicDownload;
        }
      } catch (e) {
        debugPrint("Erreur dossier Download: $e");
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _handleDownload() async {
    try {
      final cleanPath = widget.filename.startsWith('/') ? widget.filename.substring(1) : widget.filename;
      final encodedFilename = cleanPath.replaceAll('/', '%2F');
      final fileUrl = widget.filename.startsWith('http://') || widget.filename.startsWith('https://')
          ? widget.filename
          : '${widget.baseUrl}/serviceupload/file/$encodedFilename';
      final uri = Uri.parse(fileUrl);

      if (kIsWeb) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri);
        }
      } else {
        final response = await http.get(uri);
        if (response.statusCode != 200) {
          throw Exception("Statut serveur: ${response.statusCode}");
        }
        final targetDir = await _getStorageDirectory();
        final readableFileName = _getReadableFileName();
        final file = File('${targetDir.path}/$readableFileName');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Fichier téléchargé: $readableFileName", style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (error) {
      debugPrint("Download error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text("Impossible de télécharger le fichier.", style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showPreviewModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final cleanPath = widget.filename.startsWith('/') ? widget.filename.substring(1) : widget.filename;
    final encodedPath = cleanPath.replaceAll('/', '%2F');
    // On utilise gatewayBaseUrl directement (pas widget.baseUrl qui contient /servicebiblio)
    final previewUrl = widget.filename.startsWith('http://') || widget.filename.startsWith('https://')
        ? widget.filename
        : '${ApiConstants.gatewayBaseUrl}/serviceupload/file/preview/$encodedPath';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: isMobile ? 16 : 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: MediaQuery.of(context).size.width * (isMobile ? 0.96 : 0.85),
            height: MediaQuery.of(context).size.height * (isMobile ? 0.92 : 0.85),
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header du modal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: Border(bottom: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        ),
                      ),
                    ],
                  ),
                ),
                // Zone de prévisualisation
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    child: kIsWeb
                        ? PdfPreviewWebWidget(url: previewUrl)
                        : MobileDocumentPreview(
                            url: previewUrl,
                            title: widget.title,
                            isDarkMode: isDarkMode,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = _formatDate(widget.date);
    final ext = _getFileExtension();
    final headerGradient = _getHeaderGradient(ext);
    final fileIcon = _getIconForExtension(ext);

    final List<String> themesList = widget.theme
        .map((t) => t.toString().replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = _isHovered
        ? const Color(0xFF10B981)
        : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: _isHovered ? Matrix4.translationValues(0, -4, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: _isHovered ? 1.8 : 1.2),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFF10B981).withValues(alpha: isDarkMode ? 0.3 : 0.15)
                  : Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.05),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
              spreadRadius: _isHovered ? 1 : 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête Dynamique avec Dégradé & Badge Type ────────────────
            Stack(
              children: [
                Container(
                  height: 82,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: headerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtly floating translucent circle pattern in background
                      Positioned(
                        right: -15,
                        top: -15,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(fileIcon, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge extension de fichier (ex: PDF, DOCX)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      ext,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Corps de la carte avec Informations ──────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre du document
                      Text(
                        widget.title.isNotEmpty ? widget.title : "Sans titre",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Metadata Row: Date & Catégorie
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Date avec icône
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),

                          // Badge Catégorie
                          if (widget.category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              constraints: const BoxConstraints(maxWidth: 180),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      widget.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Thèmes (Badges violets fluides)
                      if (themesList.isNotEmpty) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: themesList.map((th) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                th,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFA78BFA),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Extrait de description
                      Text(
                        widget.description.isNotEmpty ? widget.description : "Aucune description fournie.",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Barre des Actions Moderne (Voir, Télécharger, Modifier, Supprimer) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.8) : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton "Voir" Principal
                    SizedBox(
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPreviewModal(context),
                        icon: const Icon(Icons.visibility_rounded, size: 15),
                        label: const Text(
                          "Voir",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: _isHovered ? 2 : 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Télécharger
                    _buildActionButton(
                      icon: Icons.download_rounded,
                      tooltip: "Télécharger",
                      backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      foregroundColor: isDarkMode ? Colors.white : const Color(0xFF475569),
                      onPressed: _handleDownload,
                    ),

                    // Modifier (si handler présent)
                    if (widget.onEdit != null) ...[
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        tooltip: "Modifier",
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF3B82F6),
                        onPressed: widget.onEdit!,
                      ),
                    ],

                    // Supprimer (si handler présent)
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: "Supprimer",
                        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFFF87171),
                        onPressed: widget.onDelete!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}