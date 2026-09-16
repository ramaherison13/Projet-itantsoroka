import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
// -----------------------------------------------------------------------------
// MODÈLES DE DONNÉES
// -----------------------------------------------------------------------------
class PieceJointe {
  final int id;
  final String name;
  final String size;
  final PlatformFile file;

  PieceJointe({
    required this.id,
    required this.name,
    required this.size,
    required this.file,
  });
}

class DistrictModel {
  final String id;
  final String formattedId;
  final String name;

  DistrictModel({
    required this.id,
    required this.formattedId,
    required this.name,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id']?.toString() ?? '',
      formattedId: json['formatted_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class CommuneModel {
  final int communeId;
  final String formattedId;
  final String name;

  CommuneModel({
    required this.communeId,
    required this.formattedId,
    required this.name,
  });

  factory CommuneModel.fromJson(Map<String, dynamic> json) {
    return CommuneModel(
      communeId: json['commune_id'] ?? 0,
      formattedId: json['formatted_id']?.toString() ?? json['commune_id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class SousTypeActe {
  final String id;
  final String nom;
  final String? description;
  final int? delaiTraitementJours;
  final bool active;

  SousTypeActe({
    required this.id,
    required this.nom,
    this.description,
    this.delaiTraitementJours,
    required this.active,
  });

  factory SousTypeActe.fromJson(Map<String, dynamic> json) {
    return SousTypeActe(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      delaiTraitementJours: json['delai_traitement_jours'],
      active: json['active'] ?? true,
    );
  }
}

class TypeActeWithSousTypes {
  final String id;
  final String nom;
  final String? description;
  final List<SousTypeActe> sousTypes;

  TypeActeWithSousTypes({
    required this.id,
    required this.nom,
    this.description,
    required this.sousTypes,
  });

  factory TypeActeWithSousTypes.fromJson(Map<String, dynamic> json) {
    var rawSousTypes = json['sous_types'] as List? ?? [];
    List<SousTypeActe> parsedSousTypes = rawSousTypes.map((st) => SousTypeActe.fromJson(st)).toList();

    return TypeActeWithSousTypes(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      sousTypes: parsedSousTypes,
    );
  }
}

// -----------------------------------------------------------------------------
// PAGE DE SOUMISSION D'ACTE
// -----------------------------------------------------------------------------
class SoumissionActe extends StatefulWidget {
  final String baseUrl;
  final Map<String, dynamic> currentUser;

  const SoumissionActe({
    super.key,
    required this.baseUrl,
    required this.currentUser,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SoumissionActeState createState() => _SoumissionActeState();
}

class _SoumissionActeState extends State<SoumissionActe> {
  // Champs requis
  String _titre = '';
  String _description = '';
  String _typeId = '';
  String _sousTypeId = '';
  String _communeId = '';
  String _districtId = '';

  // Données dynamiques
  List<TypeActeWithSousTypes> _typesActes = [];
  List<SousTypeActe> _sousTypesActes = [];
  List<DistrictModel> _districts = [];
  List<CommuneModel> _communes = [];

  // États de chargement
  bool _loadingDistricts = true;
  bool _loadingCommunes = false;
  bool _loading = false;

  // États de validation (touched)
  final Map<String, bool> _touched = {
    'titre': false,
    'sousType': false,
    'commune': false,
  };

  // Pièces jointes
  List<PieceJointe> _piecesJointes = [];

  // Contrôleurs
  late TextEditingController _auteurController;

  @override
  void initState() {
    super.initState();
    _auteurController = TextEditingController();
    _fetchTypes();
    _fetchDistricts();
  }

  @override
  void dispose() {
    _auteurController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('access_token');
    if (raw == null) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map && parsed.containsKey('access_token')) {
        return parsed['access_token'];
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _fetchTypes() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/controlelegalite/types-actes'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _typesActes = data.map((json) => TypeActeWithSousTypes.fromJson(json)).toList();
        });
      }
    } catch (error) {
      debugPrint('Erreur lors du chargement des types : $error');
    }
  }

  Future<void> _fetchDistricts() async {
    try {
      setState(() => _loadingDistricts = true);
      final token = await _getToken();
      
      // Utilisation du service territoire ou route équivalente sur baseUrl
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/districts'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] ?? decoded;
        setState(() {
          _districts = data.map((json) => DistrictModel.fromJson(json)).toList();
        });
      }
    } catch (error) {
      debugPrint('Erreur lors du chargement des districts: $error');
      setState(() => _districts = []);
    } finally {
      setState(() => _loadingDistricts = false);
    }
  }

  void _handleTypeChange(String selectedTypeId) {
    setState(() {
      _typeId = selectedTypeId;
      _sousTypeId = '';
      _sousTypesActes = [];

      if (selectedTypeId.isNotEmpty) {
        final selectedType = _typesActes.firstWhere(
          (t) => t.id == selectedTypeId,
          orElse: () => TypeActeWithSousTypes(id: '', nom: '', sousTypes: []),
        );
        _sousTypesActes = selectedType.sousTypes.where((st) => st.active).toList();
      }
    });
  }

  Future<void> _handleDistrictChange(String selectedDistrictId) async {
    setState(() {
      _districtId = selectedDistrictId;
      _communeId = '';
      _communes = [];
    });

    if (selectedDistrictId.isEmpty) return;

    try {
      setState(() => _loadingCommunes = true);
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/communes/district/$selectedDistrictId'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final List communesData = jsonDecode(res.body);
        if (communesData.isNotEmpty) {
          List<CommuneModel> loadedCommunes = communesData.map((json) => CommuneModel.fromJson(json)).toList();
          loadedCommunes.sort((a, b) => a.name.compareTo(b.name));
          setState(() => _communes = loadedCommunes);
        }
      }
    } catch (error) {
      debugPrint('Erreur lors du chargement des communes : $error');
    } finally {
      setState(() => _loadingCommunes = false);
    }
  }

  Future<void> _handleFileUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final newFile = PieceJointe(
        id: DateTime.now().millisecondsSinceEpoch,
        name: file.name,
        size: '${(file.size / 1024).toStringAsFixed(2)} KB',
        file: file,
      );
      setState(() {
        _piecesJointes.add(newFile);
      });
    }
  }

