import 'package:flutter/material.dart';

class UnauthorizedPageWidget extends StatelessWidget {
  final Function(String) onNavigate;
  final Function(int) onGoBack;

  const UnauthorizedPageWidget({
    super.key,
    required this.onNavigate,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône de sécurité 401
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.red],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.security, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    // Code et titre
                    const Text(
                      "401",
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    Text(
                      "Accès non autorisé",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Vous n'avez pas les permissions nécessaires pour accéder à cette ressource. Veuillez vous connecter avec un compte autorisé.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Boutons d'action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => onGoBack(-1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          label: const Text("Retour", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => onNavigate("/"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.home, size: 20),
                          label: const Text("Accueil", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Section Info / Avertissement
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.amber.withValues(alpha: 0.2) : Colors.amber.shade200,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.amber, Colors.red]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.security, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Informations sur l'accès",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Pour accéder à cette section, vous devez disposer des privilèges appropriés. Si vous pensez que c'est une erreur, contactez votre administrateur système.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
            ),
          ),
        ),
      ),
    );
  }
}