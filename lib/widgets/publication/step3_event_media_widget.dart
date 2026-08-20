import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Step3EventMediaWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String field, dynamic value) onChange;

  const Step3EventMediaWidget({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<Step3EventMediaWidget> createState() => _Step3EventMediaWidgetState();
}

class _Step3EventMediaWidgetState extends State<Step3EventMediaWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        widget.onChange('image', image);
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection de l'image: $e");
    }
  }

  void _removeImage() {
    widget.onChange('image', null);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamic imageFile = widget.data['image'];
    final bool isCompleted = imageFile != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'étape
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.purple.shade900.withValues(alpha: 0.3) : Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, size: 16, color: isDarkMode ? Colors.purple.shade400 : Colors.purple.shade600),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Étape 3', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500)),
                  Text(
                    'Médias et publication',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.purple.shade400 : Colors.purple.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez une image qui représentera votre événement pour attirer l'attention des participants.",
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Label
          Row(
            children: [
              const Icon(Icons.camera_alt, size: 16, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                "Image de l'événement",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const SizedBox(width: 4),
              Text(
                "(optionnel)",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Zone d'upload ou Preview
          if (!isCompleted) ...[
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.3) : Colors.grey.shade50,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.purple.shade900.withValues(alpha: 0.5) : Colors.purple.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload, size: 32, color: Colors.purple),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Glissez votre image ici",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text("ou", style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Choisir un fichier"),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Formats supportés: JPG, PNG, WEBP (max. 5MB)",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey.shade800,
                    child: kIsWeb
                        ? Image.network(
                            (imageFile as XFile).path,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            (imageFile as XFile).path,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.edit, size: 18),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        tooltip: "Remplacer",
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.red.shade600),
                        tooltip: "Supprimer",
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 18, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        (imageFile).name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                  FutureBuilder<int>(
                    future: imageFile.length(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        double sizeInMb = snapshot.data! / (1024 * 1024);
                        return Text("${sizeInMb.toStringAsFixed(2)} MB", style: TextStyle(fontSize: 12, color: Colors.grey.shade400));
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Progression de l'étape", style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white70 : Colors.black87)),
                    Text(isCompleted ? "Terminé" : "Image optionnelle", style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: isCompleted ? 1.0 : 0.5,
                  backgroundColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : Colors.purple),
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted ? "Image téléchargée avec succès !" : "Vous pouvez continuer sans image",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Récapitulatif final
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
              border: Border.all(color: isDarkMode ? Colors.green.shade800 : Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.green.shade900.withValues(alpha: 0.5) : Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 16, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Prêt pour la publication !",
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.green.shade100 : Colors.green.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous avez terminé la configuration de votre événement. Cliquez sur "Publier l\'événement" pour le rendre visible aux participants.',
                  style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.green.shade300 : Colors.green.shade800),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text("Infos générales", style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.green.shade200 : Colors.green.shade700)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text("Description ajoutée", style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.green.shade200 : Colors.green.shade700)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCompleted ? "Image ajoutée" : "Sans image",
                          style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.green.shade200 : Colors.green.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}