import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// -----------------------------------------------------------------------------
// MODÈLES DE DONNÉES
// -----------------------------------------------------------------------------
class Acte {
  final dynamic id;
  final String titre;
  final String? description;
  final String statut;
  final String? dateCreation;
  final String? dateLimite;
  final int? delaiJours;
  final String? communeId;
  final String? communeName;
  final String? districtId;
  final String? districtName;
  final String? fichierUrl;
  final String? fichierName;
  final List<String> typeNames;
  final List<String> sousTypeNames;

  Acte({
    required this.id,
    required this.titre,
    this.description,
    required this.statut,
    this.dateCreation,
    this.dateLimite,
    this.delaiJours,
    this.communeId,
    this.communeName,
    this.districtId,
    this.districtName,
    this.fichierUrl,
    this.fichierName,
    required this.typeNames,
    required this.sousTypeNames,
  });

  factory Acte.fromJson(Map<String, dynamic> json) {
    var typesList = json['types'] as List? ?? [];
    var sousTypesList = json['sous_types'] as List? ?? [];

    return Acte(
      id: json['id'],
      titre: json['titre'] ?? 'Sans titre',
      description: json['description'],
      statut: json['statut'] ?? 'en_cours',
      dateCreation: json['created_at'] ?? json['date_creation'],
      dateLimite: json['date_limite'],
      delaiJours: json['delai_jours'],
      communeId: json['commune_id']?.toString(),
      communeName: json['commune_name'] ?? json['commune']?['name'],
      districtId: json['district_id']?.toString(),
      districtName: json['district_name'] ?? json['district']?['name'],
      fichierUrl: json['fichier_url'] ?? json['fichier'],
      fichierName: json['fichier_name'],
      typeNames: typesList.map((t) => t['nom'].toString()).toList(),
      sousTypeNames: sousTypesList.map((st) => st['nom'].toString()).toList(),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET PRINCIPAL : CONTROLE LEGALITE PAGE
// -----------------------------------------------------------------------------
class AdminControleLegalitePage extends StatefulWidget {
  final String baseUrl;
  final Map<String, dynamic> currentUser;

  const AdminControleLegalitePage({
    super.key,
    required this.baseUrl,
    required this.currentUser,
  });

  @override
  _AdminControleLegalitePageState createState() => _AdminControleLegalitePageState();
}

class _AdminControleLegalitePageState extends State<AdminControleLegalitePage> {
  String? _selectedActId;

  void _viewDetails(String id) {
    setState(() => _selectedActId = id);
  }

  void _backToList() {
    setState(() => _selectedActId = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedActId != null) {
      return ActDetailsView(
        actId: _selectedActId!,
        baseUrl: widget.baseUrl,
        onBack: _backToList,
      );
    }
    return ActListView(
      baseUrl: widget.baseUrl,
      currentUser: widget.currentUser,
      onViewDetails: _viewDetails,
    );
  }
}

// -----------------------------------------------------------------------------
// VUE LISTE DES ACTES
// -----------------------------------------------------------------------------
class ActListView extends StatefulWidget {
  final String baseUrl;
  final Map<String, dynamic> currentUser;
  final Function(String) onViewDetails;

  const ActListView({
    super.key,
    required this.baseUrl,
    required this.currentUser,
    required this.onViewDetails,
  });

  @override
  _ActListViewState createState() => _ActListViewState();
}

class _ActListViewState extends State<ActListView> {
  List<Acte> _actes = [];
  List<dynamic> _communes = [];
  List<dynamic> _typesActes = [];
  List<dynamic> _sousTypesActes = [];

  bool _loading = true;
  bool _loadingStats = true;
  
  // Statistiques
  int _totalStats = 0;
  int _pendingStats = 0;
  int _acceptedStats = 0;
  int _observationStats = 0;

  // Filtres & Pagination
  int _page = 1;
  int _totalPages = 1;
  final int _limit = 10;
  
  String _searchTerm = '';
  String _communeFilter = 'Tout';
  String _typeActeFilter = 'Tout';
  String _sousTypeActeFilter = 'Tout';
  String _statutFilter = 'Tout';

  @override
  void initState() {
    super.initState();
    _loadInitialFiltersData();
    _loadStats();
    _loadActes();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('access_token');
    if (raw == null) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map && parsed.containsKey('access_token')) {
        return parsed['access_token'];
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _loadInitialFiltersData() async {
    final token = await _getToken();
    final headers = {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};

    // Charger communes
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/serviceterritoire-v2/communes'), headers: headers);
      if (res.statusCode == 200) {
        setState(() => _communes = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Erreur communes: $e');
    }

    // Charger types d'actes
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/controlelegalite/types-actes'), headers: headers);
      if (res.statusCode == 200) {
        setState(() => _typesActes = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Erreur types d\'actes: $e');
    }
  }

  Future<void> _loadSousTypes(String typeId) async {
    if (typeId == 'Tout') {
      setState(() {
        _sousTypesActes = [];
        _sousTypeActeFilter = 'Tout';
      });
      return;
    }
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/controlelegalite/types-actes/$typeId/sous-types'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _sousTypesActes = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Erreur sous-types: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      setState(() => _loadingStats = true);
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/controlelegalite/stats/general'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (data != null) {
          final totals = data['totals'] ?? {};
          final parStatut = (data['actes']?['parStatut'] as List?) ?? [];
          
          int recu = parStatut.firstWhere((s) => s['statut'] == 'recu', orElse: () => {'count': 0})['count'];
          int accepte = parStatut.firstWhere((s) => s['statut'] == 'accepte', orElse: () => {'count': 0})['count'];

          setState(() {
            _totalStats = totals['actes'] ?? 0;
            _pendingStats = recu;
            _acceptedStats = accepte;
            _observationStats = totals['observations'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur stats: $e');
    } finally {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadActes() async {
    try {
      setState(() => _loading = true);
      final token = await _getToken();
      final districtId = widget.currentUser['district_id'];

      Uri url;
      if (districtId != null) {
        url = Uri.parse('${widget.baseUrl}/controlelegalite/actes/district/$districtId?page=$_page&limit=$_limit');
      } else {
        String queryParams = '?page=$_page&limit=$_limit';
        if (_searchTerm.isNotEmpty) queryParams += '&titre=$_searchTerm';
        if (_communeFilter != 'Tout') queryParams += '&commune_id=$_communeFilter';
        if (_statutFilter != 'Tout') queryParams += '&statut=$_statutFilter';
        if (_typeActeFilter != 'Tout') queryParams += '&type_id=$_typeActeFilter';
        if (_sousTypeActeFilter != 'Tout') queryParams += '&sous_type_id=$_sousTypeActeFilter';

        url = Uri.parse('${widget.baseUrl}/controlelegalite/actes$queryParams');
      }

      final res = await http.get(url, headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] ?? [];
        setState(() {
          _actes = data.map((json) => Acte.fromJson(json)).toList();
          _totalPages = decoded['pagination']?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement actes: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatut(dynamic id, String statut) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest('PUT', Uri.parse('${widget.baseUrl}/controlelegalite/actes/$id'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields['statut'] = statut;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Statut mis à jour avec succès")));
        _loadActes();
        _loadStats();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la mise à jour")));
      }
    } catch (e) {
      debugPrint('Erreur action acte: $e');
    }
  }

  Future<void> _deleteActe(dynamic id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirmation"),
            content: const Text("Voulez-vous vraiment supprimer cet acte ?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse('${widget.baseUrl}/controlelegalite/actes/$id'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acte supprimé")));
        _loadActes();
        _loadStats();
      }
    } catch (e) {
      debugPrint('Erreur suppression: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.gavel, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Contrôle de Légalité", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Supervision et validation des actes administratifs", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cartes Statistiques
            _loadingStats
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(child: _buildStatCard("Total Actes", _totalStats.toString(), Icons.folder, Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard("En attente", _pendingStats.toString(), Icons.hourglass_top, Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard("Acceptés", _acceptedStats.toString(), Icons.check_circle, Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard("Observations", _observationStats.toString(), Icons.visibility, Colors.purple)),
                    ],
                  ),
            const SizedBox(height: 24),

            // Filtres & Recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() => _searchTerm = val);
                      _loadActes();
                    },
                    decoration: InputDecoration(
                      hintText: "Rechercher par titre...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Filtre Commune
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: _communeFilter,
                          items: [
                            const DropdownMenuItem(value: 'Tout', child: Text("Toutes les communes")),
                            ..._communes.map((c) => DropdownMenuItem(value: c['formatted_id']?.toString() ?? c['id'].toString(), child: Text(c['name'] ?? c['nom'] ?? 'Commune'))),
                          ],
                          onChanged: (val) {
                            setState(() => _communeFilter = val!);
                            _loadActes();
                          },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        ),
                      ),
                      // Filtre Statut
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _statutFilter,
                          items: const [
                            DropdownMenuItem(value: 'Tout', child: Text("Tous les statuts")),
                            DropdownMenuItem(value: 'en_cours', child: Text("En attente")),
                            DropdownMenuItem(value: 'accepte', child: Text("Accepté")),
                            DropdownMenuItem(value: 'rejete', child: Text("Rejeté")),
                          ],
                          onChanged: (val) {
                            setState(() => _statutFilter = val!);
                            _loadActes();
                          },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        ),
                      ),
                      // Filtre Type d'acte
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: _typeActeFilter,
                          items: [
                            const DropdownMenuItem(value: 'Tout', child: Text("Tous les types")),
                            ..._typesActes.map((t) => DropdownMenuItem(value: t['id'].toString(), child: Text(t['nom']))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _typeActeFilter = val!;
                              _sousTypeActeFilter = 'Tout';
                            });
                            _loadSousTypes(val!);
                            _loadActes();
                          },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        ),
                      ),
                      // Filtre Sous-type d'acte
                      if (_sousTypesActes.isNotEmpty)
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: _sousTypeActeFilter,
                            items: [
                              const DropdownMenuItem(value: 'Tout', child: Text("Tous les sous-types")),
                              ..._sousTypesActes.map((st) => DropdownMenuItem(
                                    value: st['id'].toString(),
                                    child: Text(st['nom'] ?? st['libelle'] ?? 'Sous-type'),
                                  )),
                            ],
                            onChanged: (val) {
                              setState(() => _sousTypeActeFilter = val!);
                              _loadActes();
                            },
                            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tableau des actes
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  : _actes.isEmpty
                      ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("Aucun acte trouvé")))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _actes.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final acte = _actes[index];
                            return ListTile(
                              title: Text(acte.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Commune : ${acte.communeName ?? 'N/A'} | District : ${acte.districtName ?? 'N/A'}"),
                                  Text("Types : ${acte.typeNames.join(', ')}", style: const TextStyle(color: Colors.green, fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildBadgeStatus(acte.statut),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blue),
                                    onPressed: () => widget.onViewDetails(acte.id.toString()),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _updateStatut(acte.id, 'accepte'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.orange),
                                    onPressed: () => _updateStatut(acte.id, 'rejete'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteActe(acte.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            // Pagination basique
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _page > 1 ? () { setState(() => _page--); _loadActes(); } : null,
                  child: const Text("Précédent"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Page $_page sur $_totalPages"),
                ),
                ElevatedButton(
                  onPressed: _page < _totalPages ? () { setState(() => _page++); _loadActes(); } : null,
                  child: const Text("Suivant"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStatus(String statut) {
    Color color = Colors.orange;
    String label = 'En attente';
    if (statut == 'accepte') {
      color = Colors.green;
      label = 'Accepté';
    } else if (statut == 'rejete') {
      color = Colors.red;
      label = 'Rejeté';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// -----------------------------------------------------------------------------
// VUE DETAILS DE L'ACTE
// -----------------------------------------------------------------------------
class ActDetailsView extends StatefulWidget {
  final String actId;
  final String baseUrl;
  final VoidCallback onBack;

  const ActDetailsView({super.key, required this.actId, required this.baseUrl, required this.onBack});

  @override
  _ActDetailsViewState createState() => _ActDetailsViewState();
}

class _ActDetailsViewState extends State<ActDetailsView> {
  Acte? _acte;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActeDetails();
  }

  Future<void> _loadActeDetails() async {
    try {
      setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/controlelegalite/actes/${widget.actId}'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _acte = Acte.fromJson(jsonDecode(res.body)));
      }
    } catch (e) {
      debugPrint('Erreur details acte: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openFile(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir le fichier")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_acte == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Acte introuvable"),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: widget.onBack, child: const Text("Retour")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Retour à la liste"),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_acte!.titre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  _buildDetailRow("Commune", _acte!.communeName ?? 'N/A'),
                  _buildDetailRow("District", _acte!.districtName ?? 'N/A'),
                  _buildDetailRow("Statut", _acte!.statut),
                  _buildDetailRow("Types d'actes", _acte!.typeNames.join(', ')),
                  _buildDetailRow("Sous-types", _acte!.sousTypeNames.join(', ')),
                  _buildDetailRow("Description", _acte!.description ?? 'Aucune description'),
                  const SizedBox(height: 24),
                  if (_acte!.fichierUrl != null)
                    ElevatedButton.icon(
                      onPressed: () => _openFile(_acte!.fichierUrl!),
                      icon: const Icon(Icons.download),
                      label: const Text("Visualiser / Télécharger la pièce jointe"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}