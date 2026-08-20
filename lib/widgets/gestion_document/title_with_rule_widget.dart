import 'package:flutter/material.dart';

class TitleWithRuleWidget extends StatelessWidget {
  final String? title;

  const TitleWithRuleWidget({
    super.key,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Définition de la taille du texte responsive (similaire à text-3xl sm:text-4xl lg:text-5xl)
    double fontSize = 30.0;
    if (screenWidth >= 1024) {
      fontSize = 48.0; // lg:text-5xl
    } else if (screenWidth >= 640) {
      fontSize = 36.0; // sm:text-4xl
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Titre principal
          Text(
            title ?? "Documents", // Valeur par défaut si non fourni (ou équivalent de t("doc"))
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900, // font-black
              letterSpacing: -0.5, // tracking-tight
              height: 1.2, // leading-tight
              color: isDarkMode ? Colors.grey.shade100 : Colors.black,
            ),
          ),
          const SizedBox(width: 16), // Espacement entre le titre et la ligne (gap-4)
          
          // Ligne décorative jaune (#F1C232) flexible (équivalent de after:flex-1)
          Expanded(
            child: Container(
              height: 9.0, // after:h-[9px]
              decoration: BoxDecoration(
                color: const Color(0xFFF1C232),
                borderRadius: BorderRadius.circular(9.0), // after:rounded-full
              ),
            ),
          ),
        ],
      ),
    );
  }
}