import 'package:flutter/material.dart';

List<Widget> parseRichText(String? text) {
  if (text == null || text.isEmpty) {
    return [const Text("Aucun detail")];
  }

  final lines = text.split('\n');
  List<Widget> widgets = [];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Gestion des titres (# à ######)
    final headerMatch = RegExp(r'^(#{1,6})\s+(.*)').firstMatch(line);
    if (headerMatch != null) {
      final level = headerMatch.group(1)!.length;
      final content = headerMatch.group(2)!;

      double fontSize;
      EdgeInsetsGeometry padding;

      switch (level) {
        case 1:
          fontSize = 30.0;
          padding = const EdgeInsets.symmetric(vertical: 32.0);
          break;
        case 2:
          fontSize = 24.0;
          padding = const EdgeInsets.symmetric(vertical: 24.0);
          break;
        case 3:
          fontSize = 20.0;
          padding = const EdgeInsets.symmetric(vertical: 12.0);
          break;
        case 4:
          fontSize = 18.0;
          padding = const EdgeInsets.symmetric(vertical: 8.0);
          break;
        case 5:
          fontSize = 16.0;
          padding = const EdgeInsets.symmetric(vertical: 8.0);
          break;
        default:
          fontSize = 14.0;
          padding = const EdgeInsets.symmetric(vertical: 8.0);
          break;
      }

      widgets.add(
        Padding(
          padding: padding,
          child: Text(
            content,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      continue;
    }

    // Gestion des listes à puces (- )
    if (line.trimLeft().startsWith('- ')) {
      final content = line.replaceFirst(RegExp(r'^\s*-\s*'), '');
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 24.0, bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildFormattedText(content),
              ),
            ],
          ),
        ),
      );
      continue;
    }

    // Gestion des paragraphes normaux avec support du gras (**texte**)
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _buildFormattedText(line),
      ),
    );
  }

  return widgets;
}

Widget _buildFormattedText(String text) {
  final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
  final matches = exp.allMatches(text);

  if (matches.isEmpty) {
    return Text(text);
  }

  List<InlineSpan> spans = [];
  int currentIndex = 0;

  for (final match in matches) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
    }

    final boldText = match.group(1);
    if (boldText != null) {
      spans.add(
        TextSpan(
          text: boldText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.add(TextSpan(text: text.substring(currentIndex)));
  }

  return RichText(
    text: TextSpan(
      style: TextStyle(
        color: Colors.black87,
        fontSize: 14.0,
      ),
      children: spans,
    ),
  );
}