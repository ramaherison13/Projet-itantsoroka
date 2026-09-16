import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:itantsoroka/providers/auth_provider.dart';
import 'package:itantsoroka/services/auth_service.dart';
import 'package:itantsoroka/services/sso_launcher.dart';
import 'package:itantsoroka/screens/authentification/complete_citizen_registration_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Keycloak SSO Configuration — IAHO
/// Valeurs identiques au projet React (keycloak.ts / .env)
class _KeycloakConfig {
  static const String kcUrl    = 'https://auth.tsirylab.com';
  static const String realm    = 'master';        // ← Realm officiel Keycloak
  static const String clientId = 'front-local';   // ← Client ID configuré pour le frontend

  // redirect_uri : même logique que React → window.location.origin + /callback
  // En dev Flutter Web, l'origine est http://localhost:PORT
  // CORRECTION Bug #4 : exclure les ports standards (80 pour http, 443 pour https)
  // pour éviter ":80" ou ":443" dans l'URI envoyé à Keycloak.
  static String get redirectUri {
    if (kIsWeb) {
      final scheme = Uri.base.scheme;
      final host = Uri.base.host;
      final port = Uri.base.port;
      final isStandardPort =
          (scheme == 'http' && port == 80) ||
          (scheme == 'https' && port == 443) ||
          port == 0;
      final origin = isStandardPort
          ? '$scheme://$host'
          : '$scheme://$host:$port';
      return '$origin/callback';
    }
    return 'https://gateway.tsirylab.com/callback';
  }

  static String get authorizationUrl =>
      '$kcUrl/realms/$realm/protocol/openid-connect/auth'
      '?client_id=$clientId'
      '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
      '&response_type=code'
      '&scope=openid%20profile%20email'
      '&kc_locale=fr';

  static String get tokenUrl =>
      '$kcUrl/realms/$realm/protocol/openid-connect/token';

  static String get registerUrl =>
      '$kcUrl/realms/$realm/protocol/openid-connect/registrations'
      '?client_id=$clientId'
      '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
      '&response_type=code'
      '&scope=openid%20profile%20email'
      '&kc_locale=fr';
}

