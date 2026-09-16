import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/territory_service.dart';

// --- Modèle de données pour l'Événement ---
class EventData {
  String title;
  String description;
  String startDate;
  String endDate;
  String visibility;
  List<String> theme;
  String communeId;
  String districtId;
  String eventType;
  dynamic image; // Fichier ou chemin du média

  EventData({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.visibility,
    required this.theme,
    required this.communeId,
    required this.districtId,
    required this.eventType,
    this.image,
  });
}

// --- Écran Principal : PublishEventScreen ---

class PublishEventScreen extends StatefulWidget {
  const PublishEventScreen({super.key});

  @override
  State<PublishEventScreen> createState() => _PublishEventScreenState();
}

class _PublishEventScreenState extends State<PublishEventScreen> {
  int currentStep = 1;
  bool isSubmitting = false;
  bool isSidebarOpen = false;
  String successMessage = "";
  String errorMessage = "";

  List<dynamic> _communesList = [];
  List<dynamic> _districtsList = [];
  bool _loadingTerritories = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final nextWeek = DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0];
    formData.startDate = today;
    formData.endDate = nextWeek;

    _loadTerritories();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userCommune = authProvider.user?.municipalityId;
      final userDistrict = authProvider.user?.districtId;

      setState(() {
        if (userCommune != null && userCommune.isNotEmpty && formData.communeId.isEmpty) {
          formData.communeId = userCommune;
        }
        if (userDistrict != null && userDistrict.isNotEmpty && formData.districtId.isEmpty) {
          formData.districtId = userDistrict;
        }
      });
    });
  }

  Future<void> _loadTerritories() async {
    try {
      final communes = await TerritoryService.getCommunesBasic();
      final districts = await TerritoryService.getDistrictsBasic();
      if (mounted) {
        setState(() {
          _communesList = communes ?? [];
          _districtsList = districts ?? [];
          _loadingTerritories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTerritories = false);
    }
  }

  final EventData formData = EventData(
    title: "",
    description: "",
    startDate: "",
    endDate: "",
    visibility: "public",
    theme: [],
    communeId: "",
    districtId: "",
    eventType: "",
    image: null,
  );

  final List<Map<String, dynamic>> steps = [
    {
      "id": 1,
      "title": "Informations générales",
      "icon": Icons.info_outline,
      "description": "Renseignez les informations principales qui décrivent votre événement.",
    },
    {
      "id": 2,
      "title": "Description et détails",
      "icon": Icons.description_outlined,
      "description": "Décrivez en détail le contenu de l'événement et ses objectifs.",
    },
    {
      "id": 3,
      "title": "Médias et publication",
      "icon": Icons.image_outlined,
      "description": "Ajoutez des médias et configurez les paramètres de publication.",
    },
  ];

  void _showSuccessMessage(String message) {
    setState(() {
      successMessage = message;
      errorMessage = "";
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => successMessage = "");
    });
  }

  void _showErrorMessage(String message) {
    setState(() {
      errorMessage = message;
      successMessage = "";
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => errorMessage = "");
    });
  }

  void _handleInputChange(String field, dynamic value) {
    setState(() {
      if (field == 'title') {
        formData.title = value;
      } else if (field == 'description') {
        formData.description = value;
      } else if (field == 'startDate') {
        formData.startDate = value;
      } else if (field == 'endDate') {
        formData.endDate = value;
      } else if (field == 'visibility') {
        formData.visibility = value;
      } else if (field == 'theme') {
        if (value is List<String>) {
          formData.theme = value;
        } else if (value is String) {
          formData.theme = [value];
        }
      } else if (field == 'communeId') {
        formData.communeId = value;
      } else if (field == 'districtId') {
        formData.districtId = value;
      } else if (field == 'eventType') {
        formData.eventType = value;
      } else if (field == 'image') {
        formData.image = value;
      }
    });
  }

  bool _validateCurrentStep() {
    if (currentStep == 1) {
      final step1Fields = [formData.title, formData.startDate, formData.endDate, formData.eventType, formData.communeId];
      final bool hasEmpty = step1Fields.any((field) => field.trim().isEmpty);

      if (hasEmpty) {
        _showErrorMessage("Veuillez remplir tous les champs obligatoires de cette étape");
        return false;
      }

      try {
        final startDate = DateTime.parse(formData.startDate);
        final endDate = DateTime.parse(formData.endDate);
        final now = DateTime.now();

        if (startDate.isAtSameMomentAs(endDate) || startDate.isAfter(endDate)) {
          _showErrorMessage("La date de fin doit être postérieure à la date de début");
          return false;
        }

        if (startDate.isBefore(DateTime(now.year, now.month, now.day))) {
          _showErrorMessage("La date de début ne peut pas être dans le passé");
          return false;
        }
      } catch (_) {
        _showErrorMessage("Le format des dates n'est pas valide (YYYY-MM-DD)");
        return false;
      }
    } else if (currentStep == 2) {
      if (formData.description.trim().isEmpty) {
        _showErrorMessage("La description est obligatoire");
        return false;
      }
      if (formData.theme.isEmpty) {
        _showErrorMessage("Veuillez sélectionner au moins un thème");
        return false;
      }
      if (formData.visibility.trim().isEmpty) {
        _showErrorMessage("Veuillez sélectionner la visibilité");
        return false;
      }
    }
    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (currentStep < steps.length) {
      setState(() {
        currentStep++;
        isSidebarOpen = false;
      });
    }
  }

  void _prevStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
        isSidebarOpen = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      isSubmitting = true;
      successMessage = "";
      errorMessage = "";
    });

    try {
      // Simulation d'envoi multipart (createEvent)
      await Future.delayed(const Duration(seconds: 2));

      _showSuccessMessage("Événement publié avec succès!");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/itantsorika/gererPublication');
        }
      });
    } catch (error) {
      _showErrorMessage("Une erreur inattendue s'est produite lors de la publication de l'événement");
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 80, bottom: 40),
            child: Column(
              children: [
                // Header Banner
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Publier un événement",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Renseignez les informations de votre événement afin qu'il soit visible par les participants.",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Cette section s'adresse aux Communes, Collectivités Territoriales Décentralisées (CTD) et autres acteurs publics souhaitant accéder rapidement à des ressources fiables et actualisées.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Card Content
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.event, color: Colors.white, size: 28),
                                  SizedBox(width: 12),
                                  Text(
                                    "Nouvel événement",
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(isSidebarOpen ? Icons.close : Icons.menu, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    isSidebarOpen = !isSidebarOpen;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // Body Layout (Sidebar + Form)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sidebar Stepper
                            Container(
                              width: 300,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(right: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Étape $currentStep sur ${steps.length}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 24),
                                  ...steps.map((step) {
                                    final bool isActive = currentStep == step['id'];
                                    final bool isCompleted = currentStep > step['id'];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isActive
                                                      ? Colors.orange
                                                      : (isCompleted ? Colors.green : Colors.grey.shade300),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    step['icon'],
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                              if (step['id'] < steps.length)
                                                Container(
                                                  width: 2,
                                                  height: 30,
                                                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    step['title'],
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: isActive ? Colors.orange.shade700 : Colors.black87,
                                                    ),
                                                  ),
                                                  if (isActive) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      step['description'],
                                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            // Form Content Area
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (currentStep == 1) ...[
                                      const Text("Étape 1 : Informations générales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        initialValue: formData.title,
                                        onChanged: (val) => _handleInputChange('title', val),
                                        decoration: InputDecoration(
                                          labelText: "Titre de l'événement *",
                                          prefixIcon: const Icon(Icons.event_note_rounded, color: Color(0xFF10B981)),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        initialValue: formData.eventType.isNotEmpty ? formData.eventType : "Conférence",
                                        items: const [
                                          DropdownMenuItem(value: "Conférence", child: Text("Conférence")),
                                          DropdownMenuItem(value: "Atelier", child: Text("Atelier")),
                                          DropdownMenuItem(value: "Séminaire", child: Text("Séminaire")),
                                          DropdownMenuItem(value: "Cérémonie", child: Text("Cérémonie")),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) _handleInputChange('eventType', val);
                                        },
                                        decoration: InputDecoration(
                                          labelText: "Type d'événement *",
                                          prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF10B981)),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDatePickerField(
                                              label: "Date de début *",
                                              value: formData.startDate,
                                              onChanged: (val) {
                                                _handleInputChange('startDate', val);
                                                try {
                                                  final start = DateTime.parse(val);
                                                  final end = DateTime.tryParse(formData.endDate);
                                                  if (end == null || end.isBefore(start)) {
                                                    final newEnd = start.add(const Duration(days: 7)).toIso8601String().split('T')[0];
                                                    _handleInputChange('endDate', newEnd);
                                                  }
                                                } catch (_) {}
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildDatePickerField(
                                              label: "Date de fin *",
                                              value: formData.endDate,
                                              firstDate: DateTime.tryParse(formData.startDate),
                                              onChanged: (val) => _handleInputChange('endDate', val),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildCommuneDropdown(),
                                      const SizedBox(height: 16),
                                      _buildDistrictDropdown(),
                                    ] else if (currentStep == 2) ...[
                                      const Text("Étape 2 : Description et détails", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextField(
                                        maxLines: 4,
                                        onChanged: (val) => _handleInputChange('description', val),
                                        decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) => _handleInputChange('theme', val),
                                        decoration: const InputDecoration(labelText: "Thèmes (séparés par virgule)", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        initialValue: formData.visibility,
                                        items: const [
                                          DropdownMenuItem(value: "public", child: Text("Public")),
                                          DropdownMenuItem(value: "private", child: Text("Privé")),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) _handleInputChange('visibility', val);
                                        },
                                        decoration: const InputDecoration(labelText: "Visibilité", border: OutlineInputBorder()),
                                      ),
                                    ] else ...[
                                      const Text("Étape 3 : Médias et publication", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) => _handleInputChange('image', val),
                                        decoration: const InputDecoration(labelText: "Image (URL ou chemin)", border: OutlineInputBorder()),
                                      ),
                                    ],
                                    const SizedBox(height: 32),

                                    // Navigation Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: currentStep == 1 ? null : _prevStep,
                                          icon: const Icon(Icons.chevron_left),
                                          label: const Text("Précédent"),
                                        ),
                                        ElevatedButton(
                                          onPressed: isSubmitting
                                              ? null
                                              : (currentStep == steps.length ? _handleSubmit : _nextStep),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          ),
                                          child: isSubmitting
                                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : Text(currentStep == steps.length ? "Publier l'événement" : "Suivant"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notifications Overlay
          if (successMessage.isNotEmpty || errorMessage.isNotEmpty)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: successMessage.isNotEmpty ? Colors.green.shade600 : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                    ),
                    child: Text(
                      successMessage.isNotEmpty ? successMessage : errorMessage,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    DateTime? firstDate,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        DateTime initial = DateTime.now();
        if (value.isNotEmpty) {
          initial = DateTime.tryParse(value) ?? DateTime.now();
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: firstDate ?? DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().split('T')[0]);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF10B981)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: Text(
          value.isNotEmpty ? value : "Sélectionner une date",
          style: TextStyle(
            fontSize: 14,
            color: value.isNotEmpty
                ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCommuneDropdown() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_loadingTerritories) {
      return const LinearProgressIndicator(color: Color(0xFF10B981));
    }
    final selectedVal = _communesList.any((c) => (c['formatted_id']?.toString() ?? c['id']?.toString()) == formData.communeId)
        ? formData.communeId
        : (_communesList.isNotEmpty ? (_communesList.first['formatted_id']?.toString() ?? _communesList.first['id']?.toString()) : null);

    return DropdownButtonFormField<String>(
      initialValue: selectedVal,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Commune *",
        prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFF10B981)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      items: _communesList.map<DropdownMenuItem<String>>((c) {
        final id = c['formatted_id']?.toString() ?? c['id']?.toString() ?? '';
        final name = c['commune_name'] ?? c['name'] ?? c['nom'] ?? id;
        return DropdownMenuItem<String>(
          value: id,
          child: Text(name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) _handleInputChange('communeId', val);
      },
    );
  }

  Widget _buildDistrictDropdown() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_loadingTerritories) {
      return const SizedBox.shrink();
    }
    final selectedVal = _districtsList.any((d) => (d['formatted_id']?.toString() ?? d['id']?.toString()) == formData.districtId)
        ? formData.districtId
        : (_districtsList.isNotEmpty ? (_districtsList.first['formatted_id']?.toString() ?? _districtsList.first['id']?.toString()) : null);

    return DropdownButtonFormField<String>(
      initialValue: selectedVal,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "District *",
        prefixIcon: const Icon(Icons.map_rounded, color: Color(0xFF10B981)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      items: _districtsList.map<DropdownMenuItem<String>>((d) {
        final id = d['formatted_id']?.toString() ?? d['id']?.toString() ?? '';
        final name = d['district_name'] ?? d['name'] ?? d['nom'] ?? id;
        return DropdownMenuItem<String>(
          value: id,
          child: Text(name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) _handleInputChange('districtId', val);
      },
    );
  }
}