import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController with ChangeNotifier {
  String _theme = "light";

  String get theme => _theme;

  ThemeController() {
    getThemeDefault();
  }

  Future<void> toggleTheme() async {
    final newTheme = _theme == "light" ? "dark" : "light";
    _theme = newTheme;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("theme", newTheme);
    
    debugPrint(true.toString());
    
    notifyListeners();
  }

  Future<void> getThemeDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString("theme") ?? "light";
    _theme = savedTheme;
    notifyListeners();
  }
}