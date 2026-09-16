import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import 'file_upload_widget.dart';

class AjoutFormWidget extends StatefulWidget {
  const AjoutFormWidget({super.key});

  @override
  State<AjoutFormWidget> createState() => _AjoutFormWidgetState();
}

class _AjoutFormWidgetState extends State<AjoutFormWidget> {
  final _formKey = GlobalKey<FormState>();

  // Form Data State
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  PlatformFile? _selectedFile;
  String? _selectedCategory;
  String? _selectedType;
  final List<String> _selectedThemes = [];
  String _status = "Public";
  late String _date;

  bool _isSubmitting = false;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _themes = [];
  List<Map<String, dynamic>> _types = [];

  @override
  void initState() {
    super.initState();
    _date = DateTime.now().toIso8601String().split('T')[0];
    _fetchFormData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchFormData() async {
    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('https://gateway.tsirylab.com/servicetheme/category'),
        ),
        http.get(Uri.parse('https://gateway.tsirylab.com/servicetheme/themes')),
        http.get(
          Uri.parse(
            'https://gateway.tsirylab.com/servicetheme/type?category=DOCUMENT',
          ),
        ),
      ]);

      if (responses[0].statusCode == 200 &&
          responses[1].statusCode == 200 &&
          responses[2].statusCode == 200) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            json.decode(responses[0].body),
          );
          _themes = List<Map<String, dynamic>>.from(
            json.decode(responses[1].body),
          );
          _types = List<Map<String, dynamic>>.from(
            json.decode(responses[2].body),
          );
        });
      }
    } catch (error) {
      debugPrint("Erreur lors du chargement des données : $error");
    }
  }

  void _handleThemeChange(String themeName) {
    setState(() {
      if (_selectedThemes.contains(themeName)) {
        _selectedThemes.remove(themeName);
      } else {
        _selectedThemes.add(themeName);
      }
    });
  }

  MediaType _getMediaType(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez renseigner le titre du document"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final communeId = authProvider.user?.municipalityId;

      final uri = Uri.parse('${ApiConstants.gatewayBaseUrl}/servicebiblio/resources');
      final request = http.MultipartRequest('POST', uri);

      if (_selectedFile != null) {
        final filename = _selectedFile!.name;
        final mediaType = _getMediaType(filename);

        if (kIsWeb || _selectedFile!.bytes != null) {
          if (_selectedFile!.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                _selectedFile!.bytes!,
                filename: filename,
                contentType: mediaType,
              ),
            );
          }
        } else if (_selectedFile!.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              _selectedFile!.path!,
              filename: filename,
              contentType: mediaType,
            ),
          );
        }
      }

      request.fields['title'] = title;
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['category'] = _selectedCategory ?? '';
      request.fields['type'] = _selectedType ?? '';
      request.fields['date'] = _date;
      request.fields['status'] = _status;
      if (communeId != null && communeId.isNotEmpty) {
        request.fields['communeId'] = communeId;
      }
      request.fields['theme'] = jsonEncode(_selectedThemes);
      request.fields['langage'] = 'fr';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("POST /servicebiblio/resources response (${response.statusCode}): ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedType = null;
          _selectedThemes.clear();
          _selectedFile = null;
          _status = "Public";
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Document ajouté avec succès !"),
              backgroundColor: Color(0xFF098E00),
            ),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/itantsorika/documents');
          }
        }
      } else {
        String serverMsg = "Erreur serveur (${response.statusCode})";
        try {
          final resJson = json.decode(response.body);
          if (resJson is Map && resJson.containsKey('message')) {
            final m = resJson['message'];
            serverMsg = m is List ? m.join(', ') : m.toString();
          }
        } catch (_) {}
        throw Exception(serverMsg);
      }
    } catch (error) {
      debugPrint("Erreur lors de l'ajout du document: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de l'ajout du document: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(
        top: 40,
        left: screenWidth > 768 ? 40 : 8,
        right: screenWidth > 768 ? 40 : 8,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouveau Document',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Cette section permet aux utilisateurs d'ajouter des documents.",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Grille formulaire (Colonnes gauche / droite sur grand écran)
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildLeftColumn(isDarkMode)),
                      const SizedBox(width: 32),
                      Expanded(child: _buildRightColumn(isDarkMode)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildLeftColumn(isDarkMode),
                      const SizedBox(height: 24),
                      _buildRightColumn(isDarkMode),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Bouton de soumission
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitting
                      ? Colors.green.shade300
                      : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre du document
        const Text(
          'Titre du document',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.title, size: 20),
            hintText: 'Entrer le titre',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Champ requis' : null,
        ),
        const SizedBox(height: 16),

        // Description
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Description détaillée...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Catégorie
        const Text(
          'Catégorie du document',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['name'].toString(),
              child: Text(cat['name'].toString()),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.tag, size: 20),
            hintText: 'Sélectionnez une catégorie',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          ),
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        ),
        const SizedBox(height: 16),

        // Type
        const Text(
          'Type de document',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          items: _types.map((type) {
            return DropdownMenuItem<String>(
              value: type['name'].toString(),
              child: Text(type['name'].toString()),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedType = val),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_outlined, size: 20),
            hintText: 'Sélectionnez un type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          ),
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        ),
        const SizedBox(height: 16),

        // Thèmes (sélection multiple)
        const Text(
          'Thèmes (sélection multiple)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          ),
          child: _themes.isEmpty
              ? const Center(
                  child: Text(
                    'Chargement des thèmes...',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _themes.length,
                  itemBuilder: (context, index) {
                    final theme = _themes[index];
                    final themeName = theme['name'].toString();
                    final isSelected = _selectedThemes.contains(themeName);
                    return Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        title: Text(
                          themeName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) => _handleThemeChange(themeName),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.green,
                      ),
                    );
                  },
                ),
        ),
        if (_selectedThemes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${_selectedThemes.length} thème(s) sélectionné(s)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildRightColumn(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date de création
        const Text(
          'Date de création',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _date,
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Fichier (FileUpload widget)
        const Text(
          'Ajouter le fichier',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        FileUploadWidget(
          onFileSelect: (file) {
            setState(() {
              _selectedFile = file;
            });
          },
        ),
        const SizedBox(height: 24),

        // Visibilité du document
        const Text(
          'Visibilité du document',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _status,
          onChanged: (val) => setState(() => _status = val ?? _status),
          child: Column(
            children: const [
              Material(
                color: Colors.transparent,
                child: RadioListTile<String>(
                  title: Text(
                    'Public (accessible à tous)',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: 'Public',
                  dense: true,
                  activeColor: Colors.green,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: RadioListTile<String>(
                  title: Text('Privé', style: TextStyle(fontSize: 14)),
                  value: 'Private',
                  dense: true,
                  activeColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
