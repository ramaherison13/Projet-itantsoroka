import 'package:flutter/material.dart';

enum ModalSize { sm, md, lg, xl, full }

class ModalWidget extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String title;
  final Widget children;
  final ModalSize size;

  const ModalWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.title,
    required this.children,
    this.size = ModalSize.lg,
  });

  double _getMaxWidth(ModalSize size) {
    switch (size) {
      case ModalSize.sm:
        return 448.0; // max-w-md
      case ModalSize.md:
        return 672.0; // max-w-2xl
      case ModalSize.lg:
        return 896.0; // max-w-4xl
      case ModalSize.xl:
        return 1152.0; // max-w-6xl
      case ModalSize.full:
        return 1280.0; // max-w-7xl
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Modal container
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _getMaxWidth(size),
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            tooltip: "Fermer",
                            style: IconButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: children,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}