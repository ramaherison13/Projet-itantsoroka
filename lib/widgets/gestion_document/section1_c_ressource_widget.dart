import 'package:flutter/material.dart';

class Section1CRessourceWidget extends StatelessWidget {
  final VoidCallback? onConsultPressed;

  const Section1CRessourceWidget({
    super.key,
    this.onConsultPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth >= 1024; // Équivalent de lg (1024px)

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: screenWidth >= 768 ? 48.0 : 20.0, // md:py-12 lg:py-5
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? Colors.grey.shade900 : Colors.white,
            isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre principal (équivalent de text-4xl sm:text-5xl)
              Text(
                "Gestion et Consultation des Documents", // Remplacez par votre clé de traduction si besoin
                style: TextStyle(
                  fontSize: screenWidth >= 640 ? 48.0 : 36.0,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey.shade100 : Colors.black,
                ),
              ),
              const SizedBox(height: 24), // mt-6

              // Ligne décorative verte (#008713)
              Container(
                width: 140.0, // w-35 (35 * 4px)
                height: 8.0,  // h-2
                color: const Color(0xFF008713),
              ),
              const SizedBox(height: 32), // mb-8

              // Premier paragraphe
              Text(
                "Accédez facilement à tous les documents administratifs et ressources nécessaires.",
                style: TextStyle(
                  fontSize: screenWidth >= 768 ? 24.0 : 18.0, // md:text-2xl / text-1xl
                  color: isDarkMode ? Colors.grey.shade100 : Colors.black,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40), // mb-10

              // Deuxième paragraphe descriptif
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(
                  "Cette section s'adresse aux utilisateurs souhaitant consulter, rechercher et télécharger des documents officiels en toute simplicité.",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32), // mb-8

              // Bouton Consulter
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C21C), Color(0xFF098E00)],
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onConsultPressed ?? () {},
                    icon: const Icon(Icons.list_alt, size: 20, color: Colors.white),
                    label: const Text(
                      "Consulter les documents",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Espace pour l'image sur grand écran si elle est en position absolue
              if (isLargeScreen) const SizedBox(height: 180),
            ],
          ),

          // Image pour grand écran (Positionnée à droite de manière similaire au code React)
          if (isLargeScreen)
            Positioned(
              right: 0,
              top: 60,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(360),
                  bottomLeft: Radius.circular(10),
                ),
                child: Image.asset(
                  'assets/images/centreRessource/ville.jpg',
                  width: 600, // w-150 (150 * 4px)
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Image pour petit/moyen écran (Affichée en dessous)
          if (!isLargeScreen) ...[
            const SizedBox(height: 32),
            Center(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(360),
                  bottomLeft: Radius.circular(10),
                ),
                child: Image.asset(
                  'assets/images/centreRessource/ville.jpg',
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}