import 'package:flutter/material.dart';

// Services factices ou à remplacer par vos propres services API
Future<List<Map<String, dynamic>>> getThemes() async {
  // TODO: Remplacer par votre appel API réel
  return [
    {'id': '1', 'name': 'Environnement'},
    {'id': '2', 'name': 'Éducation'},
    {'id': '3', 'name': 'Santé'},
  ];
}

Future<List<Map<String, dynamic>>> getCommunes() async {
  // TODO: Remplacer par votre appel API réel
  return [
    {'formatted_id': 'c1', 'name': 'Antananarivo Renivohitra'},
    {'formatted_id': 'c2', 'name': 'Toamasina I'},
  ];
}

class Step1GeneralWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, String value) onChange;

  const Step1GeneralWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step1GeneralWidget> createState() => _Step1GeneralWidgetState();
}

class _Step1GeneralWidgetState extends State<Step1GeneralWidget> {
  List<dynamic> _themes = [];
  List<dynamic> _communes = [];
  bool _loadingThemes = true;
  bool _loadingCommunes = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.data['name'] ?? '';
    _fetchThemes();
    _fetchCommunes();
  }

  @override
  void didUpdateWidget(covariant Step1GeneralWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data['name'] != _nameController.text) {
      _nameController.text = widget.data['name'] ?? '';
    }
  }

  Future<void> _fetchThemes() async {
    try {
      setState(() => _loadingThemes = true);
      final response = await getThemes();
      setState(() => _themes = response);
    } catch (e) {
      setState(() => _themes = []);
    } finally {
      setState(() => _loadingThemes = false);
    }
  }

  Future<void> _fetchCommunes() async {
    try {
      setState(() => _loadingCommunes = true);
      final response = await getCommunes();
      setState(() => _communes = response);
    } catch (e) {
      setState(() => _communes = []);
    } finally {
      setState(() => _loadingCommunes = false);
    }
  }

  String _formatDateForInput(String dateString) {
    if (dateString.isEmpty) return '';
    return dateString.split('T')[0];
  }

  String _formatDateForAPI(String dateString) {
    if (dateString.isEmpty) return '';
    return '${dateString}T00:00:00Z';
  }

  Future<void> _selectDate(BuildContext context, String field, String initialDateStr, String? minDateStr) async {
    DateTime initialDate = initialDateStr.isNotEmpty ? DateTime.tryParse(initialDateStr) ?? DateTime.now() : DateTime.now();
    DateTime firstDate = minDateStr != null && minDateStr.isNotEmpty ? DateTime.tryParse(minDateStr) ?? DateTime(2000) : DateTime(2000);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String formatted = picked.toIso8601String().split('T')[0];
      widget.onChange(field, _formatDateForAPI(formatted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculer les champs remplis
    int filledFields = 0;
    if ((widget.data['name'] ?? '').toString().trim().isNotEmpty) filledFields++;
    if ((widget.data['startDate'] ?? '').toString().trim().isNotEmpty) filledFields++;
    if ((widget.data['deadline'] ?? '').toString().trim().isNotEmpty) filledFields++;
    if ((widget.data['theme_name'] ?? '').toString().trim().isNotEmpty) filledFields++;
    if ((widget.data['commune_id'] ?? '').toString().trim().isNotEmpty) filledFields++;

    int remainingFields = 5 - filledFields;

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
                  color: isDarkMode ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description, size: 16, color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Étape 1', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500)),
                  Text(
                    'Informations générales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Renseignez les informations principales qui décrivent votre projet.",
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Nom du projet
          Row(
            children: [
              const Icon(Icons.description, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "Nom du projet",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (value) => widget.onChange("name", value),
            decoration: InputDecoration(
              hintText: "ex: Projet de développement communautaire",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade700 : Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orange, width: 2)),
            ),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 20),

          // Dates du projet
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;
              Widget dateStartWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text("Date de début", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700)),
                      const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context, "startDate", widget.data['startDate'] ?? '', null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.transparent,
                        border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.data['startDate'] != null && widget.data['startDate'].toString().isNotEmpty
                                ? _formatDateForInput(widget.data['startDate'])
                                : "Sélectionner une date",
                            style: TextStyle(color: widget.data['startDate'] != null && widget.data['startDate'].toString().isNotEmpty ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey.shade400),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              Widget dateEndWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text("Date de fin", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700)),
                      const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context, "deadline", widget.data['deadline'] ?? '', widget.data['startDate']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.transparent,
                        border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.data['deadline'] != null && widget.data['deadline'].toString().isNotEmpty
                                ? _formatDateForInput(widget.data['deadline'])
                                : "Sélectionner une date",
                            style: TextStyle(color: widget.data['deadline'] != null && widget.data['deadline'].toString().isNotEmpty ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey.shade400),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: dateStartWidget),
                    const SizedBox(width: 16),
                    Expanded(child: dateEndWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    dateStartWidget,
                    const SizedBox(height: 20),
                    dateEndWidget,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // Thème et Commune
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;

              Widget themeWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text("Catégorie / Thème", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700)),
                      const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: widget.data['theme_name'] != null && widget.data['theme_name'].toString().isNotEmpty ? widget.data['theme_name'] : null,
                    items: _loadingThemes
                        ? []
                        : _themes.map<DropdownMenuItem<String>>((theme) {
                            return DropdownMenuItem<String>(
                              value: theme['name'].toString(),
                              child: Text(theme['name'].toString()),
                            );
                          }).toList(),
                    onChanged: _loadingThemes ? null : (val) => widget.onChange("theme_name", val ?? ''),
                    decoration: InputDecoration(
                      hintText: _loadingThemes ? "Chargement..." : "Sélectionnez un thème",
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade700 : Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300)),
                    ),
                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                ],
              );

              Widget communeWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_pin, size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text("Communes concernées", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700)),
                      const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: widget.data['commune_id'] != null && widget.data['commune_id'].toString().isNotEmpty ? widget.data['commune_id'] : null,
                    items: _loadingCommunes
                        ? []
                        : _communes.map<DropdownMenuItem<String>>((commune) {
                            return DropdownMenuItem<String>(
                              value: commune['formatted_id'].toString(),
                              child: Text(commune['name'].toString()),
                            );
                          }).toList(),
                    onChanged: _loadingCommunes ? null : (val) => widget.onChange("commune_id", val ?? ''),
                    decoration: InputDecoration(
                      hintText: _loadingCommunes ? "Chargement..." : "Sélectionnez une commune",
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade700 : Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300)),
                    ),
                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: themeWidget),
                    const SizedBox(width: 16),
                    Expanded(child: communeWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    themeWidget,
                    const SizedBox(height: 20),
                    communeWidget,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Progression de l'étape", style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white70 : Colors.black87)),
                    Text("$filledFields/5 champs complétés", style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: filledFields / 5,
                  backgroundColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                if (remainingFields > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "$remainingFields champ${remainingFields > 1 ? 's' : ''} restant${remainingFields > 1 ? 's' : ''}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}