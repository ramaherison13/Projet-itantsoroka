import 'package:flutter/material.dart';

class ItantsorakaDashboardScreen extends StatelessWidget {
  const ItantsorakaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        "title": "Monographie",
        "description": "Données territoriales, districts et communes",
        "icon": Icons.menu_book,
        "color": Colors.blue,
        "onTap": () {
          // Navigation vers l'écran de monographie que nous avons converti
        },
      },
      {
        "title": "Offre d'appui",
        "description": "Projets, ressources et expertises STD",
        "icon": Icons.handshake,
        "color": Colors.green,
        "onTap": () {
          // Navigation vers l'offre d'appui
        },
      },
      {
        "title": "Gestion de document",
        "description": "Fichiers, rapports et documents officiels",
        "icon": Icons.folder_shared,
        "color": Colors.orange,
        "onTap": () {
          // Navigation vers la gestion des documents
        },
      },
      {
        "title": "Publication",
        "description": "Actualités, articles et annonces",
        "icon": Icons.campaign,
        "color": Colors.purple,
        "onTap": () {
          // Navigation vers les publications/actualités
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("I-TANTSOROKA"),
        backgroundColor: const Color(0xFF098E00),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tableau de bord",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sélectionnez un service pour continuer",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 colonnes
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: service['onTap'],
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: service['color'].withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                service['icon'],
                                color: service['color'],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              service['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
