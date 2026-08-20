import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String src;
  final String alt;
  final double size;
  final Color fallbackColor;

  const AvatarWidget({
    super.key,
    required this.src,
    required this.alt,
    required this.size,
    this.fallbackColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          src,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: fallbackColor,
              alignment: Alignment.center,
              child: Text(
                alt.isNotEmpty ? alt[0].toUpperCase() : '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size / 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}