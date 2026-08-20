import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:itantsoroka/constants/api_constants.dart';

// Rôles disponibles et leurs permissions associées
final Map<String, List<String>> rolesWithPermissions = {
  'admin': ['Créer des utilisateurs', 'Supprimer des utilisateurs', 'Modifier des rôles'],
  'editor': ['Modifier le contenu', 'Publier des articles'],
  'viewer': ['Lire uniquement le contenu'],
};

class UserCreationFormWidget extends StatefulWidget {
  const UserCreationFormWidget({super.key});

  @override
  UserCreationFormWidgetState createState() => UserCreationFormWidgetState();
}

class UserCreationFormWidgetState extends State<UserCreationFormWidget> {
  final List<String> _selectedRoles = [];
  List<String> _permissions = [];
  bool _submitting = false;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _updatePermissions() {
    final perms = _selectedRoles.expand<String>((role) => rolesWithPermissions[role] ?? []).toList();
    setState(() {
      _permissions = perms.toSet().toList();
    });
  }

  void _toggleRole(String role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
      _updatePermissions();
    });
  }

  void _removeRole(String role) {
    setState(() {
      _selectedRoles.remove(role);
      _updatePermissions();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_isFormValid || _submitting) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final List<int> roleIds = [];
      for (final role in _selectedRoles) {
        final rLower = role.toLowerCase();
        if (rLower.contains('admin')) {
          roleIds.add(1);
        } else if (rLower.contains('editor')) {
          roleIds.add(12);
        } else if (rLower.contains('viewer')) {
          roleIds.add(18);
        }
      }
      if (roleIds.isEmpty) {
        roleIds.add(18);
      }

      final payload = {
        "user_pseudo": _nameController.text.trim(),
        "user_email": _emailController.text.trim(),
        "user_password": _passwordController.text,
        "app_id": 1,
        "role_ids": roleIds,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.gatewayBaseUrl}/serviceauth/users/create-with-roles'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur créé avec succès !'),
              backgroundColor: Color(0xFF059669),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        dynamic resBody;
        try {
          resBody = jsonDecode(response.body);
        } catch (_) {}

        String errorMsg = 'Échec de la création de l\'utilisateur';
        if (response.statusCode == 409) {
          errorMsg = resBody?['message'] ?? 'Un utilisateur avec cet email ou ce nom existe déjà.';
        } else if (resBody is Map && (resBody['message'] != null || resBody['error'] != null)) {
          errorMsg = (resBody['message'] ?? resBody['error']).toString();
        }

        if (mounted) {
          setState(() {
            _errorMessage = errorMsg;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errText = 'Erreur lors de la création : $e';
        setState(() {
          _errorMessage = errText;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF098E00);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white54,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 550,
            margin: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add_rounded, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Créer un utilisateur",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey.shade100 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      tooltip: "Quitter",
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Formulaire
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    const Text("Nom", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) {
                        _clearError();
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    const Text("Email", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      onChanged: (_) {
                        _clearError();
                        setState(() {});
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mot de passe
                    const Text("Mot de passe", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      onChanged: (_) {
                        _clearError();
                        setState(() {});
                      },
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rôles
                    const Text("Rôles", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rolesWithPermissions.keys.map((role) {
                        final isSelected = _selectedRoles.contains(role);
                        return ChoiceChip(
                          label: Text(role),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700),
                          ),
                          onSelected: (_) => _toggleRole(role),
                        );
                      }).toList(),
                    ),

                    // Chips sélectionnés
                    if (_selectedRoles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedRoles.map((role) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(role, style: const TextStyle(color: primaryColor, fontSize: 13)),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _removeRole(role),
                                  child: const Icon(Icons.close, size: 14, color: primaryColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Permissions
                    if (_permissions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text("Permissions :", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ..._permissions.map((perm) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Row(
                              children: [
                                const Text("• ", style: TextStyle(fontSize: 14)),
                                Text(perm, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          )),
                    ],

                    // Message d'erreur explicite
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Boutons d'action (Annuler / Quitter & Créer l'utilisateur)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text("Annuler / Quitter"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_isFormValid && !_submitting) ? _handleSubmit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text("Créer l'utilisateur"),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}