  void _removeFile(int id) {
    setState(() {
      _piecesJointes.removeWhere((f) => f.id == id);
    });
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _touched['titre'] = true;
      _touched['sousType'] = true;
      _touched['commune'] = true;
    });

    if (_titre.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre doit contenir au moins 3 caractères.')),
      );
      return;
    }

    if (_typeId.isEmpty || _sousTypeId.isEmpty || _communeId.isEmpty || _districtId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires avant de soumettre.')),
      );
      return;
    }

    try {
      setState(() => _loading = true);
      final token = await _getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.baseUrl}/controlelegalite/actes'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['titre'] = _titre;
      request.fields['description'] = _description;
      request.fields['type_ids'] = _typeId;
      request.fields['sous_type_ids'] = _sousTypeId;
      request.fields['commune_id'] = _communeId;
      request.fields['district_id'] = _districtId;
      request.fields['auteur_id'] = widget.currentUser['user_id']?.toString() ?? '';
      request.fields['statut'] = 'en_cours';

      if (_piecesJointes.isNotEmpty && _piecesJointes[0].file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'fichier',
            _piecesJointes[0].file.bytes!,
            filename: _piecesJointes[0].file.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData != null) {
          final ref = 'ACTE-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
          
          _showSuccesModal(ref);

          // Reset formulaires
          setState(() {
            _titre = '';
            _description = '';
            _typeId = '';
            _sousTypeId = '';
            _communeId = '';
            _districtId = '';
            _piecesJointes = [];
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur : ${response.body}")),
        );
      }
    } catch (error) {
      debugPrint('Erreur lors de la soumission de l’acte : $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une erreur est survenue lors de l'envoi de l'acte.")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSuccesModal(String reference) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Succès"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Votre acte a été soumis avec succès."),
            const SizedBox(height: 8),
            Text("Référence : $reference", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.currentUser['user_pseudo'] ?? widget.currentUser['nom'] ?? 'Utilisateur inconnu';
    _auteurController.text = userName;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nouvelle soumission d'acte",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green, Colors.greenAccent]),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.description, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              "Formulaire de soumission d'acte",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Auteur et Titre
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Auteur *", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _auteurController,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          filled: true,
                                          fillColor: Colors.grey[100],
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
                                      const Text("Titre *", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        onChanged: (val) => setState(() => _titre = val),
                                        decoration: InputDecoration(
                                          hintText: "Titre de l'acte",
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                      if (_touched['titre']! && _titre.trim().isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text("Le titre est requis", style: TextStyle(color: Colors.red, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Type et Sous-type
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Type d'acte *", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _typeId.isEmpty ? null : _typeId,
                                        hint: const Text("Sélectionner un type"),
                                        items: _typesActes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nom))).toList(),
                                        onChanged: (val) => _handleTypeChange(val ?? ''),
                                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Sous-type d'acte *", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _sousTypeId.isEmpty ? null : _sousTypeId,
                                        hint: Text(_typeId.isEmpty ? "Sélectionnez d'abord un type" : "Sélectionner un sous-type"),
                                        items: _sousTypesActes.map((st) => DropdownMenuItem(value: st.id, child: Text(st.nom))).toList(),
                                        onChanged: _typeId.isEmpty ? null : (val) => setState(() => _sousTypeId = val ?? ''),
                                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
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
                                      const Text("District concerné *", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _districtId.isEmpty ? null : _districtId,
                                        hint: Text(_loadingDistricts ? "Chargement..." : "Sélectionner un district"),
                                        items: _districts.map((d) => DropdownMenuItem(value: d.formattedId, child: Text(d.name))).toList(),
                                        onChanged: (val) => _handleDistrictChange(val ?? ''),
                                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Commune *", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _communeId.isEmpty ? null : _communeId,
                                        hint: Text(_loadingCommunes ? "Chargement..." : "Sélectionner une commune"),
                                        items: _communes.map((c) => DropdownMenuItem(value: c.formattedId, child: Text(c.name))).toList(),
                                        onChanged: _districtId.isEmpty ? null : (val) => setState(() => _communeId = val ?? ''),
                                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Description
                            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              maxLines: 4,
                              onChanged: (val) => setState(() => _description = val),
                              decoration: InputDecoration(
                                hintText: "Description détaillée de l'acte",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Fichiers
                            const Text("Fichier de l'acte (PDF, DOC, etc.)", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _handleFileUpload,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Column(
                                    children: const [
                                      Icon(Icons.upload_file, size: 36, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text("Importer un fichier", style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_piecesJointes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ..._piecesJointes.map((f) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [const Icon(Icons.insert_drive_file, color: Colors.green), const SizedBox(width: 8), Text(f.name)]),
                                  IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _removeFile(f.id)),
                                ],
                              )),
                            ],
                            const SizedBox(height: 30),

                            // Boutons d'action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Annuler"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _loading ? null : _handleSubmit,
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: Text(_loading ? "Envoi..." : "Soumettre l'acte", style: const TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
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