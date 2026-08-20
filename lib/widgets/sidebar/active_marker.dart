import 'package:flutter/material.dart';

class ActiveMarker extends StatelessWidget {
  final double top;
  final double height;

  const ActiveMarker({
    super.key,
    required this.top,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient Indicator with smooth transition capability
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF098E00),
                  Color(0xFF0BA600),
                  Color(0xFF00C21C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF098E00).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        // Right side white indicator pill
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: top + (height * 0.125),
          right: 0,
          height: height * 0.75,
          child: Container(
            width: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(100),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}