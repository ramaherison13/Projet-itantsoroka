import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class MonographieEditWidget extends StatefulWidget {
  final dynamic user;
  final dynamic territoireStore;
  final Future<dynamic> Function(String formattedId)? getTerritoryByFormattedId;
  final Future<void> Function(FormDataMock formData) createMonographie;
  final void Function(String message, String type) showAlert;

  const MonographieEditWidget({
    super.key,
    required this.user,
    this.territoireStore,
    this.getTerritoryByFormattedId,
    required this.createMonographie,
    required this.showAlert,
  });

  @override
  MonographieEditWidgetState createState() => MonographieEditWidgetState();
}

class FormDataMock {
  File? file;
  String resume = '';
  String description = '';
  String code = '';
  String userID = '1';
  String? idDistrict;
  String? idCommune;
  String? idArrondissement;
}

class MonographieEditWidgetState extends State<MonographieEditWidget> {
  File? _monographieFile;
  PlatformFile? _webFile;
  final TextEditingController _resumeController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String? _showPreview; // null, 'resume', 'details'
  bool _loading = false;
  String _activeTab = 'resume'; // 'resume' ou 'details'
  dynamic _territory;

  bool get _isChefDistrict {
    if (widget.user == null) return false;
    final roles = widget.user['roles'] ?? widget.user.roles;
    if (roles is List) {
      return roles.any((r) => (r is Map ? r['role_slug'] : r.role_slug) == 'Chef-District');
    }
    return false;
  }

  String _replaceLastSixWithZeros(String input) {
    if (input.length < 6) {
      throw Exception("La chaîne doit contenir au moins 6 caractères.");
    }
    return "${input.substring(0, input.length - 6)}000000";
  }

  @override
  void initState() {
    super.initState();
    _loadTerritoryData();
  }

