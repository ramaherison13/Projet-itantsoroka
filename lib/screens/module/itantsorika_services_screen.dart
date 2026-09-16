import 'package:flutter/material.dart';
import 'service_card.dart';

class ItantsorikaServicesWidget extends StatelessWidget {
  final Function(String) onNavigate;

  const ItantsorikaServicesWidget({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 650;
    final bool isTablet = screenWidth >= 650 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête / Barre supérieure avec bouton Retour ───────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1C2541) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onNavigate("/admin"),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF3A506B) : const Color(0xFFF1F5F9),
                      foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF5BC0BE) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 18,
                        vertical: isMobile ? 10 : 14,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      isMobile ? "Retour" : "Retour à l'accueil",
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  // Badge I-Tantsoroka
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.widgets_rounded, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          "I-TANTSOROKA",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenu principal scrollable ─────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : (isTablet ? 32 : 48),
                  vertical: isMobile ? 28 : 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      children: [
                        // ── Titre Principal : Services I-TANTSOROKA ──────────────
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: isMobile ? 26 : (isTablet ? 32 : 36),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              fontFamily: 'Roboto',
                            ),
                            children: [
                              TextSpan(
                                text: "Services ",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const TextSpan(
                                text: "I-TANTSOROKA",
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Sous-titre ───────────────────────────────────────
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Text(
                            "Optimisez la planification des projets et la gestion des ressources locales.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              height: 1.5,
                              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 28 : 48),

                        // ── Grille des 4 Cartes (Publication, Documents, Monographie, Offre d'appui) ──
                        GridView.count(
                          crossAxisCount: isMobile ? 1 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: isMobile ? 16 : 24,
                          mainAxisSpacing: isMobile ? 16 : 24,
                          childAspectRatio: isMobile ? 1.45 : (isTablet ? 1.25 : 1.35),
                          children: [
                            ServiceCard(
                              icon: const Icon(Icons.send_rounded),
                              title: "Publication",
                              description: "Diffusez vos rapports et résultats en toute transparence pour informer et mobiliser.",
                              onClick: () => onNavigate("/itantsorika/gererPublication"),
                            ),
                            ServiceCard(
                              icon: const Icon(Icons.folder_shared_outlined),
                              title: "Gestion des documents",
                              description: "Organisez, stockez et accédez facilement à tous vos documents importants en un seul endroit.",
                              onClick: () => onNavigate("/itantsorika/documents"),
                            ),
                            ServiceCard(
                              icon: const Icon(Icons.map_outlined),
                              title: "Monographie",
                              description: "Explorez les données clés des communes et districts pour mieux comprendre leur réalité.",
                              onClick: () => onNavigate("/itantsorika/monographie"),
                            ),
                            ServiceCard(
                              icon: const Icon(Icons.handshake_outlined),
                              title: "Offre d'appui",
                              description: "Accédez à un accompagnement pratique et à des outils pour renforcer vos actions locales.",
                              onClick: () => onNavigate("/itantsorika/offres-appui"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}