import 'package:flutter/material.dart';

class PublicationEditWidget extends StatefulWidget {
  final String id;
  final String type; // 'event' ou 'project'
  final bool darkMode;

  const PublicationEditWidget({
    super.key,
    required this.id,
    required this.type,
    this.darkMode = false,
  });

  @override
  State<PublicationEditWidget> createState() => _PublicationEditWidgetState();
}

class _PublicationEditWidgetState extends State<PublicationEditWidget> {
  late bool _isDark;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  Map<String, dynamic> _formData = {};
  String _newPartner = '';

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  late TextEditingController _partnerController;

  @override
  void initState() {
    super.initState();
    _isDark = widget.darkMode;
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _budgetController = TextEditingController(text: '0');
    _partnerController = TextEditingController();
    _fetchPublication();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  Future<void> _fetchPublication() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Simulation ou appel des services correspondants (à adapter avec vos services API Flutter)
      await Future.delayed(const Duration(milliseconds: 500));

      // Exemple de données factices basées sur le type
      if (widget.type == 'event') {
        _formData = {
          'title': 'Événement exemple',
          'description': 'Description de l\'événement...',
          'startDate': '2026-07-01',
          'endDate': '2026-07-02',
          'visibility': 'public',
          'themeId': '1',
          'communeId': 'antananarivo',
          'eventTypeId': 'Conférence',
          'image': '',
          'type': 'event',
        };
      } else {
        _formData = {
          'name': 'Projet exemple',
          'description': 'Description du projet...',
          'status': 'en_cours',
          'startDate': '2026-01-01',
          'endDate': '2026-12-31',
          'deadline': '2026-11-30',
          'budget': 5000000,
          'partenaire': ['Partenaire A', 'Partenaire B'],
          'theme_name': 'Environnement',
          'commune_id': 'antananarivo',
          'type': 'project',
        };
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement de la publication';
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _updateControllersFromData();
    }
  }

  void _updateControllersFromData() {
    final titleValue = widget.type == 'event' ? _formData['title'] : _formData['name'];
    _titleController.text = titleValue?.toString() ?? '';
    _descriptionController.text = _formData['description']?.toString() ?? '';
    _budgetController.text = _formData['budget']?.toString() ?? '0';
    _partnerController.text = _newPartner;
  }

  void _handleInputChange(String field, dynamic value) {
    setState(() {
      _formData[field] = value;
    });
  }

  void _addPartner() {
    if (_newPartner.trim().isNotEmpty) {
      List partners = List.from(_formData['partenaire'] ?? []);
      if (!partners.contains(_newPartner.trim())) {
        partners.add(_newPartner.trim());
        setState(() {
          _formData['partenaire'] = partners;
          _newPartner = '';
          _partnerController.clear();
        });
      }
    }
  }

  void _removePartner(int index) {
    List partners = List.from(_formData['partenaire'] ?? []);
    partners.removeAt(index);
    setState(() {
      _formData['partenaire'] = partners;
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      // Appel API de sauvegarde ici
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _success = widget.type == 'event'
            ? 'Événement mis à jour avec succès !'
            : 'Projet mis à jour avec succès !';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la sauvegarde';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Chargement de la publication...',
                style: TextStyle(
                  fontSize: 16,
                  color: _isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.type == 'event' ? "Modifier l'événement" : 'Modifier le projet',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _isDark ? Colors.grey.shade800 : Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: _isDark ? Colors.white : Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Messages d'erreur et de succès
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_success != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _success!,
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Formulaire principal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre / Nom
                      Text(
                        widget.type == 'event' ? 'Titre' : 'Nom du projet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        onChanged: (val) => _handleInputChange(
                          widget.type == 'event' ? 'title' : 'name',
                          val,
                        ),
                        style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Entrez le titre...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: _isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        onChanged: (val) => _handleInputChange('description', val),
                        maxLines: 4,
                        style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Décrivez la publication...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: _isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Commune
                      Text(
                        'Commune',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: widget.type == 'event' ? _formData['communeId'] : _formData['commune_id'],
                        dropdownColor: _isDark ? Colors.grey.shade800 : Colors.white,
                        style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Sélectionner une commune')),
                          DropdownMenuItem(value: 'antananarivo', child: Text('Antananarivo')),
                          DropdownMenuItem(value: 'fianarantsoa', child: Text('Fianarantsoa')),
                          DropdownMenuItem(value: 'toamasina', child: Text('Toamasina')),
                          DropdownMenuItem(value: 'mahajanga', child: Text('Mahajanga')),
                        ],
                        onChanged: (val) => _handleInputChange(
                          widget.type == 'event' ? 'communeId' : 'commune_id',
                          val,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Champs spécifiques Event / Project
                      if (widget.type == 'event') ...[
                        Text(
                          'Visibilité',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _formData['visibility'],
                          dropdownColor: _isDark ? Colors.grey.shade800 : Colors.white,
                          style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'public', child: Text('Public')),
                            DropdownMenuItem(value: 'private', child: Text('Privé')),
                          ],
                          onChanged: (val) => _handleInputChange('visibility', val),
                        ),
                      ] else ...[
                        Text(
                          'Statut',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _formData['status'],
                          dropdownColor: _isDark ? Colors.grey.shade800 : Colors.white,
                          style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'planifie', child: Text('Planifié')),
                            DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                            DropdownMenuItem(value: 'termine', child: Text('Terminé')),
                            DropdownMenuItem(value: 'annule', child: Text('Annulé')),
                          ],
                          onChanged: (val) => _handleInputChange('status', val),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Budget (MGA)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _handleInputChange('budget', double.tryParse(val) ?? 0),
                          style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                            ),
                          ),
                        ),
                      ],

                      // Section Partenaires si projet
                      if (widget.type == 'project') ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Partenaires',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _partnerController,
                                onChanged: (val) => _newPartner = val,
                                onSubmitted: (_) => _addPartner(),
                                style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Ajouter un partenaire...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: _isDark ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade200),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _addPartner,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate((_formData['partenaire'] ?? []).length, (index) {
                            final partner = _formData['partenaire'][index];
                            return Chip(
                              label: Text(partner),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removePartner(index),
                              backgroundColor: _isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                              labelStyle: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                            );
                          }),
                        ),
                      ],

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Actions de bas de page
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _saving ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              side: BorderSide(color: _isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(color: _isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.save, size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Sauvegarder', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}