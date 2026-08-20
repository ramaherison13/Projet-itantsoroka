import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_preview.dart';
import 'mobile_document_preview.dart';

class DocumentCardWidget extends StatefulWidget {
  final int id;
  final String filename;
  final String title;
  final String date;
  final String description;
  final String type;
  final String category;
  final String baseUrl; // Base URL de l'API

  const DocumentCardWidget({
    super.key,
    required this.id,
    required this.filename,
    required this.title,
    required this.date,
    required this.description,
    required this.type,
    required this.category,
    required this.baseUrl,
  });

  @override
  State<DocumentCardWidget> createState() => _DocumentCardWidgetState();
}

class _DocumentCardWidgetState extends State<DocumentCardWidget> {
  bool _isLoading = false;

  String _formatDate(String dateStr) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return dateStr;
    }
  }

  String _getFileExtension() {
    if (widget.filename.isEmpty) return 'DOC';
    final parts = widget.filename.split('.');
    if (parts.length <= 1) return 'DOC';
    return parts.last.toUpperCase();
  }

  Color _getBadgeColor(String ext) {
    switch (ext.toUpperCase()) {
      case 'PDF':
        return const Color(0xFFE11D48);
      case 'DOC':
      case 'DOCX':
        return const Color(0xFF0284C7);
      case 'XLS':
      case 'XLSX':
        return const Color(0xFF16A34A);
      case 'PPT':
      case 'PPTX':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF098E00);
    }
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart_rounded;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow_rounded;
      case 'PNG':
      case 'JPG':
      case 'JPEG':
        return Icons.image_rounded;
      default:
        return Icons.description_rounded;
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
        debugPrint("Erreur obtention dossier Download: $e");
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
          throw Exception("Serveur a répondu avec le statut ${response.statusCode}");
        }
        final targetDir = await _getStorageDirectory();
        final readableFileName = _getReadableFileName();
        final file = File('${targetDir.path}/$readableFileName');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          final isPublicDownload = targetDir.path.contains('Download');
          final locationMsg = isPublicDownload
              ? "Enregistré dans Téléchargements : $readableFileName"
              : "Fichier téléchargé : $readableFileName";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locationMsg),
              backgroundColor: const Color(0xFF098E00),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: "Ouvrir",
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  }
                },
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (error) {
      debugPrint("Download error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Impossible de télécharger le fichier."),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _handlePreview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/servicebiblio/resources/${widget.id}'),
      );

      if (response.statusCode != 200) {
        throw Exception("Erreur lors de la récupération du document");
      }

      if (mounted) {
        _showPreviewModal(context);
      }
    } catch (error) {
      debugPrint("$error");
      if (mounted) {
        _showPreviewModal(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPreviewModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ext = _getFileExtension();
    final badgeColor = _getBadgeColor(ext);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final cleanPath = widget.filename.startsWith('/') ? widget.filename.substring(1) : widget.filename;
    final encodedPath = cleanPath.replaceAll('/', '%2F');
    final previewUrl = widget.filename.startsWith('http://') || widget.filename.startsWith('https://')
        ? widget.filename
        : '${widget.baseUrl}/serviceupload/file/preview/$encodedPath';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: isMobile ? 16 : 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
          child: Container(
            width: MediaQuery.of(context).size.width * (isMobile ? 0.96 : 0.9),
            height: MediaQuery.of(context).size.height * (isMobile ? 0.92 : 0.88),
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header du modal stylé avec icônes d'action
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [badgeColor.withValues(alpha: 0.15), badgeColor.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(_getFileIcon(ext), color: badgeColor, size: isMobile ? 18 : 22),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 16,
                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ext,
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeColor),
                                  ),
                                ),
                                if (widget.category.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '• ${widget.category}',
                                      style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Actions d'en-tête (Ouvrir dans nouvel onglet, Télécharger, Fermer)
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.open_in_new_rounded, size: isMobile ? 18 : 20),
                        tooltip: 'Ouvrir dans un nouvel onglet',
                        style: IconButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          foregroundColor: isDarkMode ? Colors.white : const Color(0xFF475569),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(previewUrl);
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            try {
                              await launchUrl(uri);
                            } catch (_) {}
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.download_rounded, size: isMobile ? 18 : 20),
                        tooltip: 'Télécharger',
                        style: IconButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          foregroundColor: isDarkMode ? Colors.white : const Color(0xFF475569),
                        ),
                        onPressed: _handleDownload,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.close_rounded, size: isMobile ? 18 : 20),
                        style: IconButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          foregroundColor: isDarkMode ? Colors.white : const Color(0xFF475569),
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ),

                // Zone de prévisualisation intégrée (WebView sur mobile + iframe sur Web)
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

                // Footer du modal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            'Publié le ${_formatDate(widget.date)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        'Document Officiel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF098E00).withValues(alpha: 0.8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String ext = _getFileExtension();
    Color badgeColor = _getBadgeColor(ext);
    String formattedDate = _formatDate(widget.date);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête (Icone + Titre + Catégorie/Badge)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [badgeColor.withValues(alpha: 0.15), badgeColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                ),
                child: Icon(_getFileIcon(ext), color: badgeColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.25,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ext,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        if (widget.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${widget.category}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description (max 2 lignes)
          Expanded(
            child: Text(
              widget.description.isNotEmpty ? widget.description : "Aucune description fournie pour ce document.",
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF475569),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Date de publication
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 11, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Boutons d'action (Consulter + Télécharger)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handlePreview,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.remove_red_eye_outlined, size: 14),
                    label: const Text(
                      "Consulter",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF098E00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: _handleDownload,
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: const Text(
                      "Télécharger",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                      foregroundColor: isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF098E00),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}