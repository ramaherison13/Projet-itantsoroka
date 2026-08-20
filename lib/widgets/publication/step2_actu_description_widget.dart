import 'package:flutter/material.dart';

class ThemeModel {
  final String id;
  final String name;

  ThemeModel({required this.id, required this.name});
}

class Step2ActuDescriptionWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, dynamic value) onChange;

  const Step2ActuDescriptionWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step2ActuDescriptionWidget> createState() => _Step2ActuDescriptionWidgetState();
}

class _Step2ActuDescriptionWidgetState extends State<Step2ActuDescriptionWidget> {
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
  void didUpdateWidget(covariant Step2ActuDescriptionWidget oldWidget) {
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
    List<dynamic> currentThemes = List.from(widget.data['themeId'] ?? []);
    if (!currentThemes.contains(_mandatoryTheme)) {
      currentThemes.insert(0, _mandatoryTheme);
      widget.onChange('themeId', currentThemes);
    }
  }

  Future<void> _fetchThemes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulation API
      setState(() {
        _themes = [
          ThemeModel(id: 't1', name: 'Infrastructure'),
          ThemeModel(id: 't2', name: 'Éducation'),
          ThemeModel(id: 't3', name: 'Santé'),
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
    final List<dynamic> themeIds = widget.data['themeId'] ?? [];
    final String visibility = widget.data['visibility'] ?? 'public';

    final visibilityOptions = [
      {'id': 'public', 'name': 'Public', 'description': 'Visible par tous'},
      {'id': 'private', 'name': 'Privé', 'description': 'Visible uniquement par les personnes autorisées'},
      {'id': 'restricted', 'name': 'Restreint', 'description': 'Visible par certains groupes'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
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
            "Décrivez en détail le contenu de l'actualité et configurez ses paramètres.",
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            "Description de l'actualité *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              TextField(
                controller: _descriptionController,
                onChanged: (val) => widget.onChange('description', val),
                maxLines: 5,
                maxLength: 1000,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Décrivez en détail votre actualité...',
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
                  counterText: '', // Cache le compteur natif pour utiliser le style customisé
                ),
              ),
              Positioned(
                bottom: 8,
                right: 12,
                child: Text(
                  '${_descriptionController.text.length}/1000',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Thèmes
          Text(
            "Thèmes de l'actualité *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),

          // Tags sélectionnés
          if (themeIds.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themeIds.where((t) => t != _mandatoryTheme).map((themeId) {
                final selectedTheme = _themes.firstWhere(
                  (t) => t.id == themeId,
                  orElse: () => ThemeModel(id: themeId, name: themeId),
                );
                return Chip(
                  label: Text(selectedTheme.name, style: TextStyle(color: isDarkMode ? Colors.indigo.shade200 : Colors.indigo.shade700)),
                  backgroundColor: isDarkMode ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade100,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    List<dynamic> newThemes = List.from(themeIds);
                    newThemes.remove(themeId);
                    if (!newThemes.contains(_mandatoryTheme)) {
                      newThemes.insert(0, _mandatoryTheme);
                    }
                    widget.onChange('themeId', newThemes);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 8),

          // Sélecteur de thème
          _loadingThemes
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Chargement des thèmes...'),
                )
              : DropdownButtonFormField<String>(
                  initialValue: null,
                  hint: const Text('Sélectionnez un thème à ajouter'),
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
                    final bool isSelected = themeIds.contains(theme.id);
                    return DropdownMenuItem<String>(
                      value: theme.id,
                      enabled: !isSelected,
                      child: Text(
                        isSelected ? '${theme.name} (déjà sélectionné)' : theme.name,
                        style: TextStyle(color: isSelected ? Colors.grey : (isDarkMode ? Colors.white : Colors.black87)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && !themeIds.contains(val)) {
                      List<dynamic> newThemes = List.from(themeIds);
                      newThemes.add(val);
                      if (!newThemes.contains(_mandatoryTheme)) {
                        newThemes.insert(0, _mandatoryTheme);
                      }
                      widget.onChange('themeId', newThemes);
                    }
                  },
                ),
          const SizedBox(height: 20),

          // Visibilité
          Text(
            "Visibilité de l'actualité *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: visibility,
            onChanged: (val) {
              if (val != null) {
                widget.onChange('visibility', val);
              }
            },
            child: Column(
              children: visibilityOptions.map((option) {
                final bool isSelected = visibility == option['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDarkMode ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50)
                        : (isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.green
                          : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: RadioListTile<String>(
                      title: Text(option['name']!, style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87)),
                      subtitle: Text(option['description']!, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                      value: option['id']!,
                      activeColor: Colors.green,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}