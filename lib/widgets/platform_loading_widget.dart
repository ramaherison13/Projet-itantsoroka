import 'package:flutter/material.dart';
import 'logo_widget.dart';

class PlatformLoadingWidget extends StatefulWidget {
  const PlatformLoadingWidget({super.key});

  @override
  State<PlatformLoadingWidget> createState() => _PlatformLoadingWidgetState();
}

class _PlatformLoadingWidgetState extends State<PlatformLoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoWidget(width: 112.0), // 7rem (7 * 16px)
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double delay = index * 0.15;
                    final double value = (_controller.value - delay).clamp(0.0, 1.0);
                    final double translateY = -8 * (1 - (value - 0.5).abs() * 2);

                    return Transform.translate(
                      offset: Offset(0, translateY < 0 ? translateY : 0),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}