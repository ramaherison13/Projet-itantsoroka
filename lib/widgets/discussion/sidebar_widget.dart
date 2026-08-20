import 'package:flutter/material.dart';
import 'types.dart';
import 'group_creation_modal_widget.dart';

class SidebarWidget extends StatefulWidget {
  final String apiUrl;
  final List<User> users;
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final User? selectedUser;
  final ValueChanged<User> onUserClick;

  const SidebarWidget({
    super.key,
    required this.apiUrl,
    required this.users,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.selectedUser,
    required this.onUserClick,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  bool _isModalOpen = false;

  Color _getFallbackColor(String id) {
    final colors = [
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.blue.shade400,
      Colors.amber.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.orange.shade400,
    ];
    int sum = 0;
    for (int i = 0; i < id.length; i++) {
      sum += id.codeUnitAt(i);
    }
    return colors[sum % colors.length];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'en ligne':
        return Colors.green;
      case 'away':
      case 'absent':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String? _getAvatarSrc(User user) {
    final photo = user.citoyen?.citizenPhoto;
    if (photo != null && photo.trim().isNotEmpty) {
      final p = photo.trim();
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      final clean = p.startsWith('/') ? p.substring(1) : p;
      return "${widget.apiUrl}/serviceupload/file/preview/$clean";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filteredUsers = widget.users.where((u) {
      final pseudo = u.user?.userPseudo ?? "";
      return pseudo.toLowerCase().contains(widget.searchTerm.toLowerCase());
    }).toList();

    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width / 3,
          constraints: const BoxConstraints(minWidth: 280),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            border: Border(
              right: BorderSide(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header & Search section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.grey, Colors.teal],
                          ).createShader(bounds),
                          child: Text(
                            "Discussions",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.grey.shade900,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isModalOpen = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            "Groupe",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: widget.onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Rechercher dans Messenger",
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              // Users List
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.group_outlined, size: 32, color: Colors.grey),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final u = filteredUsers[index];
                          final userData = u.user;
                          final isSelected = widget.selectedUser?.user?.userId == userData?.userId;
                          final userPseudo = userData?.userPseudo ?? "Utilisateur";
                          final userId = userData?.userId?.toString() ?? "fallback-$index";
                          final avatarChar = userPseudo.isNotEmpty ? userPseudo[0].toUpperCase() : "U";
                          final avatarSrc = _getAvatarSrc(u);
                          final status = userData?.status ?? "offline";

                          return InkWell(
                            onTap: () => widget.onUserClick(u),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDarkMode ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      avatarSrc != null
                                          ? CircleAvatar(
                                              radius: 24,
                                              backgroundImage: NetworkImage(avatarSrc),
                                            )
                                          : CircleAvatar(
                                              radius: 24,
                                              backgroundColor: _getFallbackColor(userId),
                                              child: Text(
                                                avatarChar,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userPseudo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.grey.shade900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          userData?.lastSeen ?? "Hors ligne",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
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
        GroupCreationModalWidget(
          isOpen: _isModalOpen,
          onClose: () => setState(() => _isModalOpen = false),
          users: widget.users,
          userGroupeAdmin: "1",
        ),
      ],
    );
  }
}