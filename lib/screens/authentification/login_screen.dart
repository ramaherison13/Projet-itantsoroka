import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itantsoroka/constants/api_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final String apiUrl = ApiConstants.serviceAuth;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    // IMPORTANT : Ne jamais appeler context.go() depuis initState (même via async/await).
    // Cela provoque le crash "Duplicate GlobalKey detected" car la navigation est
    // déclenchée pendant BuildOwner.finalizeTree. La navigation se fait via les
    // boutons ou après soumission du formulaire.
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Gérer la soumission du formulaire de connexion
  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showAlert("Veuillez entrer une adresse email valide", Colors.red);
      return;
    }

    if (password.isEmpty) {
      _showAlert("Veuillez entrer votre mot de passe", Colors.red);
      return;
    }

    setState(() {
      loading = true;
    });

    bool isRedirecting = false;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_email": email,
          "user_password": password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        if (data['sessionLocked'] == true) {
          if (mounted) {
            isRedirecting = true;
            context.go('/');
          }
          return;
        }

        final accessToken = data['access_token'] ?? data['data']?['access_token'];

        if (accessToken != null && accessToken.toString().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("access_token", accessToken.toString());
          await prefs.setBool("isActivated", data['isActivated'] ?? true);

          _showAlert(data['message'] ?? "Connexion réussie", Colors.green);

          // Vérification des rôles (depuis le body ou en décodant le JWT)
          List roles = [];
          if (data['user']?['roles'] != null) {
            roles = data['user']['roles'];
          } else if (data['data']?['user']?['roles'] != null) {
            roles = data['data']['user']['roles'];
          } else if (accessToken.toString().contains('.')) {
            try {
              final parts = accessToken.toString().split('.');
              if (parts.length > 1) {
                String normalized = base64Url.normalize(parts[1]);
                String utf8Payload = utf8.decode(base64Url.decode(normalized));
                Map<String, dynamic> decodedPayload = jsonDecode(utf8Payload);
                if (decodedPayload['roles'] is List) {
                  roles = decodedPayload['roles'];
                }
              }
            } catch (e) {
              debugPrint("Erreur décodage token: $e");
            }
          }

          bool isSuperAdmin = roles.any(
            (r) => r['role_slug'] == "Super-Admin" || r['role_name'] == "Super-Admin",
          );

          if (mounted) {
            isRedirecting = true;
            ScaffoldMessenger.of(context).clearSnackBars();
            if (isSuperAdmin) {
              context.go('/admin');
            } else {
              context.go('/modules');
            }
          }
        } else {
          _showAlert(data['message'] ?? "Erreur de connexion", Colors.red);
        }
      } else {
        _showAlert(data['message'] ?? "Identifiants invalides", Colors.red);
      }
    } catch (error) {
      _showAlert("Une erreur est survenue, veuillez réessayer plus tard.", Colors.red);
    } finally {
      if (mounted && !isRedirecting) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _showAlert(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 768;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isWideScreen) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        body: _buildFormPanel(showLogo: true, isDark: isDark),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panneau gauche : illustration / branding
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF154D34), Color(0xFF0D3322)],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo_dd_v3.png',
                        width: 260,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (c, e, s) => Image.asset(
                          'assets/images/logo_dd.png',
                          width: 260,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 56),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildPartnerLogo('assets/images/LogoMinistereInterieur.jpg',
                              fallbacks: ['assets/images/logo_ministere.jpg']),
                          _buildPartnerLogo('assets/images/logo2.png'),
                          _buildPartnerLogo('assets/images/logo_dd.png',
                              fallbacks: ['assets/images/DD.png', 'assets/images/logo_dd_v3.png']),
                          _buildPartnerLogo('assets/images/PNUD-Logo-Blue.png',
                              fallbacks: [
                                'assets/images/LOGO-PNUD.png',
                                'assets/images/logo_pnud_blue.png',
                                'assets/images/logo_pnud.png',
                              ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Panneau droit : formulaire
          Expanded(
            child: _buildFormPanel(showLogo: false, isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel({required bool showLogo, required bool isDark}) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 500;
    final Color pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final Color labelColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700;
    final Color fillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final Color inputBorder = isDark ? const Color(0xFF334155) : Colors.grey.shade300;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    return Container(
      color: pageBg,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 36.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showLogo) ...[
                  Center(
                    child: Image.asset(
                      'assets/images/logo_dd_v3.png',
                      width: 180,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  "Connexion à la plateforme",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Veuillez saisir vos identifiants pour accéder à vos fonctionnalités",
                  style: TextStyle(fontSize: 13, color: subtitleColor),
                ),
                const SizedBox(height: 28),

                // Champ Email
                Text(
                  "Adresse email",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: "Entrez votre email",
                    hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                    prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF16A34A)),
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Champ Mot de passe
                Text(
                  "Mot de passe",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !showPassword,
                  style: TextStyle(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: "Entrez votre mot de passe",
                    hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF16A34A)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: labelColor,
                      ),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Checkbox Rester connecté + Mot de passe oublié
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: rememberMe,
                            activeColor: const Color(0xFF16A34A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => rememberMe = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Rester connecté",
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/auth/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Bouton Se connecter
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: loading ? null : _handleSubmit,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Se connecter",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Liens secondaires
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Vous n'avez pas de compte ? ",
                            style: TextStyle(fontSize: 13, color: subtitleColor),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/auth/check-id-card'),
                            child: const Text(
                              "Créer un compte",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Text(
                          "← Revenir à l'accueil",
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  Widget _buildPartnerLogo(String assetPath, {List<String>? fallbacks}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 30,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (ctx, err, _) {
            if (fallbacks != null && fallbacks.isNotEmpty) {
              return Image.asset(
                fallbacks.first,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}