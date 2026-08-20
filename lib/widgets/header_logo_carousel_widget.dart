import 'dart:async';
import 'package:flutter/material.dart';

class LogoItem {
  final String src;
  final String alt;
  final double width;

  LogoItem({required this.src, required this.alt, required this.width});
}

class HeaderLogoCarouselWidget extends StatefulWidget {
  const HeaderLogoCarouselWidget({super.key});

  @override
  State<HeaderLogoCarouselWidget> createState() => _HeaderLogoCarouselWidgetState();
}

class _HeaderLogoCarouselWidgetState extends State<HeaderLogoCarouselWidget> {
  final List<LogoItem> _logos = [
    LogoItem(src: "assets/images/logo_pnud.png", alt: "PNUD", width: 48),
    LogoItem(src: "assets/images/logo_ministere.jpg", alt: "Ministère de l'Intérieur", width: 48),
    LogoItem(src: "assets/images/logo_dd.png", alt: "Dispositif District", width: 80),
    LogoItem(src: "assets/images/logo_pnud_blue.png", alt: "PNUD Blue", width: 56),
  ];

  int _currentIndex = 0;
  bool _isPaused = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _logos.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isPaused = true),
      onExit: (_) => setState(() => _isPaused = false),
      child: SizedBox(
        height: 64,
        width: 100,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(_logos.length, (index) {
            final logo = _logos[index];
            final isCurrent = index == _currentIndex;

            return AnimatedOpacity(
              opacity: isCurrent ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedScale(
                scale: isCurrent ? 1.0 : 0.75,
                duration: const Duration(milliseconds: 500),
                child: Image.asset(
                  logo.src,
                  width: logo.width,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: logo.alt,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}