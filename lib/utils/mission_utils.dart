import 'package:flutter/material.dart';

class MissionColorUtils {
  static Color getMissionColor(String status) {
    switch (status.toLowerCase()) {
      case "planifier":
        return Colors.amber.shade400; // shade450 n'existe pas, utiliser amber ou yellow.shade400
      case "en cours":
        return Colors.blue;
      case "terminée":
        return Colors.green;
      case "non planifier":
        return Colors.red;
      default:
        return Colors.grey.shade400;
    }
  }
}