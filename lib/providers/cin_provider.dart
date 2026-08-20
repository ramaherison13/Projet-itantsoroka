import 'package:flutter/foundation.dart';

class CinProvider with ChangeNotifier {
  String _value = "";

  String get value => _value;

  void setGlobalCin(String cin) {
    _value = cin;
    notifyListeners();
  }

  void clearCin() {
    _value = "";
    notifyListeners();
  }
}