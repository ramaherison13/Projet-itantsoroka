import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/services/territoire_monographie_service.dart';

class AdminMonographieScreen extends StatefulWidget {
  final String? initialCode;
  final String? initialTerritoryName;

  const AdminMonographieScreen({
    super.key,
    this.initialCode,
    this.initialTerritoryName,
  });

  @override
  State<AdminMonographieScreen> createState() => _AdminMonographieScreenState();
}

class _AdminMonographieScreenState extends State<AdminMonographieScreen> {
  // Fichiers
  File? _localFile;
  PlatformFile? _webFile;
  String? _existingFileName = "1787736558490-b2efead5-76da-46fa-be77-755d5afc8317.pdf";
  String? _existingFileUrl;

  // Contrôleurs de texte
  final TextEditingController _resumeController = TextEditingController(text: "**Arivonimamo**");
  final TextEditingController _detailsController = TextEditingController();

  String _activeTab = 'resume'; // 'resume' ou 'details'
  bool _showPreviewModal = false;
  bool _isLoading = false;
  String _selectedTerritoryName = "District Arivonimamo";
  String _selectedTerritoryCode = "110100000000";

  @override
  void initState() {
    super.initState();
    if (widget.initialTerritoryName != null && widget.initialTerritoryName!.isNotEmpty) {
      _selectedTerritoryName = widget.initialTerritoryName!;
    }
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _selectedTerritoryCode = widget.initialCode!;
    }
    _loadExistingMonographie();
  }

  @override
  void dispose() {
    _resumeController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // Chargement de la monographie existante depuis l'API
  Future<void> _loadExistingMonographie() async {
    try {
      final monographies = await TerritoireService.getAllMonographies();
      if (monographies != null && monographies.isNotEmpty) {
        final mono = monographies.firstWhere(
          (m) => m['code'] == _selectedTerritoryCode || m['formatted_id'] == _selectedTerritoryCode,
          orElse: () => monographies.isNotEmpty ? monographies.first : <String, dynamic>{},
        );

        if (mono != null) {
          setState(() {
            if (mono['resume'] != null && mono['resume'].toString().isNotEmpty) {
              _resumeController.text = mono['resume'].toString();
            }
            if (mono['description'] != null && mono['description'].toString().isNotEmpty) {
              _detailsController.text = mono['description'].toString();
            }
            if (mono['file'] != null && mono['file'].toString().isNotEmpty) {
              final rawFile = mono['file'].toString();
              _existingFileName = rawFile.split('/').last;
              _existingFileUrl = "${ApiConstants.gatewayBaseUrl}/$rawFile";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement de la monographie existante: $e");
    }
  }

  // Sélection d'un nouveau fichier
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            _webFile = result.files.first;
            _existingFileName = _webFile!.name;
          } else if (result.files.single.path != null) {
            _localFile = File(result.files.single.path!);
            _existingFileName = result.files.single.name;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fichier sélectionné avec succès !"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la sélection du fichier: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Insertion de balises formatées dans le champ texte actif
  void _insertFormatting(String prefix, [String suffix = '']) {
    final controller = _activeTab == 'resume' ? _resumeController : _detailsController;
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid || selection.start < 0) {
      controller.text = text + prefix + suffix;
      return;
    }

    final selectedText = selection.textInside(text);
    final replacement = '$prefix$selectedText$suffix';
    final newText = text.replaceRange(selection.start, selection.end, replacement);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      ),
    );
    setState(() {});
  }

  // Soumission / Enregistrement de la monographie
  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.serviceMonographies}/monographies'),
      );

      request.fields['code'] = _selectedTerritoryCode;
      request.fields['resume'] = _resumeController.text;
      request.fields['description'] = _detailsController.text;
      request.fields['userID'] = '1';

      if (kIsWeb && _webFile != null && _webFile!.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webFile!.bytes!,
            filename: _webFile!.name,
          ),
        );
      } else if (_localFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _localFile!.path),
        );
      }

      await TerritoireService.createMonographie(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Monographie enregistrée avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur sauvegarde monographie: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'enregistrement: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Modal de sélection de territoire/commune
  void _openAddCommuneModal() {
    final TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Ajouter monographie commune", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Entrez le nom ou le code de la commune à gérer :"),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: "Nom de la commune (ex: Amboanana)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _selectedTerritoryName = "Commune ${nameCtrl.text.trim()}";
                });
              }
              Navigator.pop(dialogContext);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    final activeController = _activeTab == 'resume' ? _resumeController : _detailsController;
    final fileName = _existingFileName ?? "Aucun fichier sélectionné";

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                border: Border(bottom: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/itantsorika-services'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      side: BorderSide(color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Retour aux services I-Tantsoroka", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // ── Contenu Principal Scrollable ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 1. Bannière En-tête Verte ────────────────────────
                        Container(
                          padding: EdgeInsets.all(isMobile ? 20 : 28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF047857), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF047857).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Monographie de territoire",
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedTerritoryName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFFD1FAE5),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _openAddCommuneModal,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: isMobile ? const SizedBox.shrink() : const Text("Ajouter monographie commune"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode ? const Color(0xFF065F46) : const Color(0xFF047857),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── 2. Zone Document de Monographie (Dashed Container) ──
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "DOCUMENT DE MONOGRAPHIE",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Zone Pointillée (Dashed box)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF10B981),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      fileName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Fichier actuellement enregistré",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    OutlinedButton(
                                      onPressed: _pickFile,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      ),
                                      child: const Text("Remplacer", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Sélectionner un nouveau fichier pour remplacer celui-ci",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDarkMode ? const Color(0xFF64748B) : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Bouton Voir le fichier
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_existingFileUrl != null && _existingFileUrl!.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Ouverture du fichier: $_existingFileUrl")),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Aperçu du fichier prêt.")),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                label: const Text("Voir le fichier"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── 3. Tabs & Éditeur de Contenu ─────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Onglets (Tabs)
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _activeTab = 'resume'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _activeTab == 'resume' ? const Color(0xFF10B981) : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Résumé du territoire",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _activeTab == 'resume'
                                              ? const Color(0xFF10B981)
                                              : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  InkWell(
                                    onTap: () => setState(() => _activeTab = 'details'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _activeTab == 'details' ? const Color(0xFF10B981) : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Détails du territoire",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _activeTab == 'details'
                                              ? const Color(0xFF10B981)
                                              : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 20),

                              // Header Éditeur + Bouton Aperçu
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _activeTab == 'resume' ? "Contenu du résumé" : "Contenu des détails",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() => _showPreviewModal = true),
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 15),
                                    label: const Text("Aperçu"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Barre d'outils de formatage (Toolbar: H1, H2, H3, B, I, List, etc.)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildToolbarButton("H1", () => _insertFormatting("# ")),
                                      _buildToolbarButton("H2", () => _insertFormatting("## ")),
                                      _buildToolbarButton("H3", () => _insertFormatting("### ")),
                                      const SizedBox(width: 8),
                                      _buildToolbarButton("B", () => _insertFormatting("**", "**")),
                                      _buildToolbarButton("I", () => _insertFormatting("*", "*")),
                                      const SizedBox(width: 8),
                                      _buildToolbarIconButton(Icons.format_list_bulleted, () => _insertFormatting("- ")),
                                      _buildToolbarIconButton(Icons.format_quote, () => _insertFormatting("> ")),
                                      _buildToolbarIconButton(Icons.undo_rounded, () {}),
                                      _buildToolbarIconButton(Icons.redo_rounded, () {}),
                                    ],
                                  ),
                                ),
                              ),

                              // Champ Texte Éditeur
                              Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                  border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                ),
                                child: TextField(
                                  controller: activeController,
                                  maxLines: 8,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    fontFamily: 'monospace',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: "Saisissez le contenu ici...",
                                    hintStyle: TextStyle(color: isDarkMode ? const Color(0xFF64748B) : Colors.grey),
                                    contentPadding: const EdgeInsets.all(14),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${activeController.text.length} caractères",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDarkMode ? const Color(0xFF64748B) : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 4. Barre d'action inférieure (Bottom Action Bar) ─────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                border: Border(top: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSave,
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isLoading ? "Enregistrement..." : "Enregistrer la monographie"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Modal d'aperçu
      bottomSheet: _showPreviewModal
          ? Container(
              color: Colors.black.withValues(alpha: 0.7),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Aperçu ${_activeTab == 'resume' ? 'du résumé' : 'des détails'}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () => setState(() => _showPreviewModal = false),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            activeController.text.isNotEmpty
                                ? activeController.text
                                : "Aucun contenu à afficher pour l'instant.",
                            style: TextStyle(
                              fontSize: 15,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                              height: 1.6,
                            ),
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

  Widget _buildToolbarButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}
