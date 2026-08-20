import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _pseudoController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  bool _showPassword = false;
  bool _loading = false;
  String _error = "";
  String _success = "";

  @override
  void initState() {
    super.initState();
    _pseudoController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();

    // Pré-remplir avec les données de la vraie session
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _pseudoController.text = user.userPseudo;
      _emailController.text = user.userEmail;
    }
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null || user.userId.isEmpty) {
      setState(() {
        _error = "Impossible de récupérer l'identifiant utilisateur. Veuillez vous reconnecter.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = "";
      _success = "";
    });

    try {
      final Map<String, dynamic> updateData = {};

      if (_pseudoController.text.trim().isNotEmpty &&
          _pseudoController.text.trim() != user.userPseudo) {
        updateData['user_pseudo'] = _pseudoController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty &&
          _emailController.text.trim() != user.userEmail) {
        updateData['user_email'] = _emailController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        updateData['user_phone'] = _phoneController.text.trim();
      }
      if (_passwordController.text.isNotEmpty) {
        updateData['user_password'] = _passwordController.text;
      }

      if (updateData.isEmpty) {
        setState(() {
          _error = "Aucune modification détectée. Veuillez modifier au moins un champ.";
          _loading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.serviceAuth}/users/${user.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Recharger la session pour mettre à jour les données affichées
        await authProvider.restoreSession();

        if (mounted) {
          setState(() {
            _success = "Profil mis à jour avec succès !";
            _passwordController.clear();
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        dynamic resBody;
        try {
          resBody = jsonDecode(response.body);
        } catch (_) {}

        String errorMsg = 'Échec de la mise à jour du profil.';
        if (response.statusCode == 409) {
          errorMsg = resBody?['message'] ?? 'Un utilisateur avec cet email existe déjà.';
        } else if (resBody is Map && (resBody['message'] != null || resBody['error'] != null)) {
          errorMsg = (resBody['message'] ?? resBody['error']).toString();
        }

        if (mounted) {
          setState(() => _error = errorMsg);
        }
      }
    } catch (err) {
      if (mounted) {
        setState(() => _error = "Erreur réseau lors de la mise à jour du profil : $err");
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de retour
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back,
                      color: isDark ? Colors.grey.shade400 : Colors.grey),
                  label: Text("Retour",
                      style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 12),
                Text(
                  "Modifier mon profil",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mettez à jour vos informations personnelles",
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey),
                ),
                const SizedBox(height: 24),

                // Formulaire
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pseudo
                        _buildTextField(
                          controller: _pseudoController,
                          label: "Pseudo",
                          icon: Icons.person_outline,
                          hint: "Votre pseudo",
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        // Email
                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.mail_outline,
                          hint: "votre@email.mg",
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        // Téléphone
                        _buildTextField(
                          controller: _phoneController,
                          label: "Téléphone",
                          icon: Icons.phone_outlined,
                          hint: "0321234567",
                          keyboardType: TextInputType.phone,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        // Mot de passe
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  "Nouveau mot de passe (optionnel)",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey.shade200
                                          : Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87),
                              decoration: InputDecoration(
                                hintText:
                                    "Laisser vide pour ne pas changer",
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey,
                                  ),
                                  onPressed: () => setState(() =>
                                      _showPassword = !_showPassword),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: isDark,
                                fillColor: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : null,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Laissez ce champ vide si vous ne souhaitez pas changer votre mot de passe",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey),
                            ),
                          ],
                        ),

                        // Bannière d'erreur
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error,
                                    style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Bannière de succès
                        if (_success.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border:
                                  Border.all(color: Colors.green.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _success,
                                    style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Boutons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400),
                                ),
                                child: Text(
                                  "Annuler",
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF098E00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save, size: 18),
                                          SizedBox(width: 8),
                                          Text("Enregistrer"),
                                        ],
                                      ),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade200 : Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: isDark,
            fillColor: isDark ? const Color(0xFF2C2C2C) : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}