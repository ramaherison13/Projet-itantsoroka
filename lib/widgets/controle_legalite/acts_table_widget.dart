import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActsTableWidget extends StatelessWidget {
  final List<dynamic> acts;
  final bool loading;
  final ValueChanged<String> onViewDetails;
  final ValueChanged<String> onOpenObservations;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;
  final ValueChanged<String> onDelete;
  final List<dynamic>? typesActes;

  const ActsTableWidget({
    super.key,
    required this.acts,
    required this.loading,
    required this.onViewDetails,
    required this.onOpenObservations,
    required this.onAccept,
    required this.onReject,
    required this.onDelete,
    this.typesActes,
  });

  String _mapStatutToStatus(String statut) {
    switch (statut) {
      case 'en_cours':
        return 'pending';
      case 'accepte':
        return 'accepted';
      case 'rejete':
        return 'rejected';
      case 'observation':
        return 'observation';
      default:
        return 'pending';
    }
  }

  Widget _buildStatusBadge(String status, bool isDarkMode) {
    Color bg;
    Color textColor;
    Color borderColor;
    String label;

    switch (status) {
      case 'accepted':
        bg = isDarkMode ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50;
        textColor = isDarkMode ? Colors.green.shade400 : Colors.green.shade700;
        borderColor = isDarkMode ? Colors.green.shade800 : Colors.green.shade200;
        label = 'Accepté';
        break;
      case 'rejected':
        bg = isDarkMode ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50;
        textColor = isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
        borderColor = isDarkMode ? Colors.red.shade800 : Colors.red.shade200;
        label = 'Rejeté';
        break;
      case 'observation':
        bg = isDarkMode ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50;
        textColor = isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700;
        borderColor = isDarkMode ? Colors.orange.shade800 : Colors.orange.shade200;
        label = 'Observation';
        break;
      case 'pending':
      default:
        bg = isDarkMode ? Colors.yellow.shade900.withValues(alpha: 0.3) : Colors.yellow.shade50;
        textColor = isDarkMode ? Colors.yellow.shade400 : Colors.yellow.shade700;
        borderColor = isDarkMode ? Colors.yellow.shade800 : Colors.yellow.shade200;
        label = 'En attente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Chargement des actes...', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    isDarkMode ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.grey.shade50,
                  ),
                  columns: const [
                    DataColumn(label: Text('Identifiant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Commune', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Type d\'acte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Titre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Observations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: acts.isEmpty
                      ? [
                          DataRow(
                            cells: List.generate(
                              8,
                              (index) => DataCell(
                                index == 0
                                    ? const SizedBox(
                                        width: 600,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.description, size: 40, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text('Aucun acte trouvé pour ces critères', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ]
                      : acts.map((act) {
                          final id = act['id']?.toString() ?? '';
                          final commune = act['commune_name'] ?? act['commune_id'] ?? '';
                          final titre = act['titre'] ?? '';
                          final dateCreation = act['date_creation'] ?? '';
                          final statut = act['statut'] ?? '';

                          // Résolution du type d'acte
                          List<dynamic>? typeNames = act['type_names'];
                          List<dynamic>? typeIds = act['type_ids'];
                          List<String> names = [];
                          if (typeNames != null && typeNames.isNotEmpty) {
                            names = typeNames.map((e) => e.toString()).toList();
                          } else if (typeIds != null && typeIds.isNotEmpty && typesActes != null) {
                            for (var tId in typeIds) {
                              final found = typesActes!.firstWhere((t) => t['id'] == tId, orElse: () => null);
                              if (found != null && found['nom'] != null) {
                                names.add(found['nom'].toString());
                              }
                            }
                          }
                          final typeStr = names.isNotEmpty ? names.join(', ') : 'N/A';

                          return DataRow(
                            cells: [
                              DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(commune)),
                              DataCell(Text(typeStr)),
                              DataCell(Text(titre, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(_formatDate(dateCreation))),
                              DataCell(_buildStatusBadge(_mapStatutToStatus(statut), isDarkMode)),
                              DataCell(
                                TextButton.icon(
                                  onPressed: () => onOpenObservations(id),
                                  icon: const Icon(Icons.description, size: 16),
                                  label: const Text('Voir'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, size: 20),
                                      onPressed: () => onViewDetails(id),
                                      tooltip: 'Voir',
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.check, size: 18, color: Colors.white),
                                        onPressed: () => onAccept(id),
                                        tooltip: 'Valider',
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Colors.white),
                                        onPressed: () => onReject(id),
                                        tooltip: 'Rejeter',
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                                        onPressed: () => onDelete(id),
                                        tooltip: 'Supprimer',
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                ),
              ),
      ),
    );
  }
}