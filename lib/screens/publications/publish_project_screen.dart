import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Modèle de données pour le Projet ---
class ProjectData {
  String name;
  String description;
  String status;
  String startDate;
  String deadline;
  double budget;
  List<int> partenaire;
  List<dynamic> files;
  String themeName;
  String communeId;

  ProjectData({
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    required this.deadline,
    required this.budget,
    required this.partenaire,
    required this.files,
    required this.themeName,
    required this.communeId,
  });
}

// --- Écran Principal : PublishProjectScreen ---

class PublishProjectScreen extends StatefulWidget {
  const PublishProjectScreen({super.key});

  @override
  State<PublishProjectScreen> createState() => _PublishProjectScreenState();
}

class _PublishProjectScreenState extends State<PublishProjectScreen> {
  int currentStep = 1;
  bool isSubmitting = false;
  String successMessage = "";
  String errorMessage = "";

  final ProjectData formData = ProjectData(
    name: "",
    description: "",
    status: "draft",
    startDate: "",
    deadline: "",
    budget: 0.0,
    partenaire: [],
    files: [],
    themeName: "",
    communeId: "",
  );

  final List<Map<String, dynamic>> steps = [
    {
      "id": 1,
      "title": "Informations générales",
      "icon": Icons.info_outline,
      "description": "Renseignez les informations principales qui décrivent rapidement votre projet.",
    },
    {
      "id": 2,
      "title": "Description et objectifs",
      "icon": Icons.track_changes,
      "description": "Décrivez en détail le contenu du projet et ses buts principaux.",
    },
    {
      "id": 3,
      "title": "Ressources et budget",
      "icon": Icons.attach_money,
      "description": "Indiquez les moyens humains, matériels et financiers nécessaires à la réalisation.",
    },
    {
      "id": 4,
      "title": "Médias et publication",
      "icon": Icons.share,
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
      if (field == 'name') {
        formData.name = value;
      } else if (field == 'description') {
        formData.description = value;
      } else if (field == 'status') {
        formData.status = value;
      } else if (field == 'startDate') {
        formData.startDate = value;
      } else if (field == 'deadline') {
        formData.deadline = value;
      } else if (field == 'budget') {
        if (value is double) {
          formData.budget = value;
        } else if (value is String) {
          formData.budget = double.tryParse(value) ?? 0.0;
        }
      } else if (field == 'partenaire') {
        if (value is List<int>) {
          formData.partenaire = value;
        } else if (value is List<String>) {
          formData.partenaire = value.map((e) => int.tryParse(e) ?? 0).toList();
        }
      } else if (field == 'files') {
        if (value is List) {
          formData.files = value;
        }
      } else if (field == 'theme_name') {
        formData.themeName = value;
      } else if (field == 'commune_id') {
        formData.communeId = value;
      }
    });
  }

  bool _validateCurrentStep() {
    if (currentStep == 1) {
      if (formData.name.trim().isEmpty) {
        _showErrorMessage("Le nom du projet est obligatoire");
        return false;
      }
      if (formData.startDate.trim().isEmpty) {
        _showErrorMessage("La date de début est obligatoire");
        return false;
      }
      if (formData.deadline.trim().isEmpty) {
        _showErrorMessage("La date limite est obligatoire");
        return false;
      }
      if (formData.communeId.trim().isEmpty) {
        _showErrorMessage("L'identifiant de la commune est obligatoire");
        return false;
      }
    } else if (currentStep == 2) {
      if (formData.description.trim().isEmpty) {
        _showErrorMessage("La description est obligatoire");
        return false;
      }
    } else if (currentStep == 3) {
      if (formData.budget <= 0) {
        _showErrorMessage("Veuillez indiquer un budget valide supérieur à 0");
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
      });
    }
  }

  void _prevStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
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
      // Simulation de la requête multipart (createProject)
      await Future.delayed(const Duration(seconds: 2));

      _showSuccessMessage("Projet ajouté avec succès");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/itantsorika/gererPublication');
        }
      });
    } catch (error) {
      _showErrorMessage("Une erreur inattendue s'est produite lors de la publication");
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
                              "Publier un projet",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Renseignez les informations de votre projet afin qu'il soit visible par les partenaires.",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Cette section s'adresse aux Communes, Collectivités Territoriales Décentralisées (CTD) et autres acteurs publics souhaitant accéder rapidement à des ressources fiables et actualisées. Vous y trouverez des documents de référence, des études, des guides méthodologiques et des outils numériques utiles.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Content Card
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
                          child: const Row(
                            children: [
                              Icon(Icons.folder_shared, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                "Nouveau projet",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                        // Body Layout (Sidebar + Form Content)
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
                                              child: Text(
                                                step['title'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: isActive ? Colors.orange.shade700 : Colors.black87,
                                                ),
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
                                      TextField(
                                        onChanged: (val) => _handleInputChange('name', val),
                                        decoration: const InputDecoration(labelText: "Nom du projet", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) => _handleInputChange('startDate', val),
                                        decoration: const InputDecoration(labelText: "Date de début (YYYY-MM-DD)", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) => _handleInputChange('deadline', val),
                                        decoration: const InputDecoration(labelText: "Date limite (YYYY-MM-DD)", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) => _handleInputChange('theme_name', val),
                                        decoration: const InputDecoration(labelText: "Nom du thème", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) => _handleInputChange('commune_id', val),
                                        decoration: const InputDecoration(labelText: "ID Commune", border: OutlineInputBorder()),
                                      ),
                                    ] else if (currentStep == 2) ...[
                                      const Text("Étape 2 : Description et objectifs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextField(
                                        maxLines: 4,
                                        onChanged: (val) => _handleInputChange('description', val),
                                        decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        initialValue: formData.status,
                                        items: const [
                                          DropdownMenuItem(value: "draft", child: Text("Brouillon")),
                                          DropdownMenuItem(value: "published", child: Text("Publié")),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) _handleInputChange('status', val);
                                        },
                                        decoration: const InputDecoration(labelText: "Statut", border: OutlineInputBorder()),
                                      ),
                                    ] else if (currentStep == 3) ...[
                                      const Text("Étape 3 : Ressources et budget", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextField(
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => _handleInputChange('budget', val),
                                        decoration: const InputDecoration(labelText: "Budget", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) {
                                          // Parse string array separated by commas
                                          final list = val.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
                                          _handleInputChange('partenaire', list);
                                        },
                                        decoration: const InputDecoration(labelText: "Partenaires (IDs séparés par des virgules)", border: OutlineInputBorder()),
                                      ),
                                    ] else ...[
                                      const Text("Étape 4 : Médias et publication", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextField(
                                        onChanged: (val) => _handleInputChange('files', [val]),
                                        decoration: const InputDecoration(labelText: "Fichiers / Médias (Chemin ou URL)", border: OutlineInputBorder()),
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
                                              : Text(currentStep == steps.length ? "Publier le projet" : "Suivant"),
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
}