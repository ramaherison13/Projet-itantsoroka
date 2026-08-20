import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class PdfPreviewWebWidget extends StatefulWidget {
  final String url;
  const PdfPreviewWebWidget({super.key, required this.url});

  @override
  State<PdfPreviewWebWidget> createState() => _PdfPreviewWebWidgetState();
}

class _PdfPreviewWebWidgetState extends State<PdfPreviewWebWidget> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'pdf-preview-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final element = web.HTMLIFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return element;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
