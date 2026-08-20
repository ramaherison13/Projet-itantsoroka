import 'package:flutter/material.dart';

class PdfPreviewWebWidget extends StatelessWidget {
  final String url;
  const PdfPreviewWebWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Aperçu non disponible sur cette plateforme."),
    );
  }
}
