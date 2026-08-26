import 'package:flutter/material.dart';
import '../../services/entite_service.dart';

Future<List<Map<String, dynamic>>> listEntitesByCategorie(String categorie) async {
  try {
    final list = await EntiteService.getEntites();
    if (list.isNotEmpty) {
      return list.map<Map<String, dynamic>>((e) {
        return {
          'id': e.id,
          'nom': e.nom,
          'categorie': e.categorie,
          'status': e.status,
        };
      }).toList();
    }
  } catch (e) {
    debugPrint("Erreur listEntitesByCategorie API: $e");
  }
  return [
    {'id': 1, 'nom': 'Banque Mondiale'},
    {'id': 2, 'nom': 'UNICEF Madagascar'},
    {'id': 3, 'nom': 'Union Européenne'},
    {'id': 4, 'nom': 'PNUD Madagascar'},
    {'id': 5, 'nom': 'AFD - Agence Française de Développement'},
  ];
}

class Step3ResourcesWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, dynamic value) onChange;

  const Step3ResourcesWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step3ResourcesWidget> createState() => _Step3ResourcesWidgetState();
}

class _Step3ResourcesWidgetState extends State<Step3ResourcesWidget> {
  final Map<String, String> _errors = {};
  late TextEditingController _budgetController;
  String _budgetFormatted = '';
  
  List<Map<String, dynamic>> _partnerSuggestions = [];
  String _selectedPartnerId = '';

  final List<Map<String, dynamic>> _budgetRanges = [
    {
      'min': 0,
      'max': 1000000,
      'label': 'Petit projet',
      'color': Colors.green,
      'description': '< 1M AR',
    },
    {
      'min': 1000000,
      'max': 10000000,
      'label': 'Projet moyen',
      'color': Colors.blue,
      'description': '1M - 10M AR',
    },
    {
      'min': 10000000,
      'max': 50000000,
      'label': 'Grand projet',
      'color': Colors.purple,
      'description': '10M - 50M AR',
    },
    {
      'min': 50000000,
      'max': double.infinity,
      'label': 'Projet majeur',
      'color': Colors.orange,
      'description': '> 50M AR',
    },
  ];

  @override
  void initState() {
    super.initState();
    double budget = (widget.data['budget'] ?? 0).toDouble();
    _budgetFormatted = budget > 0 ? _formatNumber(budget.toInt()) : '';
    _budgetController = TextEditingController(text: _budgetFormatted);
    _fetchPartners();
  }

  @override
  void didUpdateWidget(covariant Step3ResourcesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    double budget = (widget.data['budget'] ?? 0).toDouble();
    String newFormatted = budget > 0 ? _formatNumber(budget.toInt()) : '';
    if (newFormatted != _budgetFormatted) {
      _budgetFormatted = newFormatted;
      _budgetController.text = _budgetFormatted;
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  Future<void> _fetchPartners() async {
    try {
      final res = await listEntitesByCategorie("ptf");
      setState(() {
        _partnerSuggestions = res;
      });
    } catch (err) {
      debugPrint("Erreur lors du chargement des partenaires : $err");
    }
  }

  void _validateField(String field, dynamic value) {
    Map<String, String> newErrors = Map.from(_errors);

    if (field == 'budget') {
      if (value <= 0) {
        newErrors['budget'] = 'Le budget doit être supérieur à 0';
      } else if (value > 10000000000) {
        newErrors['budget'] = 'Le budget semble trop élevé (max 10 milliards)';
      } else {
        newErrors.remove('budget');
      }
    } else if (field == 'deadline') {
      if (value == null || value.toString().isEmpty) {
        newErrors['deadline'] = 'La date limite est requise';
      } else {
        DateTime? deadlineDate = DateTime.tryParse(value);
        if (deadlineDate != null && deadlineDate.isBefore(DateTime.now())) {
          newErrors['deadline'] = 'La date limite doit être dans le futur';
        } else {
          newErrors.remove('deadline');
        }
      }
    } else if (field == 'partenaire') {
      if (value is List && value.isEmpty) {
        newErrors['partenaire'] = 'Au moins un partenaire est requis';
      } else {
        newErrors.remove('partenaire');
      }
    }

    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });
  }

  void _handleInputChange(String field, dynamic value) {
    widget.onChange(field, value);
    _validateField(field, value);
  }

  void _handleBudgetChange(String value) {
    String numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
    int numberValue = int.tryParse(numericValue) ?? 0;

    setState(() {
      _budgetFormatted = numberValue > 0 ? _formatNumber(numberValue) : '';
      _budgetController.text = _budgetFormatted;
      _budgetController.selection = TextSelection.fromPosition(
        TextPosition(offset: _budgetController.text.length),
      );
    });

    _handleInputChange('budget', numberValue);
  }

  void _addPartnerById(String partnerIdStr) {
    if (partnerIdStr.isNotEmpty) {
      int partnerIdNum = int.parse(partnerIdStr);
      List<dynamic> currentPartners = List.from(widget.data['partenaire'] ?? []);
      if (!currentPartners.contains(partnerIdNum)) {
        currentPartners.add(partnerIdNum);
        _handleInputChange('partenaire', currentPartners);
        setState(() {
          _selectedPartnerId = '';
        });
      }
    }
  }

