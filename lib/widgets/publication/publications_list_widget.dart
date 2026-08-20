import 'package:flutter/material.dart';

// Modèles de données correspondants
class EventModel {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String visibility;
  final String themeId;
  final String communeId;
  final String eventTypeId;
  final String? image;
  final String type = 'event';

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.visibility,
    required this.themeId,
    required this.communeId,
    required this.eventTypeId,
    this.image,
  });
}

class ProjectModel {
  final String id;
  final dynamic name; // Peut être String ou Map selon l'API
  final dynamic description;
  final dynamic status;
  final String startDate;
  final String endDate;
  final String deadline;
  final double budget;
  final List<String> partenaire;
  final List<String> files;
  final String themeName;
  final String communeId;
  final String type = 'project';

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.deadline,
    required this.budget,
    required this.partenaire,
    required this.files,
    required this.themeName,
    required this.communeId,
  });
}

class PublicationsListWidget extends StatelessWidget {
  final List<dynamic> filteredPublications; // Accepte EventModel ou ProjectModel
  final Function(String id, String type) onEdit;
  final Function(String id, String type) onDelete;
  final VoidCallback onAddPublication;
  final String Function(String dateString) formatDate;
  final String Function(double amount) formatBudget;
  final Color Function(String status) getStatusColor;
  final String Function(String status) getStatusLabel;

  const PublicationsListWidget({
    super.key,
    required this.filteredPublications,
    required this.onEdit,
    required this.onDelete,
    required this.onAddPublication,
    required this.formatDate,
    required this.formatBudget,
    required this.getStatusColor,
    required this.getStatusLabel,
  });

  String _getText(dynamic field) {
    if (field == null) return '';
    if (field is Map) {
      return field['fr']?.toString() ?? field.values.first?.toString() ?? '';
    }
    return field.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final eventCount = filteredPublications.where((p) => p.type == 'event').length;
    final projectCount = filteredPublications.where((p) => p.type == 'project').length;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Publications (${filteredPublications.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (filteredPublications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$eventCount événements • $projectCount projets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          filteredPublications.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 48, color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune publication trouvée',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Essayez de modifier vos critères de recherche ou ajoutez une nouvelle publication !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: onAddPublication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Ajouter une publication', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1, // Ajustable selon les breakpoints si besoin (ex: Grid responsive)
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: filteredPublications.length,
                    itemBuilder: (context, index) {
                      final publication = filteredPublications[index];
                      final isEvent = publication.type == 'event';

                      return Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header de la carte
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isEvent
                                                ? [Colors.blue.shade500, Colors.blue.shade600]
                                                : [Colors.green.shade500, Colors.green.shade600],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isEvent ? Icons.calendar_today : Icons.folder_open,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isEvent
                                                ? [Colors.blue.shade500, Colors.blue.shade600]
                                                : [Colors.green.shade500, Colors.green.shade600],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isEvent ? 'ÉVÉNEMENT' : 'PROJET',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16),
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                        onPressed: () => onEdit(publication.id, publication.type),
                                        tooltip: 'Modifier',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 16),
                                        color: isDarkMode ? Colors.red.shade400 : Colors.red.shade600,
                                        onPressed: () => onDelete(publication.id, publication.type),
                                        tooltip: 'Supprimer',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Contenu de la carte
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEvent ? publication.title : _getText(publication.name),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getText(publication.description),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Métadonnées bas de carte
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          isEvent ? publication.communeId : publication.communeId,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}