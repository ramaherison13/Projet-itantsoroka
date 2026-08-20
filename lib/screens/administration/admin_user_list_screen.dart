import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/core/admin_theme.dart';
import 'package:itantsoroka/services/user_service.dart';
import 'package:itantsoroka/services/citizens_service.dart';
import 'package:itantsoroka/services/role_service.dart';
import 'package:itantsoroka/widgets/administration/role_assignation_form_widget.dart';
import 'package:itantsoroka/widgets/administration/user_card_profile_widget.dart';
import 'package:itantsoroka/widgets/administration/user_creation_form_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN LISTE DES UTILISATEURS ADMIN
// Affiche : photo, nom/prénom, CIN, numéro, adresse, email, rôle
// ─────────────────────────────────────────────────────────────────────────────

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen>
    with TickerProviderStateMixin {
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  static const int _pageSize = 10;
  String _searchQuery = '';
  String _roleFilter = 'Tous';
  Map<String, dynamic>? _selectedUser;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll - currentScroll <= 200) {
        if (!_loadingMore && _currentPage < _totalPages) {
          _loadMoreUsers();
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _currentPage = 1;
    });
    _fadeController.reset();
    try {
      final pagedData = await UserService.getAllUsersByApplicationRole2Paged(
        page: 1,
        limit: _pageSize,
        search: _searchQuery,
      );

      if (pagedData != null) {
        final List<dynamic> fetchedUsers = pagedData['data'] ?? [];
        final total = pagedData['total'] ?? fetchedUsers.length;
        final totalP = pagedData['numberOfPages'] ?? 1;

        if (mounted) {
          setState(() {
            _users = List.from(fetchedUsers);
            _totalCount = total;
            _totalPages = totalP;
            _filtered = List.from(fetchedUsers);
          });
          _applyFilters();
          _fadeController.forward();
        }
      } else {
        List<Map<String, dynamic>>? data =
            await UserService.getAllUsersByApplicationRole();

        if (data == null || data.isEmpty) {
          final response =
              await http.get(Uri.parse('${ApiConstants.serviceAuth}/users?limit=1000'));
          if (response.statusCode == 200) {
            final resBody = json.decode(response.body);
            List<dynamic> rawUsers =
                resBody is List ? resBody : resBody['data'] ?? [];
            data = await UserService.enrichUsersWithCitizens(rawUsers);
          }
        }

        if (data != null && mounted) {
          setState(() {
            _users = data!;
            _totalCount = data.length;
            _totalPages = 1;
            _filtered = data;
          });
          _applyFilters();
          _fadeController.forward();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_loadingMore || _currentPage >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final pagedData = await UserService.getAllUsersByApplicationRole2Paged(
        page: nextPage,
        limit: _pageSize,
        search: _searchQuery,
      );

      if (pagedData != null && mounted) {
        final List<dynamic> newUsers = pagedData['data'] ?? [];
        final total = pagedData['total'] ?? _totalCount;
        final totalP = pagedData['numberOfPages'] ?? _totalPages;

        setState(() {
          _users.addAll(newUsers);
          _currentPage = nextPage;
          _totalCount = total;
          _totalPages = totalP;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs supplémentaires: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        final userObj = u['user'] is Map ? u['user'] : u;
        final citoyenObj = u['citoyen'] is Map ? u['citoyen'] : null;

        final pseudo = (userObj['user_pseudo'] ?? '').toString().toLowerCase();
        final email = (userObj['user_email'] ?? '').toString().toLowerCase();
        final cin =
            (citoyenObj?['citizen_cin'] ?? citoyenObj?['citizen_national_card_number'] ?? '')
                .toString()
                .toLowerCase();
        final firstName =
            (citoyenObj?['citizen_first_name'] ?? citoyenObj?['citizen_name'] ?? '')
                .toString()
                .toLowerCase();
        final lastName =
            (citoyenObj?['citizen_last_name'] ?? citoyenObj?['citizen_lastname'] ?? '')
                .toString()
                .toLowerCase();
        final phone = (userObj['user_phone'] ?? '').toString().toLowerCase();

        final matchSearch = q.isEmpty ||
            pseudo.contains(q) ||
            email.contains(q) ||
            cin.contains(q) ||
            firstName.contains(q) ||
            lastName.contains(q) ||
            phone.contains(q);

        final roles = _getUserRoles(u);
        final matchRole = _roleFilter == 'Tous' ||
            roles.any((r) => r.toString().toLowerCase().contains(
                  _roleFilter.toLowerCase(),
                ));

        return matchSearch && matchRole;
      }).toList();
    });
  }

  List<String> _getUserRoles(dynamic u) {
    final userObj = u['user'] is Map ? u['user'] : u;
    final appUserRoles = userObj['appUserRoles'] as List? ?? [];
    return appUserRoles
        .map<String>((r) =>
            r['role']?['role_name']?.toString() ??
            r['role_slug']?.toString() ??
            '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _getUniqueRoles() {
    final Set<String> roles = {'Tous'};
    for (final u in _users) {
      roles.addAll(_getUserRoles(u));
    }
    return roles.toList();
  }

  void _openCreateUserModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const UserCreationFormWidget(),
    ).then((result) {
      if (result == true) {
        _loadUsers();
      }
    });
  }

  void _openRoleModal(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => RoleAssignationFormWidget(
        data: user,
        onClick: () {
          Navigator.of(ctx).pop();
          _loadUsers();
        },
        fetchAllRoles: () async {
          final res = await RoleService.getAllRoles();
          if (res is Map<String, dynamic>) return res;
          return {'roles': res ?? []};
        },
        assignRoles: (uId, rIds) async {
          await RoleService.assignRoleToAnUser(uId.toString(), rIds);
        },
        removeRoles: (uId, rIds) async {
          await RoleService.removeRoleToAnUser(uId.toString(), rIds);
        },
        userCardProfileWidget: UserCardProfile(
          data: user,
          apiBaseUrl: ApiConstants.gatewayBaseUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool isMobile = context.isMobile;
    final bool isTablet = context.isTablet;
    final double hPad = AdminTheme.horizontalPadding(context);

    return Scaffold(
      backgroundColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête ──────────────────────────────────────────────
            _buildHeader(isDark, isMobile),

            // ── Barre de recherche & Filtres ─────────────────────────
            _buildSearchBar(isDark, isMobile, hPad),

            // ── Résultat count ────────────────────────────────────────
            if (!_loading)
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${_filtered.length} utilisateur${_filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AdminTheme.textSecondaryDark
                            : AdminTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Contenu ───────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? _buildSkeletons(isDark, hPad)
                  : _filtered.isEmpty
                      ? _buildEmpty(isDark)
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: isMobile
                              ? _buildMobileList(isDark, hPad)
                              : isTablet
                                  ? _buildTabletGrid(isDark, hPad)
                                  : _buildDesktopTable(isDark, hPad),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── En-tête ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AdminTheme.horizontalPadding(context), vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
        border: Border(
            bottom: BorderSide(
                color:
                    isDark ? AdminTheme.borderDark : AdminTheme.borderLight)),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)]),
              borderRadius:
                  BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: const Icon(Icons.people_alt_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),

          // Titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Utilisateurs',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AdminTheme.textPrimaryDark
                        : AdminTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_users.length} compte${_users.length != 1 ? 's' : ''} enregistré${_users.length != 1 ? 's' : ''}',
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

          // Boutons
          Row(
            children: [
              // Actualiser
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: isDark
                        ? AdminTheme.textSecondaryDark
                        : AdminTheme.textSecondary,
                    size: 20),
                onPressed: _loadUsers,
                tooltip: 'Actualiser',
              ),
              const SizedBox(width: 4),
              // Créer utilisateur
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AdminTheme.radiusSm)),
                ),
                onPressed: _openCreateUserModal,
                icon: const Icon(Icons.person_add_rounded, size: 17),
                label: isMobile
                    ? const SizedBox.shrink()
                    : const Text('Créer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Barre de recherche ────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark, bool isMobile, double hPad) {
    final uniqueRoles = _getUniqueRoles();

    return Container(
      color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
      child: Column(
        children: [
          // Champ de recherche
          TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
            style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AdminTheme.textPrimaryDark
                    : AdminTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email, CIN...',
              hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AdminTheme.textMutedDark
                      : AdminTheme.textMuted),
              prefixIcon: Icon(Icons.search_rounded,
                  color: isDark
                      ? AdminTheme.textMutedDark
                      : AdminTheme.textMuted,
                  size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AdminTheme.textMutedDark
                              : AdminTheme.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? AdminTheme.bgDark
                  : AdminTheme.bgLight,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AdminTheme.radiusSm),
                borderSide: BorderSide(
                    color: isDark
                        ? AdminTheme.borderDark
                        : AdminTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AdminTheme.radiusSm),
                borderSide: BorderSide(
                    color: isDark
                        ? AdminTheme.borderDark
                        : AdminTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AdminTheme.radiusSm),
                borderSide: const BorderSide(
                    color: AdminTheme.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
            ),
          ),

          // Filtres par rôle (chips horizontaux)
          if (uniqueRoles.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: uniqueRoles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final role = uniqueRoles[i];
                  final isSelected = _roleFilter == role;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: FilterChip(
                      label: Text(
                        role,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AdminTheme.textSecondaryDark
                                  : AdminTheme.textSecondary),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _roleFilter = role);
                        _applyFilters();
                      },
                      backgroundColor: isDark
                          ? AdminTheme.bgDark
                          : AdminTheme.bgLight,
                      selectedColor: AdminTheme.primary,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                          color: isSelected
                              ? AdminTheme.primary
                              : (isDark
                                  ? AdminTheme.borderDark
                                  : AdminTheme.borderLight)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mobile : cartes avec défilement infini ───────────────────────────────

  Widget _buildMobileList(bool isDark, double hPad) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 80),
      itemCount: _filtered.length + 1,
      itemBuilder: (context, i) {
        if (i == _filtered.length) {
          return _buildInfiniteScrollFooter(isDark);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _UserCard(
            userData: _filtered[i],
            isDark: isDark,
            isMobile: true,
            onRoleAssign: () => _openRoleModal(_filtered[i]),
          ),
        );
      },
    );
  }

  // ── Tablette : grille 2 colonnes ──────────────────────────────────────────

  Widget _buildTabletGrid(bool isDark, double hPad) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 80),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 200,
            ),
            itemCount: _filtered.length,
            itemBuilder: (context, i) =>
                _UserCard(userData: _filtered[i], isDark: isDark, isMobile: false,
                    onRoleAssign: () => _openRoleModal(_filtered[i])),
          ),
          _buildInfiniteScrollFooter(isDark),
        ],
      ),
    );
  }

  // ── Desktop : tableau ─────────────────────────────────────────────────────

  Widget _buildDesktopTable(bool isDark, double hPad) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 80),
      child: Column(
        children: [
          // En-tête du tableau
          _TableHeader(isDark: isDark),
          // Lignes
          ..._filtered.map((u) => _TableRow(
                userData: u,
                isDark: isDark,
                isSelected: _selectedUser != null &&
                    _selectedUser?['user']?['user_id'] ==
                        (u['user'] is Map ? u['user'] : u)['user_id'],
                onTap: () => setState(() => _selectedUser = u),
                onRoleAssign: () => _openRoleModal(u),
              )),
          _buildInfiniteScrollFooter(isDark),
        ],
      ),
    );
  }

  // ── Pied de page défilement infini ────────────────────────────────────────

  Widget _buildInfiniteScrollFooter(bool isDark) {
    if (_loadingMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AdminTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement automatique (${_users.length} / $_totalCount)...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AdminTheme.textSecondaryDark
                    : AdminTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_currentPage >= _totalPages && _totalCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          'Tous les utilisateurs sont chargés ($_totalCount au total)',
          style: TextStyle(
            fontSize: 11,
            color: (isDark
                    ? AdminTheme.textSecondaryDark
                    : AdminTheme.textSecondary)
                .withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return const SizedBox(height: 30);
  }

  // ── Squelette chargement ──────────────────────────────────────────────────

  Widget _buildSkeletons(bool isDark, double hPad) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 80),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => _SkeletonCard(isDark: isDark),
    );
  }

  // ── État vide ─────────────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 72,
            color: (isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted)
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat pour "$_searchQuery"'
                : 'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 15,
              color:
                  isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                _searchQuery = '';
                _applyFilters();
              },
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER CARD — Mobile & Tablette
// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends StatefulWidget {
  final dynamic userData;
  final bool isDark;
  final bool isMobile;
  final VoidCallback onRoleAssign;

  const _UserCard({
    required this.userData,
    required this.isDark,
    required this.isMobile,
    required this.onRoleAssign,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _hovered = false;

  List<String> _getUserRolesList(dynamic u) {
    final userObj = u['user'] is Map ? u['user'] : u;
    final appUserRoles = userObj['appUserRoles'] as List? ?? [];
    return appUserRoles
        .map<String>((r) =>
            r['role']?['role_name']?.toString() ??
            r['role_slug']?.toString() ??
            '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.userData;
    final userObj = u['user'] is Map ? u['user'] : u;
    final citoyenObj = u['citoyen'] is Map ? u['citoyen'] as Map<String, dynamic> : null;

    final firstName = (citoyenObj?['citizen_first_name'] ??
            citoyenObj?['citizen_name'] ??
            userObj['user_first_name'] ??
            '')
        .toString();
    final lastName = (citoyenObj?['citizen_last_name'] ??
            citoyenObj?['citizen_lastname'] ??
            '')
        .toString();
    final pseudo = (userObj['user_pseudo'] ?? '').toString();
    final email = (userObj['user_email'] ?? '').toString();
    final cin = (citoyenObj?['citizen_cin'] ??
            citoyenObj?['citizen_national_card_number'] ??
            '')
        .toString();
    final phone = (userObj['user_phone'] ?? '').toString();
    final address = (citoyenObj?['citizen_adress'] ??
            citoyenObj?['citizen_address'] ??
            '')
        .toString();
    final roles = _getUserRolesList(u);
    final fullName =
        '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : pseudo;

    final photo = citoyenObj?['citizen_photo']?.toString();
    final avatarUrl = CitizensService.getCitizenAvatarPreview(photo);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          border: Border.all(
            color: _hovered
                ? AdminTheme.primary.withValues(alpha: 0.35)
                : (widget.isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered ? AdminTheme.shadowMd : AdminTheme.shadowSm,
        ),
        child: widget.isMobile
            ? _mobileLayout(fullName, pseudo, email, cin, phone, address, roles, avatarUrl, firstName)
            : _gridLayout(fullName, pseudo, email, cin, phone, address, roles, avatarUrl, firstName),
      ),
    );
  }

  Widget _mobileLayout(String fullName, String pseudo, String email,
      String cin, String phone, String address, List<String> roles,
      String? avatarUrl, String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne principale : avatar + nom
        Row(
          children: [
            _Avatar(url: avatarUrl, name: firstName.isNotEmpty ? firstName : pseudo, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: widget.isDark
                          ? AdminTheme.textPrimaryDark
                          : AdminTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pseudo.isNotEmpty && pseudo != fullName)
                    Text(
                      '@$pseudo',
                      style: TextStyle(
                        fontSize: 11,
                        color: AdminTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Menu contextuel
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 20,
                  color: widget.isDark
                      ? AdminTheme.textSecondaryDark
                      : AdminTheme.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
              onSelected: (val) {
                if (val == 'roles') widget.onRoleAssign();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'roles',
                  child: Row(children: [
                    Icon(Icons.shield_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Gérer les rôles'),
                  ]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Infos en grille compacte
        _InfoGrid(
          items: [
            if (cin.isNotEmpty) _InfoItem(icon: Icons.badge_outlined, label: 'CIN', value: cin),
            if (email.isNotEmpty) _InfoItem(icon: Icons.email_outlined, label: 'Email', value: email),
            if (phone.isNotEmpty) _InfoItem(icon: Icons.phone_outlined, label: 'Tél.', value: phone),
            if (address.isNotEmpty) _InfoItem(icon: Icons.location_on_outlined, label: 'Adresse', value: address),
          ],
          isDark: widget.isDark,
        ),

        if (roles.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: roles
                .map((r) => AdminTheme.badge(r, _roleColor(r)))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _gridLayout(String fullName, String pseudo, String email,
      String cin, String phone, String address, List<String> roles,
      String? avatarUrl, String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + Nom
        Row(
          children: [
            _Avatar(url: avatarUrl, name: firstName.isNotEmpty ? firstName : pseudo, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: widget.isDark
                          ? AdminTheme.textPrimaryDark
                          : AdminTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark
                            ? AdminTheme.textSecondaryDark
                            : AdminTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),

        // Infos compactes
        if (cin.isNotEmpty) _CompactInfo(icon: Icons.badge_outlined, value: cin, isDark: widget.isDark),
        if (phone.isNotEmpty) _CompactInfo(icon: Icons.phone_outlined, value: phone, isDark: widget.isDark),
        if (address.isNotEmpty) _CompactInfo(icon: Icons.location_on_outlined, value: address, isDark: widget.isDark),

        const SizedBox(height: 8),

        // Rôles
        if (roles.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: roles
                .take(2)
                .map((r) => AdminTheme.badge(r, _roleColor(r)))
                .toList(),
          ),

        const Spacer(),
        // Bouton rôles
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onRoleAssign,
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTheme.primary,
              side: BorderSide(color: AdminTheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
            ),
            icon: const Icon(Icons.shield_outlined, size: 14),
            label: const Text('Rôles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Color _roleColor(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('super') || lower.contains('admin')) return AdminTheme.danger;
    if (lower.contains('chef')) return AdminTheme.purple;
    if (lower.contains('secretaire')) return AdminTheme.info;
    if (lower.contains('agent')) return AdminTheme.warning;
    return AdminTheme.primaryLight;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final bool isDark;
  const _TableHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AdminTheme.surface2Dark : AdminTheme.dividerLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AdminTheme.radiusSm)),
        border: Border.all(
            color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
      ),
      child: Row(
        children: const [
          SizedBox(width: 56), // Avatar
          SizedBox(width: 10),
          Expanded(flex: 2, child: _TH('Nom & Prénom')),
          Expanded(flex: 2, child: _TH('Email')),
          Expanded(flex: 1, child: _TH('CIN')),
          Expanded(flex: 1, child: _TH('Téléphone')),
          Expanded(flex: 2, child: _TH('Adresse')),
          Expanded(flex: 1, child: _TH('Rôle(s)')),
          SizedBox(width: 40), // Actions
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  const _TH(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final dynamic userData;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRoleAssign;

  const _TableRow({
    required this.userData,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.onRoleAssign,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  List<String> _getRoles(dynamic u) {
    final userObj = u['user'] is Map ? u['user'] : u;
    final appUserRoles = userObj['appUserRoles'] as List? ?? [];
    return appUserRoles
        .map<String>((r) =>
            r['role']?['role_name']?.toString() ??
            r['role_slug']?.toString() ??
            '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Color _roleColor(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('super') || lower.contains('admin')) return AdminTheme.danger;
    if (lower.contains('chef')) return AdminTheme.purple;
    if (lower.contains('secretaire')) return AdminTheme.info;
    return AdminTheme.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.userData;
    final userObj = u['user'] is Map ? u['user'] : u;
    final citoyenObj = u['citoyen'] is Map ? u['citoyen'] as Map<String, dynamic> : null;

    final firstName = (citoyenObj?['citizen_first_name'] ?? citoyenObj?['citizen_name'] ?? '').toString();
    final lastName = (citoyenObj?['citizen_last_name'] ?? citoyenObj?['citizen_lastname'] ?? '').toString();
    final pseudo = (userObj['user_pseudo'] ?? '').toString();
    final email = (userObj['user_email'] ?? '').toString();
    final cin = (citoyenObj?['citizen_cin'] ?? citoyenObj?['citizen_national_card_number'] ?? '').toString();
    final phone = (userObj['user_phone'] ?? '').toString();
    final address = (citoyenObj?['citizen_adress'] ?? citoyenObj?['citizen_address'] ?? '').toString();
    final roles = _getRoles(u);
    final fullName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : pseudo;
    final photo = citoyenObj?['citizen_photo']?.toString();
    final avatarUrl = CitizensService.getCitizenAvatarPreview(photo);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AdminTheme.primary.withValues(alpha: 0.06)
                : _hovered
                    ? (widget.isDark
                        ? AdminTheme.surface2Dark.withValues(alpha: 0.5)
                        : AdminTheme.dividerLight)
                    : (widget.isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight),
            border: Border(
              bottom: BorderSide(
                  color: widget.isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
              left: BorderSide(
                color: widget.isSelected ? AdminTheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              _Avatar(url: avatarUrl, name: firstName.isNotEmpty ? firstName : pseudo, size: 36),
              const SizedBox(width: 10),

              // Nom & Prénom
              Expanded(
                flex: 2,
                child: Text(
                  fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: widget.isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Email
              Expanded(
                flex: 2,
                child: Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // CIN
              Expanded(
                flex: 1,
                child: Text(
                  cin.isNotEmpty ? cin : '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              // Téléphone
              Expanded(
                flex: 1,
                child: Text(
                  phone.isNotEmpty ? phone : '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                  ),
                ),
              ),

              // Adresse
              Expanded(
                flex: 2,
                child: Text(
                  address.isNotEmpty ? address : '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Rôle(s)
              Expanded(
                flex: 1,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: roles.isEmpty
                      ? [Text('—', style: TextStyle(fontSize: 12, color: AdminTheme.textMuted))]
                      : roles
                          .take(2)
                          .map((r) => AdminTheme.badge(r, _roleColor(r), fontSize: 10))
                          .toList(),
                ),
              ),

              // Actions
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.shield_outlined, size: 16),
                  color: AdminTheme.primary,
                  tooltip: 'Gérer les rôles',
                  onPressed: widget.onRoleAssign,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  const _Avatar({required this.url, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final List<Color> gradientColors = _gradientFor(initial);

    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(initial, gradientColors),
        ),
      );
    }
    return _initials(initial, gradientColors);
  }

  Widget _initials(String initial, List<Color> colors) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
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

  List<Color> _gradientFor(String char) {
    final code = char.codeUnitAt(0);
    final index = code % 6;
    const gradients = [
      [Color(0xFF059669), Color(0xFF10B981)],
      [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
      [Color(0xFFD97706), Color(0xFFF59E0B)],
      [Color(0xFFBE185D), Color(0xFFEC4899)],
      [Color(0xFF0E7490), Color(0xFF06B6D4)],
    ];
    return gradients[index].map((c) => c).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  _InfoItem({required this.icon, required this.label, required this.value});
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  final bool isDark;
  const _InfoGrid({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon,
                        size: 14,
                        color: isDark
                            ? AdminTheme.textMutedDark
                            : AdminTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AdminTheme.textSecondaryDark
                              : AdminTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;
  const _CompactInfo({required this.icon, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 13,
              color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AdminTheme.textSecondaryDark
                    : AdminTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(
                color: widget.isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
          ),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                      .withValues(alpha: _anim.value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: 140,
                      decoration: BoxDecoration(
                        color: (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                            .withValues(alpha: _anim.value),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 200,
                      decoration: BoxDecoration(
                        color: (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                            .withValues(alpha: _anim.value * 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
