import 'package:flutter/material.dart';

class FloatingDiscussionButtonWidget extends StatefulWidget {
  final bool isAuthenticated;
  final Widget discussionWidget; // Le widget de discussion à l'intérieur de la boîte

  const FloatingDiscussionButtonWidget({
    super.key,
    required this.isAuthenticated,
    required this.discussionWidget,
  });

  @override
  State<FloatingDiscussionButtonWidget> createState() => _FloatingDiscussionButtonWidgetState();
}

class _FloatingDiscussionButtonWidgetState extends State<FloatingDiscussionButtonWidget> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isOpen) {
      return Material(
        elevation: 24,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 420,
          height: 600,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Header du widget
              Container(
                color: const Color(0xFF098e00),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Discussions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isOpen = false),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        hoverColor: Colors.white.withValues(alpha: 0.2),
                        shape: const CircleBorder(),
                      ),
                      tooltip: "Fermer les discussions",
                    ),
                  ],
                ),
              ),
              // Contenu du widget
              Expanded(
                child: widget.discussionWidget,
              ),
            ],
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: () => setState(() => _isOpen = true),
      backgroundColor: const Color(0xFF098e00),
      elevation: 8,
      tooltip: "Ouvrir les discussions",
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
    );
  }
}