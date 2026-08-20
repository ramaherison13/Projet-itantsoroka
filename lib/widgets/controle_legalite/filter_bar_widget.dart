import 'package:flutter/material.dart';

class FilterBarWidget extends StatelessWidget {
  final String communeFilter;
  final String typeActeFilter;
  final String sousTypeActeFilter;
  final String dateSubmissionFilter;
  final String statutFilter;
  final String periodeFilter;
  final List<dynamic> communes;
  final List<dynamic> typesActes;
  final List<dynamic> sousTypesActes;
  final bool loadingCommunes;
  final bool loadingTypes;
  final bool loadingSousTypes;
  final ValueChanged<String> onCommuneChange;
  final ValueChanged<String> onTypeActeChange;
  final ValueChanged<String> onSousTypeActeChange;
  final ValueChanged<String> onDateSubmissionChange;
  final ValueChanged<String> onStatutChange;
  final ValueChanged<String> onPeriodeChange;
  final VoidCallback onReset;

  const FilterBarWidget({
    super.key,
    required this.communeFilter,
    required this.typeActeFilter,
    required this.sousTypeActeFilter,
    required this.dateSubmissionFilter,
    required this.statutFilter,
    required this.periodeFilter,
    required this.communes,
    required this.typesActes,
    required this.sousTypesActes,
    required this.loadingCommunes,
    required this.loadingTypes,
    required this.loadingSousTypes,
    required this.onCommuneChange,
    required this.onTypeActeChange,
    required this.onSousTypeActeChange,
    required this.onDateSubmissionChange,
    required this.onStatutChange,
    required this.onPeriodeChange,
    required this.onReset,
  });

  InputDecoration _dropdownDecoration(bool isDarkMode) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Commune dropdown
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: communes.any((c) => c['formatted_id'] == communeFilter) || communeFilter == 'Tout' ? communeFilter : 'Tout',
            decoration: _dropdownDecoration(isDarkMode),
            dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
            style: TextStyle(fontSize: 14, color: textColor),
            items: [
              const DropdownMenuItem(value: 'Tout', child: Text('Commune: Tout')),
              ...communes.map((c) => DropdownMenuItem(
                    value: c['formatted_id'].toString(),
                    child: Text(c['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: loadingCommunes ? null : (val) => onCommuneChange(val ?? 'Tout'),
          ),
        ),

        // Type d'acte dropdown
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: typesActes.any((t) => t['id'] == typeActeFilter) || typeActeFilter == 'Tout' ? typeActeFilter : 'Tout',
            decoration: _dropdownDecoration(isDarkMode),
            dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
            style: TextStyle(fontSize: 14, color: textColor),
            items: [
              const DropdownMenuItem(value: 'Tout', child: Text("Type d'acte: Tout")),
              ...typesActes.map((t) => DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text(t['nom']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: loadingTypes ? null : (val) => onTypeActeChange(val ?? 'Tout'),
          ),
        ),

        // Sous-type d'acte dropdown (conditionnel)
        if (typeActeFilter != 'Tout')
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: sousTypesActes.any((st) => st['id'] == sousTypeActeFilter) || sousTypeActeFilter == 'Tout' ? sousTypeActeFilter : 'Tout',
              decoration: _dropdownDecoration(isDarkMode),
              dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(fontSize: 14, color: textColor),
              items: [
                const DropdownMenuItem(value: 'Tout', child: Text('Sous-type: Tout')),
                ...sousTypesActes.map((st) => DropdownMenuItem(
                      value: st['id'].toString(),
                      child: Text(st['nom']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: loadingSousTypes ? null : (val) => onSousTypeActeChange(val ?? 'Tout'),
            ),
          ),

        // Date de soumission input
        SizedBox(
          width: 180,
          child: TextFormField(
            initialValue: dateSubmissionFilter,
            decoration: _dropdownDecoration(isDarkMode).copyWith(
              hintText: 'Date de soumission',
              prefixIcon: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            ),
            style: TextStyle(fontSize: 14, color: textColor),
            onChanged: onDateSubmissionChange,
          ),
        ),

        // Statut dropdown
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: ['Tout', 'en_cours', 'accepte', 'rejete', 'observation'].contains(statutFilter) ? statutFilter : 'Tout',
            decoration: _dropdownDecoration(isDarkMode),
            dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
            style: TextStyle(fontSize: 14, color: textColor),
            items: const [
              DropdownMenuItem(value: 'Tout', child: Text('Statut: Tout')),
              DropdownMenuItem(value: 'en_cours', child: Text('En attente')),
              DropdownMenuItem(value: 'accepte', child: Text('Accepté')),
              DropdownMenuItem(value: 'rejete', child: Text('Rejeté')),
              DropdownMenuItem(value: 'observation', child: Text('Observation')),
            ],
            onChanged: (val) => onStatutChange(val ?? 'Tout'),
          ),
        ),

        // Période dropdown
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: ['Tout', 'semaine', 'mois', 'trimestre'].contains(periodeFilter) ? periodeFilter : 'Tout',
            decoration: _dropdownDecoration(isDarkMode),
            dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
            style: TextStyle(fontSize: 14, color: textColor),
            items: const [
              DropdownMenuItem(value: 'Tout', child: Text('Période: Tout')),
              DropdownMenuItem(value: 'semaine', child: Text('Cette semaine')),
              DropdownMenuItem(value: 'mois', child: Text('Ce mois')),
              DropdownMenuItem(value: 'trimestre', child: Text('Ce trimestre')),
            ],
            onChanged: (val) => onPeriodeChange(val ?? 'Tout'),
          ),
        ),

        // Reset button
        ElevatedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.rotate_left, size: 16),
          label: const Text('Réinitialiser', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            foregroundColor: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }
}