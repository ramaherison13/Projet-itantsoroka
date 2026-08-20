import 'package:flutter/material.dart';

// Modèle de données pour les listes
class DistrictModel {
  final String id;
  final String formattedId;
  final String name;

  DistrictModel({required this.id, required this.formattedId, required this.name});
}

class CommuneModel {
  final String id;
  final String formattedId;
  final String name;

  CommuneModel({required this.id, required this.formattedId, required this.name});
}

class TypeModel {
  final String id;
  final String name;

  TypeModel({required this.id, required this.name});
}

class Step1ActuWidget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChanged;
  final bool isSuperAdmin;
  final String? userDistrictId;
  final String? userCommuneId;
  final bool isCommuneAffiliated;

  const Step1ActuWidget({
    super.key,
    required this.formData,
    required this.onFormDataChanged,
    required this.isSuperAdmin,
    this.userDistrictId,
    this.userCommuneId,
    required this.isCommuneAffiliated,
  });

  @override
  State<Step1ActuWidget> createState() => _Step1ActuWidgetState();
}

class _Step1ActuWidgetState extends State<Step1ActuWidget> {
  List<DistrictModel> _districts = [];
  List<CommuneModel> _communes = [];
  List<TypeModel> _types = [];

  bool _loadingCommunes = false;
  bool _loadingDistricts = false;
  bool _loadingTypes = false;

  late TextEditingController _titleController;
  late String _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now().toIso8601String().split('T')[0];
    _titleController = TextEditingController(text: widget.formData['title'] ?? '');

    // Pré-remplir la date par défaut si vide
    if (widget.formData['startDate'] == null || widget.formData['startDate'].toString().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateField('startDate', _today);
      });
    }

    // Pré-remplir district et commune si non super-admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Map<String, dynamic> updated = Map.from(widget.formData);
      bool modified = false;
      if (!widget.isSuperAdmin && widget.userDistrictId != null && (updated['districtId'] == null || updated['districtId'].toString().isEmpty)) {
        updated['districtId'] = widget.userDistrictId;
        modified = true;
      }
      if (widget.isCommuneAffiliated && widget.userCommuneId != null && (updated['communeId'] == null || updated['communeId'].toString().isEmpty)) {
        updated['communeId'] = widget.userCommuneId;
        modified = true;
      }
      if (modified) {
        widget.onFormDataChanged(updated);
      }
    });

    _fetchEventTypes();
    _fetchDistricts();
    if (widget.isSuperAdmin ? (widget.formData['districtId'] != null && widget.formData['districtId'].toString().isNotEmpty) : widget.userDistrictId != null) {
      _fetchCommunes();
    }
  }

  @override
  void didUpdateWidget(covariant Step1ActuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formData['districtId'] != oldWidget.formData['districtId']) {
      _fetchCommunes();
    }
  }

  String? get districtIdSafe => widget.formData['districtId'];

  void _updateField(String key, dynamic value) {
    Map<String, dynamic> updated = Map.from(widget.formData);
    updated[key] = value;
    widget.onFormDataChanged(updated);
  }

  Future<void> _fetchEventTypes() async {
    setState(() => _loadingTypes = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulation API
      setState(() {
        _types = [
          TypeModel(id: '1', name: 'Conférence'),
          TypeModel(id: '2', name: 'Atelier'),
          TypeModel(id: '3', name: 'Communiqué officiel'),
        ];
      });
    } catch (e) {
      setState(() => _types = []);
    } finally {
      setState(() => _loadingTypes = false);
    }
  }

  Future<void> _fetchDistricts() async {
    setState(() => _loadingDistricts = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _districts = [
          DistrictModel(id: 'd1', formattedId: 'ANT_01', name: 'Antananarivo Renivohitra'),
          DistrictModel(id: 'd2', formattedId: 'ANT_02', name: 'Atsimondrano'),
        ];
      });
    } catch (e) {
      setState(() => _districts = []);
    } finally {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _fetchCommunes() async {
    final targetDistrictId = widget.isSuperAdmin ? widget.formData['districtId'] : widget.userDistrictId;
    if (targetDistrictId == null || targetDistrictId.toString().isEmpty) {
      setState(() => _communes = []);
      return;
    }

    setState(() => _loadingCommunes = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _communes = [
          CommuneModel(id: 'c1', formattedId: 'ANT_01_C1', name: 'Analakely'),
          CommuneModel(id: 'c2', formattedId: 'ANT_01_C2', name: 'Isoraka'),
        ];
      });
    } catch (e) {
      setState(() => _communes = []);
    } finally {
      setState(() => _loadingCommunes = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calcul du nombre de champs remplis
    final fields = [
      widget.formData['title'],
      widget.formData['startDate'],
      widget.formData['communeId'],
      widget.formData['districtId'],
      widget.formData['eventType'],
    ];
    final filledFields = fields.where((f) => f != null && f.toString().trim().isNotEmpty).length;
    final remainingFields = 5 - filledFields;

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
                child: Icon(Icons.label, size: 16, color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600),
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
                      color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Renseignez les informations principales qui décrivent votre actualité.',
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Titre de l'actualité
          Text(
            "Titre de l'actualité *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            onChanged: (val) => _updateField('title', val),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'ex: Nouvelle infrastructure dans la commune',
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
            ),
          ),
          const SizedBox(height: 20),

          // Type d'actualité et Date de publication
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Type de l'actualité *",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: widget.formData['eventType']?.toString().isEmpty ?? true ? null : widget.formData['eventType'],
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
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Sélectionnez un type')),
                        ..._types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: _loadingTypes ? null : (val) => _updateField('eventType', val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Date de publication",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                        border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.formData['startDate'] ?? _today,
                        style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // District et Commune
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "District concerné *",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: widget.formData['districtId']?.toString().isEmpty ?? true ? null : widget.formData['districtId'],
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
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Sélectionnez un district')),
                        ..._districts.map((d) => DropdownMenuItem(value: d.formattedId, child: Text(d.name))),
                      ],
                      onChanged: (_loadingDistricts || !widget.isSuperAdmin) ? null : (val) {
                        _updateField('districtId', val);
                        _updateField('communeId', '');
                        _fetchCommunes();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Commune concernée *",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: widget.formData['communeId']?.toString().isEmpty ?? true ? null : widget.formData['communeId'],
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
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Sélectionnez une commune')),
                        ..._communes.map((c) => DropdownMenuItem(value: c.formattedId, child: Text(c.name))),
                      ],
                      onChanged: (_loadingCommunes || widget.isCommuneAffiliated) ? null : (val) => _updateField('communeId', val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

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
                    Text("$filledFields/5 champs complétés", style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: filledFields / 5,
                  backgroundColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 8),
                remainingFields > 0
                    ? Text("$remainingFields champ(s) restant(s) - Complétez tous les champs pour continuer", style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                    : const Text("✓ Tous les champs sont remplis, vous pouvez passer à l'étape suivante", style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}