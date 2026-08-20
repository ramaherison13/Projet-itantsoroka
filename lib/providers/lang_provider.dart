import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LangProvider with ChangeNotifier {
  String _currentLang = "fr";

  String get currentLang => _currentLang;

  LangProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString("appLanguage");
    if (savedLang != null && (savedLang == "fr" || savedLang == "mg")) {
      _currentLang = savedLang;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String lang) async {
    if (lang == "fr" || lang == "mg") {
      _currentLang = lang;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("appLanguage", lang);
      
      // Appliquer dans le système de localisation si nécessaire (ex: context.setLocale(Locale(lang)))
      
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    final newLang = _currentLang == "fr" ? "mg" : "fr";
    await setLanguage(newLang);
  }
}