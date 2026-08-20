import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final spinnerColor = isDarkMode ? const Color(0xFF00C21C) : const Color(0xFF098E00);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Chargement...",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: spinnerColor,
            ),
          ),
        ],
      ),
    );
  }
}