import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PublishPagePrincipalScreen extends StatelessWidget {
  const PublishPagePrincipalScreen({super.key});

  void _navigateToProject(BuildContext context) {
    context.go('/itantsorika/publier/projet');
  }

  void _navigateToEvent(BuildContext context) {
    context.go('/itantsorika/publier/evenement');
  }

  void _navigateToNews(BuildContext context) {
    context.go('/itantsorika/publier/actualite');
  }

  void _navigateBackToManage(BuildContext context) {
    context.go('/itantsorika/gererPublication');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            ElevatedButton.icon(
              onPressed: () => _navigateBackToManage(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text("Retour"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                foregroundColor: isDarkMode ? Colors.white : Colors.grey.shade800,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(height: 32),

            // Header Section
            Center(
              child: Column(
                children: [
                  Text(
                    "Publier du contenu",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.white : const Color(0xFF131313),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Text(
                      "Choisissez le type de contenu que vous souhaitez publier pour informer la communauté.",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF5D5D5D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Publishing Options Grid
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildProjectCard(context, isDarkMode)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildEventCard(context, isDarkMode)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildNewsCard(context, isDarkMode)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildProjectCard(context, isDarkMode),
                      const SizedBox(height: 24),
                      _buildEventCard(context, isDarkMode),
                      const SizedBox(height: 24),
                      _buildNewsCard(context, isDarkMode),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 48),

            // Additional Info Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [Colors.grey.shade800, Colors.grey.shade700]
                      : [const Color(0xFF098E00).withValues(alpha: 0.1), const Color(0xFF00C21C).withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade600 : const Color(0xFF098E00).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue.shade400 : const Color(0xFF098E00),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Besoin d'aide ?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDarkMode ? Colors.blue.shade400 : const Color(0xFF098E00),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Cette section s'adresse aux Communes, Collectivités Territoriales Décentralisées (CTD) et autres acteurs publics souhaitant accéder rapidement à des ressources fiables et actualisées.",
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF131313),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, bool isDarkMode) {
    return InkWell(
      onTap: () => _navigateToProject(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade600 : const Color(0xFF5D5D5D).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF098E00),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_open, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              "Publier un projet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : const Color(0xFF131313),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Partagez l'initiation de nouveaux projets communaux et suivez leur avancement.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF5D5D5D),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: const [
                Text(
                  "Créer un projet",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF098E00),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18, color: Color(0xFF098E00)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, bool isDarkMode) {
    return InkWell(
      onTap: () => _navigateToEvent(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade600 : const Color(0xFF5D5D5D).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF442EDF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.calendar_today, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              "Publier un événement",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : const Color(0xFF131313),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Organisez et annoncez vos événements publics pour mobiliser la communauté.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF5D5D5D),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: const [
                Text(
                  "Créer un événement",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF442EDF),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18, color: Color(0xFF442EDF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, bool isDarkMode) {
    return InkWell(
      onTap: () => _navigateToNews(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade600 : const Color(0xFF5D5D5D).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE98C21),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.newspaper, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              "Publier une actualité",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : const Color(0xFF131313),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Partagez les dernières nouvelles et informations importantes. Tenez la communauté informée.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF5D5D5D),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: const [
                Text(
                  "Créer une actualité",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE98C21),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18, color: Color(0xFFE98C21)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}