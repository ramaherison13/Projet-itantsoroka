import 'package:flutter/foundation.dart';

class TerritoireVisiteProvider with ChangeNotifier {
  List<dynamic> _territoiresEnCollecte = [];

  List<dynamic> get territoiresEnCollecte => _territoiresEnCollecte;

  // ➕ Ajouter un territoire à la collecte (évite les doublons)
  void ajouterTerritoireEnCollecte(dynamic territoire) {
    final int? id = territoire is Map ? territoire['id'] : null;
    if (id != null) {
      final existe = _territoiresEnCollecte.any((t) => (t is Map ? t['id'] : null) == id);
      if (!existe) {
        _territoiresEnCollecte.add(territoire);
        notifyListeners();
      }
    }
  }

  // ➖ Retirer un territoire par ID
  void retirerTerritoireEnCollecte(int id) {
    _territoiresEnCollecte.removeWhere((t) => (t is Map ? t['id'] : null) == id);
    notifyListeners();
  }

  // 🧹 Vider toute la collecte
  void viderCollecte() {
    _territoiresEnCollecte = [];
    notifyListeners();
  }

  // ✅ SELECTORS (Méthodes utilitaires équivalentes)
  bool contientTerritoireById(int id) {
    return _territoiresEnCollecte.any((t) => (t is Map ? t['id'] : null) == id);
  }

  dynamic getTerritoireEnCollecteById(int id) {
    try {
      return _territoiresEnCollecte.firstWhere((t) => (t is Map ? t['id'] : null) == id);
    } catch (e) {
      return null;
    }
  }

  int get nombreTerritoiresEnCollecte {
    return _territoiresEnCollecte.length;
  }
}