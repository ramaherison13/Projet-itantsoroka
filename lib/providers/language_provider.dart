import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _prefKey = 'selected_language';
  Locale _locale = const Locale('fr', 'FR');

  Locale get locale => _locale;
  String get currentLanguageCode => _locale.languageCode;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString(_prefKey) ?? 'fr';
      if (langCode == 'mg') {
        _locale = const Locale('mg', 'MG');
      } else {
        _locale = const Locale('fr', 'FR');
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode == _locale.languageCode) return;

    if (langCode == 'mg') {
      _locale = const Locale('mg', 'MG');
    } else {
      _locale = const Locale('fr', 'FR');
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (_) {}
  }
}
