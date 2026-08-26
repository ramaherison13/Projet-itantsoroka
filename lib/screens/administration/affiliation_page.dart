import 'package:flutter/material.dart';
import '../../core/admin_theme.dart';
import '../../l10n/app_localization.dart';
import '../../services/affiliation_service.dart';
import '../../services/citizens_service.dart';
import '../../services/user_service.dart';
import '../../services/territory_service.dart';

class AffiliationPage extends StatefulWidget {
  const AffiliationPage({super.key});

  @override
  State<AffiliationPage> createState() => _AffiliationPageState();
}

class _AffiliationPageState extends State<AffiliationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Saisies & Chargements ──────────────────────────────────────────────────
  bool _loading = false;
  String _searchQuery = '';

  // ── Données ────────────────────────────────────────────────────────────────
  List<dynamic> _users = [];
  List<dynamic> _entites = [];
  List<dynamic> _stds = [];
  List<dynamic> _affiliations = [];
  List<dynamic> _affiliationStds = [];
  List<dynamic> _userTerritoires = [];
  List<dynamic> _offres = [];

  // Territoires
  List<dynamic> _regions = [];
  List<dynamic> _districts = [];
  List<dynamic> _communes = [];

  // Filtres
  String _entiteCategorieFilter = 'all'; // 'all' | 'ministere' | 'ptf'
  String _stdEntiteFilter = 'all';
  String _stdTerritoireFilter = 'all'; // 'all' | territoire formattedId
  String _affUserFilter = 'all'; // 'all' | 'affiliated'
  String _stdUserFilter = 'all'; // 'all' | 'affiliated'
  String _territoireUserFilter = 'all'; // 'all' | 'assigned'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadInitialData();
  }

  void _handleTabSelection() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  String _getUserId(dynamic u) {
    if (u is! Map) return '';
    final userMap = u['user'] is Map ? u['user'] : u;
    return (userMap['user_id'] ?? userMap['id_user'] ?? userMap['id'] ?? u['user_id'] ?? u['id_user'] ?? u['id'])?.toString() ?? '';
  }

  String _getUserName(dynamic u) {
    if (u is! Map) return 'Utilisateur';
    final userMap = u['user'] is Map ? u['user'] : u;
    final citoyenMap = u['citoyen'] is Map ? u['citoyen'] : (u['citizen'] is Map ? u['citizen'] : null);

    if (citoyenMap != null) {
      final first = citoyenMap['citizen_name'] ?? citoyenMap['name'] ?? '';
      final last = citoyenMap['citizen_lastname'] ?? citoyenMap['lastname'] ?? '';
      final fullName = '$first $last'.trim();
      if (fullName.isNotEmpty) return fullName;
    }

    final pseudo = userMap['user_pseudo'] ?? userMap['pseudo'] ?? userMap['nom'] ?? userMap['name'] ?? u['user_pseudo'] ?? u['nom'];
    if (pseudo != null && pseudo.toString().trim().isNotEmpty) {
      return pseudo.toString().trim();
    }
    final email = userMap['user_email'] ?? userMap['email'] ?? u['user_email'] ?? u['email'];
    if (email != null && email.toString().trim().isNotEmpty) {
      return email.toString().trim();
    }
    return 'Utilisateur';
  }

  String _getUserEmail(dynamic u) {
    if (u is! Map) return '';
    final userMap = u['user'] is Map ? u['user'] : u;
    final citoyenMap = u['citoyen'] is Map ? u['citoyen'] : (u['citizen'] is Map ? u['citizen'] : null);

    final email = userMap['user_email'] ?? userMap['email'] ?? citoyenMap?['citizen_mail'] ?? u['user_email'] ?? u['email'];
    return email?.toString().trim() ?? '';
  }

  String _getUserCin(dynamic u) {
    if (u is! Map) return 'Non renseigné';
    final userMap = u['user'] is Map ? u['user'] : u;
    final citoyenMap = u['citoyen'] is Map ? u['citoyen'] : (u['citizen'] is Map ? u['citizen'] : null);

    final cin = citoyenMap?['citizen_national_card_number'] ??
        citoyenMap?['citizen_cin'] ??
        citoyenMap?['national_card_number'] ??
        citoyenMap?['cin'] ??
        citoyenMap?['num_cin'] ??
        citoyenMap?['number'] ??
        citoyenMap?['card_number'] ??
        userMap['user_cin'] ??
        userMap['cin'] ??
        userMap['citizen_national_card_number'] ??
        u['user_cin'] ??
        u['cin'] ??
        u['citizen_national_card_number'] ??
        u['citizen_cin'];

    if (cin != null && cin.toString().trim().isNotEmpty && cin.toString().trim() != '0') {
      return cin.toString().trim();
    }
    return 'Non renseigné';
  }

  String _getUserPhone(dynamic u) {
    if (u is! Map) return 'Non renseigné';
    final userMap = u['user'] is Map ? u['user'] : u;

    // L'API retourne un objet plat — citizen directement à la racine
    final citoyenMap = u['citoyen'] is Map
        ? u['citoyen']
        : (u['citizen'] is Map
            ? u['citizen']
            : (userMap is Map && userMap['citoyen'] is Map
                ? userMap['citoyen']
                : (userMap is Map && userMap['citizen'] is Map ? userMap['citizen'] : null)));

    final phone = citoyenMap?['citizen_phone_number'] ??
        citoyenMap?['phone_number'] ??
        citoyenMap?['citizen_phone'] ??
        citoyenMap?['phone'] ??
        citoyenMap?['telephone'] ??
        citoyenMap?['tel'] ??
        citoyenMap?['contact'] ??
        citoyenMap?['num_tel'] ??
        // user_phone est aussi retourné à la racine par l'API /serviceauth/users
        u['user_phone'] ??
        u['user_telephone'] ??
        userMap['user_phone'] ??
        userMap['user_telephone'] ??
        userMap['user_tel'] ??
        userMap['phone_number'] ??
        userMap['phone'] ??
        userMap['telephone'] ??
        userMap['tel'] ??
        u['phone_number'] ??
        u['phone'] ??
        u['telephone'] ??
        u['tel'] ??
        u['contact'];

    if (phone != null && phone.toString().trim().isNotEmpty && phone.toString().trim() != '0') {
      return phone.toString().trim();
    }
    return 'Non renseigné';
  }

  String? _getUserPhotoUrl(dynamic u) {
    if (u is! Map) return null;
    final userMap = u['user'] is Map ? u['user'] : u;

    // L'API retourne un objet plat — citizen directement à la racine
    final citoyenMap = u['citoyen'] is Map
        ? u['citoyen']
        : (u['citizen'] is Map
            ? u['citizen']
            : (userMap is Map && userMap['citoyen'] is Map
                ? userMap['citoyen']
                : (userMap is Map && userMap['citizen'] is Map ? userMap['citizen'] : null)));

    // citizen_photo peut être dans citoyen ou directement dans la racine
    final photo = citoyenMap?['citizen_photo'] ??
        citoyenMap?['photo'] ??
        citoyenMap?['photo_url'] ??
        citoyenMap?['avatar'] ??
        u['citizen_photo'] ??
        userMap['citizen_photo'] ??
        userMap['user_photo'] ??
        userMap['photo'] ??
        userMap['photo_url'] ??
        userMap['avatar'] ??
        u['user_photo'] ??
        u['photo'] ??
        u['photo_url'] ??
        u['avatar'];

    if (photo != null && photo.toString().trim().isNotEmpty) {
      return CitizensService.getCitizenAvatarPreview(photo.toString().trim());
    }
    return null;
  }

  Widget _buildUserAvatar(dynamic u, {double size = 44}) {
    final photoUrl = _getUserPhotoUrl(u);
    final name = _getUserName(u);
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join()
        : 'U';

    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    if (hasPhoto) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('[avatar] Erreur chargement photo: $photoUrl -> $error');
              return CircleAvatar(
                radius: size / 2,
                backgroundColor: AdminTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.38,
                    color: AdminTheme.primary,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircleAvatar(
                radius: size / 2,
                backgroundColor: AdminTheme.primary.withValues(alpha: 0.1),
                child: SizedBox(
                  width: size * 0.45,
                  height: size * 0.45,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AdminTheme.primary,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AdminTheme.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
          color: AdminTheme.primary,
        ),
      ),
    );
  }

  Future<void> _loadInitialData({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      if (forceRefresh) {
        AffiliationService.clearCache();
      }
      final results = await Future.wait([
        UserService.getAllUsersByApplicationRole().catchError((e) {
          debugPrint('Erreur getAllUsersByApplicationRole: $e');
          return null;
        }),
        AffiliationService.listEntites(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('Erreur listEntites: $e');
          return [];
        }),
        AffiliationService.listStds(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('Erreur listStds: $e');
          return [];
        }),
        AffiliationService.listAffiliations(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('Erreur listAffiliations: $e');
          return [];
        }),
        AffiliationService.listAffiliationStds(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('Erreur listAffiliationStds: $e');
          return [];
        }),
        AffiliationService.listUserTerritoires(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('Erreur listUserTerritoires: $e');
          return [];
        }),
        AffiliationService.listOffres(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('Erreur listOffres: $e');
          return [];
        }),
        TerritoryService.getRegionsBasic(forceRefresh: forceRefresh).catchError((_) => []),
        TerritoryService.getDistrictsBasic(forceRefresh: forceRefresh).catchError((_) => []),
        TerritoryService.getCommunesBasic(forceRefresh: forceRefresh).catchError((_) => []),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] ?? [];
          _entites = results[1] ?? [];
          _stds = results[2] ?? [];
          _affiliations = results[3] ?? [];
          _affiliationStds = results[4] ?? [];
          _userTerritoires = results[5] ?? [];
          _offres = results[6] ?? [];
          _regions = results[7] ?? [];
          _districts = results[8] ?? [];
          _communes = results[9] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données affiliation: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AdminTheme.danger : AdminTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── MODALES D'ACTION ───────────────────────────────────────────────────────

  // 1. Ajouter / Modifier Entité
  void _openEntiteForm({dynamic entite}) {
    final isEdit = entite != null;
    final nameCtrl = TextEditingController(text: entite?['nom'] ?? '');
    final descCtrl = TextEditingController(text: entite?['description'] ?? '');
    String category = entite?['categorie'] ?? 'ministere';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Modifier l'entité" : 'Créer une entité'),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'entité *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ministere', child: Text('Ministère', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'ptf', child: Text('PTF', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setModalState(() => category = val ?? 'ministere'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final payload = {
                    'nom': nameCtrl.text.trim(),
                    'categorie': category,
                    'description': descCtrl.text.trim(),
                  };
                  if (isEdit) {
                    await AffiliationService.updateEntite(entite['id'], payload);
                    _showSnackBar('Entité mise à jour');
                  } else {
                    await AffiliationService.createEntite(payload);
                    _showSnackBar('Entité créée avec succès');
                  }
                  _loadInitialData();
                } catch (e) {
                  _showSnackBar('Erreur lors de l\'enregistrement: $e', isError: true);
                }
              },
              child: Text(isEdit ? 'Mettre à jour' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Desactiver / Activer Entité
  Future<void> _toggleEntiteStatus(dynamic entite) async {
    final bool isDisable = entite['status'] != 'disabled';
    try {
      if (isDisable) {
        await AffiliationService.disableEntite(entite['id']);
        _showSnackBar('Entité désactivée');
      } else {
        await AffiliationService.enableEntite(entite['id']);
        _showSnackBar('Entité activée');
      }
      _loadInitialData();
    } catch (e) {
      _showSnackBar('Erreur de changement de statut: $e', isError: true);
    }
  }

  // 3. Supprimer Entité
  Future<void> _deleteEntite(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette entité ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AffiliationService.deleteEntite(id);
        _showSnackBar('Entité supprimée');
        _loadInitialData();
      } catch (e) {
        _showSnackBar('Erreur de suppression: $e', isError: true);
      }
    }
  }

  // 4. Ajouter / Modifier STD
  void _openStdForm({dynamic std}) {
    final isEdit = std != null;
    final nameCtrl = TextEditingController(text: std?['nom'] ?? '');
    final descCtrl = TextEditingController(text: std?['description'] ?? '');
    dynamic selectedEntiteId = std?['entiteId'] ?? std?['entite_id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Modifier le STD" : 'Créer un STD'),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom du STD *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<dynamic>(
                    initialValue: selectedEntiteId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Entité (Ministère) *',
                      border: OutlineInputBorder(),
                    ),
                    items: _entites
                        .where((e) => e['categorie'] == 'ministere')
                        .map<DropdownMenuItem<dynamic>>((e) => DropdownMenuItem(
                              value: e['id'],
                              child: Text(e['nom'] ?? '', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedEntiteId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || selectedEntiteId == null) return;
                Navigator.pop(ctx);
                try {
                  final payload = {
                    'nom': nameCtrl.text.trim(),
                    'entiteId': selectedEntiteId,
                    'description': descCtrl.text.trim(),
                  };
                  if (isEdit) {
                    await AffiliationService.updateStd(std['id'].toString(), payload);
                    _showSnackBar('STD mis à jour');
                  } else {
                    await AffiliationService.createStd(payload);
                    _showSnackBar('STD créé avec succès');
                  }
                  _loadInitialData();
                } catch (e) {
                  _showSnackBar('Erreur lors de l\'enregistrement STD: $e', isError: true);
                }
              },
              child: Text(isEdit ? 'Mettre à jour' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Supprimer STD
  Future<void> _deleteStd(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce STD ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AffiliationService.deleteStd(id);
        _showSnackBar('STD supprimé');
        _loadInitialData();
      } catch (e) {
        _showSnackBar('Erreur de suppression STD: $e', isError: true);
      }
    }
  }

  // 6. Modal d'affiliation utilisateur -> Entité
  void _openAssignEntiteModal(dynamic user) {
    dynamic selectedEntiteId;
    final userId = _getUserId(user);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── En-tête vert avec titre et bouton fermer ─────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Affilier utilisateur',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Associer l\'utilisateur à une entité',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ),
                // ── Corps du modal ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo & Nom utilisateur
                      Row(
                        children: [
                          _buildUserAvatar(user, size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getUserName(user),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Téléphone: ${_getUserPhone(user)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ENTITÉ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<dynamic>(
                        initialValue: selectedEntiteId,
                        isExpanded: true,
                        decoration: _inputDecoration(isDark: isDark, hint: 'Sélectionner une entité'),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        items: _entites.map<DropdownMenuItem<dynamic>>((e) {
                          return DropdownMenuItem(
                            value: e['id'],
                            child: Text(
                              "${e['nom']} (${e['categorie']?.toUpperCase()})",
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedEntiteId = val),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                          border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cette action validera la demande et affiliera l\'utilisateur à l\'entité sélectionnée.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD97706),
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
                // ── Footer ─────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                          foregroundColor: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                        ),
                        onPressed: () async {
                          if (selectedEntiteId == null || userId.isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await AffiliationService.createAffiliation(userId, selectedEntiteId as int);
                            _showSnackBar('Affiliation enregistrée');
                            _loadInitialData();
                          } catch (e) {
                            _showSnackBar('Erreur d\'affiliation: $e', isError: true);
                          }
                        },
                        child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // 7. Modal d'affiliation utilisateur -> STD
  void _openAssignStdModal(dynamic user) {
    dynamic selectedStdId;
    final userId = _getUserId(user);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── En-tête vert ─────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Affilier au STD',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Associer l\'utilisateur à un STD',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ),
                // ── Corps du modal ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildUserAvatar(user, size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getUserName(user),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Téléphone: ${_getUserPhone(user)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'STD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<dynamic>(
                        initialValue: selectedStdId,
                        isExpanded: true,
                        decoration: _inputDecoration(isDark: isDark, hint: 'Sélectionner un STD'),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        items: _stds.map<DropdownMenuItem<dynamic>>((s) {
                          return DropdownMenuItem(
                            value: s['id'],
                            child: Text(
                              s['nom'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedStdId = val),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                          border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cette action validera la demande et affiliera l\'utilisateur au STD sélectionné.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD97706),
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
                // ── Footer ─────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                          foregroundColor: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                        ),
                        onPressed: () async {
                          if (selectedStdId == null || userId.isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await AffiliationService.createAffiliationStd(userId, selectedStdId.toString());
                            _showSnackBar('Affiliation STD enregistrée');
                            _loadInitialData();
                          } catch (e) {
                            String errorMsg = e.toString();
                            if (errorMsg.contains("territoire") || errorMsg.contains("403")) {
                              errorMsg = "Le territoire de l'utilisateur n'est pas inclus dans les territoires couverts par ce STD. Veuillez d'abord lui affecter un territoire compatible.";
                            }
                            _showSnackBar(errorMsg, isError: true);
                          }
                        },
                        child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // 8. Modal d'affectation de Territoire (User-Territoire)
  void _openAssignTerritoireModal(dynamic user) {
    final userId = _getUserId(user);
    String type = 'region';
    dynamic selectedFormattedId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          List<dynamic> options = [];
          if (type == 'region') options = _regions;
          if (type == 'district') options = _districts;
          if (type == 'commune') options = _communes;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── En-tête violet dégradé ─────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Affecter un territoire',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Associer l\'utilisateur à une zone géographique',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          tooltip: 'Fermer',
                        ),
                      ],
                    ),
                  ),
                  // ── Corps du modal ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildUserAvatar(user, size: 52),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getUserName(user),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Téléphone: ${_getUserPhone(user)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'TYPE DE TERRITOIRE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          isExpanded: true,
                          decoration: _inputDecoration(isDark: isDark, hint: 'Type de territoire'),
                          dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'region', child: Text('Région', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'district', child: Text('District', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'commune', child: Text('Commune', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              type = val ?? 'region';
                              selectedFormattedId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TERRITOIRE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<dynamic>(
                          initialValue: selectedFormattedId,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            isDark: isDark,
                            hint: 'Sélectionner ${type == 'region' ? 'la région' : type == 'district' ? 'le district' : 'la commune'}',
                          ),
                          dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                          items: options.map<DropdownMenuItem<dynamic>>((t) {
                            final fId = t['formatted_id'] ?? t['formattedId'] ?? t['code'] ?? t['id'];
                            final name = t['nom'] ?? t['name'] ?? t['region_name'] ?? t['district_name'] ?? t['commune_name'] ?? fId;
                            return DropdownMenuItem(
                              value: fId,
                              child: Text(name.toString(), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setModalState(() => selectedFormattedId = val),
                        ),
                      ],
                    ),
                  ),
                  // ── Footer ─────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                            side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                            foregroundColor: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          ),
                          onPressed: () async {
                            if (selectedFormattedId == null || userId.isEmpty) return;
                            Navigator.pop(ctx);
                            try {
                              await AffiliationService.createUserTerritoire(userId, selectedFormattedId.toString());
                              _showSnackBar('Territoire affecté avec succès');
                              _loadInitialData();
                            } catch (e) {
                              _showSnackBar('Erreur d\'affectation de territoire: $e', isError: true);
                            }
                          },
                          child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 6. Créer / Modifier une Offre d'appui
  void _openOffreForm({dynamic offre}) {
    final isEdit = offre != null;
    final titleCtrl = TextEditingController(text: offre?['titre'] ?? offre?['nom'] ?? '');
    final descCtrl = TextEditingController(text: offre?['description'] ?? '');
    String? selectedStdId = offre?['stdId']?.toString() ?? (_stds.isNotEmpty ? _stds.first['id']?.toString() : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Modifier l'offre" : 'Nouvelle offre d\'appui'),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titre de l\'offre *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStdId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'STD parente *',
                      border: OutlineInputBorder(),
                    ),
                    items: _stds.map<DropdownMenuItem<String>>((s) {
                      final sId = s['id']?.toString() ?? '';
                      final sNom = s['nom'] ?? 'STD #$sId';
                      return DropdownMenuItem(
                        value: sId,
                        child: Text(sNom, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedStdId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final titre = titleCtrl.text.trim();
                if (titre.isEmpty) {
                  _showSnackBar('Le titre est obligatoire', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final payload = {
                  'titre': titre,
                  'description': descCtrl.text.trim(),
                  '?stdId': selectedStdId,
                };
                try {
                  if (isEdit) {
                    await AffiliationService.updateOffre(offre['id'].toString(), payload);
                    _showSnackBar('Offre modifiée avec succès');
                  } else {
                    await AffiliationService.createOffre(payload);
                    _showSnackBar('Offre créée avec succès');
                  }
                  _loadInitialData();
                } catch (e) {
                  _showSnackBar('Erreur: $e', isError: true);
                }
              },
              child: Text(isEdit ? 'Enregistrer' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }



  // ── HELPER DECORATION & THEME ──────────────────────────────────────────────

  InputDecoration _inputDecoration({required bool isDark, String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
      ),
      filled: true,
      fillColor: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        borderSide: BorderSide(
          color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        borderSide: BorderSide(
          color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        borderSide: const BorderSide(color: AdminTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    );
  }

  Widget _buildSearchBar(String hint, {required bool isDark}) {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
      ),
      decoration: _inputDecoration(isDark: isDark, hint: hint).copyWith(
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }

  // ── CONSTRUCTEURS D'ONGLETS RESPONSIVE ──────────────────────────────────────

  // Onglet 1: Affiliations Entités
  Widget _buildAffiliationsTab(bool isDark) {
    final double hPad = AdminTheme.horizontalPadding(context);
    final bool isMobile = AdminTheme.isMobile(context);

    final filteredUsers = _users.where((u) {
      final uId = _getUserId(u);
      final hasAff = _affiliations.any(
          (a) => a['userId']?.toString() == uId || a['user_id']?.toString() == uId);

      if (_affUserFilter == 'affiliated' && !hasAff) return false;

      final name = _getUserName(u).toLowerCase();
      final email = _getUserEmail(u).toLowerCase();
      final cin = _getUserCin(u).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || email.contains(q) || cin.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: isMobile
              ? Column(
                  children: [
                    _buildSearchBar(context.tr('aff_search_user'), isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _affUserFilter,
                            decoration: _inputDecoration(isDark: isDark),
                            dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                              DropdownMenuItem(value: 'affiliated', child: Text('Uniquement affiliés')),
                            ],
                            onChanged: (val) => setState(() => _affUserFilter = val ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                              side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                            ),
                          ),
                          onPressed: _loadInitialData,
                          icon: Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, size: 20),
                          tooltip: context.tr('actualiser'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchBar(context.tr('aff_search_user'), isDark: isDark)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _affUserFilter,
                        decoration: _inputDecoration(isDark: isDark),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                          DropdownMenuItem(value: 'affiliated', child: Text('Uniquement affiliés')),
                        ],
                        onChanged: (val) => setState(() => _affUserFilter = val ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                      tooltip: context.tr('actualiser'),
                      onPressed: _loadInitialData,
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, isMobile ? 100 : hPad),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final u = filteredUsers[i];
                    final uId = _getUserId(u);
                    final userAffs = _affiliations
                        .where((a) => a['userId']?.toString() == uId || a['user_id']?.toString() == uId)
                        .toList();
                    final cinStr = _getUserCin(u);

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                        onTap: () => _openAssignEntiteModal(u),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AdminTheme.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                            border: Border.all(
                              color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                            ),
                            boxShadow: AdminTheme.shadowSm,
                          ),
                          child: Row(
                            children: [
                              _buildUserAvatar(u, size: 44),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          _getUserName(u),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                          ),
                                        ),
                                        AdminTheme.badge('CIN: $cinStr', AdminTheme.purple),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getUserEmail(u),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: userAffs.isEmpty
                                          ? [AdminTheme.badge(context.tr('aff_aucune_entite'), Colors.grey)]
                                          : userAffs.map((a) {
                                              final ent = _entites.firstWhere(
                                                (e) => e['id'] == a['entiteId'],
                                                orElse: () => {'nom': 'Entité #${a['entiteId']}'},
                                              );
                                              return Chip(
                                                backgroundColor: AdminTheme.primary.withValues(alpha: 0.1),
                                                label: Text(
                                                  ent['nom'] ?? '',
                                                  style: const TextStyle(color: AdminTheme.primary, fontSize: 12),
                                                ),
                                                deleteIcon: const Icon(Icons.close, size: 14),
                                                onDeleted: () async {
                                                  final msgSuccess = context.tr('aff_retiree');
                                                  final errPrefix = context.tr('erreur');
                                                  try {
                                                    await AffiliationService.deleteAffiliation(a['id']);
                                                    _showSnackBar(msgSuccess);
                                                    _loadInitialData();
                                                  } catch (e) {
                                                    _showSnackBar('$errPrefix: $e', isError: true);
                                                  }
                                                },
                                              );
                                            }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_link_rounded, color: AdminTheme.primary),
                                tooltip: context.tr('aff_add_entite'),
                                onPressed: () => _openAssignEntiteModal(u),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Onglet 2: Affiliations STD
  Widget _buildAffiliationsStdTab(bool isDark) {
    final double hPad = AdminTheme.horizontalPadding(context);
    final bool isMobile = AdminTheme.isMobile(context);

    final filteredUsers = _users.where((u) {
      final uId = _getUserId(u);
      final hasStdAff = _affiliationStds.any(
          (a) => a['userId']?.toString() == uId || a['user_id']?.toString() == uId);

      if (_stdUserFilter == 'affiliated' && !hasStdAff) return false;

      final name = _getUserName(u).toLowerCase();
      final email = _getUserEmail(u).toLowerCase();
      final cin = _getUserCin(u).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || email.contains(q) || cin.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: isMobile
              ? Column(
                  children: [
                    _buildSearchBar(context.tr('aff_search_std_user'), isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _stdUserFilter,
                            decoration: _inputDecoration(isDark: isDark),
                            dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                              DropdownMenuItem(value: 'affiliated', child: Text('Uniquement affiliés STD')),
                            ],
                            onChanged: (val) => setState(() => _stdUserFilter = val ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                              side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                            ),
                          ),
                          onPressed: _loadInitialData,
                          icon: Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, size: 20),
                          tooltip: context.tr('actualiser'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchBar(context.tr('aff_search_std_user'), isDark: isDark)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 230,
                      child: DropdownButtonFormField<String>(
                        initialValue: _stdUserFilter,
                        decoration: _inputDecoration(isDark: isDark),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                          DropdownMenuItem(value: 'affiliated', child: Text('Uniquement affiliés STD')),
                        ],
                        onChanged: (val) => setState(() => _stdUserFilter = val ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                      tooltip: context.tr('actualiser'),
                      onPressed: _loadInitialData,
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, isMobile ? 100 : hPad),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final u = filteredUsers[i];
                    final uId = _getUserId(u);
                    final userStdAffs = _affiliationStds
                        .where((a) => a['userId']?.toString() == uId || a['user_id']?.toString() == uId)
                        .toList();
                    final cinStr = _getUserCin(u);

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                        onTap: () => _openAssignStdModal(u),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AdminTheme.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                            border: Border.all(
                              color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                            ),
                            boxShadow: AdminTheme.shadowSm,
                          ),
                          child: Row(
                            children: [
                              _buildUserAvatar(u, size: 44),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          _getUserName(u),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                          ),
                                        ),
                                        AdminTheme.badge('CIN: $cinStr', AdminTheme.purple),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getUserEmail(u),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: userStdAffs.isEmpty
                                          ? [AdminTheme.badge(context.tr('aff_aucun_std'), Colors.grey)]
                                          : userStdAffs.map((a) {
                                              final std = _stds.firstWhere(
                                                (s) => s['id']?.toString() == a['stdId']?.toString(),
                                                orElse: () => {'nom': 'STD #${a['stdId']}'},
                                              );
                                              return Chip(
                                                backgroundColor: AdminTheme.info.withValues(alpha: 0.1),
                                                label: Text(std['nom'] ?? '', style: const TextStyle(color: AdminTheme.info, fontSize: 12)),
                                                deleteIcon: const Icon(Icons.close, size: 14),
                                                onDeleted: () async {
                                                  final msgSuccess = context.tr('aff_std_retiree');
                                                  final errPrefix = context.tr('erreur');
                                                  try {
                                                    await AffiliationService.deleteAffiliationStd(a['id']);
                                                    if (!mounted) return;
                                                    _showSnackBar(msgSuccess);
                                                    _loadInitialData();
                                                  } catch (e) {
                                                    if (!mounted) return;
                                                    _showSnackBar('$errPrefix: $e', isError: true);
                                                  }
                                                },
                                              );
                                            }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_business_rounded, color: AdminTheme.info),
                                tooltip: context.tr('aff_add_std'),
                                onPressed: () => _openAssignStdModal(u),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Onglet 3: Entités (Ministères & PTFs)
  Widget _buildEntitesTab(bool isDark) {
    final double hPad = AdminTheme.horizontalPadding(context);
    final bool isMobile = AdminTheme.isMobile(context);
    final filteredEntites = _entites.where((e) {
      final matchCat = _entiteCategorieFilter == 'all' || e['categorie'] == _entiteCategorieFilter;
      final q = _searchQuery.toLowerCase();
      final matchQuery = q.isEmpty || (e['nom'] ?? '').toString().toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: isMobile
              ? Column(
                  children: [
                    _buildSearchBar(context.tr('aff_search_entite'), isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _entiteCategorieFilter,
                            decoration: _inputDecoration(isDark: isDark),
                            dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'all', child: Text(context.tr('toutes_categories'), overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'ministere', child: Text(context.tr('ministeres'), overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'ptf', child: Text(context.tr('ptfs'), overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) => setState(() => _entiteCategorieFilter = val ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                              side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                            ),
                          ),
                          onPressed: _loadInitialData,
                          icon: Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, size: 20),
                          tooltip: context.tr('actualiser'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                          ),
                          onPressed: () => _openEntiteForm(),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Créer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchBar(context.tr('aff_search_entite'), isDark: isDark)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        initialValue: _entiteCategorieFilter,
                        decoration: _inputDecoration(isDark: isDark),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(context.tr('toutes_categories'))),
                          DropdownMenuItem(value: 'ministere', child: Text(context.tr('ministeres'))),
                          DropdownMenuItem(value: 'ptf', child: Text(context.tr('ptfs'))),
                        ],
                        onChanged: (val) => setState(() => _entiteCategorieFilter = val ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                      tooltip: context.tr('actualiser'),
                      onPressed: _loadInitialData,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                      ),
                      onPressed: () => _openEntiteForm(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.tr('aff_creer_entite')),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, isMobile ? 100 : hPad),
                  itemCount: filteredEntites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final e = filteredEntites[i];
                    final isMinistere = e['categorie'] == 'ministere';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AdminTheme.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                        border: Border.all(
                          color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                        ),
                        boxShadow: AdminTheme.shadowSm,
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AdminTheme.iconBox(
                                      isMinistere ? Icons.account_balance_rounded : Icons.public_rounded,
                                      isMinistere ? AdminTheme.primary : AdminTheme.purple,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        e['nom'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    AdminTheme.badge(
                                      e['categorie']?.toUpperCase() ?? '',
                                      isMinistere ? AdminTheme.primary : AdminTheme.purple,
                                    ),
                                  ],
                                ),
                                if (e['description'] != null && e['description'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      e['description'].toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        e['status'] == 'disabled' ? Icons.block : Icons.check_circle_outline,
                                        color: e['status'] == 'disabled' ? AdminTheme.warning : AdminTheme.primary,
                                      ),
                                      tooltip: e['status'] == 'disabled' ? context.tr('activer') : context.tr('desactiver'),
                                      onPressed: () => _toggleEntiteStatus(e),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: AdminTheme.info),
                                      tooltip: context.tr('modifier'),
                                      onPressed: () => _openEntiteForm(entite: e),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AdminTheme.danger),
                                      tooltip: context.tr('supprimer'),
                                      onPressed: () => _deleteEntite(e['id']),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                AdminTheme.iconBox(
                                  isMinistere ? Icons.account_balance_rounded : Icons.public_rounded,
                                  isMinistere ? AdminTheme.primary : AdminTheme.purple,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              e['nom'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AdminTheme.badge(
                                            e['categorie']?.toUpperCase() ?? '',
                                            isMinistere ? AdminTheme.primary : AdminTheme.purple,
                                          ),
                                        ],
                                      ),
                                      if (e['description'] != null && e['description'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            e['description'].toString(),
                                            style: TextStyle(
                                              color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    e['status'] == 'disabled' ? Icons.block : Icons.check_circle_outline,
                                    color: e['status'] == 'disabled' ? AdminTheme.warning : AdminTheme.primary,
                                  ),
                                  tooltip: e['status'] == 'disabled' ? context.tr('activer') : context.tr('desactiver'),
                                  onPressed: () => _toggleEntiteStatus(e),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: AdminTheme.info),
                                  tooltip: context.tr('modifier'),
                                  onPressed: () => _openEntiteForm(entite: e),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AdminTheme.danger),
                                  tooltip: context.tr('supprimer'),
                                  onPressed: () => _deleteEntite(e['id']),
                                ),
                              ],
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Onglet 4: STDs (Services Techniques Déconcentrés) — Grid Cards
  Widget _buildStdsTab(bool isDark) {
    final double hPad = AdminTheme.horizontalPadding(context);
    final bool isMobile = AdminTheme.isMobile(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    final filteredStds = _stds.where((s) {
      final matchEntite = _stdEntiteFilter == 'all' || s['entiteId']?.toString() == _stdEntiteFilter;
      final q = _searchQuery.toLowerCase();
      final matchQuery = q.isEmpty ||
          (s['nom'] ?? '').toString().toLowerCase().contains(q) ||
          (s['description'] ?? '').toString().toLowerCase().contains(q);
      bool matchTerritoire = true;
      if (_stdTerritoireFilter != 'all') {
        final terrs = s['territoires'] as List? ?? [];
        matchTerritoire = terrs.any((t) =>
            t['formatted_id']?.toString() == _stdTerritoireFilter ||
            t['formattedId']?.toString() == _stdTerritoireFilter);
      }
      return matchEntite && matchQuery && matchTerritoire;
    }).toList();

    int crossAxisCount = 1;
    if (screenWidth >= 1100) {
      crossAxisCount = 3;
    } else if (screenWidth >= 680) {
      crossAxisCount = 2;
    }

    Color terrChipColor(String? type) {
      if (type == 'region') return const Color(0xFF3B82F6);
      if (type == 'district') return const Color(0xFF10B981);
      if (type == 'commune') return const Color(0xFFF59E0B);
      return AdminTheme.info;
    }

    Widget buildStdCard(dynamic s) {
      final sId = s['id']?.toString() ?? '';
      final parentEntite = _entites.firstWhere(
        (e) => e['id'].toString() == s['entiteId']?.toString(),
        orElse: () => <String, dynamic>{'nom': 'Ministère #${s['entiteId']}'},
      );
      final terrs = (s['territoires'] as List?) ?? [];

      return Container(
        decoration: BoxDecoration(
          color: isDark ? AdminTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          border: Border.all(
            color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
            width: 1,
          ),
          boxShadow: AdminTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (s['nom'] ?? '').toString().toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 15,
                      color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: $sId',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, size: 14, color: AdminTheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (parentEntite['nom'] ?? '').toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (s['description'] != null && s['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  s['description'].toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 12, color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                  Text(
                    'Territoires (${terrs.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (terrs.isEmpty)
                    Text(
                      'Aucun territoire',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: terrs.take(4).map<Widget>((t) {
                        final fId = t['formatted_id']?.toString() ?? t['formattedId']?.toString() ?? '';
                        final nom = t['name']?.toString() ?? t['nom']?.toString() ?? fId;
                        final type = t['type']?.toString();
                        final chipColor = terrChipColor(type);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: chipColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '$nom${type != null ? ' ($type)' : ''}',
                            style: TextStyle(fontSize: 10, color: chipColor, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList()
                        ..addAll(terrs.length > 4
                            ? [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '+${terrs.length - 4}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
                                    ),
                                  ),
                                )
                              ]
                            : []),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.info,
                        side: const BorderSide(color: AdminTheme.info),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _openStdForm(std: s),
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: Text(context.tr('modifier'), style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.danger,
                        side: const BorderSide(color: AdminTheme.danger),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _deleteStd(sId),
                      icon: const Icon(Icons.delete_outline_rounded, size: 15),
                      label: Text(context.tr('supprimer'), style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Barre de filtres ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 4),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchBar(context.tr('aff_search_std'), isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _stdEntiteFilter,
                            decoration: _inputDecoration(isDark: isDark, hint: context.tr('tous_ministeres')),
                            dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'all', child: Text(context.tr('tous_ministeres'), overflow: TextOverflow.ellipsis)),
                              ..._entites.where((e) => e['categorie'] == 'ministere').map(
                                    (e) => DropdownMenuItem(
                                      value: e['id'].toString(),
                                      child: Text(e['nom'] ?? '', overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                            ],
                            onChanged: (val) => setState(() => _stdEntiteFilter = val ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _stdTerritoireFilter,
                            decoration: _inputDecoration(isDark: isDark, hint: 'Territoires'),
                            dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('Tous territoires', overflow: TextOverflow.ellipsis)),
                              ...[..._regions, ..._districts, ..._communes].map((t) {
                                final fId = t['formatted_id']?.toString() ?? t['formattedId']?.toString() ?? '';
                                final nom = t['name']?.toString() ?? t['nom']?.toString() ?? fId;
                                return DropdownMenuItem(
                                  value: fId,
                                  child: Text(nom, overflow: TextOverflow.ellipsis),
                                );
                              }),
                            ],
                            onChanged: (val) => setState(() => _stdTerritoireFilter = val ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                              side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                            ),
                          ),
                          onPressed: _loadInitialData,
                          icon: Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, size: 20),
                          tooltip: context.tr('actualiser'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                            ),
                            onPressed: () => _openStdForm(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Créer STD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchBar(context.tr('aff_search_std'), isDark: isDark)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<String>(
                        initialValue: _stdEntiteFilter,
                        decoration: _inputDecoration(isDark: isDark),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(context.tr('tous_ministeres'), overflow: TextOverflow.ellipsis)),
                          ..._entites.where((e) => e['categorie'] == 'ministere').map(
                                (e) => DropdownMenuItem(
                                  value: e['id'].toString(),
                                  child: Text(e['nom'] ?? '', overflow: TextOverflow.ellipsis),
                                ),
                              ),
                        ],
                        onChanged: (val) => setState(() => _stdEntiteFilter = val ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 175,
                      child: DropdownButtonFormField<String>(
                        initialValue: _stdTerritoireFilter,
                        decoration: _inputDecoration(isDark: isDark),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Tous les territoires', overflow: TextOverflow.ellipsis)),
                          ...[..._regions, ..._districts, ..._communes].map((t) {
                            final fId = t['formatted_id']?.toString() ?? t['formattedId']?.toString() ?? '';
                            final nom = t['name']?.toString() ?? t['nom']?.toString() ?? fId;
                            final type = t['type']?.toString() ?? '';
                            return DropdownMenuItem(
                              value: fId,
                              child: Text('$nom ($type)', overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _stdTerritoireFilter = val ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                      tooltip: context.tr('actualiser'),
                      onPressed: _loadInitialData,
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                      ),
                      onPressed: () => _openStdForm(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.tr('aff_creer_std')),
                    ),
                  ],
                ),
        ),
        // ── Grille de cartes ──────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filteredStds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_outlined, size: 56, color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune STD trouvée',
                            style: TextStyle(color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : isMobile
                      ? ListView.separated(
                          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 100),
                          itemCount: filteredStds.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => buildStdCard(filteredStds[i]),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, hPad),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: filteredStds.length,
                          itemBuilder: (ctx, i) => buildStdCard(filteredStds[i]),
                        ),
        ),
      ],
    );
  }

  // Onglet 5: Territoires Utilisateur (User-Territoires)
  Widget _buildUserTerritoiresTab(bool isDark) {
    final double hPad = AdminTheme.horizontalPadding(context);
    final bool isMobile = AdminTheme.isMobile(context);

    final filteredUsers = _users.where((u) {
      final uId = _getUserId(u);
      final hasTerritory = _userTerritoires.any(
          (ut) => ut['userId']?.toString() == uId || ut['user_id']?.toString() == uId);

      if (_territoireUserFilter == 'assigned' && !hasTerritory) return false;

      final name = _getUserName(u).toLowerCase();
      final email = _getUserEmail(u).toLowerCase();
      final cin = _getUserCin(u).toLowerCase();
      final phone = _getUserPhone(u).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || email.contains(q) || cin.contains(q) || phone.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: isMobile
              ? Column(
                  children: [
                    _buildSearchBar(context.tr('aff_search_user'), isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _territoireUserFilter,
                            decoration: _inputDecoration(isDark: isDark),
                            dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'assigned', child: Text('Avec territoire affecté', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) => setState(() => _territoireUserFilter = val ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                              side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                            ),
                          ),
                          onPressed: _loadInitialData,
                          icon: Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, size: 20),
                          tooltip: context.tr('actualiser'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchBar(context.tr('aff_search_user'), isDark: isDark)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 230,
                      child: DropdownButtonFormField<String>(
                        initialValue: _territoireUserFilter,
                        decoration: _inputDecoration(isDark: isDark),
                        dropdownColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                          DropdownMenuItem(value: 'assigned', child: Text('Avec territoire affecté')),
                        ],
                        onChanged: (val) => setState(() => _territoireUserFilter = val ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                      tooltip: context.tr('actualiser'),
                      onPressed: _loadInitialData,
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, isMobile ? 100 : hPad),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final u = filteredUsers[i];
                    final uId = _getUserId(u);
                    final userTerrs = _userTerritoires
                        .where((ut) => ut['userId']?.toString() == uId || ut['user_id']?.toString() == uId)
                        .toList();
                    final cinStr = _getUserCin(u);
                    final phoneStr = _getUserPhone(u);
                    final emailStr = _getUserEmail(u);

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                        onTap: () => _openAssignTerritoireModal(u),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AdminTheme.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                            border: Border.all(
                              color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                            ),
                            boxShadow: AdminTheme.shadowSm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUserAvatar(u, size: 44),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          _getUserName(u),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                          ),
                                        ),
                                        AdminTheme.badge('CIN: $cinStr', AdminTheme.purple),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (emailStr.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.email_outlined, size: 13, color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted),
                                              const SizedBox(width: 4),
                                              ConstrainedBox(
                                                constraints: BoxConstraints(maxWidth: isMobile ? 140 : 300),
                                                child: Text(
                                                  emailStr,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.phone_outlined, size: 13, color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tél: $phoneStr',
                                              style: TextStyle(
                                                color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: userTerrs.isEmpty
                                          ? [AdminTheme.badge(context.tr('aff_aucun_territoire'), Colors.grey)]
                                          : userTerrs.map((ut) {
                                              final fId = ut['formatted_id'] ?? ut['formattedId'];
                                              return Chip(
                                                backgroundColor: AdminTheme.purple.withValues(alpha: 0.1),
                                                label: Text("${context.tr('territoire')} #$fId", style: const TextStyle(color: AdminTheme.purple, fontSize: 12)),
                                                deleteIcon: const Icon(Icons.close, size: 14),
                                                onDeleted: () async {
                                                  try {
                                                    await AffiliationService.deleteUserTerritoire(ut['id']);
                                                    _showSnackBar('Territoire retiré');
                                                    _loadInitialData();
                                                  } catch (e) {
                                                    _showSnackBar('Erreur: $e', isError: true);
                                                  }
                                                },
                                              );
                                            }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_location_alt_rounded, color: AdminTheme.purple),
                                tooltip: 'Affecter un territoire',
                                onPressed: () => _openAssignTerritoireModal(u),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Onglet 6: Offres d'Appui
  Widget _buildOffresTab(bool isDark) {
    final double hPad = AdminTheme.horizontalPadding(context);
    final bool isMobile = AdminTheme.isMobile(context);

    final filteredOffres = _offres.where((o) {
      final q = _searchQuery.toLowerCase();
      final titre = (o['titre'] ?? o['nom'] ?? '').toString().toLowerCase();
      final desc = (o['description'] ?? '').toString().toLowerCase();
      return q.isEmpty || titre.contains(q) || desc.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: isMobile
              ? Column(
                  children: [
                    _buildSearchBar(context.tr('aff_search_offre'), isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AdminTheme.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                              side: BorderSide(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
                            ),
                          ),
                          onPressed: _loadInitialData,
                          icon: Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary, size: 20),
                          tooltip: context.tr('actualiser'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                            ),
                            onPressed: () => _openOffreForm(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Nouvelle offre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchBar(context.tr('aff_search_offre'), isDark: isDark)),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh_rounded, color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary),
                      tooltip: context.tr('actualiser'),
                      onPressed: _loadInitialData,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
                      ),
                      onPressed: () => _openOffreForm(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nouvelle offre'),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, isMobile ? 100 : hPad),
                  itemCount: filteredOffres.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final o = filteredOffres[i];
                    final stdIdStr = o['stdId']?.toString() ?? o['std_id']?.toString();
                    final parentStd = _stds.firstWhere(
                      (s) => s['id']?.toString() == stdIdStr,
                      orElse: () => <String, dynamic>{'nom': stdIdStr != null ? 'STD #$stdIdStr' : 'Aucun STD'},
                    );

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AdminTheme.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                        border: Border.all(
                          color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight,
                        ),
                        boxShadow: AdminTheme.shadowSm,
                      ),
                      child: Row(
                        children: [
                          AdminTheme.iconBox(Icons.handshake_rounded, AdminTheme.accent),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      o['titre'] ?? o['nom'] ?? 'Offre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
                                      ),
                                    ),
                                    AdminTheme.badge(parentStd['nom'] ?? '', AdminTheme.accent),
                                  ],
                                ),
                                if (o['description'] != null && o['description'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      o['description'].toString(),
                                      style: TextStyle(
                                        color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: AdminTheme.info),
                            tooltip: context.tr('modifier'),
                            onPressed: () => _openOffreForm(offre: o),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AdminTheme.danger),
                            tooltip: context.tr('supprimer'),
                            onPressed: () async {
                              try {
                                await AffiliationService.deleteOffre(o['id'].toString());
                                _showSnackBar('Offre supprimée');
                                _loadInitialData();
                              } catch (e) {
                                _showSnackBar('Erreur suppression: $e', isError: true);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── BUILD PILL TAB DYNAMIQUE & MODERNE ──────────────────────────────────────

  Widget _buildPillTab({
    required int index,
    required String label,
    required IconData icon,
    required String badgeCount,
    required bool isDark,
  }) {
    final bool isSelected = _tabController.index == index;

    return Tab(
      height: 40,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF098E00)
              : (isDark ? AdminTheme.surface2Dark : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF098E00)
                : (isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF098E00).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AdminTheme.textSecondaryDark : const Color(0xFF475569)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AdminTheme.textPrimaryDark : const Color(0xFF334155)),
              ),
            ),
            if (badgeCount.isNotEmpty && badgeCount != '0') ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AdminTheme.textMutedDark : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── BUILD PRINCIPAL ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = AdminTheme.isMobile(context);
    final double hPad = AdminTheme.horizontalPadding(context);

    return Scaffold(
      backgroundColor: isDark ? AdminTheme.bgDark : AdminTheme.bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AdminTheme.surfaceDark : AdminTheme.primary,
        titleSpacing: hPad,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('aff_gestion_titre'),
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                if (!isMobile)
                  Text(
                    '${_users.length} utilisateurs • ${_affiliations.length} aff. entités • ${_userTerritoires.length} territoires • ${_affiliationStds.length} aff. STD',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: hPad),
            child: IconButton(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: context.tr('actualiser'),
              onPressed: _loadInitialData,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 54 : 58),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AdminTheme.borderDark : const Color(0xFF334155),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                _buildPillTab(
                  index: 0,
                  label: context.tr('aff_tab_users'),
                  icon: Icons.group_outlined,
                  badgeCount: _affiliations.length.toString(),
                  isDark: isDark,
                ),
                _buildPillTab(
                  index: 1,
                  label: context.tr('aff_tab_entites_short'),
                  icon: Icons.apartment_outlined,
                  badgeCount: _entites.length.toString(),
                  isDark: isDark,
                ),
                _buildPillTab(
                  index: 2,
                  label: context.tr('aff_tab_stds_short'),
                  icon: Icons.business_outlined,
                  badgeCount: _stds.length.toString(),
                  isDark: isDark,
                ),
                _buildPillTab(
                  index: 3,
                  label: context.tr('aff_tab_territoires_short'),
                  icon: Icons.map_outlined,
                  badgeCount: _userTerritoires.length.toString(),
                  isDark: isDark,
                ),
                _buildPillTab(
                  index: 4,
                  label: context.tr('aff_tab_offres_short'),
                  icon: Icons.handshake_outlined,
                  badgeCount: _offres.length.toString(),
                  isDark: isDark,
                ),
                _buildPillTab(
                  index: 5,
                  label: context.tr('aff_tab_affiliation_std'),
                  icon: Icons.account_tree_outlined,
                  badgeCount: _affiliationStds.length.toString(),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAffiliationsTab(isDark),
          _buildEntitesTab(isDark),
          _buildStdsTab(isDark),
          _buildUserTerritoiresTab(isDark),
          _buildOffresTab(isDark),
          _buildAffiliationsStdTab(isDark),
        ],
      ),
    );
  }
}
