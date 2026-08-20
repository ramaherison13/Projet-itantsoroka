import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:itantsoroka/services/citizens_service.dart';

class UserProfilePopupWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final dynamic fullProfile;
  final dynamic user;
  final String apiUrl;
  final ValueChanged<String> onNavigate;

  const UserProfilePopupWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.fullProfile,
    required this.user,
    required this.apiUrl,
    required this.onNavigate,
  });

  @override
  State<UserProfilePopupWidget> createState() => _UserProfilePopupWidgetState();
}

class _UserProfilePopupWidgetState extends State<UserProfilePopupWidget> {
  dynamic _territoireData;
  bool _loadingTerritory = false;


  @override
  void didUpdateWidget(covariant UserProfilePopupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _fetchTerritoireData();
    }
  }

  Future<void> _fetchTerritoireData() async {
    final municipalityId = widget.user?['municipality_id'];
    if (municipalityId != null && _territoireData == null) {
      setState(() {
        _loadingTerritory = true;
      });
      try {
        final apiTerritoire = '${widget.apiUrl}/serviceterritoire-v2';
        final response = await http.get(Uri.parse('$apiTerritoire/communes/noForm/$municipalityId'));
        if (response.statusCode == 200) {
          setState(() {
            _territoireData = jsonDecode(response.body);
          });
        }
      } catch (error) {
        debugPrint("Erreur récupération territoire : $error");
      } finally {
        if (mounted) {
          setState(() {
            _loadingTerritory = false;
          });
        }
      }
    }
  }

  String? _getAvatarUrl() {
    final citizenPhoto = widget.fullProfile?['citoyen']?['citizen_photo'] ?? widget.fullProfile?['user']?['user_photo'];
    if (citizenPhoto != null && citizenPhoto.toString().trim().isNotEmpty) {
      return CitizensService.getCitizenAvatarPreview(citizenPhoto.toString().trim());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = _getAvatarUrl();
    final citizenData = widget.fullProfile?['citoyen'];

    final userPseudo = widget.user?['user_pseudo'] ?? "Utilisateur";
    final userEmail = widget.user?['user_email'];
    final userPhone = widget.user?['user_phone'];

    String citizenName = "";
    if (citizenData != null) {
      final name = citizenData['citizen_name'] ?? '';
      final lastname = citizenData['citizen_lastname'] ?? '';
      citizenName = "$name $lastname".trim();
    }

    // Gestion des rôles
    String rolesDisplay = "Aucun rôle assigné";
    final roles = widget.user?['roles'];
    if (roles != null) {
      if (roles is List) {
        rolesDisplay = roles.map((r) => r['role_slug'] ?? r['name'] ?? r['role_name'] ?? '').where((s) => s.isNotEmpty).join(", ");
      } else if (roles is Map) {
        rolesDisplay = roles['role_slug'] ?? roles['name'] ?? roles['role_name'] ?? "Aucun rôle assigné";
      }
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 80,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 384, // w-96
              constraints: const BoxConstraints(maxWidth: 384),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDarkMode ? Colors.grey.shade700.withValues(alpha: 0.5) : Colors.grey.shade200.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Avatar & Nom
                              if (avatarUrl != null)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image.network(
                                        avatarUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            const Color(0xFF00C21C).withValues(alpha: 0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF098e00),
                                    border: Border.all(
                                      color: const Color(0xFF00C21C).withValues(alpha: 0.2),
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userPseudo.isNotEmpty ? userPseudo[0].toUpperCase() : (userEmail?.isNotEmpty == true ? userEmail![0].toUpperCase() : "U"),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                citizenData != null && citizenName.isNotEmpty ? citizenName : userPseudo,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "@$userPseudo",
                                style: const TextStyle(
                                  color: Color(0xFF00C21C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            onPressed: widget.onClose,
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              hoverColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Contenu défilable
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Localisation
                            if (_territoireData != null && (_territoireData['name'] != null || _territoireData['district']?['name'] != null)) ...[
                              _buildInfoRow(
                                icon: Icons.location_on,
                                label: "Localisation",
                                value: _territoireData['name'] != null && _territoireData['district']?['name'] != null
                                    ? "${_territoireData['name']}, ${_territoireData['district']['name']}"
                                    : _territoireData['name'] ?? _territoireData['district']?['name'] ?? '',
                                isDarkMode: isDarkMode,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Rôle
                            _buildInfoRow(
                              icon: Icons.work,
                              label: "Rôle",
                              value: rolesDisplay,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 12),

                            // Email
                            if (userEmail != null) ...[
                              _buildInfoRow(
                                icon: Icons.mail,
                                label: "Email",
                                value: userEmail,
                                isDarkMode: isDarkMode,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Téléphone
                            if (userPhone != null) ...[
                              _buildInfoRow(
                                icon: Icons.phone,
                                label: "Téléphone",
                                value: userPhone,
                                isDarkMode: isDarkMode,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Chargement territoire
                            if (_loadingTerritory)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C21C)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Chargement de la localisation...",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Bouton Modifier le profil
                            ElevatedButton(
                              onPressed: () {
                                widget.onClose();
                                widget.onNavigate("/profile/edit");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C21C),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Modifier mon profil",
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00C21C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}