  void _removePartner(int index) {
    List<dynamic> currentPartners = List.from(widget.data['partenaire'] ?? []);
    if (index >= 0 && index < currentPartners.length) {
      currentPartners.removeAt(index);
      _handleInputChange('partenaire', currentPartners);
    }
  }

  Map<String, dynamic> _getBudgetRange(double budget) {
    try {
      return _budgetRanges.firstWhere(
        (range) => budget >= range['min'] && budget < range['max'],
      );
    } catch (e) {
      return _budgetRanges[0];
    }
  }

  String _formatDateForInput(String dateString) {
    if (dateString.isEmpty) return '';
    return dateString.split('T')[0];
  }

  String _formatDateForAPI(String dateString) {
    if (dateString.isEmpty) return '';
    return '${dateString}T23:59:59Z';
  }

  int _getDaysUntilDeadline(String deadlineStr) {
    if (deadlineStr.isEmpty) return 0;
    DateTime? deadlineDate = DateTime.tryParse(deadlineStr);
    if (deadlineDate == null) return 0;
    final diffTime = deadlineDate.difference(DateTime.now()).inDays;
    return diffTime > 0 ? diffTime : 0;
  }

  Future<void> _selectDeadlineDate(BuildContext context) async {
    String currentDeadline = widget.data['deadline'] ?? '';
    DateTime initialDate = currentDeadline.isNotEmpty
        ? (DateTime.tryParse(currentDeadline) ?? DateTime.now())
        : DateTime.now().add(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String formatted = picked.toIso8601String().split('T')[0];
      _handleInputChange('deadline', _formatDateForAPI(formatted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    double budget = (widget.data['budget'] ?? 0).toDouble();
    String deadline = widget.data['deadline'] ?? '';
    List<dynamic> partenaires = widget.data['partenaire'] ?? [];

    Map<String, dynamic> rangeInfo = _getBudgetRange(budget);
    int daysUntil = _getDaysUntilDeadline(deadline);

    int completedCount = 0;
    if (budget > 0) completedCount++;
    if (deadline.isNotEmpty) completedCount++;
    if (partenaires.isNotEmpty) completedCount++;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Ressources et budget',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Indiquez les moyens humains, matériels et financiers nécessaires à la réalisation.',
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Budget
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Budget estimatif',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            onChanged: _handleBudgetChange,
            decoration: InputDecoration(
              hintText: 'Entrer le montant',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixText: 'AR',
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errors.containsKey('budget') ? Colors.red : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errors.containsKey('budget') ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
          ),
          if (_errors.containsKey('budget')) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(_errors['budget']!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ],

          // Budget Range Indicator
          if (budget > 0 && !_errors.containsKey('budget')) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
                border: Border.all(color: isDarkMode ? Colors.green.shade800 : Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: rangeInfo['color']),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rangeInfo['label'],
                            style: TextStyle(fontWeight: FontWeight.bold, color: rangeInfo['color']),
                          ),
                          Text(
                            rangeInfo['description'],
                            style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatNumber(budget.toInt())} AR',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                      Text(
                        '≈ ${(budget / 5000).toStringAsFixed(1)}K USD',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Deadline
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Date limite (deadline)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDeadlineDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.transparent,
                border: Border.all(
                  color: _errors.containsKey('deadline') ? Colors.red : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    deadline.isNotEmpty ? _formatDateForInput(deadline) : 'Sélectionner une date limite',
                    style: TextStyle(
                      color: deadline.isNotEmpty ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey.shade400,
                    ),
                  ),
                  const Icon(Icons.calendar_month, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (_errors.containsKey('deadline')) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(_errors['deadline']!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ],

          // Deadline Countdown
          if (deadline.isNotEmpty && !_errors.containsKey('deadline')) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50,
                border: Border.all(color: isDarkMode ? Colors.red.shade800 : Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '$daysUntil jours restants',
                    style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.red.shade200 : Colors.red.shade800),
                  ),
                  if (daysUntil < 30) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Urgent', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Partners Section
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Partenaires du projet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPartnerId.isNotEmpty ? _selectedPartnerId : null,
                  items: _partnerSuggestions
                      .where((p) => !partenaires.contains(p['id']))
                      .map<DropdownMenuItem<String>>((partner) {
                    return DropdownMenuItem<String>(
                      value: partner['id'].toString(),
                      child: Text(partner['nom'].toString()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPartnerId = val ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Sélectionner un partenaire...',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade800 : Colors.transparent,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300)),
                  ),
                  dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedPartnerId.isNotEmpty ? () => _addPartnerById(_selectedPartnerId) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          if (_errors.containsKey('partenaire')) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(_errors['partenaire']!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ],

          // Partners List Chips
          if (partenaires.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Partenaires ajoutés (${partenaires.length})',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: partenaires.asMap().entries.map((entry) {
                int index = entry.key;
                dynamic partnerId = entry.value;

                var partner = _partnerSuggestions.firstWhere(
                  (p) => p['id'] == partnerId,
                  orElse: () => {'nom': 'ID: $partnerId'},
                );

                return Chip(
                  avatar: const Icon(Icons.business, size: 16, color: Colors.blue),
                  label: Text(partner['nom'].toString()),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removePartner(index),
                  backgroundColor: isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.5) : Colors.blue.shade100,
                  labelStyle: TextStyle(color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade800),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),

          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  _errors.isEmpty && completedCount == 3
                      ? '✅ Prêt pour l\'étape suivante'
                      : '${3 - completedCount} champs restants',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}