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
  final String? dateModification;
  final String? dateLimite;
  final int? delaiJours;
  final String? communeId;
  final String? communeName;
  final String? districtId;
  final String? districtName;
  final String? fichierUrl;
  final List<String> typeNames;
  final List<String> sousTypeNames;
  final List<dynamic> typeIds;
  final List<dynamic> sousTypeIds;

  Acte({
    required this.id,
    required this.titre,
    this.description,
    required this.statut,
    this.dateCreation,
    this.dateModification,
    this.dateLimite,
    this.delaiJours,
    this.communeId,
    this.communeName,
    this.districtId,
    this.districtName,
    this.fichierUrl,
    required this.typeNames,
    required this.sousTypeNames,
    required this.typeIds,
    required this.sousTypeIds,
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
      dateModification: json['updated_at'] ?? json['date_modification'],
      dateLimite: json['date_limite'],
      delaiJours: json['delai_jours'],
      communeId: json['commune_id']?.toString(),
      communeName: json['commune_name'] ?? json['commune']?['name'],
      districtId: json['district_id']?.toString(),
      districtName: json['district_name'] ?? json['district']?['name'],
      fichierUrl: json['fichier_url'] ?? json['fichier'],
      typeNames: typesList.map((t) => t['nom'].toString()).toList(),
      sousTypeNames: sousTypesList.map((st) => st['nom'].toString()).toList(),
      typeIds: typesList.map((t) => t['id']).toList(),
      sousTypeIds: sousTypesList.map((st) => st['id']).toList(),
    );
  }
}

class TypeActe {
  final dynamic id;
  final String nom;

  TypeActe({required this.id, required this.nom});

