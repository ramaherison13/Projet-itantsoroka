import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('theme_mode');
    if (modeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (modeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (modeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      final isDark = prefs.getBool('isDarkMode');
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString('theme_mode', 'dark');
      await prefs.setBool('isDarkMode', true);
    } else if (mode == ThemeMode.light) {
      await prefs.setString('theme_mode', 'light');
      await prefs.setBool('isDarkMode', false);
    } else {
      await prefs.setString('theme_mode', 'system');
      await prefs.remove('isDarkMode');
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
