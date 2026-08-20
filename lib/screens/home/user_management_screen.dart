import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itantsoroka/constants/api_constants.dart';
import 'package:itantsoroka/services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final String apiUrl = ApiConstants.gatewayBaseUrl;

  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool loading = true;

  int currentPage = 1;
  int totalPages = 1;
  int numberOfUsers = 0;

  final TextEditingController _searchController = TextEditingController();
  String searchTerm = "";
  bool isFilterRecent = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);

    try {
      final pagedResult = await UserService.getAllUsersByApplicationRole2Paged(
        page: currentPage,
        search: searchTerm,
        limit: 50,
      );

      if (pagedResult != null &&
          pagedResult['data'] is List &&
          (pagedResult['data'] as List).isNotEmpty) {
        final List<dynamic> data = pagedResult['data'];
        final totalCount = pagedResult['total'] ?? data.length;
        final pageLimit = pagedResult['limit'] ?? 50;
        final numPages = pagedResult['numberOfPages'] ??
            ((totalCount / pageLimit).ceil() > 0 ? (totalCount / pageLimit).ceil() : 1);
        setState(() {
          users = data;
          applyLocalFilter();
          numberOfUsers = totalCount;
          totalPages = numPages;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final rawToken = prefs.getString("access_token");
      final headers = <String, String>{"Content-Type": "application/json"};
      if (rawToken != null && rawToken.isNotEmpty) {
        headers["Authorization"] = "Bearer $rawToken";
      }

      final uri =
          Uri.parse('${ApiConstants.serviceAuth}/users').replace(queryParameters: {
        'page': currentPage.toString(),
        'limit': '50',
        if (searchTerm.trim().isNotEmpty) 'search': searchTerm.trim(),
      });

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        List<dynamic> allData = [];
        int total = 0;

        if (result is List) {
          allData = result;
          total = allData.length;
        } else if (result is Map) {
          allData = result['data'] ?? result['users'] ?? result['content'] ?? [];
          total = result['total'] ?? result['count'] ?? allData.length;
        }

        if (allData.isNotEmpty) {
          final enriched = await UserService.enrichUsersWithCitizens(allData);
          setState(() {
            users = enriched;
            applyLocalFilter();
            numberOfUsers = total;
            totalPages = (total / 10).ceil() > 0 ? (total / 10).ceil() : 1;
          });
          return;
        }
      }

      setState(() {
        users = [];
        filteredUsers = [];
        numberOfUsers = 0;
        totalPages = 1;
      });
    } catch (e) {
      debugPrint("Erreur chargement utilisateurs : $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void applyLocalFilter() {
    if (isFilterRecent) {
      filteredUsers = users.where((u) {
        if (u is! Map) return false;
        final userObj = u['user'] is Map ? u['user'] : u;
        List roles = userObj['appUserRoles'] ?? [];
        return roles.length == 1;
      }).toList();
    } else {
      filteredUsers = users;
    }
  }

  // ─── Extraction des données utilisateur ───────────────────────────────────

  String _getPhotoUrl(Map user, Map citoyen) {
    final photoPath =
        citoyen['citizen_photo'] ?? citoyen['photo'] ?? user['user_photo'] ?? user['photo'];
    if (photoPath == null || photoPath.toString().trim().isEmpty) return '';
    final rawP = photoPath.toString().trim();
    if (rawP.contains('/file/preview/hello%2F')) return rawP;
    if (rawP.contains('hello')) {
      final parts = rawP.split('hello');
      final afterHello = parts.length > 1 ? parts[1] : rawP;
      final encoded = afterHello.startsWith('/')
          ? "%2F${afterHello.substring(1)}"
          : afterHello.replaceFirst('/', '%2F');
      return '$apiUrl/serviceupload/file/preview/hello$encoded';
    }
    if (rawP.startsWith('http://') || rawP.startsWith('https://')) return rawP;
    final clean = rawP.startsWith('/') ? rawP.substring(1) : rawP;
    return '$apiUrl/serviceupload/file/preview/${Uri.encodeComponent(clean)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 680;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── En-tête ──────────────────────────────────────────────────────
            _buildHeader(isMobile),

            // ── Barre de recherche + filtre ───────────────────────────────────
            _buildFilters(isMobile),

            // ── Tableau / Cartes ──────────────────────────────────────────────
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
                  : filteredUsers.isEmpty
                      ? _buildEmpty()
                      : isMobile
                          ? _buildMobileCards()
                          : _buildDesktopTable(),
            ),

            // ── Pagination ───────────────────────────────────────────────────
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  // ─── En-tête ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Utilisateurs",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "$numberOfUsers comptes enregistrés",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF098E00),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: isMobile
                ? const SizedBox.shrink()
                : const Text("Créer", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Recherche + filtre ───────────────────────────────────────────────────

  Widget _buildFilters(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 10,
      ),
      color: const Color(0xFF1E293B),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),
                const SizedBox(height: 8),
                _buildFilterDropdown(),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 12),
                _buildFilterDropdown(),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: "Rechercher un utilisateur...",
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      onChanged: (v) {
        setState(() {
          searchTerm = v;
          currentPage = 1;
        });
        loadUsers();
      },
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: isFilterRecent,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF94A3B8), size: 18),
          items: const [
            DropdownMenuItem(value: false, child: Text("Tous les comptes")),
            DropdownMenuItem(value: true, child: Text("Rôle unique")),
          ],
          onChanged: (v) {
            setState(() {
              isFilterRecent = v ?? false;
              applyLocalFilter();
            });
          },
        ),
      ),
    );
  }

  // ─── MOBILE : Cartes empilées ─────────────────────────────────────────────

  Widget _buildMobileCards() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final u = filteredUsers[index];
        if (u is! Map) return const SizedBox.shrink();
        final userObj = u['user'] is Map ? u['user'] as Map : u;
        final citoyen = u['citoyen'] is Map
            ? u['citoyen'] as Map
            : (u['citizen'] is Map ? u['citizen'] as Map : <String, dynamic>{});

        final firstName = (citoyen['citizen_name'] ??
                citoyen['citizen_first_name'] ??
                userObj['user_pseudo'] ??
                '')
            .toString();
        final lastName = (citoyen['citizen_lastname'] ??
                citoyen['citizen_last_name'] ??
                '')
            .toString();
        String fullName = "$firstName $lastName".trim();
        if (fullName.isEmpty) fullName = userObj['user_pseudo'] ?? 'Utilisateur';

        final email = (userObj['user_email'] ?? '').toString();
        final cin = (citoyen['citizen_national_card_number'] ??
                citoyen['citizen_cin'] ??
                'N/A')
            .toString();
        final phone = (citoyen['citizen_phone_number'] ??
                citoyen['citizen_phone'] ??
                'N/A')
            .toString();
        final photoUrl = _getPhotoUrl(userObj, citoyen);
        final List roles = userObj['appUserRoles'] is List
            ? userObj['appUserRoles'] as List
            : (u['appUserRoles'] is List ? u['appUserRoles'] as List : []);

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(photoUrl, fullName, 40),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (cin != 'N/A')
                            _buildChip(Icons.badge_rounded, cin,
                                const Color(0xFF334155), const Color(0xFF94A3B8)),
                          if (phone != 'N/A')
                            _buildChip(Icons.phone_rounded, phone,
                                const Color(0xFF334155), const Color(0xFF94A3B8)),
                          ...roles.take(2).map((r) {
                            final roleName = (r is Map)
                                ? (r['role_name'] ?? r['name'] ?? 'Rôle')
                                : r.toString();
                            return _buildChip(
                              Icons.shield_rounded,
                              roleName.toString(),
                              const Color(0xFF098E00).withValues(alpha: 0.2),
                              const Color(0xFF4ADE80),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(
      IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAvatar(String photoUrl, String name, double size) {
    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(name, size),
        ),
      );
    }
    return _buildInitials(name, size);
  }

  Widget _buildInitials(String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF),
        shape: BoxShape.circle,
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

  // ─── DESKTOP : Tableau horizontal ────────────────────────────────────────

  Widget _buildDesktopTable() {
    const double colPhoto = 52;
    const double colName = 180;
    const double colCin = 130;
    const double colEmail = 200;
    const double colPhone = 130;
    const double colAddr = 160;
    const double colRole = 160;
    const double totalW = colPhoto + colName + colCin + colEmail + colPhone + colAddr + colRole;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Entête colonnes ──
              Container(
                color: const Color(0xFF161E2E),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: const [
                    SizedBox(width: colPhoto, child: Text("", style: _thStyle)),
                    SizedBox(width: colName, child: Text("NOM", style: _thStyle)),
                    SizedBox(width: colCin, child: Text("CIN", style: _thStyle)),
                    SizedBox(width: colEmail, child: Text("EMAIL", style: _thStyle)),
                    SizedBox(width: colPhone, child: Text("TÉL.", style: _thStyle)),
                    SizedBox(width: colAddr, child: Text("ADRESSE", style: _thStyle)),
                    SizedBox(width: colRole, child: Text("RÔLE(S)", style: _thStyle)),
                  ],
                ),
              ),
              // ── Lignes ──
              ...filteredUsers.asMap().entries.map((entry) {
                final index = entry.key;
                final u = entry.value;
                if (u is! Map) return const SizedBox.shrink();
                final userObj = u['user'] is Map ? u['user'] as Map : u;
                final citoyen = u['citoyen'] is Map
                    ? u['citoyen'] as Map
                    : (u['citizen'] is Map ? u['citizen'] as Map : <String, dynamic>{});

                final firstName = (citoyen['citizen_name'] ??
                        citoyen['citizen_first_name'] ??
                        userObj['user_pseudo'] ?? '').toString();
                final lastName = (citoyen['citizen_lastname'] ??
                        citoyen['citizen_last_name'] ?? '').toString();
                String fullName = "$firstName $lastName".trim();
                if (fullName.isEmpty) fullName = userObj['user_pseudo'] ?? 'Utilisateur';

                final email = (userObj['user_email'] ?? 'N/A').toString();
                final cin = (citoyen['citizen_national_card_number'] ??
                        citoyen['citizen_cin'] ?? 'N/A').toString();
                final phone = (citoyen['citizen_phone_number'] ??
                        citoyen['citizen_phone'] ?? 'N/A').toString();
                final addr = (citoyen['citizen_adress'] ??
                        citoyen['citizen_address'] ?? 'N/A').toString();
                final photoUrl = _getPhotoUrl(userObj, citoyen);
                final List roles = userObj['appUserRoles'] is List
                    ? userObj['appUserRoles'] as List
                    : (u['appUserRoles'] is List ? u['appUserRoles'] as List : []);

                final bg = index.isEven
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF1A2335);

                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: colPhoto,
                        child: _buildAvatar(photoUrl, fullName, 36),
                      ),
                      SizedBox(
                        width: colName,
                        child: Text(fullName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: colCin,
                        child: Text(cin, style: _tdStyle,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: colEmail,
                        child: Text(email, style: _tdStyle,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: colPhone,
                        child: Text(phone, style: _tdStyle),
                      ),
                      SizedBox(
                        width: colAddr,
                        child: Text(addr, style: _tdStyle,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: colRole,
                        child: roles.isEmpty
                            ? const Text("Aucun",
                                style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic))
                            : Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: roles.take(2).map((r) {
                                  final n = r is Map
                                      ? (r['role_name'] ?? r['name'] ?? 'Rôle')
                                      : r.toString();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF098E00)
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(n.toString(),
                                        style: const TextStyle(
                                            color: Color(0xFF4ADE80),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _thStyle = TextStyle(
    color: Color(0xFF64748B),
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 0.5,
  );

  static const TextStyle _tdStyle = TextStyle(
    color: Color(0xFFCBD5E1),
    fontSize: 12,
  );

  // ─── État vide ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text("Aucun utilisateur trouvé",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
        ],
      ),
    );
  }

  // ─── Pagination ──────────────────────────────────────────────────────────

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E293B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(Icons.first_page_rounded, currentPage > 1, () {
            setState(() => currentPage = 1);
            loadUsers();
          }),
          const SizedBox(width: 6),
          _pageBtn(Icons.chevron_left_rounded, currentPage > 1, () {
            setState(() => currentPage--);
            loadUsers();
          }),
          const SizedBox(width: 12),
          Text(
            "Page $currentPage / $totalPages",
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          _pageBtn(Icons.chevron_right_rounded, currentPage < totalPages, () {
            setState(() => currentPage++);
            loadUsers();
          }),
          const SizedBox(width: 6),
          _pageBtn(Icons.last_page_rounded, currentPage < totalPages, () {
            setState(() => currentPage = totalPages);
            loadUsers();
          }),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF098E00)
              : const Color(0xFF334155).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.white : const Color(0xFF475569)),
      ),
    );
  }
}