import 'package:flutter/material.dart';

class PageHeaderWidget extends StatelessWidget {
  final VoidCallback onNewActePressed;

  const PageHeaderWidget({
    super.key,
    required this.onNewActePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDarkMode
                        ? [Colors.green.shade400, Colors.teal.shade400]
                        : [Colors.green.shade600, Colors.teal.shade600],
                  ).createShader(bounds),
                  child: const Text(
                    'Gestion des observations sur les actes communaux',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ajoutez des remarques, demandez des compléments et assurez le suivi des échanges avec les communes.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onNewActePressed,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Nouvel acte',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C21C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}