import 'package:flutter/material.dart';

class SpinnerWidget extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const SpinnerWidget({
    super.key,
    this.color,
    this.size = 32.0, // Équivalent de h-8 w-8 (8 * 4px = 32px)
    this.strokeWidth = 2.0, // Équivalent de border-t-2 border-b-2
  });

  @override
  Widget build(BuildContext context) {
    return Center( // Équivalent de flex justify-center items-center
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          // Utilise border-gray-100 par défaut, ou une couleur personnalisée (utile si le fond est clair)
          color: color ?? Colors.grey.shade100, 
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}