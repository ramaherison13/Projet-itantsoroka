import 'package:flutter/material.dart';
import 'service_card.dart';

class AdministrationServicesWidget extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Function(String) onNavigate;

  const AdministrationServicesWidget({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  void _handleControleLegaliteClick() {
    bool isCTDOnly = false;
    if (user != null && user!['roles'] is List) {
      List roles = user!['roles'];
      bool hasCTD = roles.any((role) => role['role_slug'] == 'CTD');
      bool hasOtherPrivilegedRole = roles.any((role) =>
          ['Chef-District', 'Admin-District', 'Ministre', 'Super-Admin', 'service-habilité']
              .contains(role['role_slug']));
      isCTDOnly = hasCTD && !hasOtherPrivilegedRole;
    }

    if (isCTDOnly) {
      onNavigate("/idistrika/commune-controle-legalite");
    } else {
      onNavigate("/idistrika/admin-controle-legalite");
    }
  }

  bool _checkRoleAccess(List<String> allowedRoles) {
    if (user == null || user!['roles'] is! List) return false;
    List roles = user!['roles'];
    return roles.any((role) => allowedRoles.contains(role['role_slug']));
  }

  @override
  Widget build(BuildContext context) {
    final allowedRoles = ["Chef-District", "Admin-District", "Ministre", "Super-Admin"];
    final allowedRoles2 = ["Chef-District", "Admin-District", "Ministre", "Super-Admin", "service-habilité", "CTD"];

    final bool canAccessTpg = _checkRoleAccess(allowedRoles);
    final bool canAccessTpg2 = _checkRoleAccess(allowedRoles2);
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
                        "I-DISTRIKA",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Services de l'Administration Territoriale I-District",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Un accès centralisé aux outils de suivi, de contrôle et d'accompagnement des collectivités locales.",
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
                          if (canAccessTpg)
                            ServiceCard(
                              icon: const Icon(Icons.local_shipping),
                              title: "Tournée des Polices Générales",
                              description: "Suivez les visites de terrain et veillez au respect des règles locales.",
                              onClick: () => onNavigate("/idistrika/calendrier"),
                            ),
                          if (canAccessTpg2)
                            ServiceCard(
                              icon: const Icon(Icons.balance),
                              title: "Contrôle de Légalité",
                              description: "Assurez la conformité des décisions communales aux lois.",
                              onClick: _handleControleLegaliteClick,
                            ),
                          ServiceCard(
                            icon: const Icon(Icons.video_call),
                            title: "Réunion périodique",
                            description: "Centralisez les infos du terrain pour mieux planifier.",
                            onClick: () => onNavigate("/idistrika/reunion"),
                          ),
                          ServiceCard(
                            icon: const Icon(Icons.mail),
                            title: "Doléances",
                            description: "Consultez la liste et le suivi des doléances.",
                            onClick: () => onNavigate("/idistrika/doleance"),
                          ),
                          ServiceCard(
                            icon: const Icon(Icons.book),
                            title: "Guide",
                            description: "Consultez ressources et directives pour accompagner les communes.",
                            onClick: () => {},
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