  factory TypeActe.fromJson(Map<String, dynamic> json) {
    return TypeActe(
      id: json['id'],
      nom: json['nom'] ?? '',
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANT STATUS BADGE
// -----------------------------------------------------------------------------
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    String label;

    switch (status) {
      case 'recu':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        border = Colors.blue.shade200;
        label = 'Reçu';
        break;
      case 'accepte':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        border = Colors.green.shade200;
        label = 'Accepté';
        break;
      case 'rejete':
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        border = Colors.red.shade200;
        label = 'Rejeté';
        break;
      case 'observation':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade700;
        border = Colors.orange.shade200;
        label = 'Observation';
        break;
      case 'en_cours':
      default:
        bg = Colors.yellow.shade50;
        text = Colors.yellow.shade800;
        border = Colors.yellow.shade200;
        label = 'En cours';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAGE PRINCIPALE : COMMUNE CONTROLE LEGALITE
// -----------------------------------------------------------------------------
class CommuneControleLegalite extends StatefulWidget {
  final String baseUrl;
  final Map<String, dynamic> currentUser;
  final VoidCallback? onNavigateToNouvelActe;

  const CommuneControleLegalite({
    super.key,
    required this.baseUrl,
    required this.currentUser,
    this.onNavigateToNouvelActe,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CommuneControleLegaliteState createState() => _CommuneControleLegaliteState();
}

class _CommuneControleLegaliteState extends State<CommuneControleLegalite> {
  List<Acte> _actes = [];
  List<TypeActe> _typesActes = [];
  
  bool _loadingActes = false;
  bool _loadingDetails = false;
  
  String _searchTerm = '';
  String _statutFilter = 'Tout';
  String _typeActeFilter = 'Tout';
  
  String _currentView = 'list'; // 'list' ou 'details'
  Acte? _selectedActe;

  // Pagination
  int _page = 1;
  int _totalPages = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadTypesActes();
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

  Future<void> _loadTypesActes() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/controlelegalite/types-actes'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _typesActes = data.map((json) => TypeActe.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement types d\'actes: $e');
    }
  }

  Future<void> _loadActes() async {
    final municipalityId = widget.currentUser['municipality_id'] ?? widget.currentUser['commune_id'];
    if (municipalityId == null) {
      debugPrint('Utilisateur sans municipality_id');
      return;
    }

    try {
      setState(() => _loadingActes = true);
      final token = await _getToken();
      
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/controlelegalite/actes/commune/$municipalityId?page=$_page&limit=$_limit'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] ?? [];
        
        List<Acte> loadedActes = data.map((json) => Acte.fromJson(json)).toList();

        // Filtres locaux si besoin
        if (_searchTerm.isNotEmpty) {
          loadedActes = loadedActes.where((a) => a.titre.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
        }
        if (_statutFilter != 'Tout') {
          loadedActes = loadedActes.where((a) => a.statut == _statutFilter).toList();
        }
        if (_typeActeFilter != 'Tout') {
          loadedActes = loadedActes.where((a) => a.typeIds.contains(_typeActeFilter) || a.typeIds.contains(int.tryParse(_typeActeFilter))).toList();
        }

        setState(() {
          _actes = loadedActes;
          _totalPages = decoded['totalPages'] ?? decoded['pagination']?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement actes commune: $e');
      setState(() => _actes = []);
    } finally {
      setState(() => _loadingActes = false);
    }
  }

  Future<void> _handleViewDetails(dynamic acteId) async {
    try {
      setState(() => _loadingDetails = true);
      final token = await _getToken();
      
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/controlelegalite/actes/$acteId'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final acteData = jsonDecode(res.body);
        setState(() {
          _selectedActe = Acte.fromJson(acteData);
          _currentView = 'details';
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement détails acte: $e');
    } finally {
      setState(() => _loadingDetails = false);
    }
  }

  void _handleBackToList() {
    setState(() {
      _currentView = 'list';
      _selectedActe = null;
    });
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // VUE DETAILS
    // -------------------------------------------------------------------------
    if (_currentView == 'details') {
      if (_loadingDetails) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.green)),
        );
      }

      if (_selectedActe == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text("Acte introuvable", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _handleBackToList, child: const Text("Retour à la liste")),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.grey[550],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: _handleBackToList,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Retour à la liste des actes"),
              ),
              const SizedBox(height: 16),
              const Text(
                "Détails de l'acte",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Text("Consultez les informations complètes de votre acte.", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.description, color: Colors.green, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _selectedActe!.titre,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoBlock("Date de soumission", _formatDate(_selectedActe!.dateCreation)),
                              const SizedBox(height: 16),
                              _buildInfoBlock("Date limite de traitement", _selectedActe!.dateLimite != null ? _formatDate(_selectedActe!.dateLimite) : 'N/A'),
                              const SizedBox(height: 16),
                              _buildInfoBlock("Commune", _selectedActe!.communeName ?? _selectedActe!.communeId ?? 'N/A'),
                              const SizedBox(height: 16),
                              _buildInfoBlock("District", _selectedActe!.districtName ?? _selectedActe!.districtId ?? 'N/A'),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Statut actuel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            StatusBadge(status: _selectedActe!.statut),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Informations principales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          _buildInfoBlock("Type d'acte", _selectedActe!.typeNames.join(', ')),
                          if (_selectedActe!.sousTypeNames.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoBlock("Sous-type", _selectedActe!.sousTypeNames.join(', ')),
                          ],
                          const SizedBox(height: 8),
                          _buildInfoBlock("Description", _selectedActe!.description ?? 'Aucune description'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedActe!.fichierUrl != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.blue),
                            const SizedBox(width: 12),
                            const Expanded(child: Text("Pièce jointe disponible", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                            ElevatedButton.icon(
                              onPressed: () => _openFile(_selectedActe!.fichierUrl!),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text("Visualiser"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleBackToList,
                      child: const Text("Retour"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // VUE LISTE (PAR DÉFAUT)
    // -------------------------------------------------------------------------
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Contrôle de Légalité", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Déposez vos actes et suivez leur traitement", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: widget.onNavigateToNouvelActe,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Nouvel acte", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C21C),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Liste des actes soumis
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
                  Row(
                    children: const [
                      Icon(Icons.folder_open, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Mes actes soumis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filtres
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
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
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _statutFilter,
                          items: const [
                            DropdownMenuItem(value: 'Tout', child: Text("Tous les statuts")),
                            DropdownMenuItem(value: 'recu', child: Text("Reçu")),
                            DropdownMenuItem(value: 'en_cours', child: Text("En cours")),
                            DropdownMenuItem(value: 'accepte', child: Text("Accepté")),
                            DropdownMenuItem(value: 'rejete', child: Text("Rejeté")),
                            DropdownMenuItem(value: 'observation', child: Text("Observation")),
                          ],
                          onChanged: (val) {
                            setState(() => _statutFilter = val!);
                            _loadActes();
                          },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _typeActeFilter,
                          items: [
                            const DropdownMenuItem(value: 'Tout', child: Text("Tous les types")),
                            ..._typesActes.map((t) => DropdownMenuItem(value: t.id.toString(), child: Text(t.nom))),
                          ],
                          onChanged: (val) {
                            setState(() => _typeActeFilter = val!);
                            _loadActes();
                          },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tableau / Liste des actes
                  _loadingActes
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                      : _actes.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Aucun acte trouvé")))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _actes.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final acte = _actes[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    title: Text(acte.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text("Type : ${acte.typeNames.join(', ')}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text("Date : ${_formatDate(acte.dateCreation)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        StatusBadge(status: acte.statut),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline, color: Colors.green),
                                          onPressed: () => _handleViewDetails(acte.id),
                                          tooltip: "Voir les informations",
                                        ),
                                        if (acte.fichierUrl != null)
                                          IconButton(
                                            icon: const Icon(Icons.download, color: Colors.blue),
                                            onPressed: () => _openFile(acte.fichierUrl!),
                                            tooltip: "Télécharger le fichier",
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                  // Pagination
                  if (_totalPages > 1) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _page > 1
                              ? () {
                                  setState(() => _page = (_page - 1).clamp(1, _totalPages));
                                  _loadActes();
                                }
                              : null,
                          child: const Text("Précédent"),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Page $_page sur $_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          onPressed: _page < _totalPages
                              ? () {
                                  setState(() => _page = (_page + 1).clamp(1, _totalPages));
                                  _loadActes();
                                }
                              : null,
                          child: const Text("Suivant"),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}