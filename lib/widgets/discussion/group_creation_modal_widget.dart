import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'types.dart';

class GroupCreationModalWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final List<User> users;
  final String userGroupeAdmin;
  final Function(String groupName, List<User> selectedUsers, String userGroupeAdmin)? onCreateGroup;

  const GroupCreationModalWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.users,
    required this.userGroupeAdmin,
    this.onCreateGroup,
  });

  @override
  State<GroupCreationModalWidget> createState() => _GroupCreationModalWidgetState();
}

class _GroupCreationModalWidgetState extends State<GroupCreationModalWidget> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<User> _selectedUsers = [];
  String _searchTerm = "";
  bool _loading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleUserSelection(User user) {
    setState(() {
      final userId = user.user?.userId;
      final exists = _selectedUsers.any((u) => u.user?.userId == userId);
      if (exists) {
        _selectedUsers.removeWhere((u) => u.user?.userId == userId);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _handleCreateGroup() async {
    if (_groupNameController.text.trim().isEmpty || _selectedUsers.isEmpty) return;

    final memberIds = _selectedUsers
        .map((u) => int.tryParse(u.user?.userId?.toString() ?? '0') ?? 0)
        .toList();

    try {
      setState(() => _loading = true);

      if (widget.onCreateGroup != null) {
        widget.onCreateGroup!(_groupNameController.text, _selectedUsers, widget.userGroupeAdmin);
      }

      final dio = Dio();
      await dio.post(
        "https://servicediscu-2.onrender.com/servicediscussion/group",
        data: {
          "name": _groupNameController.text.trim(),
          "userGroupeAdmin": widget.userGroupeAdmin,
          "members": memberIds,
        },
      );

      _groupNameController.clear();
      _searchController.clear();
      setState(() => _selectedUsers = []);
      widget.onClose();
    } catch (error) {
      debugPrint("Erreur création du groupe : $error");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleClose() {
    _groupNameController.clear();
    _searchController.clear();
    setState(() => _selectedUsers = []);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filteredUsers = widget.users.where((user) {
      final pseudo = user.user?.userPseudo ?? "";
      return pseudo.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Créer un groupe",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  IconButton(
                    onPressed: _handleClose,
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Name
                    Text(
                      "Nom du groupe",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        hintText: "Entrez le nom du groupe...",
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User Search
                    Text(
                      "Ajouter des membres (${_selectedUsers.length} sélectionné${_selectedUsers.length != 1 ? "s" : ""})",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchTerm = val),
                      decoration: InputDecoration(
                        hintText: "Rechercher des utilisateurs...",
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(Icons.group_outlined, size: 20, color: Colors.grey),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Selected Users Preview Chips
                    if (_selectedUsers.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedUsers.map((user) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.user?.userPseudo ?? "",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode ? Colors.green.shade200 : Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _toggleUserSelection(user),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: isDarkMode ? Colors.green.shade200 : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Users List
                    SizedBox(
                      height: 200,
                      child: filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.group_off, size: 32, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Aucun utilisateur trouvé",
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = _selectedUsers.any((u) => u.user?.userId == user.user?.userId);

                                return InkWell(
                                  onTap: () => _toggleUserSelection(user),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDarkMode ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.user?.userPseudo ?? "",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.user?.status ?? "Hors ligne",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check, color: Colors.green, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _handleClose,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      "Annuler",
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_groupNameController.text.trim().isEmpty || _selectedUsers.isEmpty || _loading)
                        ? null
                        : _handleCreateGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add, size: 18, color: Colors.white),
                    label: Text(
                      _loading ? "Création..." : "Créer le groupe",
                      style: const TextStyle(color: Colors.white),
                    ),
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