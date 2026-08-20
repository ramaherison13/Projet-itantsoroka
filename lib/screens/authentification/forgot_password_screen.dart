import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';

// Modèles de données
class CitizenData {
  final String idCitizen;
  final String citizenName;
  final String citizenLastname;
  final int citizenNationalCardNumber;
  final String? citizenPhoto;

  CitizenData({
    required this.idCitizen,
    required this.citizenName,
    required this.citizenLastname,
    required this.citizenNationalCardNumber,
    this.citizenPhoto,
  });

  factory CitizenData.fromJson(Map<String, dynamic> json) {
    return CitizenData(
      idCitizen: json['id_citizen']?.toString() ?? '',
      citizenName: json['citizen_name'] ?? '',
      citizenLastname: json['citizen_lastname'] ?? '',
      citizenNationalCardNumber: json['citizen_national_card_number'] ?? 0,
      citizenPhoto: json['citizen_photo'],
    );
  }
}

class UserData {
  final String userId;
  final String userPseudo;
  final String userEmail;
  final String userKeycloakId;
  final CitizenData citizen;

  UserData({
    required this.userId,
    required this.userPseudo,
    required this.userEmail,
    required this.userKeycloakId,
    required this.citizen,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id']?.toString() ?? '',
      userPseudo: json['user_pseudo'] ?? '',
      userEmail: json['user_email'] ?? '',
      userKeycloakId: json['user_keycloak_id']?.toString() ?? '',
      citizen: CitizenData.fromJson(json['citizen'] ?? {}),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int step = 1; // 1: CIN, 2: Confirmation, 3: Succès
  final TextEditingController _nationalCardController = TextEditingController();
  UserData? userData;
  bool loading = false;

  final String apiUrl = ApiConstants.gatewayBaseUrl;

  void _showAlert(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 4)),
    );
  }

  // Étape 1: Rechercher par CIN
  Future<void> handleSearchByCIN() async {
    final nationalCardId = _nationalCardController.text.trim();
    if (nationalCardId.isEmpty || nationalCardId.length != 12) {
      _showAlert("Veuillez saisir un numéro CIN valide à 12 chiffres.", Colors.red);
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final citizenResponse = await http.get(
        Uri.parse('$apiUrl/servicecitoyen/citizens/$nationalCardId'),
      );

      if (citizenResponse.statusCode != 200) {
        throw {'status': citizenResponse.statusCode};
      }

      final citizenDataJson = json.decode(citizenResponse.body);
      final citizen = CitizenData.fromJson(citizenDataJson);

      final userResponse = await http.get(
        Uri.parse('$apiUrl/serviceauth/users/user-citizen/${citizen.idCitizen}'),
      );

      if (userResponse.statusCode != 200) {
        throw {'status': userResponse.statusCode};
      }

      final userDataJson = json.decode(userResponse.body);
      final user = UserData.fromJson(userDataJson);

      setState(() {
        userData = user;
        step = 2;
      });

      _showAlert("Compte trouvé ! Vérifiez les informations avant de continuer.", Colors.green);
    } catch (error) {
      String message = "Une erreur est survenue. Veuillez vérifier votre numéro de CIN.";
      if (error is Map && error['status'] == 404) {
        message = "Aucun compte trouvé avec ce numéro de carte d'identité.";
      }
      _showAlert(message, Colors.red);
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // Étape 2: Envoyer le code de réinitialisation par email
  Future<void> handleSendResetLink() async {
    if (userData == null) return;

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/serviceauth/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_email': userData!.userEmail}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          step = 3;
        });
        _showAlert("Un code de réinitialisation a été envoyé à ${maskEmail(userData!.userEmail)}.", Colors.green);
      } else {
        final data = json.decode(response.body);
        _showAlert(data['message'] ?? "Une erreur est survenue lors de l'envoi du code.", Colors.red);
      }
    } catch (error) {
      _showAlert("Une erreur est survenue lors de l'envoi du code.", Colors.red);
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // Masquer partiellement l'email
  String maskEmail(String email) {
    final parts = email.split("@");
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 3) {
      return "${username[0]}***@$domain";
    }
    return "${username.substring(0, 3)}***@$domain";
  }

  void handleReset() {
    setState(() {
      step = 1;
      _nationalCardController.clear();
      userData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0FDF4), Colors.white, Color(0xFFF0FDF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 1024;
            return Row(
              children: [
                // Left Section - Branding (Visible sur grand écran)
                if (isWide)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF098e00), Color(0xFF076d00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const FlutterLogo(size: 100),
                                  ),
                                  const SizedBox(height: 32),
                                  const Text(
                                    "Réinitialisation",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Récupérez l'accès à votre compte en toute sécurité",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 48),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildPartnerLogo("assets/images/logo_ministere.jpg"),
                                      const SizedBox(width: 16),
                                      _buildPartnerLogo("assets/images/logo2.png"),
                                      const SizedBox(width: 16),
                                      _buildPartnerLogo("assets/images/logo_dd.png"),
                                      const SizedBox(width: 16),
                                      _buildPartnerLogo("assets/images/logo_pnud.png"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Right Section - Form Card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isWide) ...[
                              Column(
                                children: [
                                  const FlutterLogo(size: 60),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                       Image.asset("assets/images/logo_ministere.jpg", width: 32, height: 32, fit: BoxFit.contain, errorBuilder: (c,e,s) => const SizedBox.shrink()),
                                       const SizedBox(width: 6),
                                       Image.asset("assets/images/logo2.png", width: 24, height: 24, fit: BoxFit.contain, errorBuilder: (c,e,s) => const SizedBox.shrink()),
                                       const SizedBox(width: 6),
                                       Image.asset("assets/images/logo_dd.png", width: 60, height: 28, fit: BoxFit.contain, errorBuilder: (c,e,s) => const SizedBox.shrink()),
                                       const SizedBox(width: 6),
                                       Image.asset("assets/images/pnud_logo.png", width: 24, height: 24, fit: BoxFit.contain, errorBuilder: (c,e,s) => const SizedBox.shrink()),
                                     ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            // En-tête dynamique selon l'étape
                            Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      step == 3 ? Icons.check_circle_outline : Icons.mail_outline,
                                      size: 32,
                                      color: const Color(0xFF098E00),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  step == 3
                                      ? "Email envoyé !"
                                      : step == 1
                                      ? "Mot de passe oublié ?"
                                      : "Confirmation",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  step == 3
                                      ? "Consultez votre boîte email pour récupérer le code de réinitialisation."
                                      : step == 1
                                      ? "Entrez votre numéro de carte d'identité nationale pour retrouver votre compte."
                                      : "Vérifiez que ces informations vous correspondent avant de continuer.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Contenu conditionnel par étape
                            if (step == 1) ...[
                              TextField(
                                controller: _nationalCardController,
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                                decoration: InputDecoration(
                                  labelText: "Numéro CIN",
                                  hintText: "117121029160",
                                  prefixIcon: const Icon(Icons.badge_outlined, color: Colors.grey),
                                  counterText: "",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text("Entrez le numéro à 12 chiffres figurant sur votre carte d'identité", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF098E00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: loading ? null : handleSearchByCIN,
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text("Rechercher mon compte", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ] else if (step == 2) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        userData?.citizen.citizenPhoto != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(32),
                                                child: Image.network(userData!.citizen.citizenPhoto!, width: 64, height: 64, fit: BoxFit.cover),
                                              )
                                            : Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.person, size: 32, color: Color(0xFF098E00)),
                                              ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${userData?.citizen.citizenName} ${userData?.citizen.citizenLastname}",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                              ),
                                              const SizedBox(height: 4),
                                              Text("@${userData?.userPseudo}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("Email associé au compte :", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(userData?.userEmail ?? "", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: loading ? null : handleReset,
                                      child: const Text("Annuler", style: TextStyle(color: Colors.black87)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF098E00),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: loading ? null : handleSendResetLink,
                                      child: loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : const Text("Envoyer le code"),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  "Un code de réinitialisation a été envoyé à ${maskEmail(userData?.userEmail ?? "")}. Veuillez vérifier votre boîte de réception et vos spams.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Colors.green),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF098E00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  context.go('/auth/reset-password');
                                },
                                child: const Text("Saisir le code de réinitialisation", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Le code expirera dans 1 heure pour des raisons de sécurité.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  context.go('/auth/login');
                                },
                                icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF098E00)),
                                label: const Text("Retour à la connexion", style: TextStyle(color: Color(0xFF098E00), fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPartnerLogo(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(assetPath, width: 40, height: 40, fit: BoxFit.contain),
    );
  }
}