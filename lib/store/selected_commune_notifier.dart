import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── ÉTAPE 4 : Migré de flutter_riverpod vers ChangeNotifier (provider) ────────
// flutter_riverpod a été retiré du projet car il n'était utilisé que dans ce
// fichier. On utilise maintenant ChangeNotifier (déjà présent via provider).

class SelectedCommuneState {
  final String id;
  final String statut;
  final String periode;

  SelectedCommuneState({
    required this.id,
    required this.statut,
    required this.periode,
  });

  SelectedCommuneState copyWith({
    String? id,
    String? statut,
    String? periode,
  }) {
    return SelectedCommuneState(
      id: id ?? this.id,
      statut: statut ?? this.statut,
      periode: periode ?? this.periode,
    );
  }
}

class SelectedCommuneNotifier extends ChangeNotifier {
  SelectedCommuneState _state = SelectedCommuneState(
    id: '',
    statut: 'tous',
    periode: 'toutes',
  );

  SelectedCommuneState get state => _state;

  SelectedCommuneNotifier() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selectedCommuneId') ?? '';
    final statut = prefs.getString('selectedStatut') ?? 'tous';
    final periode = prefs.getString('selectedPeriode') ?? 'toutes';

    _state = SelectedCommuneState(id: id, statut: statut, periode: periode);
    notifyListeners();
  }

  Future<void> setSelectedCommune(dynamic communeId) async {
    final prefs = await SharedPreferences.getInstance();
    final stringId = communeId.toString();

    if (stringId.isEmpty) {
      await prefs.remove('selectedCommuneId');
    } else {
      await prefs.setString('selectedCommuneId', stringId);
    }
    _state = _state.copyWith(id: stringId);
    notifyListeners();
  }

  Future<void> setSelectedStatut(String statut) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedStatut', statut);
    _state = _state.copyWith(statut: statut);
    notifyListeners();
  }

  Future<void> setSelectedPeriode(String periode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedPeriode', periode);
    _state = _state.copyWith(periode: periode);
    notifyListeners();
  }
}