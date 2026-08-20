import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class PlatformModuleWidget extends StatefulWidget {
  final String apiUrl;
  final Function(String) onNavigate;
  final Function() onBack;

  const PlatformModuleWidget({
    super.key,
    required this.apiUrl,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  PlatformModuleWidgetState createState() => PlatformModuleWidgetState();
}

class PlatformModuleWidgetState extends State<PlatformModuleWidget> {
  String ihofanaUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchIhofanaUrl();
  }

  Future<void> _fetchIhofanaUrl() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiUrl}/serviceauth/application/slug/ihofana'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['app_url'] != null) {
          setState(() {
            ihofanaUrl = data['app_url'];
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération de l'URL I-HOFANA: $e");
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      {
        "title": "I-DISTRIKA",
        "description": "Tournée de police générale, Réunion périodique, Contrôle de légalité",
        "image": "assets/images/modules/district1.jpeg",
        "onclick": () => widget.onNavigate("/admin")
      },
      {
        "title": "I-TANTSOROKA",
        "description": "Planification de projets et Gestion des Ressources",
        "image": "assets/images/modules/commune.jpeg",
        "onclick": () => widget.onNavigate("/itantsorika-services")
      },
      {
        "title": "I-HOFANA",
        "description": "Plateforme Numérique pour Renforcer les Communes Malgaches",
        "image": "assets/images/modules/ihofana.jpg",
        "onclick": () {
          if (ihofanaUrl.isNotEmpty) {
            _launchExternalUrl(ihofanaUrl);
          }
        }
      },
    ];

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Logo Placeholder
                      const Text(
                        "LOGO",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Choisissez le module que vous voulez visiter",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Explorez les différents modules disponibles",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 900;
                          return Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: cards.map((c) {
                              return Expanded(
                                flex: isWide ? 1 : 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: InkWell(
                                    onTap: c["onclick"] as void Function(),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: Image.asset(
                                              c["image"] as String,
                                              height: 180,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  c["title"] as String,
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  c["description"] as String,
                                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bouton retour en haut à gauche (Positionné EN DERNIER pour être au-dessus et cliquable)
            Positioned(
              top: 12,
              left: 12,
              child: ElevatedButton.icon(
                onPressed: () => widget.onBack(),
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