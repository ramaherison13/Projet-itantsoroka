import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/l10n/app_localization.dart';
import 'package:itantsoroka/services/territory_service.dart';
import 'package:itantsoroka/widgets/language_setting_widget.dart';

class RegisterScreen extends StatefulWidget {
  final String globalCin;

  const RegisterScreen({super.key, required this.globalCin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final String apiUrl = ApiConstants.gatewayBaseUrl;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cinController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cardLocationController = TextEditingController();
  final TextEditingController _cardDateController = TextEditingController();
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<dynamic> communes = [];
  dynamic selectedCommune;
  dynamic selectedFokontany;
  List<dynamic> communeFokotanys = [];
  bool loadingFokotanys = false;

  XFile? citizenPhoto;
  Uint8List? photoBytes;

  bool isLoading = false;
  bool loadingPage = true;
  bool showPassword = false;

  Map<String, String> errors = {};
  Map<String, bool> touched = {};
  String query = "";
  String fokontanyQuery = "";

  @override
  void initState() {
    super.initState();
    String initialCin = widget.globalCin;
    if (initialCin.length > 12) {
      initialCin = initialCin.substring(0, 12);
    }
    _cinController = TextEditingController(text: initialCin);

    if (widget.globalCin.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth/check-id-card');
      });
    }

    loadCommunes();
  }

