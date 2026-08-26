import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSettingWidget extends StatelessWidget {
  const LanguageSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLang = languageProvider.currentLanguageCode;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLang,
          dropdownColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              size: 20,
            ),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: [
            DropdownMenuItem(
              value: 'fr',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇫🇷 ', style: TextStyle(fontSize: 14)),
                  Text(
                    "Français",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'mg',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇲🇬 ', style: TextStyle(fontSize: 14)),
                  Text(
                    "Malagasy",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (String? newLang) {
            if (newLang != null) {
              languageProvider.setLanguage(newLang);
            }
          },
        ),
      ),
    );
  }
}