  Future<void> _loadTerritoryData() async {
    try {
      if (_isChefDistrict && widget.user?['municipality_id'] != null) {
        final districtCode = _replaceLastSixWithZeros(widget.user['municipality_id']);
        if (widget.getTerritoryByFormattedId != null) {
          final territoryData = await widget.getTerritoryByFormattedId!(districtCode);
          if (territoryData != null) {
            setState(() {
              _territory = territoryData;
            });
          }
        }
      } else if (widget.territoireStore != null) {
        setState(() {
          _territory = widget.territoireStore;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement territoire pour Chef District: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        if (kIsWeb) {
          setState(() {
            _webFile = result.files.first;
          });
        } else {
          if (result.files.single.path != null) {
            setState(() {
              _monographieFile = File(result.files.single.path!);
            });
          }
        }
        widget.showAlert("Fichier sélectionné avec succès", "success");
      }
    } catch (e) {
      widget.showAlert("Erreur lors de la sélection du fichier", "error");
    }
  }

  bool get _isFormDirty =>
      _resumeController.text.isNotEmpty ||
      _detailsController.text.isNotEmpty ||
      _monographieFile != null ||
      _webFile != null;

  Future<void> _handleSubmit() async {
    if (_monographieFile == null && _webFile == null) {
      widget.showAlert("Veuillez sélectionner un fichier de monographie", "error");
      return;
    }

    if (widget.user == null || (widget.user['user_id'] == null && widget.user['id'] == null)) {
      widget.showAlert("Utilisateur non connecté", "error");
      return;
    }

    if (widget.user['municipality_id'] == null) {
      widget.showAlert("ID de municipalité introuvable", "error");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      String code = widget.user['municipality_id'];
      if (_isChefDistrict) {
        code = _replaceLastSixWithZeros(code);
      }

      final formData = FormDataMock();
      if (!kIsWeb && _monographieFile != null) {
        formData.file = _monographieFile;
      }
      formData.resume = _resumeController.text;
      formData.description = _detailsController.text;
      formData.code = code;

      final numericUserId = widget.user['id'] ?? widget.user['user_id'] ?? 1;
      formData.userID = numericUserId.toString();

      if (_territory != null) {
        if (_territory['district']?['id'] != null) {
          formData.idDistrict = _territory['district']['id'].toString();
        }
        if (_territory['region']?['commune']?['id'] != null) {
          formData.idCommune = _territory['region']['commune']['id'].toString();
        } else if (_territory['commune']?['id'] != null) {
          formData.idCommune = _territory['commune']['id'].toString();
        }
        if (_territory['arrondissement']?['id'] != null) {
          formData.idArrondissement = _territory['arrondissement']['id'].toString();
        } else if (_territory['arrondissement'] is List && (_territory['arrondissement'] as List).isNotEmpty) {
          formData.idArrondissement = _territory['arrondissement'][0]['id'].toString();
        }
      }

      await widget.createMonographie(formData);

      widget.showAlert("Monographie créée avec succès!", "success");

      setState(() {
        _monographieFile = null;
        _webFile = null;
        _resumeController.clear();
        _detailsController.clear();
      });
    } catch (error) {
      debugPrint("Erreur lors de la création de la monographie: $error");
      widget.showAlert("Erreur lors de la création de la monographie", "error");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final territoryName = _territory?['commune']?['name'] ??
        _territory?['district']?['name'] ??
        _territory?['region']?['name'] ??
        "Territoire";

    final fileName = _webFile?.name ?? (_monographieFile?.path.split('/').last);
    final fileSize = _webFile?.size ?? (_monographieFile != null ? _monographieFile!.lengthSync() : 0);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.grey.shade900, Colors.grey.shade800]
                  : [Colors.grey.shade50, Colors.grey.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [Colors.green.shade700, Colors.teal.shade800]
                            : [Colors.green.shade600, Colors.teal.shade600],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Monographie de territoire",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          territoryName,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green.shade100,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload Section
                        const Text(
                          "DOCUMENT DE MONOGRAPHIE",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: fileName != null ? Colors.green.shade400 : Colors.grey.shade400,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: fileName != null
                                  ? Colors.green.withValues(alpha: 0.05)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  fileName != null ? Icons.check_circle : Icons.upload_file,
                                  size: 40,
                                  color: fileName != null ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                if (fileName != null) ...[
                                  Text(
                                    fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${(fileSize / 1024).toStringAsFixed(2)} KB",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _monographieFile = null;
                                      _webFile = null;
                                    }),
                                    child: const Text("Supprimer le fichier", style: TextStyle(color: Colors.red)),
                                  ),
                                ] else ...[
                                  const Text(
                                    "Glissez-déposez ou cliquez pour parcourir",
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Formats acceptés: PDF, DOC, DOCX, TXT",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tabs
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _activeTab = 'resume'),
                              child: Text(
                                "Résumé du territoire",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _activeTab == 'resume' ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () => setState(() => _activeTab = 'details'),
                              child: Text(
                                "Détails du territoire",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _activeTab == 'details' ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Editor Field
                        if (_activeTab == 'resume') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Contenu du résumé", style: TextStyle(fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text("Aperçu"),
                                onPressed: () => setState(() => _showPreview = 'resume'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _resumeController,
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText: 'Commencez à écrire le résumé...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text("${_resumeController.text.length} caractères", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Contenu des détails", style: TextStyle(fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text("Aperçu"),
                                onPressed: () => setState(() => _showPreview = 'details'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _detailsController,
                            maxLines: 8,
                            decoration: InputDecoration(
                              hintText: 'Commencez à écrire les détails...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text("${_detailsController.text.length} caractères", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Footer Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isFormDirty)
                          const Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.orange),
                              SizedBox(width: 8),
                              Text("Modifications non enregistrées", style: TextStyle(fontSize: 12, color: Colors.orange)),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: _loading || (_monographieFile == null && _webFile == null) ? null : _handleSubmit,
                          icon: _loading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check),
                          label: Text(_loading ? "Enregistrement..." : "Enregistrer la monographie"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Modal Aperçu
      bottomSheet: _showPreview != null
          ? Container(
              color: Colors.black.withValues(alpha: 0.6),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: Colors.green),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Aperçu ${_showPreview == 'resume' ? 'du résumé' : 'des détails'}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => setState(() => _showPreview = null),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _showPreview == 'resume' ? _resumeController.text : _detailsController.text,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}