import 'dart:io';
import 'package:flutter/foundation.dart';

class MonographieEditController with ChangeNotifier {
  File? _monographieFile;
  String _resume = '';
  String _details = '';
  bool _showGuide = true;
  String? _showPreview; // null, "resume", ou "details"

  File? get monographieFile => _monographieFile;
  String get resume => _resume;
  String get details => _details;
  bool get showGuide => _showGuide;
  String? get showPreview => _showPreview;

  void setMonographieFile(File? file) {
    _monographieFile = file;
    notifyListeners();
  }

  void setResume(String value) {
    _resume = value;
    notifyListeners();
  }

  void setDetails(String value) {
    _details = value;
    notifyListeners();
  }

  void setShowGuide(bool value) {
    _showGuide = value;
    notifyListeners();
  }

  void setShowPreview(String? value) {
    _showPreview = value;
    notifyListeners();
  }
}