  @override
  void dispose() {
    _cinController.dispose();
    _nameController.dispose();
    _lastnameController.dispose();
    _workController.dispose();
    _addressController.dispose();
    _cardLocationController.dispose();
    _cardDateController.dispose();
    _pseudoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> loadCommunes() async {
    if (!mounted) return;
    setState(() => loadingPage = true);

    try {
      final list = await TerritoryService.getAllCommunes();
      if (list != null && list.isNotEmpty && mounted) {
        setState(() {
          communes = list;
          loadingPage = false;
        });
        return;
      }
    } catch (_) {}

    final endpoints = [
      '${ApiConstants.serviceTerritoire}/communes/sans-form',
      '${ApiConstants.serviceTerritoire}/communes/basic?page=1&limit=1579',
    ];

    for (final url in endpoints) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 12));
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
            } else if (raw['items'] is List) {
              extracted = raw['items'];
            }
            if (extracted.isNotEmpty) {
              if (mounted) setState(() => communes = extracted);
              break;
            }
          }
        } catch (e) {
          debugPrint('loadCommunes attempt ${attempt + 1} for $url: $e');
          if (attempt == 0) await Future.delayed(const Duration(milliseconds: 800));
        }
      }
      if (communes.isNotEmpty) break;
    }

    if (communes.isEmpty && mounted) _setFallbackCommunes();

    if (mounted) setState(() => loadingPage = false);
  }

  void _setFallbackCommunes() {
    setState(() {
      communes = [
        {'formatted_id': '101', 'commune_name': 'Befandriana Nord'},
        {'formatted_id': '102', 'commune_name': 'Andilanatoby'},
        {'formatted_id': '103', 'commune_name': 'Mahavoky Nord'},
        {'formatted_id': '104', 'commune_name': 'Ranohira'},
        {'formatted_id': '105', 'commune_name': 'Antananarivo Renivohitra'},
        {'formatted_id': '106', 'commune_name': 'Fianarantsoa'},
        {'formatted_id': '107', 'commune_name': 'Toamasina'},
        {'formatted_id': '108', 'commune_name': 'Mahajanga'},
        {'formatted_id': '109', 'commune_name': 'Toliara'},
        {'formatted_id': '110', 'commune_name': 'Antsiranana'},
      ];
    });
  }

  Future<void> _fetchFokotanysForCommune(String communeFormattedId) async {
    setState(() {
      loadingFokotanys = true;
      communeFokotanys = [];
    });

    try {
      final foks = await TerritoryService.getFokotanysByCommune(communeFormattedId);
      if (mounted) {
        setState(() {
          communeFokotanys = foks ?? [];
          loadingFokotanys = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          communeFokotanys = [];
          loadingFokotanys = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final fileSize = await pickedFile.length();
      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      if (fileSize > 2 * 1024 * 1024) {
        if (mounted) {
          setState(() {
            errors['citizen_photo'] = context.tr('register.err_photo_size');
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          citizenPhoto = pickedFile;
          photoBytes = bytes;
          errors.remove('citizen_photo');
        });
      }
    }
  }

  bool validateFormFull() {
    setState(() {
      errors.clear();

      final errRequis = context.tr('register.champ_requis');

      // Nom (citizen_name) - Required
      if (_nameController.text.trim().isEmpty) {
        errors['citizen_name'] = errRequis;
      }

      // Commune (municipality_id) - Required
      if (selectedCommune == null) {
        errors['municipality_id'] = errRequis;
      }

      // Fonction (citizen_work) - Required
      if (_workController.text.trim().isEmpty) {
        errors['citizen_work'] = errRequis;
      }

      // Fokontany (fokotany_id / fokotany_formatted_id) - Required
      if (selectedFokontany == null) {
        errors['fokotany_id'] = errRequis;
        errors['fokotany_formatted_id'] = errRequis;
      }

      // CIN (citizen_national_card_number) - Required 12 digits
      final cinText = _cinController.text.trim();
      if (cinText.length != 12 || !RegExp(r'^\d+$').hasMatch(cinText)) {
        errors['citizen_national_card_number'] = context.tr('register.err_cin_12_chiffres');
      }

      // Email (user_email) - Required
      final emailText = _emailController.text.trim();
      if (emailText.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailText)) {
        errors['user_email'] = context.tr('register.err_email_invalide');
      }

      // Password (user_password) - Required
      if (_passwordController.text.isEmpty) {
        errors['user_password'] = errRequis;
      }

      // Confirm Password - Required & must match
      if (_passwordController.text != _confirmPasswordController.text) {
        errors['confirm_password'] = context.tr('register.err_password_mismatch');
      }

      // Phone (user_phone) - Optional, but if typed must be 10 digits
      final phoneText = _phoneController.text.trim();
      if (phoneText.isNotEmpty && (phoneText.length != 10 || !RegExp(r'^\d+$').hasMatch(phoneText))) {
        errors['user_phone'] = context.tr('register.err_phone_10_chiffres');
      }
    });

    return errors.isEmpty;
  }

  Future<void> handleSubmit() async {
    setState(() {
      touched = {
        'citizen_name': true,
        'citizen_lastname': true,
        'citizen_adress': true,
        'citizen_national_card_number': true,
        'citizen_national_card_location': true,
        'citizen_national_card_date': true,
        'fokotany_id': true,
        'fokotany_formatted_id': true,
        'user_pseudo': true,
        'user_email': true,
        'user_password': true,
        'confirm_password': true,
        'user_phone': true,
        'municipality_id': true,
        'citizen_work': true,
        'citizen_photo': true,
      };
    });

    if (!validateFormFull()) {
      _showAlert(context.tr('register.erreur_formulaire'), Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final msgSucces = context.tr('register.succes');
    final msgErreur = context.tr('register.erreur_generique');
    final msgErreurInscription = context.tr('register.erreur_inscription');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.serviceAuth}/users/register-with-citizen-short'),
      );

      final communeId = selectedCommune?['formatted_id']?.toString() ?? selectedCommune?['municipality_id']?.toString() ?? selectedCommune?['id']?.toString() ?? '';
      final fokontanyFormattedId = selectedFokontany?['formatted_id']?.toString() ?? selectedFokontany?['fokotany_formatted_id']?.toString() ?? selectedFokontany?['id']?.toString() ?? '';

      // Required fields
      request.fields['citizen_name'] = _nameController.text.trim();
      request.fields['citizen_lastname'] = _lastnameController.text.trim();
      request.fields['citizen_national_card_number'] = _cinController.text.trim();
      request.fields['fokotany_formatted_id'] = fokontanyFormattedId;
      request.fields['user_email'] = _emailController.text.trim();
      request.fields['user_password'] = _passwordController.text;
      request.fields['municipality_id'] = communeId;
      request.fields['citizen_work'] = _workController.text.trim();

      // Optional fields
      if (_addressController.text.trim().isNotEmpty) {
        request.fields['citizen_adress'] = _addressController.text.trim();
      }
      if (_cardLocationController.text.trim().isNotEmpty) {
        request.fields['citizen_national_card_location'] = _cardLocationController.text.trim();
      }
      if (_cardDateController.text.trim().isNotEmpty) {
        request.fields['citizen_national_card_date'] = _cardDateController.text.trim();
      }
      if (_pseudoController.text.trim().isNotEmpty) {
        request.fields['user_pseudo'] = _pseudoController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        request.fields['user_phone'] = _phoneController.text.trim();
      }

      if (citizenPhoto != null && photoBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'citizen_photo',
            photoBytes!,
            filename: citizenPhoto!.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showAlert(msgSucces, Colors.green);
        if (mounted) {
          context.go('/auth/login');
        }
      } else {
        _showAlert(data['message'] ?? msgErreurInscription, Colors.red);
      }
    } catch (error) {
      _showAlert(msgErreur, Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _communeName(dynamic c) {
    return c['commune_name'] ?? c['name'] ?? c['nom'] ?? '';
  }

  InputDecoration _customInputDecoration({
    required BuildContext ctx,
    required String labelText,
    bool isRequired = true,
    String? hintText,
    required IconData icon,
    String? errorText,
    Widget? suffixIcon,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
    final Color fillNormal = isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB);
    final Color fillError  = isDark ? const Color(0xFF2D1515) : const Color(0xFFFEF2F2);
    final Color borderNormal = isDark ? const Color(0xFF334155) : Colors.grey.shade300;
    final Color labelNormal = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700;
    final Color hintColor = isDark ? const Color(0xFF64748B) : Colors.grey.shade400;
    return InputDecoration(
      labelText: isRequired ? "$labelText *" : labelText,
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: hasError ? Colors.red.shade400 : const Color(0xFF16A34A),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: hasError ? fillError : fillNormal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(
        color: hasError ? Colors.red.shade700 : labelNormal,
        fontSize: 14,
        fontWeight: isRequired ? FontWeight.w500 : FontWeight.normal,
      ),
      hintStyle: TextStyle(color: hintColor, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderNormal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.red.shade300 : borderNormal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFF16A34A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
    );
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final Color pillBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;

    if (loadingPage) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: borderColor),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      LanguageSettingWidget(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Logo DISPOSITIF DISTRICT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF098E00).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF098E00).withValues(alpha: 0.15)),
                    ),
                    child: Image.asset(
                      'assets/images/logo_dd_v3.png',
                      height: 60,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (c, e, s) => Image.asset(
                        'assets/images/LOGO - Dispositif District.png',
                        height: 60,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (c2, e2, s2) => Image.asset(
                          'assets/images/logo_dd.png',
                          height: 60,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Partner Logos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildPartnerLogo('assets/images/LogoMinistereInterieur.jpg', fallbacks: ['assets/images/logo_ministere.jpg']),
                        _buildPartnerLogo('assets/images/logo2.png'),
                        _buildPartnerLogo('assets/images/logo_dd.png', fallbacks: ['assets/images/DD.png', 'assets/images/logo_dd_v3.png']),
                        _buildPartnerLogo('assets/images/PNUD-Logo-Blue.png', fallbacks: ['assets/images/LOGO-PNUD.png', 'assets/images/logo_pnud_blue.png', 'assets/images/logo_pnud.png']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title & Subtitle
                  Column(
                    children: [
                      Text(
                        context.tr('register.titre'),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF098E00)),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('register.officiel'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF098E00)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('register.sous_titre'),
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 650;

                      // Left Column: Prénom (optional), Nom (*), Commune (*), Fokontany (*), CIN (*)
                      Widget leftColumn = Column(
                        children: [
                          TextFormField(
                            controller: _lastnameController,
                            onChanged: (_) => setState(() {}),
                            decoration: _customInputDecoration(
                              ctx: context,
                              labelText: context.tr('register.prenom'),
                              isRequired: false,
                              icon: Icons.person_outline,
                              errorText: touched['citizen_lastname'] == true ? errors['citizen_lastname'] : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _nameController,
                            onChanged: (_) => setState(() {}),
                            decoration: _customInputDecoration(
                              ctx: context,
                              labelText: context.tr('register.nom'),
                              isRequired: true,
                              icon: Icons.badge_outlined,
                              errorText: touched['citizen_name'] == true ? errors['citizen_name'] : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Commune Selection
                          if (selectedCommune == null) ...[
                            TextField(
                              onChanged: (val) => setState(() => query = val),
                              decoration: _customInputDecoration(
                                ctx: context,
                                labelText: context.tr('register.commune'),
                                hintText: context.tr('register.commune_hint'),
                                isRequired: true,
                                icon: Icons.location_city_outlined,
                                errorText: touched['municipality_id'] == true ? errors['municipality_id'] : null,
                              ),
                            ),
                            if (query.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 160),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: communes
                                      .where((c) => (_communeName(c)).toLowerCase().contains(query.toLowerCase()))
                                      .length,
                                  itemBuilder: (context, index) {
                                    final filteredList = communes
                                        .where((c) => (_communeName(c)).toLowerCase().contains(query.toLowerCase()))
                                        .toList();
                                    final c = filteredList[index];
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          final cId = c['formatted_id']?.toString() ?? c['id']?.toString() ?? '';
                                          setState(() {
                                            selectedCommune = c;
                                            selectedFokontany = null;
                                            query = "";
                                            fokontanyQuery = "";
                                            errors.remove('municipality_id');
                                          });
                                          if (c['fokotanys'] is List && (c['fokotanys'] as List).isNotEmpty) {
                                            setState(() => communeFokotanys = c['fokotanys']);
                                          } else if (cId.isNotEmpty) {
                                            _fetchFokotanysForCommune(cId);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(_communeName(c), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF16A34A), width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_communeName(selectedCommune), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => setState(() {
                                      selectedCommune = null;
                                      selectedFokontany = null;
                                      query = "";
                                      fokontanyQuery = "";
                                      communeFokotanys = [];
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Fokontany Selection
                          if (selectedCommune != null) ...[
                            if (selectedFokontany == null) ...[
                              TextField(
                                onChanged: (val) => setState(() => fokontanyQuery = val),
                                decoration: _customInputDecoration(
                                  ctx: context,
                                  labelText: context.tr('register.fokontany'),
                                  hintText: context.tr('register.fokontany_hint'),
                                  isRequired: true,
                                  icon: Icons.map_outlined,
                                  errorText: touched['fokotany_id'] == true ? errors['fokotany_id'] : null,
                                ),
                              ),
                              if (loadingFokotanys)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(child: CircularProgressIndicator(color: Color(0xFF16A34A), strokeWidth: 2)),
                                )
                              else if (communeFokotanys.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 160),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: communeFokotanys
                                        .where((f) => (f['name'] ?? f['nom'] ?? '').toString().toLowerCase().contains(fokontanyQuery.toLowerCase()))
                                        .length,
                                    itemBuilder: (context, index) {
                                      final fokList = communeFokotanys
                                          .where((f) => (f['name'] ?? f['nom'] ?? '').toString().toLowerCase().contains(fokontanyQuery.toLowerCase()))
                                          .toList();
                                      final f = fokList[index];
                                      final fName = f['name'] ?? f['nom'] ?? '';
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => setState(() {
                                            selectedFokontany = f;
                                            errors.remove('fokotany_id');
                                            errors.remove('fokotany_formatted_id');
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(fName, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF16A34A), width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(selectedFokontany['name'] ?? selectedFokontany['nom'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () => setState(() {
                                        selectedFokontany = null;
                                        fokontanyQuery = "";
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],

                          // CIN Number
                          TextFormField(
                            controller: _cinController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: _customInputDecoration(
                              ctx: context,
                              labelText: context.tr('register.cin'),
                              isRequired: true,
                              icon: Icons.credit_card_outlined,
                              errorText: touched['citizen_national_card_number'] == true ? errors['citizen_national_card_number'] : null,
                            ),
                          ),
                        ],
                      );

                      // Right Column: Email (*), Password (*), Confirm Password (*), Fonction (*)
                      Widget rightColumn = Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                            decoration: _customInputDecoration(
                              ctx: context,
                              labelText: context.tr('register.email'),
                              isRequired: true,
                              icon: Icons.email_outlined,
                              errorText: touched['user_email'] == true ? errors['user_email'] : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: !showPassword,
                            onChanged: (_) => setState(() {}),
                            decoration: _customInputDecoration(
                              ctx: context,
                              labelText: context.tr('register.mot_de_passe'),
                              isRequired: true,
                              icon: Icons.lock_outline,
                              errorText: touched['user_password'] == true ? errors['user_password'] : null,
                              suffixIcon: IconButton(
                                icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade600),
                                onPressed: () => setState(() => showPassword = !showPassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !showPassword,
                            onChanged: (_) => setState(() {}),
                            decoration: _customInputDecoration(
                              ctx: context,
                              labelText: context.tr('register.confirmer_pass'),
                              isRequired: true,
                              icon: Icons.lock_outline,
                              errorText: touched['confirm_password'] == true ? errors['confirm_password'] : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Fonction (citizen_work) - Required
                          TextFormField(
                            controller: _workController,
                            onChanged: (_) => setState(() {}),
                            decoration: _customInputDecoration(
                              ctx: context,
                              labelText: context.tr('register.fonction'),
                              isRequired: true,
                              icon: Icons.work_outline,
                              errorText: touched['citizen_work'] == true ? errors['citizen_work'] : null,
                            ),
                          ),
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: leftColumn),
                            const SizedBox(width: 24),
                            Expanded(child: rightColumn),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            leftColumn,
                            const SizedBox(height: 16),
                            rightColumn,
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Optional Fields Section
                  ExpansionTile(
                    title: Text(
                      context.tr('register.photo'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor),
                    ),
                    childrenPadding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      TextFormField(
                        controller: _addressController,
                        onChanged: (_) => setState(() {}),
                        decoration: _customInputDecoration(
                          ctx: context,
                          labelText: context.tr('register.adresse'),
                          isRequired: false,
                          icon: Icons.home_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _cardDateController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _cardDateController.text = pickedDate.toIso8601String().split('T')[0];
                            });
                          }
                        },
                        decoration: _customInputDecoration(
                          ctx: context,
                          labelText: context.tr('register.date_delivrance'),
                          hintText: context.tr('register.date_hint'),
                          isRequired: false,
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _cardLocationController,
                        onChanged: (_) => setState(() {}),
                        decoration: _customInputDecoration(
                          ctx: context,
                          labelText: context.tr('register.lieu_delivrance'),
                          isRequired: false,
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _pseudoController,
                        onChanged: (_) => setState(() {}),
                        decoration: _customInputDecoration(
                          ctx: context,
                          labelText: context.tr('register.pseudo'),
                          isRequired: false,
                          icon: Icons.account_circle_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        decoration: _customInputDecoration(
                          ctx: context,
                          labelText: context.tr('register.telephone'),
                          isRequired: false,
                          icon: Icons.phone_outlined,
                          errorText: touched['user_phone'] == true ? errors['user_phone'] : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upload Photo
                      Column(
                        children: [
                          if (photoBytes != null)
                            Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: MemoryImage(photoBytes!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      citizenPhoto = null;
                                      photoBytes = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, color: Color(0xFF16A34A), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('register.photo'),
                                      style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF374151), fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (errors['citizen_photo'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(errors['citizen_photo']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF098E00), Color(0xFF056500)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF098E00).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading ? null : handleSubmit,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('register.btn_creer'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('register.deja_compte'), style: TextStyle(color: subtitleColor, fontSize: 14)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.go('/auth/login'),
                        child: Text(
                          context.tr('register.se_connecter'),
                          style: const TextStyle(color: Color(0xFF098E00), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              for (String fb in fallbacks) {
                return Image.asset(
                  fb,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}