import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget d'aperçu de document pour mobile (Android/iOS) via WebView
class MobileDocumentPreview extends StatefulWidget {
  final String url;
  final String title;
  final bool isDarkMode;

  const MobileDocumentPreview({
    super.key,
    required this.url,
    required this.title,
    required this.isDarkMode,
  });

  @override
  State<MobileDocumentPreview> createState() => _MobileDocumentPreviewState();
}

class _MobileDocumentPreviewState extends State<MobileDocumentPreview> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initWebView() {
    String finalUrl = widget.url;
    final lowerUrl = widget.url.toLowerCase();

    // Android WebView ne gère pas nativement l'affichage des PDF/Docs.
    // On passe par Google Docs Viewer pour obtenir un rendu HTML/canvas fiable dans WebView.
    final isDoc = lowerUrl.contains('.pdf') ||
        lowerUrl.contains('.doc') ||
        lowerUrl.contains('.docx') ||
        lowerUrl.contains('.xls') ||
        lowerUrl.contains('.xlsx') ||
        lowerUrl.contains('.ppt') ||
        lowerUrl.contains('.pptx') ||
        widget.url.contains('/serviceupload/file/');

    if (isDoc && !widget.url.contains('docs.google.com/gview')) {
      finalUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; });
            _startTimeoutTimer();
          },
          onPageFinished: (_) {
            _timeoutTimer?.cancel();
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            _timeoutTimer?.cancel();
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    // Sécurité: Si le chargement en WebView prend trop de temps, lever le masque de chargement
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _openInExternalApp() async {
    try {
      final uri = Uri.parse(widget.url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(Uri.parse(widget.url));
      } catch (err) {
        debugPrint("Erreur ouverture URL externe: $err");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorFallback();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: widget.isDarkMode
                ? const Color(0xFF0F172A)
                : const Color(0xFFF1F5F9),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF098E00),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement du document...',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _openInExternalApp,
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16, color: Color(0xFF098E00)),
                    label: const Text(
                      'Ouvrir directement dans le navigateur',
                      style: TextStyle(color: Color(0xFF098E00), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 54,
              color: widget.isDarkMode
                  ? Colors.grey.shade500
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible d\'afficher l\'aperçu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le document ne peut pas être prévisualisé directement dans cette fenêtre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: widget.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _initWebView,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF098E00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openInExternalApp,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                  label: const Text('Ouvrir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF098E00),
                    side: const BorderSide(color: Color(0xFF098E00)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
