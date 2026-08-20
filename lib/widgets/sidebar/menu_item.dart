import 'package:flutter/material.dart';

// Fonction utilitaire pour mapper les noms d'icônes string aux icônes Flutter Material
IconData getIconByName(String? name) {
  switch (name?.toLowerCase()) {
    case 'home':
      return Icons.home;
    case 'dashboard':
    case 'layoutdashboard':
      return Icons.dashboard;
    case 'user':
    case 'users':
      return Icons.person;
    case 'settings':
      return Icons.settings;
    case 'logout':
      return Icons.logout;
    case 'filetext':
    case 'document':
      return Icons.description;
    default:
      return Icons.insert_drive_file;
  }
}

class MenuItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onClick;
  final int index;
  final bool isFooter;
  final bool isActive;

  const MenuItemWidget({
    super.key,
    required this.item,
    this.onClick,
    required this.index,
    this.isFooter = false,
    this.isActive = false,
  });

  @override
  MenuItemWidgetState createState() => MenuItemWidgetState();
}

class MenuItemWidgetState extends State<MenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconName = widget.item['icon'] ?? '';
    final nameKey = widget.item['nameKey'] ?? '';
    final badge = widget.item['badge'];

    const darkGreenAccent = Color(0xFF00C21C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onClick,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? Colors.white.withValues(alpha: 0.1)
                  : (_isHovered
                      ? (isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.6) : const Color(0xFFF0FFF0))
                      : Colors.transparent),
              gradient: _isHovered && !widget.isActive
                  ? LinearGradient(
                      colors: isDarkMode
                          ? [Colors.grey.shade700.withValues(alpha: 0.4), Colors.grey.shade700.withValues(alpha: 0.6)]
                          : [const Color(0xFFF0FFF0), const Color(0xFFE8FFE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Icône avec conteneur stylisé
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? Colors.white.withValues(alpha: 0.25)
                        : darkGreenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: widget.isActive
                        ? [const BoxShadow(color: Colors.black12, blurRadius: 2)]
                        : [],
                  ),
                  child: Icon(
                    getIconByName(iconName),
                    size: 20,
                    color: widget.isActive
                        ? Colors.white
                        : darkGreenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                // Texte du menu
                Expanded(
                  child: Text(
                    nameKey,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: widget.isActive
                          ? Colors.white
                          : (isDarkMode ? Colors.grey.shade300 : const Color(0xFF5D5D5D)),
                    ),
                  ),
                ),
                // Badge optionnel
                if (badge != null && badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      "$badge",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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