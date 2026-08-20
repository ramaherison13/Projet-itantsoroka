import 'package:flutter/material.dart';

class NavBarWidget extends StatelessWidget {
  final bool isAuthenticated;
  final bool isActivated;
  final String currentPath;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onLinkClicked;

  const NavBarWidget({
    super.key,
    required this.isAuthenticated,
    required this.isActivated,
    required this.currentPath,
    required this.onNavigate,
    this.onLinkClicked,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> links = [
      {"to": "/", "text": "Accueil"},
      {"to": "/monographie", "text": "Monographie"},
      {"to": "/actualites", "text": "Actualités"},
      {"to": "/offres-appui", "text": "Offres d'Appui"},
      {"to": "/officeprojet", "text": "Projet"},
    ];

    final List<Map<String, String>> itantsorika = [
      {"to": "/monographie", "text": "Monographie"},
      {"to": "/actualites", "text": "Actualités"},
      {"to": "/gestion", "text": "Réservation"},
      {"to": "/offres-appui", "text": "Offres d'Appui"},
      {"to": "/officeprojet", "text": "Projet"},
    ];

    final activeList = (isAuthenticated && isActivated) ? itantsorika : links;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeScreen = MediaQuery.of(context).size.width >= 1024;

          if (isLargeScreen) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildNavLinks(activeList, isDarkMode),
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildNavLinks(activeList, isDarkMode),
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildNavLinks(List<Map<String, String>> list, bool isDarkMode) {
    return list.map((link) {
      final to = link["to"]!;
      final text = link["text"]!;
      final isActive = currentPath == to;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: InkWell(
          onTap: () {
            if (onLinkClicked != null) onLinkClicked!();
            onNavigate(to);
          },
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? const Color(0xFF00C21C)
                  : (isDarkMode ? Colors.grey.shade100 : const Color(0xFF444141)),
            ),
          ),
        ),
      );
    }).toList();
  }
}