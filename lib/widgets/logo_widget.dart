import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LogoWidget extends StatelessWidget {
  final double width;
  final VoidCallback? onTap;

  const LogoWidget({
    super.key,
    this.width = 140.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap ?? () {
        context.go('/');
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isDarkMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Image.asset(
            'assets/images/logo_dd_v3.png',
            width: width,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/logo_dd.png',
              width: width,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (ctx, err, _) => Container(
                width: width,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF098E00), Color(0xFF056B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Dispositif District',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}