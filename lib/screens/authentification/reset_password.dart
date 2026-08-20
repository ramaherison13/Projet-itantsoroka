import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final String apiUrl = ApiConstants.gatewayBaseUrl;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool loading = false;
  bool success = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  bool validateForm() {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showAlert("Veuillez saisir une adresse email valide.", Colors.red);
      return false;
    }

    if (token.isEmpty || token.length != 6) {
      _showAlert("Veuillez saisir le code à 6 chiffres reçu par email.", Colors.red);
      return false;
    }

    if (password != confirmPassword) {
      _showAlert("Les mots de passe ne correspondent pas.", Colors.red);
      return false;
    }

    if (password.length < 8) {
      _showAlert("Le mot de passe doit contenir au moins 8 caractères.", Colors.red);
      return false;
    }

    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(password);

    if (!hasUpperCase || !hasLowerCase || !hasNumber || !hasSpecialChar) {
      _showAlert(
        "Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial.",
        Colors.red,
      );
      return false;
    }

    return true;
  }

  void _showAlert(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 4)),
    );
  }

  Future<void> handleSubmit() async {
    if (!validateForm()) return;

    setState(() {
      loading = true;
    });

    try {
      final payload = {
        "token": _tokenController.text.trim(),
        "newPassword": _passwordController.text,
        "user_email": _emailController.text.trim(),
      };

      final response = await http.post(
        Uri.parse('$apiUrl/serviceauth/auth/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          success = true;
        });
        _showAlert("Mot de passe réinitialisé avec succès !", Colors.green);

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            context.go('/auth/login');
          }
        });
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? "Une erreur est survenue lors de la réinitialisation du mot de passe.";
        _showAlert(message, Colors.red);
      }
    } catch (error) {
      _showAlert("Une erreur est survenue lors de la réinitialisation du mot de passe.", Colors.red);
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
                                    "Nouveau mot de passe",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Choisissez un mot de passe fort et sécurisé",
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

                            // En-tête de la carte
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
                                      success ? Icons.check_circle_outline : Icons.lock_outline,
                                      size: 32,
                                      color: const Color(0xFF098E00),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  success ? "Mot de passe réinitialisé !" : "Nouveau mot de passe",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  success
                                      ? "Votre mot de passe a été réinitialisé avec succès."
                                      : "Choisissez un nouveau mot de passe sécurisé pour votre compte.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (!success)
                              Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email Input
                                  _buildTextField(
                                    controller: _emailController,
                                    label: "Email",
                                    hint: "votre.email@example.com",
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),

                                  // Token Input
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Code de réinitialisation", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _tokenController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        decoration: InputDecoration(
                                          hintText: "Code à 6 chiffres",
                                          prefixIcon: const Icon(Icons.key_outlined, color: Colors.grey),
                                          counterText: "",
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text("Entrez le code à 6 chiffres reçu par email", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Input
                                  _buildPasswordField(
                                    controller: _passwordController,
                                    label: "Nouveau mot de passe",
                                    show: showPassword,
                                    onToggle: () => setState(() => showPassword = !showPassword),
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm Password Input
                                  _buildPasswordField(
                                    controller: _confirmPasswordController,
                                    label: "Confirmer le mot de passe",
                                    show: showConfirmPassword,
                                    onToggle: () => setState(() => showConfirmPassword = !showConfirmPassword),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Requirements Box
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Le mot de passe doit contenir :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        const Text("• Au moins 8 caractères", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        const Text("• Une lettre majuscule et une minuscule", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        const Text("• Au moins un chiffre", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text("• Un caractère spécial (!@#\$%^&*)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Submit Button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF098E00),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: loading ? null : handleSubmit,
                                    child: loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Text("Réinitialiser le mot de passe", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ) else Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: const Text(
                                    "Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: Colors.green),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Redirection automatique vers la page de connexion...",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !show,
          decoration: InputDecoration(
            hintText: "••••••••",
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }
}