import 'package:flutter/material.dart';

class Step2DescriptionWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, String value) onChange;

  const Step2DescriptionWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step2DescriptionWidget> createState() => _Step2DescriptionWidgetState();
}

class _Step2DescriptionWidgetState extends State<Step2DescriptionWidget> {
  final Map<String, String> _errors = {};
  late TextEditingController _descriptionController;
  int _charCount = 0;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'id': 'draft',
      'name': 'Brouillon',
      'description': 'Projet en cours de préparation',
      'icon': Icons.insert_drive_file,
      'color': Colors.grey,
    },
    {
      'id': 'planning',
      'name': 'Planification',
      'description': 'Projet en phase de planification',
      'icon': Icons.access_time,
      'color': Colors.blue,
    },
    {
      'id': 'en_cours',
      'name': 'En cours',
      'description': "Projet en cours d'exécution",
      'icon': Icons.trending_up,
      'color': Colors.green,
    },
    {
      'id': 'completed',
      'name': 'Terminé',
      'description': 'Projet finalisé',
      'icon': Icons.check_circle,
      'color': Colors.teal,
    },
    {
      'id': 'on-hold',
      'name': 'En pause',
      'description': 'Projet temporairement suspendu',
      'icon': Icons.warning_amber,
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    String initialDesc = widget.data['description'] ?? '';
    _descriptionController = TextEditingController(text: initialDesc);
    _charCount = initialDesc.length;
  }

  @override
  void didUpdateWidget(covariant Step2DescriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    String currentDesc = widget.data['description'] ?? '';
    if (currentDesc != _descriptionController.text) {
      _descriptionController.text = currentDesc;
      _charCount = currentDesc.length;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateField(String field, String value) {
    Map<String, String> newErrors = Map.from(_errors);

    if (field == 'description') {
      if (value.trim().isEmpty) {
        newErrors['description'] = 'La description du projet est requise';
      } else if (value.trim().length < 50) {
        newErrors['description'] = 'La description doit contenir au moins 50 caractères';
      } else if (value.trim().length > 2000) {
        newErrors['description'] = 'La description ne peut pas dépasser 2000 caractères';
      } else {
        newErrors.remove('description');
      }
    } else if (field == 'status') {
      if (value.isEmpty) {
        newErrors['status'] = 'Veuillez sélectionner un statut';
      } else {
        newErrors.remove('status');
      }
    }

    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });
  }

  void _handleInputChange(String field, String value) {
    if (field == 'description') {
      setState(() {
        _charCount = value.length;
      });
    }
    widget.onChange(field, value);
    _validateField(field, value);
  }

  Map<String, dynamic>? _getSelectedStatus() {
    try {
      return _statusOptions.firstWhere((status) => status['id'] == widget.data['status']);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String description = widget.data['description'] ?? '';
    String status = widget.data['status'] ?? '';

    Color getCharCountColor() {
      if (_charCount > 2000) return Colors.red;
      if (_charCount > 1800) return Colors.orange;
      return Colors.grey;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Description et objectifs',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Décrivez en détail le contenu du projet et ses buts principaux.',
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Project Description
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Description complète du projet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                  ),
                  const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                '$_charCount/2000 caractères',
                style: TextStyle(fontSize: 12, color: getCharCountColor()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 8,
            onChanged: (value) => _handleInputChange('description', value),
            decoration: InputDecoration(
              hintText: 'Décrivez en détail votre projet : contexte, enjeux, bénéficiaires, impact attendu, méthodologie, partenaires impliqués...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errors.containsKey('description') ? Colors.red : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errors.containsKey('description') ? Colors.red : Colors.blue,
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
          if (_errors.containsKey('description')) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(_errors['description']!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Project Status Label
          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Statut du projet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          // Project Status Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _statusOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final item = _statusOptions[index];
              final bool isSelected = status == item['id'];
              final Color itemColor = item['color'];

              return InkWell(
                onTap: () => _handleInputChange('status', item['id']),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? itemColor.withValues(alpha: isDarkMode ? 0.3 : 0.1)
                        : (isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.transparent),
                    border: Border.all(
                      color: isSelected ? itemColor : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(item['icon'], size: 20, color: itemColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['description'],
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, size: 16, color: itemColor),
                    ],
                  ),
                ),
              );
            },
          ),

          if (_errors.containsKey('status')) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(_errors['status']!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ],

          // Selected status summary
          if (status.isNotEmpty && !_errors.containsKey('status')) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50,
                border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getSelectedStatus()?['color'] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statut sélectionné : ${_getSelectedStatus()?['name'] ?? ''}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                  ),
                ],
              ),
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
                  _errors.isEmpty && description.isNotEmpty && status.isNotEmpty
                      ? '✅ Prêt pour l\'étape suivante'
                      : '${2 - [description.isNotEmpty, status.isNotEmpty].where((e) => e).length} champs restants',
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