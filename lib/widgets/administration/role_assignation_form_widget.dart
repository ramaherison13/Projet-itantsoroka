import 'package:flutter/material.dart';

// Modèle de rôle
class RoleModel {
  final int roleId;
  final String roleName;

  RoleModel({required this.roleId, required this.roleName});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: json['role_id'] ?? 0,
      roleName: json['role_name'] ?? '',
    );
  }
}

class RoleAssignationFormWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClick;
  final Future<Map<String, dynamic>> Function() fetchAllRoles;
  final Future<void> Function(int userId, List<int> roleIds) assignRoles;
  final Future<void> Function(int userId, List<int> roleIds) removeRoles;
  final Widget userCardProfileWidget; // Composant UserCardProfile converti

  const RoleAssignationFormWidget({
    super.key,
    required this.data,
    required this.onClick,
    required this.fetchAllRoles,
    required this.assignRoles,
    required this.removeRoles,
    required this.userCardProfileWidget,
  });

  @override
  RoleAssignationFormWidgetState createState() => RoleAssignationFormWidgetState();
}

class RoleAssignationFormWidgetState extends State<RoleAssignationFormWidget> {
  List<RoleModel> _availableRoles = [];
  List<int> _selectedRoles = [];
  List<int> _initialRoles = [];
  bool _rolesLoading = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    _initializeUserRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      setState(() => _rolesLoading = true);
      final res = await widget.fetchAllRoles();
      if (res.containsKey('roles')) {
        final List rolesList = res['roles'];
        setState(() {
          _availableRoles = rolesList.map((r) => RoleModel.fromJson(r)).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des rôles: $e");
    } finally {
      setState(() => _rolesLoading = false);
    }
  }

  void _initializeUserRoles() {
    final user = widget.data['user'];
    if (user != null && user['appUserRoles'] is List) {
      final List appUserRoles = user['appUserRoles'];
      final roleIds = appUserRoles
          .map<int>((userRole) => userRole['role']['role_id'] as int)
          .toList();

      setState(() {
        _selectedRoles = roleIds;
        _initialRoles = roleIds;
      });
    }
  }

  void _toggleRole(int roleId) {
    setState(() {
      if (_selectedRoles.contains(roleId)) {
        _selectedRoles.remove(roleId);
      } else {
        _selectedRoles.add(roleId);
      }
    });
  }

  Future<void> _handleSubmit() async {
    try {
      setState(() => _loading = true);

      final userId = widget.data['user']['user_id'];
      final rolesToAdd = _selectedRoles.where((id) => !_initialRoles.contains(id)).toList();
      final rolesToRemove = _initialRoles.where((id) => !_selectedRoles.contains(id)).toList();

      if (rolesToAdd.isNotEmpty) {
        await widget.assignRoles(userId, rolesToAdd);
      }

      if (rolesToRemove.isNotEmpty) {
        await widget.removeRoles(userId, rolesToRemove);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rôles mis à jour avec succès')),
        );
      }

      widget.onClick();
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour des rôles')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF098E00);

    final assignedRoles = _availableRoles.where((role) => _selectedRoles.contains(role.roleId)).toList();
    final unassignedRoles = _availableRoles.where((role) => !_selectedRoles.contains(role.roleId)).toList();

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black54 : Colors.black26,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_note, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Attribuer des rôles à un utilisateur",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Corps (Profil + Rôles)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              widget.userCardProfileWidget,
                              const SizedBox(width: 16),
                              Expanded(child: _buildRolesSection(assignedRoles, unassignedRoles, isDarkMode, primaryColor)),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              widget.userCardProfileWidget,
                              const SizedBox(height: 16),
                              _buildRolesSection(assignedRoles, unassignedRoles, isDarkMode, primaryColor),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bouton Enregistrer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedRoles.isEmpty || _loading) ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(_loading ? "Enregistrement..." : "Enregistrer", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                // Bouton Fermer (X)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: widget.onClick,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolesSection(
      List<RoleModel> assignedRoles, List<RoleModel> unassignedRoles, bool isDarkMode, Color primaryColor) {
    if (_rolesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: Color(0xFF098E00)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rôles assignés
        const Text("Rôles assignés", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: assignedRoles.isNotEmpty
              ? assignedRoles.map((role) {
                  return ActionChip(
                    label: Text(role.roleName, style: const TextStyle(color: Colors.white)),
                    backgroundColor: primaryColor,
                    onPressed: () => _toggleRole(role.roleId),
                  );
                }).toList()
              : const [Text("Aucun rôle attribué", style: TextStyle(fontSize: 13, color: Colors.grey))],
        ),
        const SizedBox(height: 16),

        // Rôles disponibles
        const Text("Rôles disponibles", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: unassignedRoles.map((role) {
            return ActionChip(
              label: Text(role.roleName),
              backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              onPressed: () => _toggleRole(role.roleId),
            );
          }).toList(),
        ),
      ],
    );
  }
}