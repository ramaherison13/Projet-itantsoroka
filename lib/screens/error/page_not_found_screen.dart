import 'package:flutter/material.dart';

class PageNotFoundWidget extends StatefulWidget {
  final Function(String) onNavigate;
  final Function(int) onGoBack;
  final Function(String, String, int, {String? label, VoidCallback? onClick}) showAlert;

  const PageNotFoundWidget({
    super.key,
    required this.onNavigate,
    required this.onGoBack,
    required this.showAlert,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PageNotFoundWidgetState createState() => _PageNotFoundWidgetState();
}

class _PageNotFoundWidgetState extends State<PageNotFoundWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.showAlert(
        "Vous êtes hors ligne. Votre connexion réseau est instable.",
        "warning",
        200000,
        label: "Recharger la page",
        onClick: () {
          // Action de rechargement si nécessaire
        },
      );
      widget.onGoBack(-1);
    });
  }

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
                    // Icône d'erreur 404
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.orange],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.search, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    // Code et titre
                    const Text(
                      "404",
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      "Page introuvable",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Désolé, la page que vous recherchez n'existe pas ou a été déplacée.",
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
                          onPressed: () => widget.onGoBack(-1),
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
                          onPressed: () => widget.onNavigate("/"),
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