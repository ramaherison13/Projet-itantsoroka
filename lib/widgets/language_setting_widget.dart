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
    final bool compact = isCompact || screenWidth < 480;

    return Container(
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLang,
          alignment: Alignment.center,
          isDense: true,
          dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
              size: 18,
            ),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          items: [
            DropdownMenuItem(
              value: 'fr',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇫🇷', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    compact ? 'FR' : 'Français',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 12.5,
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
                  const Text('🇲🇬', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    compact ? 'MG' : 'Malagasy',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 12.5,
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