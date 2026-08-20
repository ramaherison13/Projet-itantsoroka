import 'package:flutter/material.dart';

class LogoutButton extends StatefulWidget {
  final VoidCallback? onClick;
  final String label;

  const LogoutButton({
    super.key,
    this.onClick,
    this.label = "Déconnexion",
  });

  @override
  LogoutButtonState createState() => LogoutButtonState();
}

class LogoutButtonState extends State<LogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onClick,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _isHovered
                  ? LinearGradient(
                      colors: isDarkMode
                          ? [Colors.red.shade700, Colors.red.shade800]
                          : [Colors.red.shade500, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? Colors.white.withValues(alpha: 0.25)
                        : (isDarkMode
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 20,
                    color: _isHovered
                        ? Colors.white
                        : (isDarkMode ? Colors.red.shade400 : Colors.red.shade500),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: _isHovered
                          ? Colors.white
                          : (isDarkMode ? Colors.red.shade400 : Colors.red.shade500),
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