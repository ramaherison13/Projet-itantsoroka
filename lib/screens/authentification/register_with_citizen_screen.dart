import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/l10n/app_localization.dart';
import 'package:itantsoroka/widgets/language_setting_widget.dart';

class RegisterWithCitizenScreen extends StatefulWidget {
  final String citizenId;

  const RegisterWithCitizenScreen({super.key, required this.citizenId});

  @override
  State<RegisterWithCitizenScreen> createState() => _RegisterWithCitizenScreenState();
}

class _RegisterWithCitizenScreenState extends State<RegisterWithCitizenScreen> {
  final String apiUrl = ApiConstants.gatewayBaseUrl;
  final int appId = 1; // Remplacez par votre APP_ID
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<dynamic> territories = [];
  String? selectedMunicipalityId;

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool loading = false;
  bool loadingTerritories = false;

  @override
  void initState() {
    super.initState();

    // Rediriger si pas d'id_citizen
    if (widget.citizenId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAlert(context.tr('register.err_no_citizen'), Colors.red);
        context.go('/auth/check-id-card');
      });
    }

    fetchTerritories();
  }

  Future<void> fetchTerritories() async {
    if (!mounted) return;
    setState(() {
      loadingTerritories = true;
    });

    try {
      final response = await http.get(Uri.parse('${ApiConstants.serviceTerritoire}/communes/basic?page=1&limit=1579')).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final raw = json.decode(response.body);
        List<dynamic> extracted = [];
        if (raw is List) {
          extracted = raw;
        } else if (raw['data'] is List) {
          extracted = raw['data'];
        } else if (raw['data'] is Map && raw['data']['data'] is List) {
          extracted = raw['data']['data'];
        } else if (raw['results'] is List) {
          extracted = raw['results'];
        }
        if (mounted) {
          setState(() {
            territories = extracted;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            territories = [];
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _showAlert(context.tr('register.err_load_communes'), Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          loadingTerritories = false;
        });
      }
    }
  }

  bool validateForm() {
    if (_pseudoController.text.trim().isEmpty) {
      _showAlert(context.tr('register.err_pseudo_requis'), Colors.red);
      return false;
    }
    if (_emailController.text.trim().isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showAlert(context.tr('register.err_email_invalide'), Colors.red);
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showAlert(context.tr('register.err_password_6_char'), Colors.red);
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showAlert(context.tr('register.err_password_mismatch'), Colors.red);
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showAlert(context.tr('register.err_phone_requis'), Colors.red);
      return false;
    }
    if (selectedMunicipalityId == null || selectedMunicipalityId!.isEmpty) {
      _showAlert(context.tr('register.err_commune_requis'), Colors.red);
      return false;
    }
    return true;
  }

  void _showAlert(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white))),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  Future<void> handleSubmit() async {
    if (!validateForm()) return;

    setState(() {
      loading = true;
    });

    final msgSucces = context.tr('register.succes_connexion');
    final msgErreur = context.tr('register.erreur_inscription');

    try {
      final payload = {
        "user_pseudo": _pseudoController.text.trim(),
        "user_email": _emailController.text.trim(),
        "user_password": _passwordController.text,
        "user_phone": _phoneController.text.trim(),
        "municipality_id": selectedMunicipalityId,
        "id_citizen": widget.citizenId,
        "app_id": appId,
        "role_ids": [19],
      };

      final response = await http.post(
        Uri.parse('$apiUrl/serviceauth/users/create-with-roles'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showAlert(msgSucces, Colors.green);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/auth/login');
          }
        });
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? data['error'] ?? msgErreur;
        _showAlert(errorMessage, Colors.red);
      }
    } catch (error) {
      _showAlert(msgErreur, Colors.red);
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
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 700;

                Widget leftPane = Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    border: Border(right: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('register.titre'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('register.completez_profil'),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset('assets/images/logo_dd_v3.png', width: 180, fit: BoxFit.contain),
                      ),
                    ],
                  ),
                );

                Widget formWidget = Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            LanguageSettingWidget(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!isWide) ...[
                          Center(
                            child: Image.asset('assets/images/logo_dd_v3.png', width: 140, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Étapes visuelles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text("✓", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Container(width: 32, height: 4, color: Colors.green),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text("2", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          context.tr('register.completez_profil'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('register.remplissez_infos'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Nom d'utilisateur
                        _buildTextField(
                          controller: _pseudoController,
                          label: context.tr('register.pseudo'),
                          hint: context.tr('register.pseudo_hint'),
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _buildTextField(
                          controller: _emailController,
                          label: context.tr('register.email'),
                          hint: "votre.email@example.com",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Téléphone
                        _buildTextField(
                          controller: _phoneController,
                          label: context.tr('register.telephone'),
                          hint: "0XX XX XXX XX",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Commune (Dropdown)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('register.commune'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedMunicipalityId,
                                        hint: Text(loadingTerritories ? context.tr('register.chargement') : context.tr('register.select_commune')),
                                        isExpanded: true,
                                        items: territories.map((territory) {
                                          final id = territory['formatted_id']?.toString() ?? '';
                                          final name = territory['name'] ?? territory['nom'] ?? '';
                                          return DropdownMenuItem<String>(
                                            value: id,
                                            child: Text(name),
                                          );
                                        }).toList(),
                                        onChanged: loadingTerritories
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  selectedMunicipalityId = val;
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Mot de passe
                        _buildPasswordField(
                          controller: _passwordController,
                          label: context.tr('register.mot_de_passe'),
                          show: showPassword,
                          onToggle: () => setState(() => showPassword = !showPassword),
                        ),
                        const SizedBox(height: 16),

                        // Confirmation mot de passe
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: context.tr('register.confirmer_pass'),
                          show: showConfirmPassword,
                          onToggle: () => setState(() => showConfirmPassword = !showConfirmPassword),
                        ),
                        const SizedBox(height: 24),

                        // Boutons d'action
                        if (isWide)
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () => context.go('/auth/check-id-card'),
                                icon: const Icon(Icons.arrow_back, size: 20),
                                label: Text(context.tr('register.btn_retour')),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF098E00),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  onPressed: loading ? null : handleSubmit,
                                  child: loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(context.tr('register.btn_creer_mon_compte'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF098E00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: loading ? null : handleSubmit,
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(context.tr('register.btn_creer_mon_compte'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () => context.go('/auth/check-id-card'),
                                icon: const Icon(Icons.arrow_back, size: 20),
                                label: Text(context.tr('register.btn_retour')),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),

                        // Lien connexion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${context.tr('register.deja_compte')} ", style: const TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => context.go('/auth/login'),
                              child: Text(context.tr('register.se_connecter'), style: const TextStyle(color: Color(0xFF098E00), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: leftPane),
                        Expanded(child: formWidget),
                      ],
                    ),
                  );
                } else {
                  return formWidget;
                }
              },
            ),
          ),
        ),
      ),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }
}