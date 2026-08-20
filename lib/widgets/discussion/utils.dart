import 'package:flutter/material.dart';

class Utils {
  static Color getFallbackColor(String id) {
    final colors = [
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.blue.shade400,
      Colors.amber.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.orange.shade400,
    ];

    int sum = 0;
    for (int i = 0; i < id.length; i++) {
      sum += id.codeUnitAt(i);
    }

    return colors[sum % colors.length];
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'en ligne':
        return Colors.green;
      case 'away':
      case 'absent':
        return Colors.amber.shade400;
      case 'busy':
      case 'occupé':
        return Colors.red;
      default:
        return Colors.grey; // offline
    }
  }
}