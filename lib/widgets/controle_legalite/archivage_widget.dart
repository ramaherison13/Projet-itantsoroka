import 'package:flutter/material.dart';

class ArchivageWidget extends StatefulWidget {
  const ArchivageWidget({super.key});

  @override
  State<ArchivageWidget> createState() => _ArchivageWidgetState();
}

class _ArchivageWidgetState extends State<ArchivageWidget> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _data = List.generate(
    6,
    (index) => {
      'id': index + 1,
      'title': 'Arrêté communal n°2025-14',
      'commune': 'Commune Andranomena',
      'date': '09/09/2025',
      'type': 'Arrêté',
      'service': 'Service Habilité',
      'status': 'Validé & Archivé',
      'pieces': 3,
    },
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Barre supérieure (Navbar de filtre)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recherche
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un acte',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtres
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Type d’acte'),
                      _buildFilterChip('Commune'),
                      _buildFilterChip('Date de validation'),
                      _buildFilterChip('Service validateur'),
                    ],
                  ),
                ],
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de section
                  const Text(
                    'Archivage et recherche des actes validés',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 120,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE98C21),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Consultez les actes communaux validés et archivés. Filtrez par commune, période ou type d’acte pour retrouver facilement les documents officiels.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Grille des cartes
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth >= 1024) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth >= 640) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: _data.length,
                        itemBuilder: (context, index) {
                          final item = _data[index];
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.description, size: 18, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['title'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDarkMode ? Colors.white : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.business, item['commune'], isDarkMode),
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.calendar_today, item['date'], isDarkMode),
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.layers, item['type'], isDarkMode),
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.description_outlined, item['service'], isDarkMode),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['status'],
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item['pieces']} pièces jointes',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Consulter', style: TextStyle(fontSize: 13)),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.download, size: 14),
                                      label: const Text('Télécharger PDF', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade100,
                                        foregroundColor: Colors.grey.shade700,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        const Text('▾', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}