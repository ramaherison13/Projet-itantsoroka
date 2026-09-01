import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localization.dart';

// ── ÉTAPE 3 : Widget d'alertes autonome avec Timer isolé ──────────────────────
// Ce widget possède son propre état et son propre Timer.
// Ainsi, le défilement des alertes ne reconstruit plus toute la HomePage.
class HomeAlertsBanner extends StatefulWidget {
  final bool isDark;
  final double screenW;

  const HomeAlertsBanner({
    super.key,
    required this.isDark,
    required this.screenW,
  });

  @override
  State<HomeAlertsBanner> createState() => _HomeAlertsBannerState();
}

class _HomeAlertsBannerState extends State<HomeAlertsBanner> {
  bool _visible = true;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_visible) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isMobileSmall(double w) => w < 380;

  List<Map<String, dynamic>> _buildAlerts(BuildContext context) => [
        {
          'title': context.tr('alert_legalite_title'),
          'message': context.tr('alert_legalite_msg'),
          'type': context.tr('alert_type_urgent'),
          'color': Colors.red.shade600,
          'icon': Icons.warning_amber_rounded,
          'actionText': context.tr('alert_legalite_action'),
          'path': '/soumission-acte',
        },
        {
          'title': context.tr('alert_mono_title'),
          'message': context.tr('alert_mono_msg'),
          'type': context.tr('alert_type_info'),
          'color': Colors.blue.shade600,
          'icon': Icons.info_outline_rounded,
          'actionText': context.tr('alert_mono_action'),
          'path': '/monographie',
        },
        {
          'title': context.tr('alert_affil_title'),
          'message': context.tr('alert_affil_msg'),
          'type': context.tr('alert_type_nouveau'),
          'color': Colors.green.shade600,
          'icon': Icons.verified_user_outlined,
          'actionText': context.tr('alert_affil_action'),
          'path': '/offrestd',
        },
      ];

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final alerts = _buildAlerts(context);
    final alert = alerts[_currentIndex];
    final Color alertColor = alert['color'] as Color;
    final bool isSmall = _isMobileSmall(widget.screenW);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_currentIndex),
        width: double.infinity,
        padding: EdgeInsets.all(isSmall ? 13 : 15),
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF1E293B)
              : alertColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: alertColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alert['icon'] as IconData,
                    color: alertColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: alertColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert['type'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _visible = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              alert['message'] as String,
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicateurs de page
                Row(
                  children: List.generate(
                    alerts.length,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _currentIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 5),
                        width: _currentIndex == i ? 14 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _currentIndex == i
                              ? alertColor
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(alert['path'] as String),
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: alertColor,
                  ),
                  label: Text(
                    alert['actionText'] as String,
                    style: TextStyle(
                      color: alertColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
