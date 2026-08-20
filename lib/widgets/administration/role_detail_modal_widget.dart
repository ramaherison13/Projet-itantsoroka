import 'package:flutter/material.dart';

class RoleDetailModalWidget extends StatefulWidget {
  final Map<String, dynamic> role;
  final VoidCallback onClose;
  final Future<Map<String, dynamic>> Function() fetchAllPermissions;

  const RoleDetailModalWidget({
    super.key,
    required this.role,
    required this.onClose,
    required this.fetchAllPermissions,
  });

  @override
  RoleDetailModalWidgetState createState() => RoleDetailModalWidgetState();
}

class RoleDetailModalWidgetState extends State<RoleDetailModalWidget> {
  List<dynamic> _permissions = [];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final res = await widget.fetchAllPermissions();
      if (res.containsKey('data')) {
        final List allPermissions = res['data'];
        final rolePermissions = widget.role['rolePermissions'] as List? ?? [];
        final rolePermissionIds = rolePermissions
            .map((rp) => rp['userpermission_id'])
            .toList();

        final filtered = allPermissions.where((permission) {
          final permRolePermissions = permission['rolePermissions'] as List? ?? [];
          return permRolePermissions.any(
            (rp) => rolePermissionIds.contains(rp['userpermission_id']),
          );
        }).toList();

        setState(() {
          _permissions = filtered;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des permissions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF10B981); // Emerald 500

    final roleName = widget.role['role_name'] ?? '';
    final roleSlug = widget.role['role_slug'] ?? '';
    final roleId = widget.role['role_id'] ?? 0;
    final rolePermissions = widget.role['rolePermissions'] as List? ?? [];
    final appUserRoles = widget.role['appUserRoles'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? primaryColor.withValues(alpha: 0.1) : Colors.green.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.security, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Détails du Rôle",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleName,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Informations générales
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person, size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  "Informations générales",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow("Nom du rôle", roleName),
                            const SizedBox(height: 8),
                            _buildInfoRow("Slug du rôle", roleSlug, isMono: true),
                            const SizedBox(height: 8),
                            _buildInfoRow("Id role", "#$roleId"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Statistiques
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.calendar_today, size: 20, color: Colors.purple),
                                SizedBox(width: 8),
                                Text(
                                  "Statistiques",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${rolePermissions.length}",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Permission${rolePermissions.length != 1 ? 's' : ''}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${appUserRoles.length}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Utilisateur${appUserRoles.length != 1 ? 's' : ''} assigné${appUserRoles.length != 1 ? 's' : ''}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Permissions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.key, size: 20, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  "Permissions (${rolePermissions.length})",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (rolePermissions.isNotEmpty && _permissions.isNotEmpty)
                              SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  itemCount: _permissions.length,
                                  itemBuilder: (context, index) {
                                    final permission = _permissions[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? Colors.grey.shade700 : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              permission['permission_label'] ?? '',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "Aucune permission assignée",
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
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

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Fermer"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Modifier"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: isMono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}