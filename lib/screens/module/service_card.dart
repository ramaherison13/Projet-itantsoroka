import 'package:flutter/material.dart';

class ServiceCard extends StatefulWidget {
  final Widget icon;
  final String title;
  final String description;
  final VoidCallback? onClick;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onClick,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onClick,
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
            highlightColor: const Color(0xFF16A34A).withValues(alpha: 0.05),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 20 : 28),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? (_isHovered ? const Color(0xFF1E293B) : const Color(0xFF0F172A))
                    : (_isHovered ? Colors.white : Colors.white.withValues(alpha: 0.9)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered
                      ? const Color(0xFF16A34A).withValues(alpha: 0.6)
                      : (isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200),
                  width: _isHovered ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? const Color(0xFF16A34A).withValues(alpha: isDarkMode ? 0.25 : 0.12)
                        : Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône avec conteneur stylisé
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isMobile ? 54 : 64,
                    height: isMobile ? 54 : 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isHovered
                            ? [const Color(0xFF16A34A), const Color(0xFF059669)]
                            : [
                                isDarkMode
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                                    : const Color(0xFFDCFCE7),
                                isDarkMode
                                    ? const Color(0xFF059669).withValues(alpha: 0.15)
                                    : const Color(0xFFF0FDF4),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: _isHovered
                              ? Colors.white
                              : (isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)),
                          size: isMobile ? 26 : 30,
                        ),
                        child: widget.icon,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 14 : 18),

                  // Titre
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 12.5 : 13.5,
                      height: 1.45,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}