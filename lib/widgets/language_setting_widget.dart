import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSettingWidget extends StatelessWidget {
  final bool isCompact;
  const LanguageSettingWidget({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLang = languageProvider.currentLanguageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool compact = isCompact || screenWidth < 420;

    return Container(
      height: 34,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
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
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              size: 18,
            ),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: [
            DropdownMenuItem(
              value: 'fr',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇫🇷 ', style: TextStyle(fontSize: 13)),
                  Text(
                    compact ? 'FR' : 'Français',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                  const Text('🇲🇬 ', style: TextStyle(fontSize: 13)),
                  Text(
                    compact ? 'MG' : 'Malagasy',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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