import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';

// Modèle Citizen - correspond aux champs retournés par servicecitoyen
class Citizen {
  final String idCitizen;
  final String citizenName;
  final String citizenLastname;

  Citizen({
    required this.idCitizen,
    required this.citizenName,
    required this.citizenLastname,
  });

  factory Citizen.fromJson(Map<String, dynamic> json) {
    // L'API peut retourner la donnée directement ou imbriquée dans 'data' ou 'citizen'
    final Map<String, dynamic> d = json['data'] is Map ? json['data'] : json['citizen'] is Map ? json['citizen'] : json;
    return Citizen(
      idCitizen: d['id_citizen']?.toString() ?? d['id']?.toString() ?? '',
      citizenName: d['citizen_name'] ?? d['name'] ?? '',
      citizenLastname: d['citizen_lastname'] ?? d['lastname'] ?? '',
    );
  }
}

// Service réel pour récupérer le citoyen par CIN avec timeout court et gestion d'erreur
Future<Citizen?> getCitizenByIdCard(String cin) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConstants.serviceCitoyen}/citizens/$cin'),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) return null;
      return Citizen.fromJson(data is Map<String, dynamic> ? data : {});
    }
    return null;
  } catch (e) {
    return null;
  }
}

class CheckIDCardScreen extends StatefulWidget {
  const CheckIDCardScreen({super.key});

  @override
  State<CheckIDCardScreen> createState() => _CheckIDCardScreenState();
}

class _CheckIDCardScreenState extends State<CheckIDCardScreen> {
  final TextEditingController _cinController = TextEditingController();
  Citizen? citizen;
  bool loading = false;
  String step = "initial"; // "initial", "not-found", "found"

  bool get isCinValid => _cinController.text.length == 12;

  void _handleChange(String value) {
    if (RegExp(r'^\d*$').hasMatch(value) && value.length <= 12) {
      setState(() {
        _cinController.text = value;
        _cinController.selection = TextSelection.fromPosition(
          TextPosition(offset: value.length),
        );
      });
    }
  }

  void _handleBackClick() {
    context.go('/auth/login');
  }

  Future<void> _handleSubmit() async {
    if (!isCinValid) return;

    if (!mounted) return;
    setState(() {
      loading = true;
    });

    try {
      final data = await getCitizenByIdCard(_cinController.text.trim());

      if (!mounted) return;
      setState(() {
        if (data != null) {
          citizen = data;
          step = "found";
        } else {
          citizen = null;
          step = "not-found";
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          citizen = null;
          step = "not-found";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) {
      final Map<String, String> translations = {
        "creer_votre_compte": "Créer votre compte",
        "dd": "Digital",
        "enregistre_vous": "Enregistrez-vous dès maintenant",
        "verific_ident": "Vérification d'identité",
        "veuil_saisi_num": "Veuillez saisir votre numéro de CIN",
        "pour_com_insc": "Pour commencer votre inscription, veuillez renseigner votre numéro de carte d'identité.",
        "num_carte_ident": "Numéro de carte d'identité",
        "num_contenir_12chiffr": "Le numéro doit contenir 12 chiffres",
        "Retour": "Retour",
        "continue": "Continuer",
        "CIN_nontrouve": "CIN non trouvé",
        "votre_num_pas_trouve": "Votre numéro n'a pas été trouvé",
        "num_cin_nontrouve_systeme": "Ce numéro de CIN n'est pas répertorié dans le système.",
        "vous_pouvez_acce_inscr_comp": "Vous pouvez accéder à l'inscription complète directement.",
        "proced_inscr_complet": "Procéder à l'inscription complète",
        "ressayer_autre_num": "Réessayer un autre numéro",
        "bienvenue": "Bienvenue",
        "inform_retrouve": "Informations retrouvées avec succès.",
        "continuer_inscri": "Continuer l'inscription",
      };
      return translations[key] ?? key;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 960),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 768;

                  Widget rightPaneContent = Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 36.0 : 20.0, vertical: isWide ? 40.0 : 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isWide) ...[
                          Center(
                            child: Image.asset(
                              "assets/images/logo_dd_v3.png",
                              width: 160,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (c, e, s) => Image.asset(
                                "assets/images/logo_dd.png",
                                width: 160,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Indicateur d'étapes (1 - 2)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "1",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              color: step == "initial" ? Colors.grey.shade300 : const Color(0xFF16A34A),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: step != "initial" ? const Color(0xFF16A34A) : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "2",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: step != "initial" ? Colors.white : Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Étape 1 : Saisie CIN
                        if (step == "initial") ...[
                          const Text(
                            "Vérification d'identité",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Veuillez saisir votre numéro de carte d'identité nationale",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Pour commencer l'inscription, nous devons vérifier si vous êtes déjà enregistré dans notre système.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 28),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: isCinValid
                                    ? const Color(0xFF16A34A)
                                    : (_cinController.text.isNotEmpty ? Colors.red.shade400 : Colors.grey.shade300),
                                width: isCinValid ? 2 : 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                if (isCinValid)
                                  BoxShadow(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                    blurRadius: 8,
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF87171),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.badge_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _cinController,
                                    onChanged: _handleChange,
                                    keyboardType: TextInputType.number,
                                    maxLength: 12,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                                    decoration: InputDecoration(
                                      hintText: "Numéro de carte d'identité nationale",
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                      border: InputBorder.none,
                                      counterText: "",
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCinValid && _cinController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                t("num_contenir_12chiffr"),
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 28),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1F2937),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    elevation: 0,
                                  ),
                                  onPressed: _handleBackClick,
                                  icon: const Icon(Icons.arrow_back, size: 18),
                                  label: const Text("Retour", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      if (isCinValid)
                                        BoxShadow(
                                          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      disabledBackgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      elevation: 0,
                                    ),
                                    onPressed: (loading || !isCinValid) ? null : _handleSubmit,
                                    child: loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Text("Continuer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              SizedBox(width: 6),
                                              Icon(Icons.arrow_forward, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ]

                        // Étape 2 : CIN non trouvé
                        else if (step == "not-found") ...[
                          const Text(
                            "CIN non trouvé",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Votre numéro n'a pas été trouvé dans notre système",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEFCE8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE047)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text(
                                  "Numéro de carte d'identité non trouvé dans notre système.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF854D0E), fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Vous pouvez procéder à une inscription complète ou essayer avec un autre numéro.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFFA16207)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                context.go(
                                  '/auth/register',
                                  extra: _cinController.text.trim(),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text("Procéder à l'inscription complète", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Color(0xFF374151), width: 1.5),
                              foregroundColor: const Color(0xFF374151),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () {
                              setState(() {
                                step = "initial";
                                _cinController.clear();
                              });
                            },
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text("Réessayer avec un autre numéro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ]

                        // Étape 3 : CIN trouvé
                        else if (step == "found" && citizen != null) ...[
                          Text(
                            "Bienvenue, ${citizen!.citizenName} ${citizen!.citizenLastname}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t("inform_retrouve"),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                context.go(
                                  '/auth/register-with-citizen',
                                  extra: citizen!.idCitizen,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(t("continuer_inscri"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );

                  if (!isWide) {
                    return rightPaneContent;
                  }

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 460),
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF7EE),
                              border: Border(right: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Créez votre compte",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Dispositif District",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Enregistrez-vous pour accéder à votre espace personnel",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 36),
                                Image.asset(
                                  'assets/images/logo_dd_v3.png',
                                  width: 220,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (c, e, s) => Image.asset(
                                    'assets/images/logo_dd.png',
                                    width: 220,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: rightPaneContent,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}