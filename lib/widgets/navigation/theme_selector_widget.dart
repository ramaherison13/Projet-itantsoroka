import 'package:flutter/material.dart';

class ThemeModel {
  final String themeId;
  final String name;

  const ThemeModel({
    required this.themeId,
    required this.name,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      themeId: json['theme_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class ThemeSelectorWidget extends StatefulWidget {
  final List<ThemeModel> themes;
  final ValueChanged<String> onThemeSelect;

  const ThemeSelectorWidget({
    super.key,
    required this.themes,
    required this.onThemeSelect,
  });

  @override
  State<ThemeSelectorWidget> createState() => _ThemeSelectorWidgetState();
}

class _ThemeSelectorWidgetState extends State<ThemeSelectorWidget> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700;

    return PopupMenuButton<String>(
      // Note: standard Flutter PopupMenuButton handles its own open state
      onOpened: () => setState(() => _isOpen = true),
      onCanceled: () => setState(() => _isOpen = false),
      onSelected: (String themeId) {
        setState(() => _isOpen = false);
        widget.onThemeSelect(themeId);
      },
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      itemBuilder: (BuildContext context) {
        if (widget.themes.isEmpty) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                "Aucun thème disponible",
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ),
          ];
        }

        return widget.themes.map((theme) {
          return PopupMenuItem<String>(
            value: theme.themeId,
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                theme.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList();
      },
      child: InkWell(
        onTap: () {}, // Handled by PopupMenuButton wrapper or direct callback if needed
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.book_outlined,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Text(
                "Thématiques",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}