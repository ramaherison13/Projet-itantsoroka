import 'package:flutter/material.dart';
import 'package:itantsoroka/services/auth_service.dart';
import 'package:itantsoroka/services/territory_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CompleteCitizenRegistrationScreen
/// Affiché quand le flux SSO renvoie needsCitizenForm = true (HTTP 400).
/// Source : documentation guide-frontend-sso — Section 4.3
/// ─────────────────────────────────────────────────────────────────────────────
class CompleteCitizenRegistrationScreen extends StatefulWidget {
  final String ssoToken;

  const CompleteCitizenRegistrationScreen({
    super.key,
    required this.ssoToken,
  });

  @override
  State<CompleteCitizenRegistrationScreen> createState() =>
      _CompleteCitizenRegistrationScreenState();
}

class _CompleteCitizenRegistrationScreenState
    extends State<CompleteCitizenRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cinController           = TextEditingController();
  final _workController          = TextEditingController();
  final _phoneController         = TextEditingController();
  final _addressController       = TextEditingController();
  final _priseServiceController  = TextEditingController();
  final _cardLocationController  = TextEditingController();
  final _cardDateController      = TextEditingController();

  List<dynamic> _communes     = [];
  List<dynamic> _fokotanys    = [];
  dynamic _selectedCommune;
  dynamic _selectedFokotany;

  bool _loadingCommunes  = true;
  bool _loadingFokotanys = false;
  bool _submitting       = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadCommunes();
  }

  @override
  void dispose() {
    _cinController.dispose();
    _workController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _priseServiceController.dispose();
    _cardLocationController.dispose();
    _cardDateController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunes() async {
    try {
      final data = await TerritoryService.getAllCommunes();
      if (mounted) setState(() { _communes = data ?? []; _loadingCommunes = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCommunes = false);
    }
  }

  Future<void> _onCommuneSelected(dynamic commune) async {
    setState(() {
      _selectedCommune  = commune;
      _selectedFokotany = null;
      _fokotanys        = [];
      _loadingFokotanys = true;
    });

    final formattedId = commune?['formatted_id']?.toString() ??
        commune?['municipality_id']?.toString() ??
        commune?['id']?.toString() ?? '';

    if (formattedId.isEmpty) {
      setState(() => _loadingFokotanys = false);
      return;
    }

    try {
      final data = await TerritoryService.getFokotanysByCommune(formattedId);
      if (mounted) setState(() { _fokotanys = data ?? []; _loadingFokotanys = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingFokotanys = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCommune == null || _selectedFokotany == null) {
      setState(() => _errorMsg = 'Veuillez sélectionner une commune et un fokontany.');
      return;
    }
    if (_cinController.text.trim().length != 12) {
      setState(() => _errorMsg = 'Le numéro CIN doit comporter 12 chiffres.');
      return;
    }

    setState(() { _submitting = true; _errorMsg = null; });

    final communeId = _selectedCommune?['formatted_id']?.toString() ??
        _selectedCommune?['municipality_id']?.toString() ??
        _selectedCommune?['id']?.toString() ?? '';

    final fokotanyId = _selectedFokotany?['formatted_id']?.toString() ??
        _selectedFokotany?['fokotany_formatted_id']?.toString() ??
        _selectedFokotany?['id']?.toString() ?? '';

    final citizenData = <String, dynamic>{
      'citizen_national_card_number': _cinController.text.trim(),
      'municipality_id'             : communeId,
      'fokotany_formatted_id'       : fokotanyId,
    };

    // Champs optionnels
    if (_workController.text.trim().isNotEmpty) {
      citizenData['citizen_work'] = _workController.text.trim();
    }
    if (_priseServiceController.text.trim().isNotEmpty) {
      citizenData['citizen_prise_service'] = _priseServiceController.text.trim();
    }
    if (_addressController.text.trim().isNotEmpty) {
      citizenData['citizen_adress'] = _addressController.text.trim();
    }
    if (_cardLocationController.text.trim().isNotEmpty) {
      citizenData['citizen_national_card_location'] = _cardLocationController.text.trim();
    }
    if (_cardDateController.text.trim().isNotEmpty) {
      citizenData['citizen_national_card_date'] = _cardDateController.text.trim();
    }
    if (_phoneController.text.trim().isNotEmpty) {
      citizenData['user_phone'] = _phoneController.text.trim();
    }

    try {
      final result = await AuthService.completeCitizenRegistration(
        widget.ssoToken,
        citizenData,
      );
      if (!mounted) return;
      if (result.loggedIn && result.data != null) {
        Navigator.of(context).pop(result.data);
      } else {
        setState(() {
          _submitting = false;
          _errorMsg   = "Échec de l'inscription. Veuillez réessayer.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMsg   = e.toString();
        });
      }
    }
  }

  String _communeName(dynamic c) =>
      c?['commune_name']?.toString() ??
      c?['name']?.toString() ??
      c?['nom']?.toString() ?? '';

  String _fokotanyName(dynamic f) =>
      f?['fokotany_name']?.toString() ??
      f?['name']?.toString() ??
      f?['nom']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor  = isDark ? Colors.white : const Color(0xFF1F2937);
    final Color subColor   = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final Color fillColor  = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final Color borderC    = isDark ? const Color(0xFF334155) : Colors.grey.shade300;

    InputDecoration inputDecor({required String label, required IconData icon, bool required = true}) {
      return InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(fontSize: 13, color: subColor),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF16A34A)),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border           : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
        enabledBorder    : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
        focusedBorder    : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2)),
        errorBorder      : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Compléter votre profil citoyen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF16A34A), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Authentification SSO réussie. Veuillez renseigner vos informations citoyennes pour finaliser votre inscription.',
                          style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Message d'erreur
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── CIN (Obligatoire) ─────────────────────────────
                        _sectionTitle('Informations obligatoires', textColor),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cinController,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: inputDecor(
                              label: 'N° CIN (12 chiffres)', icon: Icons.credit_card_rounded),
                          validator: (v) => (v == null || v.trim().length != 12)
                              ? 'Le CIN doit comporter exactement 12 chiffres'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Commune ───────────────────────────────────────
                        _loadingCommunes
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<dynamic>(
                                initialValue: _selectedCommune,
                                decoration: inputDecor(
                                    label: 'Commune', icon: Icons.location_city_rounded),
                                style: TextStyle(fontSize: 14, color: textColor),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: _communes.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text(_communeName(c),
                                        style: TextStyle(fontSize: 13, color: textColor)),
                                  );
                                }).toList(),
                                onChanged: (val) => _onCommuneSelected(val),
                                validator: (v) => v == null ? 'Sélectionnez une commune' : null,
                              ),
                        const SizedBox(height: 16),

                        // ── Fokontany ─────────────────────────────────────
                        _loadingFokotanys
                            ? const Center(child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: CircularProgressIndicator(),
                              ))
                            : DropdownButtonFormField<dynamic>(
                                initialValue: _selectedFokotany,
                                decoration: inputDecor(
                                    label: 'Fokontany', icon: Icons.map_rounded),
                                style: TextStyle(fontSize: 14, color: textColor),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                disabledHint: Text(
                                  _selectedCommune == null
                                      ? 'Sélectionnez d\'abord une commune'
                                      : 'Aucun fokontany disponible',
                                  style: TextStyle(fontSize: 13, color: subColor),
                                ),
                                items: _fokotanys.isEmpty
                                    ? null
                                    : _fokotanys.map((f) {
                                        return DropdownMenuItem(
                                          value: f,
                                          child: Text(_fokotanyName(f),
                                              style: TextStyle(fontSize: 13, color: textColor)),
                                        );
                                      }).toList(),
                                onChanged: _fokotanys.isEmpty
                                    ? null
                                    : (val) => setState(() => _selectedFokotany = val),
                                validator: (v) => v == null ? 'Sélectionnez un fokontany' : null,
                              ),
                        const SizedBox(height: 28),

                        // ── Champs optionnels ─────────────────────────────
                        _sectionTitle('Informations complémentaires (optionnelles)', textColor),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _workController,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: inputDecor(
                              label: 'Fonction / Profession',
                              icon: Icons.work_outline_rounded,
                              required: false),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: inputDecor(
                              label: 'Téléphone',
                              icon: Icons.phone_outlined,
                              required: false),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _addressController,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: inputDecor(
                              label: 'Adresse physique',
                              icon: Icons.home_outlined,
                              required: false),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _cardLocationController,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: inputDecor(
                              label: 'Lieu de délivrance du CIN',
                              icon: Icons.place_outlined,
                              required: false),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _cardDateController,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: inputDecor(
                              label: 'Date de délivrance du CIN',
                              icon: Icons.calendar_today_outlined,
                              required: false),
                        ),
                        const SizedBox(height: 32),

                        // ── Bouton soumettre ──────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Finalisation en cours...',
                                          style: TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 20),
                                      SizedBox(width: 10),
                                      Text("Finaliser l'inscription",
                                          style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Annuler
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: Text(
                              'Annuler',
                              style: TextStyle(fontSize: 14, color: subColor),
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
      ),
    );
  }

  Widget _sectionTitle(String title, Color textColor) {
    return Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(2),
      )),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
    ]);
  }
}
