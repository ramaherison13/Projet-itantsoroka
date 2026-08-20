import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SelectedCommuneNotifier extends Notifier<SelectedCommuneState> {
  @override
  SelectedCommuneState build() {
    _loadFromPrefs();
    return SelectedCommuneState(id: '', statut: 'tous', periode: 'toutes');
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selectedCommuneId') ?? '';
    final statut = prefs.getString('selectedStatut') ?? 'tous';
    final periode = prefs.getString('selectedPeriode') ?? 'toutes';
    
    state = SelectedCommuneState(id: id, statut: statut, periode: periode);
  }

  Future<void> setSelectedCommune(dynamic communeId) async {
    final prefs = await SharedPreferences.getInstance();
    final stringId = communeId.toString();
    
    if (stringId.isEmpty) {
      await prefs.remove('selectedCommuneId');
    } else {
      await prefs.setString('selectedCommuneId', stringId);
    }
    state = state.copyWith(id: stringId);
  }

  Future<void> setSelectedStatut(String statut) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedStatut', statut);
    state = state.copyWith(statut: statut);
  }

  Future<void> setSelectedPeriode(String periode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedPeriode', periode);
    state = state.copyWith(periode: periode);
  }
}

final selectedCommuneProvider =
    NotifierProvider<SelectedCommuneNotifier, SelectedCommuneState>(
  () => SelectedCommuneNotifier(),
);