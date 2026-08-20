import 'package:flutter/material.dart';

class LanguageSettingWidget extends StatelessWidget {
  final String currentLang;
  final ValueChanged<String?> onLanguageChanged;

  const LanguageSettingWidget({
    super.key,
    required this.currentLang,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onHover: (hovering) {},
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: 18,
                  color: isDarkMode ? Colors.grey.shade100 : Colors.black87,
                ),
                const SizedBox(width: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentLang,
                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    icon: const SizedBox.shrink(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade100 : Colors.black,
                      fontSize: 14,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(
                          // On peut adapter l'affichage selon l'espace ou utiliser un LayoutBuilder pour simuler mobile/desktop
                          "Français",
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade100 : Colors.black,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'mg',
                        child: Text(
                          "Malagasy",
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade100 : Colors.black,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onLanguageChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}