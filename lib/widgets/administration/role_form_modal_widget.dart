import 'package:flutter/material.dart';

class RoleFormModalWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Map<String, dynamic> data) onSubmit;
  final Map<String, dynamic>? initialData;
  final Future<void> Function(Map<String, dynamic> data)? createRole;
  final Future<void> Function(int roleId, Map<String, dynamic> data)? updateRole;
  final int appId;

  const RoleFormModalWidget({
    super.key,
    required this.onClose,
    required this.onSubmit,
    this.initialData,
    this.createRole,
    this.updateRole,
    required this.appId,
  });

  @override
  RoleFormModalWidgetState createState() => RoleFormModalWidgetState();
}

class RoleFormModalWidgetState extends State<RoleFormModalWidget> {
  late TextEditingController _roleNameController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _roleNameController = TextEditingController(
      text: widget.initialData != null ? widget.initialData!['role_name'] ?? '' : '',
    );
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_roleNameController.text.isEmpty) return;

    setState(() => _loading = true);

    final Map<String, dynamic> formData = {
      'role_name': _roleNameController.text,
      'app_id': widget.appId,
    };

    if (widget.initialData != null && widget.initialData!['role_id'] != null) {
      formData['role_id'] = widget.initialData!['role_id'];
    }

    try {
      if (widget.initialData != null && widget.updateRole != null) {
        await widget.updateRole!(widget.initialData!['role_id'] ?? 0, formData);
      } else if (widget.createRole != null) {
        await widget.createRole!(formData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialData != null
                  ? "Rôle mis à jour avec succès!"
                  : "Rôle créé avec succès!",
            ),
          ),
        );
      }

      widget.onSubmit(formData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Une erreur est survenue. Veuillez réessayer."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF10B981); // Emerald 500
    final isEditing = widget.initialData != null;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
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
                          Text(
                            isEditing ? "Modifier le rôle" : "Créer un rôle",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Remplissez les informations ci-dessous",
                            style: TextStyle(
                              fontSize: 13,
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
                      // Nom du rôle
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
                            const Text(
                              "NOM DU RÔLE",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _roleNameController,
                              decoration: InputDecoration(
                                hintText: "Ex: Administrateur",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Permissions placeholder
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
                                Icon(Icons.key, size: 20, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  "Permissions",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "(À implémenter : sélection de permissions)",
                              style: TextStyle(fontSize: 13, color: Colors.grey),
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
                      child: const Text("Annuler"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? "Enregistrer" : "Créer"),
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
}