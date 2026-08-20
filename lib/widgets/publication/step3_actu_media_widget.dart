import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Step3ActuMediaWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, dynamic value) onChange;

  const Step3ActuMediaWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step3ActuMediaWidget> createState() => _Step3ActuMediaWidgetState();
}

class _Step3ActuMediaWidgetState extends State<Step3ActuMediaWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // En Flutter web ou mobile, on peut stocker soit l'objet File, soit XFile / les octets (bytes) selon l'implémentation du backend.
        // Ici, on transmet l'objet File (ou XFile selon l'usage, ou les bytes pour le Web).
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          widget.onChange('image', bytes); // Souvent utile pour le web, ou stocker XFile
          widget.onChange('image_xfile', pickedFile);
        } else {
          widget.onChange('image', File(pickedFile.path));
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection de l'image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamic imageFile = widget.data['image'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Image principale",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    imageFile != null ? "Modifier l'image" : "Sélectionner une image",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (imageFile != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb && imageFile is Uint8List
                        ? Image.memory(
                            imageFile,
                            height: 192,
                            fit: BoxFit.cover,
                          )
                        : imageFile is File
                            ? Image.file(
                                imageFile,
                                height: 192,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: () {
                          widget.onChange('image', null);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}