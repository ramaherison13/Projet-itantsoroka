import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadedFileModel {
  final String id;
  final String name;
  final String type;
  final int size;
  final String url; // Pour le web (base64) ou chemin local
  final String category; // 'image' ou 'document'
  final dynamic file; // PlatformFile ou File selon la plateforme

  UploadedFileModel({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.url,
    required this.category,
    required this.file,
  });
}

class Step4MediaWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, dynamic value) onChange;

  const Step4MediaWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step4MediaWidget> createState() => _Step4MediaWidgetState();
}

class _Step4MediaWidgetState extends State<Step4MediaWidget> {
  final List<UploadedFileModel> _uploadedFiles = [];
  final bool _dragActive = false;

  @override
  void initState() {
    super.initState();
    // Initialisation si des fichiers existent déjà dans data['files']
    if (widget.data['files'] != null && widget.data['files'] is List) {
      // Optionnel : reconstruire _uploadedFiles si besoin
    }
  }

  Future<void> _pickFiles(String category) async {
    FileType fileType = category == 'image' ? FileType.image : FileType.custom;
    List<String>? allowedExtensions = category == 'document'
        ? ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx']
        : null;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      allowMultiple: true,
      withData: true, // Important pour le web ou pour lire les bytes
    );

    if (result != null) {
      List<UploadedFileModel> newFiles = [];
      for (var file in result.files) {
        String id = DateTime.now().millisecondsSinceEpoch.toString() +
            (1000 + (DateTime.now().microsecond % 9000)).toString();
        
        String url = '';
        if (file.bytes != null) {
          // Sur le web ou si bytes disponibles, on peut simuler ou garder le nom
          url = file.name;
        } else if (file.path != null) {
          url = file.path!;
        }

        newFiles.add(
          UploadedFileModel(
            id: id,
            name: file.name,
            type: file.extension ?? '',
            size: file.size,
            url: url,
            category: category,
            file: file,
          ),
        );
      }

      setState(() {
        _uploadedFiles.addAll(newFiles);
        // On envoie au parent la liste des fichiers bruts ou modèles
        widget.onChange(
          'files',
          _uploadedFiles.map((f) => f.file).toList(),
        );
      });
    }
  }

  void _removeFile(String fileId) {
    setState(() {
      _uploadedFiles.removeWhere((file) => file.id == fileId);
      widget.onChange(
        'files',
        _uploadedFiles.map((f) => f.file).toList(),
      );
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    int i = (bytes > 0) ? (bytes.toString().length > 3 ? (bytes.toString().length - 1) ~/ 3 : 0) : 0;
    // Calcul plus précis de la taille
    double val = bytes / (k > 0 ? math.pow(k, i > 3 ? 3 : i) : 1);
    return '${val.toStringAsFixed(2)} ${sizes[i > 3 ? 3 : i]}';
  }

  Future<void> _handleSubmit() async {
    // Exemple d'envoi simulation
    debugPrint("Envoi de ${_uploadedFiles.length} fichiers...");
    // TODO: Implémenter l'appel API MultipartRequest
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Médias et publication',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez des visuels et documents pour illustrer votre projet avant sa publication.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Grille Image / Documents
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildImageUploadCard(isDarkMode)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDocumentUploadCard(isDarkMode)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildImageUploadCard(isDarkMode),
                    const SizedBox(height: 16),
                    _buildDocumentUploadCard(isDarkMode),
                  ],
                );
              }
            },
          ),

          // Liste des fichiers ajoutés
          if (_uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Fichiers ajoutés (${_uploadedFiles.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _uploadedFiles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final file = _uploadedFiles[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50,
                    border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.white,
                          border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          file.category == 'image' ? Icons.image : Icons.description,
                          color: file.category == 'image' ? Colors.green : Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatFileSize(file.size),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (file.category == 'image')
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                              color: Colors.grey,
                              tooltip: 'Prévisualiser',
                              onPressed: () {
                                _showPreviewDialog(context, file);
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.red,
                            tooltip: 'Supprimer',
                            onPressed: () => _removeFile(file.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // Bouton submit pour test
          if (_uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Envoyer les fichiers'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadCard(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image de représentation',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickFiles('image'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: _dragActive ? Colors.green : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Importer une image',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'ou glissez-déposez vos fichiers ici',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadCard(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pièce jointe',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickFiles('document'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.upload_file, color: Colors.grey.shade400, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Importer une pièce jointe',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, DOC, XLS, PPT...',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPreviewDialog(BuildContext context, UploadedFileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: file.file.bytes != null
                ? Image.memory(file.file.bytes!)
                : (file.file.path != null
                    ? Image.file(File(file.file.path!))
                    : const Text('Aperçu non disponible')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}