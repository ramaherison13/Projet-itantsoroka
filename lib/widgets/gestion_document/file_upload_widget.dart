import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadWidget extends StatefulWidget {
  final Function(PlatformFile? file) onFileSelect;

  const FileUploadWidget({
    super.key,
    required this.onFileSelect,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  PlatformFile? _file;
  final bool _isDragOver = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true, // Pour récupérer les octets si nécessaire
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.first;
      });
      widget.onFileSelect(_file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120, // Équivalent de h-30 (30 * 4 = 120)
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDragOver
              ? Colors.green.shade50
              : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50),
          border: Border.all(
            color: _isDragOver ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: _file != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _file!.name,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Importer un fichier',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}