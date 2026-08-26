import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/l10n/app_localization.dart';
import 'package:itantsoroka/services/user_service.dart';
import 'package:itantsoroka/services/citizens_service.dart';

class UserPasswordManagementScreen extends StatefulWidget {
  const UserPasswordManagementScreen({super.key});

  @override
  State<UserPasswordManagementScreen> createState() =>
      _UserPasswordManagementScreenState();
}

class _UserPasswordManagementScreenState
    extends State<UserPasswordManagementScreen> with TickerProviderStateMixin {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  Map<String, dynamic>? selectedUser;

  String newPassword = '';
  String confirmPassword = '';
  bool showPassword = false;
  bool showConfirmPassword = false;

  bool loading = false;
  bool loadingUsers = true;
  bool _showFormPanel = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim =
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    loadUsers();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() => loadingUsers = true);
    try {
      List<Map<String, dynamic>>? data =
          await UserService.getAllUsersByApplicationRole();

      if (data == null || data.isEmpty) {
        final response =
            await http.get(Uri.parse('${ApiConstants.serviceAuth}/users'));
        if (response.statusCode == 200) {
          final resBody = json.decode(response.body);
          List<dynamic> rawUsers =
              resBody is List ? resBody : resBody['data'] ?? [];
          data = await UserService.enrichUsersWithCitizens(rawUsers);
        }
      }

      if (data != null && data.isNotEmpty) {
        final usersWithCitizen =
            data.where((u) => u['citoyen'] != null).toList();
        final listToUse =
            usersWithCitizen.isNotEmpty ? usersWithCitizen : data;
        setState(() {
          users = listToUse;
          filteredUsers = listToUse;
        });
      }
    } catch (e) {
      _showAlert('Erreur lors du chargement des utilisateurs', AdminTheme.danger);
    } finally {
      if (mounted) setState(() => loadingUsers = false);
    }
  }

  void filterUsers(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredUsers = users;
      } else {
        final q = query.toLowerCase();
        filteredUsers = users.where((u) {
          final userObj = u['user'] is Map ? u['user'] : u;
          final citoyenObj = u['citoyen'] is Map ? u['citoyen'] : null;
          final pseudo = (userObj['user_pseudo'] ?? '').toString().toLowerCase();
          final email = (userObj['user_email'] ?? '').toString().toLowerCase();
          final cin =
              (citoyenObj?['citizen_cin'] ?? '').toString().toLowerCase();
          final firstName =
              (citoyenObj?['citizen_first_name'] ?? citoyenObj?['citizen_name'] ?? '')
                  .toString()
                  .toLowerCase();
          final lastName =
              (citoyenObj?['citizen_last_name'] ?? citoyenObj?['citizen_lastname'] ?? '')
                  .toString()
                  .toLowerCase();
          return pseudo.contains(q) ||
              email.contains(q) ||
              cin.contains(q) ||
              firstName.contains(q) ||
              lastName.contains(q);
        }).toList();
      }
    });
  }

  Map<String, dynamic> validatePassword(String password) {
    if (password.length < 8) {
      return {'valid': false, 'message': 'Au moins 8 caractères requis'};
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return {'valid': false, 'message': 'Au moins une majuscule requise'};
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return {'valid': false, 'message': 'Au moins une minuscule requise'};
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return {'valid': false, 'message': 'Au moins un chiffre requis'};
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return {'valid': false, 'message': 'Un caractère spécial requis'};
    }
    return {'valid': true};
  }

  double _passwordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double score = 0.0;
    if (password.length >= 8) score += 0.2;
    if (password.length >= 12) score += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.15;
    return math.min(score, 1.0);
  }

  Color _strengthColor(double strength) {
    if (strength < 0.4) return AdminTheme.danger;
    if (strength < 0.7) return AdminTheme.warning;
    return AdminTheme.primaryLight;
  }

  String _strengthLabel(double strength) {
    if (strength < 0.4) return 'Faible';
    if (strength < 0.7) return 'Moyen';
    return 'Fort';
  }

  Future<void> handleResetPassword() async {
    if (selectedUser == null) {
      _showAlert('Veuillez sélectionner un utilisateur', AdminTheme.danger);
      return;
    }
    if (newPassword != confirmPassword) {
      _showAlert('Les mots de passe ne correspondent pas', AdminTheme.danger);
      return;
    }
    final validation = validatePassword(newPassword);
    if (validation['valid'] == false) {
      _showAlert(
          validation['message'] ?? 'Mot de passe invalide', AdminTheme.danger);
      return;
    }

    setState(() => loading = true);
    try {
      final userObj =
          selectedUser!['user'] is Map ? selectedUser!['user'] : selectedUser!;
      final keycloakId = userObj['user_keycloak_id'] ??
          userObj['keycloak_id'] ??
          userObj['id'];
      if (keycloakId == null) {
        throw Exception('ID Keycloak non trouvé');
      }

      final response = await http.post(
        Uri.parse(
            '${ApiConstants.serviceAuth}/users/change-password/$keycloakId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'password': newPassword}),
      );

      if (response.statusCode == 200) {
        final pseudo = userObj['user_pseudo'] ?? userObj['pseudo'] ?? '';
        _showAlert(
            'Mot de passe de $pseudo réinitialisé avec succès !',
            AdminTheme.primaryLight);
        setState(() {
          selectedUser = null;
          newPassword = '';
          confirmPassword = '';
          showPassword = false;
          showConfirmPassword = false;
          _showFormPanel = false;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erreur lors de la réinitialisation');
      }
    } catch (e) {
      _showAlert(e.toString().replaceAll('Exception: ', ''), AdminTheme.danger);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showAlert(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AdminTheme.danger
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, isMobile),
            Expanded(
              child: isMobile
                  ? _buildMobileLayout(isDark)
                  : _buildDesktopLayout(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── En-tête ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AdminTheme.horizontalPadding(context), vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0E7490), Color(0xFF06B6D4)]),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('pwd_gestion_titre'),
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AdminTheme.textPrimaryDark
                        : AdminTheme.textPrimary,
                  ),
                ),
                Text(
                  context.tr('pwd_gestion_sous_titre'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AdminTheme.textSecondaryDark
                        : AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: isDark
                    ? AdminTheme.textSecondaryDark
                    : AdminTheme.textSecondary,
                size: 20),
            onPressed: loadUsers,
            tooltip: context.tr('actualiser'),
          ),
        ],
      ),
    );
  }

  // ── Mobile ────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(bool isDark) {
    if (_showFormPanel && selectedUser != null) {
      return SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Barre retour
              InkWell(
                onTap: () => setState(() {
                  _showFormPanel = false;
                  selectedUser = null;
                  _slideCtrl.reverse();
                }),
                child: Container(
                  color: isDark ? AdminTheme.surface2Dark : AdminTheme.dividerLight,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_rounded,
                          size: 18, color: Color(0xFF374151)),
                      const SizedBox(width: 8),
                      Text(
                        'Choisir un autre utilisateur',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark
                              ? AdminTheme.textSecondaryDark
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildResetForm(isDark),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchField(isDark),
        Expanded(child: _buildUserList(isDark: true, isMobile: true)),
      ],
    );
  }

  // ── Desktop ───────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panneau gauche : liste
        SizedBox(
          width: 380,
          child: Column(
            children: [
              _buildSearchField(isDark),
              Divider(
                  height: 1,
                  color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
              Expanded(child: _buildUserList(isDark: isDark, isMobile: false)),
            ],
          ),
        ),
        VerticalDivider(
            width: 1,
            color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
        // Panneau droit : formulaire
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: _buildResetForm(isDark),
          ),
        ),
      ],
    );
  }

  // ── Champ recherche ───────────────────────────────────────────────────────

  Widget _buildSearchField(bool isDark) {
    return Container(
      color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: filterUsers,
        style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AdminTheme.textPrimaryDark
                : AdminTheme.textPrimary),
        decoration: InputDecoration(
          hintText: context.tr('user_rechercher_hint'),
          hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted),
          prefixIcon: Icon(Icons.search_rounded,
              color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
              size: 20),
          filled: true,
          fillColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              borderSide: BorderSide(
                  color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              borderSide: BorderSide(
                  color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              borderSide:
                  const BorderSide(color: AdminTheme.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ── Liste utilisateurs ────────────────────────────────────────────────────

  Widget _buildUserList({required bool isDark, required bool isMobile}) {
    if (loadingUsers) {
      return Center(
          child: CircularProgressIndicator(color: AdminTheme.primary));
    }
    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          context.tr('user_aucun_trouve'),
          style: TextStyle(
              color:
                  isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(8, 8, 8, isMobile ? 100 : 8),
      itemCount: filteredUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = filteredUsers[index];
        final userObj = item['user'] is Map ? item['user'] : item;
        final citoyenObj = item['citoyen'] is Map
            ? item['citoyen'] as Map<String, dynamic>
            : null;

        final userId =
            userObj['user_id'] ?? userObj['id'] ?? userObj['id_user'];
        final selectedUserId = selectedUser?['user']?['user_id'] ??
            selectedUser?['user']?['id'] ??
            selectedUser?['user_id'] ??
            selectedUser?['id'];
        final isSelected = selectedUserId != null &&
            selectedUserId.toString() == userId.toString();

        final firstName = (citoyenObj?['citizen_first_name'] ??
                citoyenObj?['citizen_name'] ??
                userObj['user_first_name'] ??
                '')
            .toString();
        final lastName = (citoyenObj?['citizen_last_name'] ??
                citoyenObj?['citizen_lastname'] ??
                '')
            .toString();
        final pseudo =
            (userObj['user_pseudo'] ?? userObj['pseudo'] ?? '').toString();
        final email =
            (userObj['user_email'] ?? userObj['email'] ?? '').toString();
        final cin = (citoyenObj?['citizen_cin'] ??
                citoyenObj?['citizen_national_card_number'] ??
                '')
            .toString();
        final photo = citoyenObj?['citizen_photo']?.toString();
        final avatarUrl = CitizensService.getCitizenAvatarPreview(photo);
        final displayName =
            '$firstName $lastName'.trim().isNotEmpty
                ? '$firstName $lastName'.trim()
                : pseudo;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isSelected
                ? AdminTheme.primary.withValues(alpha: 0.07)
                : (isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight),
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AdminTheme.primary.withValues(alpha: 0.5)
                  : (isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedUser = item;
                newPassword = '';
                confirmPassword = '';
                if (isMobile) {
                  _showFormPanel = true;
                  _slideCtrl.forward(from: 0);
                }
              });
            },
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _UserAvatar(url: avatarUrl, name: firstName.isNotEmpty ? firstName : pseudo, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? AdminTheme.textPrimaryDark
                                : AdminTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cin.isNotEmpty)
                          Text(
                            'CIN: $cin',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AdminTheme.textMutedDark
                                  : AdminTheme.textMuted,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AdminTheme.textSecondaryDark
                                  : AdminTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AdminTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    )
                  else if (isMobile)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AdminTheme.textMutedDark
                          : AdminTheme.textMuted,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Formulaire ────────────────────────────────────────────────────────────

  Widget _buildResetForm(bool isDark) {
    if (selectedUser == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AdminTheme.surfaceDark
                    : AdminTheme.dividerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.key_rounded,
                size: 36,
                color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('pwd_selectionner'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color:
                    isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('pwd_choisir_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AdminTheme.textSecondaryDark
                    : AdminTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final userObj = selectedUser!['user'] is Map
        ? selectedUser!['user']
        : selectedUser!;
    final citoyenObj =
        selectedUser?['citoyen'] is Map ? selectedUser!['citoyen'] : null;
    final selFirstName = (citoyenObj?['citizen_first_name'] ??
            citoyenObj?['citizen_name'] ??
            userObj['user_first_name'] ??
            '')
        .toString();
    final selPseudo =
        (userObj['user_pseudo'] ?? userObj['pseudo'] ?? '').toString();
    final selEmail =
        (userObj['user_email'] ?? userObj['email'] ?? '').toString();
    final selCin = (citoyenObj?['citizen_cin'] ??
            citoyenObj?['citizen_national_card_number'] ??
            '')
        .toString();
    final photo = citoyenObj?['citizen_photo']?.toString();
    final avatarUrl = CitizensService.getCitizenAvatarPreview(photo);

    final strength = _passwordStrength(newPassword);
    final strengthColor = _strengthColor(strength);
    final passwordsMatch =
        confirmPassword.isNotEmpty && newPassword == confirmPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Utilisateur sélectionné ────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdminTheme.primary.withValues(alpha: 0.05),
            border: Border.all(
                color: AdminTheme.primary.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          ),
          child: Row(
            children: [
              _UserAvatar(
                  url: avatarUrl,
                  name: selFirstName.isNotEmpty ? selFirstName : selPseudo,
                  size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selPseudo.isNotEmpty ? selPseudo : selFirstName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? AdminTheme.textPrimaryDark
                            : AdminTheme.textPrimary,
                      ),
                    ),
                    if (selCin.isNotEmpty)
                      Text('CIN: $selCin',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AdminTheme.textMutedDark
                                : AdminTheme.textMuted,
                            fontFamily: 'monospace',
                          )),
                    Text(
                      selEmail,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AdminTheme.textSecondaryDark
                              : AdminTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AdminTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Nouveau mot de passe ───────────────────────────────────
        Text(context.tr('pwd_nouveau'),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AdminTheme.textPrimaryDark
                    : AdminTheme.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          obscureText: !showPassword,
          onChanged: (val) => setState(() => newPassword = val),
          style: TextStyle(
              color: isDark
                  ? AdminTheme.textPrimaryDark
                  : AdminTheme.textPrimary),
          decoration: _inputDecoration(
            isDark: isDark,
            hint: context.tr('pwd_hint_nouveau'),
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                  showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                  color: isDark
                      ? AdminTheme.textMutedDark
                      : AdminTheme.textMuted),
              onPressed: () => setState(() => showPassword = !showPassword),
            ),
          ),
        ),

        // Indicateur de force
        if (newPassword.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    backgroundColor: isDark
                        ? AdminTheme.surface2Dark
                        : AdminTheme.dividerLight,
                    valueColor: AlwaysStoppedAnimation(strengthColor),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _strengthLabel(strength),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // ── Confirmer mot de passe ────────────────────────────────
        Text(context.tr('pwd_confirmer'),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AdminTheme.textPrimaryDark
                    : AdminTheme.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          obscureText: !showConfirmPassword,
          onChanged: (val) => setState(() => confirmPassword = val),
          style: TextStyle(
              color: isDark
                  ? AdminTheme.textPrimaryDark
                  : AdminTheme.textPrimary),
          decoration: _inputDecoration(
            isDark: isDark,
            hint: context.tr('pwd_hint_confirmer'),
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                  showConfirmPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                  color: isDark
                      ? AdminTheme.textMutedDark
                      : AdminTheme.textMuted),
              onPressed: () =>
                  setState(() => showConfirmPassword = !showConfirmPassword),
            ),
            hasError: confirmPassword.isNotEmpty && !passwordsMatch,
            hasSuccess: passwordsMatch,
          ),
        ),
        if (confirmPassword.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  passwordsMatch
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 14,
                  color: passwordsMatch
                      ? AdminTheme.primaryLight
                      : AdminTheme.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  passwordsMatch
                      ? context.tr('pwd_correspond')
                      : context.tr('pwd_ne_correspond_pas'),
                  style: TextStyle(
                    fontSize: 12,
                    color: passwordsMatch
                        ? AdminTheme.primaryLight
                        : AdminTheme.danger,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // ── Exigences ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AdminTheme.surfaceDark : AdminTheme.bgLight,
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            border: Border.all(
                color:
                    isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('pwd_exigences'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AdminTheme.textSecondaryDark
                        : AdminTheme.textSecondary,
                  )),
              const SizedBox(height: 8),
              ..._requirements(newPassword),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Boutons ───────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AdminTheme.radiusSm)),
                ),
                onPressed: () => setState(() {
                  selectedUser = null;
                  newPassword = '';
                  confirmPassword = '';
                  showPassword = false;
                  showConfirmPassword = false;
                  _showFormPanel = false;
                }),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(context.tr('annuler'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AdminTheme.radiusSm)),
                  elevation: 0,
                ),
                onPressed: loading ? null : handleResetPassword,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.lock_reset_rounded, size: 16),
                label: Text(
                  loading ? context.tr('traitement') : context.tr('pwd_reinitialiser'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
    bool hasError = false,
    bool hasSuccess = false,
  }) {
    final borderColor = hasError
        ? AdminTheme.danger
        : hasSuccess
            ? AdminTheme.primaryLight
            : (isDark ? AdminTheme.borderDark : AdminTheme.borderLight);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted),
      prefixIcon: Icon(prefixIcon, size: 18,
          color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          borderSide: BorderSide(
              color: hasError ? AdminTheme.danger : AdminTheme.primary,
              width: 1.5)),
    );
  }

  List<Widget> _requirements(String pwd) {
    final checks = [
      {'label': 'Au moins 8 caractères', 'met': pwd.length >= 8},
      {'label': 'Une lettre majuscule (A-Z)', 'met': RegExp(r'[A-Z]').hasMatch(pwd)},
      {'label': 'Une lettre minuscule (a-z)', 'met': RegExp(r'[a-z]').hasMatch(pwd)},
      {'label': 'Un chiffre (0-9)', 'met': RegExp(r'[0-9]').hasMatch(pwd)},
      {'label': 'Un caractère spécial (!@#\$%)', 'met': RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pwd)},
    ];
    return checks.map((c) {
      final met = c['met'] as bool;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: met ? AdminTheme.primaryLight : AdminTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              c['label'] as String,
              style: TextStyle(
                fontSize: 11.5,
                color: met ? AdminTheme.primaryLight : AdminTheme.textMuted,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR WIDGET LOCAL
// ─────────────────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  const _UserAvatar({required this.url, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(initial),
        ),
      );
    }
    return _fallback(initial);
  }

  Widget _fallback(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF0E7490), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}