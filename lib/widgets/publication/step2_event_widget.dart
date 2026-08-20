import 'package:flutter/material.dart';

class ThemeModel {
  final String id;
  final String name;

  ThemeModel({required this.id, required this.name});
}

class Step2EventWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, dynamic value) onChange;

  const Step2EventWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step2EventWidget> createState() => _Step2EventWidgetState();
}

class _Step2EventWidgetState extends State<Step2EventWidget> {
  List<ThemeModel> _themes = [];
  bool _loadingThemes = true;
  final String _mandatoryTheme = "Dispositif District";

  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.data['description'] ?? '');
    _fetchThemes();
    _checkMandatoryTheme();
  }

  @override
  void didUpdateWidget(covariant Step2EventWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data['description'] != _descriptionController.text) {
      _descriptionController.text = widget.data['description'] ?? '';
      _descriptionController.selection = TextSelection.fromPosition(
        TextPosition(offset: _descriptionController.text.length),
      );
    }
    _checkMandatoryTheme();
  }

  void _checkMandatoryTheme() {
    List<dynamic> currentThemes = List.from(widget.data['theme'] ?? []);
    if (!currentThemes.contains(_mandatoryTheme)) {
      currentThemes.insert(0, _mandatoryTheme);
      // Utilisation différée pour éviter d'appeler onChange pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChange('theme', currentThemes);
      });
    }
  }

  Future<void> _fetchThemes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _themes = [
          ThemeModel(id: 't1', name: 'Éducation'),
          ThemeModel(id: 't2', name: 'Environnement'),
          ThemeModel(id: 't3', name: 'Santé et Social'),
          ThemeModel(id: 't4', name: 'Culture et Sport'),
        ];
        _loadingThemes = false;
      });
    } catch (e) {
      setState(() => _loadingThemes = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String description = widget.data['description'] ?? '';
    final String visibility = widget.data['visibility'] ?? '';
    final List<dynamic> selectedThemes = widget.data['theme'] ?? [_mandatoryTheme];

    final visibilityOptions = [
      {"id": "public", "name": "Public", "description": "Visible par tous"},
      {"id": "private", "name": "Privé", "description": "Visible uniquement par les invités"},
      {"id": "restricted", "name": "Restreint", "description": "Visible par certains groupes"},
    ];

    final bool hasDesc = description.trim().isNotEmpty;
    final bool hasVis = visibility.trim().isNotEmpty;
    final bool hasTheme = selectedThemes.isNotEmpty;

    final filledFields = [hasDesc, hasVis, hasTheme].where((element) => element).length;
    final remainingFields = 3 - filledFields;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'étape
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description, size: 16, color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Étape 2', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500)),
                  Text(
                    'Description et détails',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Décrivez en détail le contenu de l'événement et configurez ses paramètres.",
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            "Description de l'événement *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              TextField(
                controller: _descriptionController,
                onChanged: (val) => widget.onChange('description', val),
                maxLines: 6,
                maxLength: 1000,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Décrivez en détail votre événement : objectifs, programme, public cible, déroulement...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  counterText: '', // Masque le compteur natif pour le replacer proprement
                ),
              ),
              Positioned(
                bottom: 8,
                right: 12,
                child: Text(
                  "${description.length}/1000",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Thèmes
          Text(
            "Thèmes de l'événement *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),

          // Tags sélectionnés
          if (selectedThemes.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedThemes.where((t) => t != _mandatoryTheme).map((themeId) {
                final selectedTheme = _themes.firstWhere(
                  (t) => t.id == themeId,
                  orElse: () => ThemeModel(id: themeId, name: themeId),
                );
                return Chip(
                  label: Text(selectedTheme.name),
                  backgroundColor: isDarkMode ? Colors.indigo.shade900.withValues(alpha: 0.4) : Colors.indigo.shade100,
                  labelStyle: TextStyle(color: isDarkMode ? Colors.indigo.shade200 : Colors.indigo.shade700, fontSize: 13),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    List<dynamic> newThemes = List.from(selectedThemes)..remove(themeId);
                    if (!newThemes.contains(_mandatoryTheme)) {
                      newThemes.insert(0, _mandatoryTheme);
                    }
                    widget.onChange('theme', newThemes);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Sélecteur de thème
          _loadingThemes
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("Chargement des thèmes...", style: TextStyle(color: Colors.grey.shade500)),
                )
              : DropdownButtonFormField<String>(
                  initialValue: null,
                  hint: const Text("Sélectionnez un thème à ajouter"),
                  dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                    ),
                  ),
                  items: _themes.map((theme) {
                    final bool isAlreadySelected = selectedThemes.contains(theme.id);
                    return DropdownMenuItem<String>(
                      value: theme.id,
                      enabled: !isAlreadySelected,
                      child: Text(
                        isAlreadySelected ? "${theme.name} (déjà sélectionné)" : theme.name,
                        style: TextStyle(color: isAlreadySelected ? Colors.grey : (isDarkMode ? Colors.white : Colors.black87)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && !selectedThemes.contains(val)) {
                      List<dynamic> newThemes = [...selectedThemes, val];
                      if (!newThemes.contains(_mandatoryTheme)) {
                        newThemes.insert(0, _mandatoryTheme);
                      }
                      widget.onChange('theme', newThemes);
                    }
                  },
                ),
          const SizedBox(height: 24),

          // Visibilité
          Text(
            "Visibilité de l'événement *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: visibility,
            onChanged: (val) {
              if (val != null) widget.onChange('visibility', val);
            },
            child: Column(
              children: visibilityOptions.map((option) {
                final isSelected = visibility == option['id'];
                return InkWell(
                  onTap: () => widget.onChange('visibility', option['id']!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDarkMode ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50)
                          : (isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade50),
                      border: Border.all(
                        color: isSelected ? Colors.green : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: option['id']!,
                          activeColor: Colors.green,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option['description']!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
          const SizedBox(height: 24),

          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Progression de l'étape", style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white70 : Colors.black87)),
                    Text("$filledFields/3 champs complétés", style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: filledFields / 3,
                  backgroundColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 8),
                remainingFields > 0
                    ? Text("$remainingFields champ(s) restant(s)", style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                    : const Text("✓ Tous les champs sont remplis", style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ),

          // Aperçu des informations
          if (hasDesc && hasTheme && hasVis) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50,
                border: Border.all(color: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aperçu de votre événement",
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Thèmes: ${selectedThemes.map((id) => _themes.firstWhere((t) => t.id == id, orElse: () => ThemeModel(id: id, name: id)).name).join(', ')}",
                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Visibilité: ${visibilityOptions.firstWhere((v) => v['id'] == visibility, orElse: () => {'name': visibility})['name']}",
                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Description: ${description.length > 150 ? '${description.substring(0, 150)}...' : description}",
                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}