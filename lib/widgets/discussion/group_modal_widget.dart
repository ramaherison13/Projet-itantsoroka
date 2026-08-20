import 'package:flutter/material.dart';
import 'types.dart';

class GroupModalWidget extends StatefulWidget {
  final List<User> users;
  final VoidCallback onClose;
  final Function(List<User> selectedUsers)? onCreateGroup;

  const GroupModalWidget({
    super.key,
    required this.users,
    required this.onClose,
    this.onCreateGroup,
  });

  @override
  State<GroupModalWidget> createState() => _GroupModalWidgetState();
}

class _GroupModalWidgetState extends State<GroupModalWidget> {
  final List<User> _selectedUsers = [];

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

  void _handleCreate() {
    if (widget.onCreateGroup != null) {
      widget.onCreateGroup!(_selectedUsers);
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 384, // Équivalent w-96 (384px)
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Créer un groupe",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160, // Équivalent max-h-40
              child: widget.users.isEmpty
                  ? Center(
                      child: Text(
                        "Aucun utilisateur disponible",
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.users.length,
                      itemBuilder: (context, index) {
                        final user = widget.users[index];
                        final isSelected = _selectedUsers.any((u) => u.user?.userId == user.user?.userId);

                        return Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              _toggleUserSelection(user);
                            },
                            title: Text(
                              user.user?.userPseudo ?? "Utilisateur",
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: Colors.green,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onClose,
                  style: TextButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Annuler"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Créer"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}