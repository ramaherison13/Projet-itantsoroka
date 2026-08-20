import 'package:flutter/material.dart';
import 'chat_messages_widget.dart';
import 'chat_input_widget.dart';
import 'types.dart';

class DiscussionWidget extends StatefulWidget {
  final String apiUrl;
  final String currentUserId;
  final String currentUsername;
  final List<User> users;
  final Function(Map<String, dynamic>)? onSendMessage;
  final VoidCallback? onLoadMessages;
  final List<ChatMessageModel> messages;

  const DiscussionWidget({
    super.key,
    required this.apiUrl,
    required this.currentUserId,
    required this.currentUsername,
    required this.users,
    this.onSendMessage,
    this.onLoadMessages,
    required this.messages,
  });

  @override
  State<DiscussionWidget> createState() => _DiscussionWidgetState();
}

class _DiscussionWidgetState extends State<DiscussionWidget> {
  String _searchTerm = "";
  String _messageContent = "";
  User? _selectedUser;

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
      final email = u.user?.userEmail ?? "";
      return email.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();

    return Container(
      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: _selectedUser == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec recherche
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Messages",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (val) => setState(() => _searchTerm = val),
                        decoration: InputDecoration(
                          hintText: "Rechercher...",
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF098e00), width: 2),
                          ),
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                // Liste des contacts
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.group_outlined, size: 32, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Aucun contact trouvé",
                                style: TextStyle(
                                  fontSize: 14,
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
                            final userEmail = user.user?.userEmail ?? "Utilisateur";
                            final avatarChar = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "U";
                            final avatarSrc = _getAvatarSrc(user);
                            final pseudoDisplay = userEmail.split('@')[0];

                            return InkWell(
                              onTap: () => setState(() => _selectedUser = user),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    avatarSrc != null
                                        ? CircleAvatar(
                                            radius: 24,
                                            backgroundImage: NetworkImage(avatarSrc),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [Color(0xFF098e00), Color(0xFF076d00)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              avatarChar,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                pseudoDisplay,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDarkMode ? Colors.white : Colors.grey.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Cliquer pour discuter",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            )
          : Column(
              children: [
                // Header conversation avec retour
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _selectedUser = null),
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(builder: (context) {
                        final userEmail = _selectedUser!.user?.userEmail ?? "Utilisateur";
                        final avatarChar = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "U";
                        final avatarSrc = _getAvatarSrc(_selectedUser!);

                        return avatarSrc != null
                            ? CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(avatarSrc),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF098e00), Color(0xFF076d00)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  avatarChar,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedUser!.user?.userEmail?.split('@')[0] ?? "Utilisateur",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.grey.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: ChatMessagesWidget(
                    apiUrl: widget.apiUrl,
                    userA: widget.currentUserId,
                    userB: _selectedUser!.user?.userId?.toString(),
                    messages: widget.messages,
                    onLoadMessages: widget.onLoadMessages,
                  ),
                ),
                // Input moderne
                ChatInputWidget(
                  content: _messageContent,
                  setMessage: (msg) => setState(() => _messageContent = msg),
                  senderId: widget.currentUserId,
                  username: widget.currentUsername,
                  groupId: 1,
                  receiverId: _selectedUser!.user?.userId?.toString() ?? "",
                  onSendMessage: widget.onSendMessage,
                ),
              ],
            ),
    );
  }
}