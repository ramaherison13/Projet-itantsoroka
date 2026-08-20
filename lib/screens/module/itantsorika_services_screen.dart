import 'package:flutter/material.dart';
import 'service_card.dart';

class ItantsorikaServicesWidget extends StatelessWidget {
  final Function(String) onNavigate;

  const ItantsorikaServicesWidget({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "I-TANTSOROKA",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Services et Outils I-Tantsoroka",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Accédez aux outils d'accompagnement, de publication et d'appui aux projets de développement.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 40),
                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.5,
                        children: [
                          ServiceCard(
                            icon: const Icon(Icons.handshake),
                            title: "Offres d'appui",
                            description: "Consultez et postulez aux offres d'appui pour les projets.",
                            onClick: () => onNavigate("/itantsorika/offres-appui"),
                          ),
                          ServiceCard(
                            icon: const Icon(Icons.publish),
                            title: "Publier",
                            description: "Publiez de nouveaux projets, événements ou actualités.",
                            onClick: () => onNavigate("/itantsorika/publier"),
                          ),
                          ServiceCard(
                            icon: const Icon(Icons.folder),
                            title: "Gérer les publications",
                            description: "Consultez, modifiez ou supprimez vos publications.",
                            onClick: () => onNavigate("/itantsorika/gererPublication"),
                          ),
                          ServiceCard(
                            icon: const Icon(Icons.map),
                            title: "Monographie",
                            description: "Consultez les informations monographiques des territoires.",
                            onClick: () => onNavigate("/itantsorika/monographie"),
                          ),
                          ServiceCard(
                            icon: const Icon(Icons.video_call),
                            title: "Réunion",
                            description: "Accédez aux réunions et échanges en ligne.",
                            onClick: () => onNavigate("/itantsorika/reunion"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: ElevatedButton.icon(
                onPressed: () => onNavigate("/admin"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  foregroundColor: isDarkMode ? Colors.white : Colors.grey.shade700,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text("Retour à l'accueil", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}