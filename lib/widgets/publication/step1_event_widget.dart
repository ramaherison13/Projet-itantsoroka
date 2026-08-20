import 'package:flutter/material.dart';

class EventTypeModel {
  final String id;
  final String name;

  EventTypeModel({required this.id, required this.name});
}

class CommuneModel {
  final String id;
  final String name;

  CommuneModel({required this.id, required this.name});
}

class DistrictModel {
  final String formattedId;
  final String districtId;
  final String name;

  DistrictModel({
    required this.formattedId,
    required this.districtId,
    required this.name,
  });
}

class Step1EventWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, String value) onChange;

  const Step1EventWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step1EventWidget> createState() => _Step1EventWidgetState();
}

class _Step1EventWidgetState extends State<Step1EventWidget> {
  List<EventTypeModel> _eventTypes = [];
  List<CommuneModel> _communes = [];
  List<DistrictModel> _districts = [];

  bool _loadingEventTypes = true;
  bool _loadingCommunes = true;
  bool _loadingDistricts = true;

  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.data['title'] ?? '');
    _fetchEventTypes();
    _fetchCommunes();
    _fetchDistricts();
  }

  @override
  void didUpdateWidget(covariant Step1EventWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data['title'] != _titleController.text) {
      _titleController.text = widget.data['title'] ?? '';
      _titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: _titleController.text.length),
      );
    }
  }

  Future<void> _fetchEventTypes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _eventTypes = [
          EventTypeModel(id: '1', name: 'Conférence'),
          EventTypeModel(id: '2', name: 'Atelier'),
          EventTypeModel(id: '3', name: 'Séminaire'),
        ];
        _loadingEventTypes = false;
      });
    } catch (e) {
      setState(() => _loadingEventTypes = false);
    }
  }

  Future<void> _fetchCommunes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _communes = [
          CommuneModel(id: 'c1', name: 'Analakely'),
          CommuneModel(id: 'c2', name: 'Isoraka'),
        ];
        _loadingCommunes = false;
      });
    } catch (e) {
      setState(() => _loadingCommunes = false);
    }
  }

  Future<void> _fetchDistricts() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _districts = [
          DistrictModel(formattedId: 'd1', districtId: '1', name: 'Antananarivo Renivohitra'),
          DistrictModel(formattedId: 'd2', districtId: '2', name: 'Atsimondrano'),
        ];
        _loadingDistricts = false;
      });
    } catch (e) {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _selectDate(BuildContext context, String fieldName, String? initialDateStr) async {
    DateTime initialDate = DateTime.now();
    if (initialDateStr != null && initialDateStr.isNotEmpty) {
      initialDate = DateTime.tryParse(initialDateStr) ?? DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String formattedDate = picked.toIso8601String().split('T')[0];
      widget.onChange(fieldName, formattedDate);
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

    final String title = widget.data['title'] ?? '';
    final String startDate = widget.data['startDate'] ?? '';
    final String endDate = widget.data['endDate'] ?? '';
    final String eventType = widget.data['eventType'] ?? '';
    final String communeId = widget.data['communeId'] ?? '';
    final String districtId = widget.data['districtId'] ?? '';

    final fields = [title, startDate, endDate, eventType, communeId];
    final filledFields = fields.where((f) => f.trim().isNotEmpty).length;
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
                  color: isDarkMode ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tag, size: 16, color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600),
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
            'Renseignez les informations principales qui décrivent votre événement.',
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Titre de l'événement
          Text(
            "Titre de l'événement *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            onChanged: (val) => widget.onChange('title', val),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'ex: Conférence sur le développement durable',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dates de l'événement
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Date de début *",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, 'startDate', startDate),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                          border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              startDate.isEmpty ? 'Sélectionner une date' : startDate,
                              style: TextStyle(color: startDate.isEmpty ? Colors.grey.shade400 : (isDarkMode ? Colors.white : Colors.black87)),
                            ),
                            const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                          ],
                        ),
                      ),
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
                      "Date de fin *",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, 'endDate', endDate),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                          border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              endDate.isEmpty ? 'Sélectionner une date' : endDate,
                              style: TextStyle(color: endDate.isEmpty ? Colors.grey.shade400 : (isDarkMode ? Colors.white : Colors.black87)),
                            ),
                            const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Type d'événement et Commune
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Type d'événement *",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: eventType.isEmpty ? null : eventType,
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
                        ..._eventTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: _loadingEventTypes ? null : (val) => widget.onChange('eventType', val ?? ''),
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
                      initialValue: communeId.isEmpty ? null : communeId,
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
                        ..._communes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: _loadingCommunes ? null : (val) => widget.onChange('communeId', val ?? ''),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // District concerné
          Text(
            "District concerné *",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: districtId.isEmpty ? null : districtId,
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
            onChanged: _loadingDistricts ? null : (val) => widget.onChange('districtId', val ?? ''),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 8),
                remainingFields > 0
                    ? Text("$remainingFields champ(s) restant(s)", style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                    : const Text("✓ Tous les champs sont remplis", style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}