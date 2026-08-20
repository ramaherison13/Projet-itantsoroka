import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ObservationsModalWidget extends StatefulWidget {
  final String actId;
  final String currentUserId;
  final Future<Map<String, dynamic>> Function(String actId) getObservationsByActe;
  final Future<Map<String, dynamic>> Function(String actId) getActeById;
  final Future<void> Function(http.MultipartRequest formData) createObservation;
  final Future<Map<String, dynamic>?> Function(String userId) getCitizenByIdOrUserId;
  final String Function(String photoPath) getCitizenAvatarPreview;

  const ObservationsModalWidget({
    super.key,
    required this.actId,
    required this.currentUserId,
    required this.getObservationsByActe,
    required this.getActeById,
    required this.createObservation,
    required this.getCitizenByIdOrUserId,
    required this.getCitizenAvatarPreview,
  });

  @override
  State<ObservationsModalWidget> createState() => _ObservationsModalWidgetState();
}

class _ObservationsModalWidgetState extends State<ObservationsModalWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _observationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  List<dynamic> _observations = [];
  Map<String, dynamic>? _acte;
  final List<PlatformFile> _selectedFiles = [];
  final Map<String, Map<String, String>> _observersData = {};

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _observationController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.getObservationsByActe(widget.actId),
        widget.getActeById(widget.actId),
      ]);

      final obsData = results[0];
      final acteData = results[1];

      if (obsData['data'] != null) {
        List<dynamic> sorted = List.from(obsData['data']);
        sorted.sort((a, b) {
          final dateA = DateTime.tryParse(a['date_creation'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['date_creation'] ?? '') ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });

        setState(() {
          _observations = sorted;
        });

        Set<String> uniqueObserverIds = sorted.map<String>((obs) => obs['observateur_id'].toString()).toSet();
        Map<String, Map<String, String>> observersMap = {};

        await Future.wait(uniqueObserverIds.map((observerId) async {
          try {
            final citizen = await widget.getCitizenByIdOrUserId(observerId);
            if (citizen != null) {
              final fullName = '${citizen['citizen_name'] ?? ''} ${citizen['citizen_lastname'] ?? ''}'.trim();
              observersMap[observerId] = {
                'nom': fullName,
                'photo': citizen['citizen_photo'] ?? '',
              };
            }
          } catch (_) {}
        }));

        setState(() {
          _observersData.addAll(observersMap);
        });
      }

      setState(() {
        _acte = acteData;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _handleClose() {
    _animController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (_) {}
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _sendObservation() async {
    if (_observationController.text.trim().isEmpty || widget.currentUserId.isEmpty) return;

    setState(() => _sending = true);
    try {
      final formData = http.MultipartRequest('POST', Uri.parse(''));
      formData.fields['contenu'] = _observationController.text.trim();
      formData.fields['auteurId'] = widget.currentUserId;
      // Ajouter les fichiers si besoin
      await widget.createObservation(formData);

      _observationController.clear();
      _selectedFiles.clear();
      await _loadData();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
    } finally {
      setState(() => _sending = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return DateFormat('HH:mm').format(date);
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        return 'Hier';
      }
      return DateFormat('d MMM', 'fr_FR').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_cours': return Colors.amber;
      case 'accepte': return Colors.green;
      case 'rejete': return Colors.red;
      case 'observation': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getUserInitials(String? nom) {
    if (nom == null || nom.isEmpty) return '?';
    List<String> parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return nom.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withValues(alpha: 0.4 * _opacityAnimation.value),
          child: Stack(
            children: [
              GestureDetector(
                onTap: _handleClose,
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 650,
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                        children: [
                          // En-tête
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.description, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Observations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _handleClose,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_loading)
                                  const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                else if (_acte != null)
                                  Row(
                                    children: [
                                      Text(_acte!['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(_acte!['statut'] ?? '').withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _acte!['statut'] ?? '',
                                          style: TextStyle(color: _getStatusColor(_acte!['statut'] ?? ''), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Corps / Liste messages
                          Expanded(
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : _observations.isEmpty
                                    ? const Center(child: Text('Aucune observation', style: TextStyle(color: Colors.grey)))
                                    : ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.all(20),
                                        itemCount: _observations.length,
                                        itemBuilder: (context, index) {
                                          final obs = _observations[index];
                                          final bool isMe = obs['observateur_id'].toString() == widget.currentUserId;
                                          final observerData = _observersData[obs['observateur_id'].toString()];
                                          final nom = observerData?['nom'] ?? obs['observateur_nom'] ?? 'Utilisateur';

                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: Column(
                                              children: [
                                                Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(_formatDate(obs['date_creation'] ?? ''), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (!isMe) ...[
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor: Colors.blue,
                                                        child: Text(_getUserInitials(nom), style: const TextStyle(fontSize: 10, color: Colors.white)),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Flexible(
                                                      child: Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: isMe ? Colors.green.shade600 : Colors.white,
                                                          borderRadius: BorderRadius.circular(16),
                                                          border: isMe ? null : Border.all(color: Colors.grey.shade200),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            if (!isMe)
                                                              Text(nom, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                                            Text(
                                                              obs['contenu'] ?? '',
                                                              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                          ),

                          // Zone de saisie
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                              border: Border(top: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Column(
                              children: [
                                if (_selectedFiles.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    children: _selectedFiles.asMap().entries.map((entry) {
                                      return Chip(
                                        label: Text(entry.value.name, style: const TextStyle(fontSize: 11)),
                                        deleteIcon: const Icon(Icons.close, size: 14),
                                        onDeleted: () => _removeFile(entry.key),
                                      );
                                    }).toList(),
                                  ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                                      onPressed: _pickFiles,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _observationController,
                                        decoration: const InputDecoration(
                                          hintText: 'Votre observation...',
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (_) => _sendObservation(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: _sending
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.send, color: Colors.green),
                                      onPressed: _sending ? null : _sendObservation,
                                    ),
                                  ],
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
            ),
          ],
        ),
      );
      },
    );
  }
}