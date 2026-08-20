import 'package:flutter/material.dart';

class MobileHeader extends StatelessWidget {
  final VoidCallback onClose;

  const MobileHeader({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo / En-tête
          SizedBox(
            width: 80, // ~5rem en Flutter
            child: Text(
              "Logo",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),

          // Bouton de fermeture
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close,
                  size: 22,
                  color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF5D5D5D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}