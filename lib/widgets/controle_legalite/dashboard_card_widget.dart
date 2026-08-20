import 'package:flutter/material.dart';

class DashboardCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String comparison;
  final String percentage;
  final bool isIncrease;
  final Widget icon;
  final Color borderColor;
  final Color iconBgColor;

  const DashboardCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.comparison,
    required this.percentage,
    required this.isIncrease,
    required this.icon,
    required this.borderColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final percentColor = isIncrease ? Colors.green : Colors.red;
    final arrow = isIncrease ? '▲' : '▼';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: icon,
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          Row(
            children: [
              Text(
                '$arrow $percentage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: percentColor,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  comparison,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}