/// LoginScreen — Option C : Page d'accueil avec boutons IAHO
/// [ssoCode] : code d'autorisation Keycloak transmis depuis la route /callback
class LoginScreen extends StatefulWidget {
  final String? ssoCode;
  const LoginScreen({super.key, this.ssoCode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _loading        = false;
  bool _showWebView    = false;
  bool _isRegisterMode = false;
  String? _errorMessage;

  WebViewController? _webController;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Priorité 1 : code transmis via la route /callback (GoRouter)
    if (widget.ssoCode != null && widget.ssoCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onCodeReceived(widget.ssoCode!));
      return;
    }

    // Priorité 2 : fallback — détecter ?code= dans l'URL directement (Flutter Web)
    if (kIsWeb) {
      final code = Uri.base.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onCodeReceived(code));
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onCodeReceived(String code) async {
    setState(() { _showWebView = false; _loading = true; _errorMessage = null; });
    try {
      final ssoToken = await _exchangeCodeForSsoToken(code);
      if (ssoToken == null || ssoToken.isEmpty) {
        _setError("Impossible d'obtenir le token SSO depuis Keycloak."); return;
      }
      final result = await AuthService.handleSsoLogin(ssoToken);
      if (!mounted) return;
      if (result.loggedIn && result.data != null) {
        await _finalizeLogin(result.data!);
      } else if (result.needsCitizenForm) {
        final citizenData = await Navigator.of(context).push<Map<String, dynamic>?>(
          MaterialPageRoute(builder: (_) => CompleteCitizenRegistrationScreen(ssoToken: ssoToken)),
        );
        if (citizenData != null && mounted) {
          await _finalizeLogin(citizenData);
        } else if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      _setError("Erreur d'authentification SSO : ${e.toString()}");
    }
  }

  Future<String?> _exchangeCodeForSsoToken(String code) async {
    try {
      final body = {
        'grant_type': 'authorization_code',
        'client_id': _KeycloakConfig.clientId,
        'code': code,
        'redirect_uri': _KeycloakConfig.redirectUri,
      };
      final response = await http.post(
        Uri.parse(_KeycloakConfig.tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['access_token']?.toString();
      }
    } catch (e) { debugPrint('Erreur échange code : $e'); }
    return null;
  }

  Future<void> _finalizeLogin(Map<String, dynamic> data) async {
    // Extraire le JWT brut depuis la réponse du serveur SSO
    // La réponse de /auth/sso/token est { access_token: "eyJ...", ... }
    // Miroir de authSlice.ts ligne 61 : on cherche access_token, token ou jwt
    final accessToken =
        data['access_token']?.toString() ??
        data['token']?.toString() ??
        data['jwt']?.toString() ??
        // Compatibilité avec des réponses imbriquées { data: { access_token: ... } }
        data['data']?['access_token']?.toString();

    if (accessToken == null || accessToken.trim().isEmpty) {
      _setError('Token JWT applicatif non reçu du serveur.');
      return;
    }
    final jwt = accessToken.trim();

    // Déterminer isActivated depuis la réponse
    final isActivated = data['isActivated'] as bool? ?? true;

    // Passer au provider le format attendu par login() :
    // JSON.stringify({ data: jwtString, isActivated: bool })
    // — Miroir de authSlice.ts :
    //   const token = typeof rawData.data === "string" ? rawData.data : ...
    // On passe le JWT brut comme chaîne dans 'data' pour que
    // AuthProvider.login() l'extrait sans ambigüité.
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    await authProvider.login(jsonEncode({'data': jwt, 'isActivated': isActivated}));
    if (!mounted) return;

    // Déterminer le rôle pour la redirection
    bool isSuperAdmin = false;
    try {
      final parts = jwt.split('.');
      if (parts.length > 1) {
        final normalized = base64Url.normalize(parts[1]);
        final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
        final roles = payload['roles'];
        if (roles is List) {
          isSuperAdmin = roles.any(
            (r) => r is Map &&
                (r['role_slug'] == 'Super-Admin' || r['role_name'] == 'Super-Admin'),
          );
        }
      }
    } catch (e) {
      debugPrint('_finalizeLogin : erreur d\'analyse du JWT pour le rôle : $e');
    }

    _showSnack('Connexion SSO réussie !', Colors.green);
    router.go(isSuperAdmin ? '/admin' : '/modules');
  }

  void _openKeycloakSso({bool register = false}) {
    final targetUrl = register ? _KeycloakConfig.registerUrl : _KeycloakConfig.authorizationUrl;
    if (kIsWeb) {
      redirectToSsoUrl(targetUrl);
      return;
    }
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (NavigationRequest request) {
        final url = request.url;
        if (url.contains('code=')) {
          final code = Uri.parse(url).queryParameters['code'];
          if (code != null && code.isNotEmpty) _onCodeReceived(code);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ));
    controller.loadRequest(Uri.parse(targetUrl));
    _webController = controller;
    if (mounted) setState(() { _showWebView = true; _isRegisterMode = register; _errorMessage = null; });
  }

  void _setError(String msg) {
    if (mounted) setState(() { _loading = false; _errorMessage = msg; });
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _webController != null) return _buildKeycloakWebView();

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool   isDesktop   = screenWidth > 900;

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF072C33),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIahoLogoWhite(),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Color(0xFFD99450), strokeWidth: 3),
              const SizedBox(height: 20),
              const Text('Authentification en cours…', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF072C33),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32.0 : 20.0, vertical: 24.0),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 480),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 50, offset: const Offset(0, 20))],
                ),
                clipBehavior: Clip.antiAlias,
                child: isDesktop
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: _buildBrandingPanel(isMobile: false)),
                            Expanded(flex: 6, child: _buildActionPanel()),
                          ],
                        ),
                      )
                    : Column(children: [_buildBrandingPanel(isMobile: true), _buildActionPanel()]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel({required bool isMobile}) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isMobile ? 28.0 : 42.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIahoLogoColored(),
          const SizedBox(height: 32),
          const Text(
            'Un seul accès,\ntoutes vos identités protégées.',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D454D), height: 1.3),
          ),
          const SizedBox(height: 14),
          Text(
            'IAHO centralise l\'authentification et le contrôle d\'accès de vos services gouvernementaux, avec une sécurité pensée pour durer.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.55),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: const [
              _FeatureBadge(icon: Icons.security_rounded, label: 'SSO Sécurisé'),
              _FeatureBadge(icon: Icons.speed_rounded, label: 'Accès rapide'),
              _FeatureBadge(icon: Icons.verified_user_rounded, label: 'Certifié IAHO'),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: _buildStatBadge('99,99 %', 'Disponibilité')),
              const SizedBox(width: 14),
              Expanded(child: _buildStatBadge('24/7', 'Support actif')),
            ]),
          ],
          const SizedBox(height: 24),
          Text(
            '© 2025 IAHO — Identité · Accès · Autorité\nMinistère malgache du Numérique',
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
      color: const Color(0xFF0D4A52),
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bienvenue sur la IAHO',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Connectez-vous ou créez votre compte\nvia le portail sécurisé IAHO.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Color(0xFFA3C9CE), height: 1.5),
          ),
          const SizedBox(height: 36),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            ),
            child: const Icon(Icons.shield_outlined, size: 42, color: Color(0xFFD99450)),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null) ...[
            _buildErrorCard(),
            const SizedBox(height: 20),
          ],
          _buildKeycloakButton(
            label: 'Se connecter avec IAHO',
            sublabel: 'Portail SSO officiel Keycloak',
            icon: Icons.login_rounded,
            onPressed: () => _openKeycloakSso(register: false),
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('ou', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1)),
          ]),
          const SizedBox(height: 16),
          _buildKeycloakButton(
            label: 'Créer un compte IAHO',
            sublabel: 'Inscription via le portail officiel',
            icon: Icons.person_add_outlined,
            onPressed: () => _openKeycloakSso(register: true),
            isPrimary: false,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 7),
                Text(
                  'Connexion 100% sécurisée par IAHO · Keycloak',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55), letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeycloakButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF1C522F) : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPrimary ? const Color(0xFF1C522F) : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: isPrimary ? [BoxShadow(color: const Color(0xFF1C522F).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))] : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isPrimary ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(sublabel, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIahoLogoColored() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(color: const Color(0xFF006B70).withValues(alpha: 0.08), shape: BoxShape.circle),
            ),
            const Icon(Icons.shield_outlined, size: 50, color: Color(0xFF006B70)),
            const Positioned(top: 12, child: Icon(Icons.key_rounded, size: 22, color: Color(0xFF006B70))),
          ],
        ),
        const SizedBox(height: 10),
        const Text('IAHO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF006B70), letterSpacing: 4.0)),
        const SizedBox(height: 2),
        Text('IDENTITY · ACCESS · AUTHORITY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.4)),
      ],
    );
  }

  Widget _buildIahoLogoWhite() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
            ),
            const Icon(Icons.shield_outlined, size: 56, color: Color(0xFFD99450)),
            const Positioned(top: 14, child: Icon(Icons.key_rounded, size: 26, color: Color(0xFFD99450))),
          ],
        ),
        const SizedBox(height: 12),
        const Text('IAHO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 5.0)),
      ],
    );
  }

  Widget _buildStatBadge(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D5C4), width: 1.2),
        boxShadow: [BoxShadow(color: const Color(0xFFD99450).withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFD99450))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.white))),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildKeycloakWebView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D4A52),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => setState(() { _showWebView = false; _webController = null; }),
        ),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFD99450)),
            const SizedBox(width: 8),
            Text(
              _isRegisterMode ? 'Créer un compte — IAHO' : 'Portail SSO — IAHO',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: WebViewWidget(controller: _webController!),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF006B70).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF006B70).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF006B70)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF006B70))),
        ],
      ),
    );
  }
}
