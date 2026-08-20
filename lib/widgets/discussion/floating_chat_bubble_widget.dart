import 'package:flutter/material.dart';

class FloatingChatBubbleWidget extends StatefulWidget {
  final bool isAuthenticated;
  final Widget chatContent; // Contenu ou page de discussion à afficher dans la modale
  final int unreadCount;

  const FloatingChatBubbleWidget({
    super.key,
    required this.isAuthenticated,
    required this.chatContent,
    this.unreadCount = 3,
  });

  @override
  State<FloatingChatBubbleWidget> createState() => _FloatingChatBubbleWidgetState();
}

class _FloatingChatBubbleWidgetState extends State<FloatingChatBubbleWidget> {
  bool _isOpen = false;

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Modal de discussion (Affichée au-dessus de la bulle)
        if (_isOpen)
          Material(
            elevation: 24,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 900,
              height: 600,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: widget.chatContent,
            ),
          ),

        if (_isOpen) const SizedBox(height: 16),

        // Bulle flottante
        FloatingActionButton(
          onPressed: _toggleChat,
          backgroundColor: Colors.transparent,
          elevation: 8,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _isOpen ? Icons.close : Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 28,
                ),
                if (!_isOpen && widget.unreadCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}