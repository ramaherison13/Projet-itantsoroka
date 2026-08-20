import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerritoireProvider with ChangeNotifier {
  dynamic _value;
  dynamic _territoireMonographie;

  dynamic get value => _value;
  dynamic get territoireMonographie => _territoireMonographie;

  Future<void> setGlobalTerritoire(dynamic territoire) async {
    _value = territoire;
    debugPrint(territoire.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("territoire", jsonEncode(territoire));
    notifyListeners();
  }

  Future<void> setMonographieTerritoire(dynamic territoire) async {
    _value = territoire;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("territoire", jsonEncode(territoire));
    notifyListeners();
  }

  void clearTerritoire() {
    _value = null;
    notifyListeners();
  }

  Future<void> restoreTerritoire() async {
    final prefs = await SharedPreferences.getInstance();
    final territoireString = prefs.getString("territoire");
    if (territoireString != null) {
      try {
        _value = jsonDecode(territoireString);
      } catch (e) {
        _value = territoireString;
      }
      notifyListeners();
    }
  }
}