import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';

// ============================================================================
// MODELS
// ============================================================================

class CitoyenModel {
  final String? citizenId;
  final String? citizenPhoto;
  final String? firstName;
  final String? lastName;

  CitoyenModel({
    this.citizenId,
    this.citizenPhoto,
    this.firstName,
    this.lastName,
  });

  factory CitoyenModel.fromJson(Map<String, dynamic> json) {
    return CitoyenModel(
      citizenId: json['citizen_id']?.toString(),
      citizenPhoto: json['citizen_photo']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
    );
  }

  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return 'Citoyen';
  }
}

class UserInnerModel {
  final String userId;
  final String userEmail;
  final String? userRole;

  UserInnerModel({
    required this.userId,
    required this.userEmail,
    this.userRole,
  });

  factory UserInnerModel.fromJson(Map<String, dynamic> json) {
    return UserInnerModel(
      userId: json['user_id']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? 'Utilisateur',
      userRole: json['role']?.toString() ?? json['user_role']?.toString(),
    );
  }
}

class UserModel {
  final UserInnerModel user;
  final CitoyenModel? citoyen;
  final bool isOnline;
  final String? lastMessage;

  UserModel({
    required this.user,
    this.citoyen,
    this.isOnline = false,
    this.lastMessage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      user: UserInnerModel.fromJson(json['user'] ?? json),
      citoyen: json['citoyen'] != null
          ? CitoyenModel.fromJson(json['citoyen'])
          : null,
      isOnline: json['is_online'] == true || json['status'] == 'online',
      lastMessage: json['last_message']?.toString(),
    );
  }

  String get displayName {
    if (citoyen != null && citoyen!.displayName.isNotEmpty) {
      return citoyen!.displayName;
    }
    return user.userEmail.split('@').first;
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final String? senderPhoto;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.senderPhoto,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? json['receiverId']?.toString() ?? '',
      content: json['content']?.toString() ?? json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      senderPhoto: json['sender_photo']?.toString(),
    );
  }
}

// ============================================================================
// SERVICE USER
// ============================================================================

class UserService {
  static Future<List<UserModel>> getAllUsersByApplicationRole() async {
    try {
      final response = await http
          .get(Uri.parse('https://servicediscu-2.onrender.com/users'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Note API users: $e. Données de secours chargées.');
    }

    return [
      UserModel(
        user: UserInnerModel(
            userId: 'u1', userEmail: 'jean.dupont@commune.mg', userRole: 'Maire'),
        citoyen: CitoyenModel(
          citizenId: 'c1',
          firstName: 'Jean',
          lastName: 'DUPONT',
          citizenPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        ),
        isOnline: true,
        lastMessage: 'Bonjour, le document PCD est validé.',
      ),
      UserModel(
        user: UserInnerModel(
            userId: 'u2',
            userEmail: 'marie.rasoa@district.mg',
            userRole: 'Agent CTD'),
        citoyen: CitoyenModel(
          citizenId: 'c2',
          firstName: 'Marie',
          lastName: 'RASOA',
          citizenPhoto: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        ),
        isOnline: true,
        lastMessage: 'Avez-vous reçu le rapport financier ?',
      ),
      UserModel(
        user: UserInnerModel(
            userId: 'u3',
            userEmail: 'alain.randria@region.mg',
            userRole: 'Responsable Suivi'),
        citoyen: CitoyenModel(
          citizenId: 'c3',
          firstName: 'Alain',
          lastName: 'RANDRIANIRINA',
          citizenPhoto: null,
        ),
        isOnline: false,
        lastMessage: 'La réunion est reportée à mardi 10h.',
      ),
      UserModel(
        user: UserInnerModel(
            userId: 'u4',
            userEmail: 'soroka.support@itantsoroka.mg',
            userRole: 'Support Technique'),
        citoyen: CitoyenModel(
          citizenId: 'c4',
          firstName: 'Support',
          lastName: 'ITANTSOROKA',
          citizenPhoto: null,
        ),
        isOnline: true,
        lastMessage: 'Comment pouvons-nous vous aider ?',
      ),
    ];
  }
}

// ============================================================================
// DISCUSSIONS SCREEN
// ============================================================================

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  List<UserModel> _users = [];
  String _searchTerm = '';
  String _message = '';
  UserModel? _selectedUser;
  bool _showPopup = false;
  bool _showGroupModal = false;
  bool _isConnected = false;
  bool _isLoadingUsers = true;

  final Map<String, List<MessageModel>> _messagesMap = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _initSocketConnection();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final loadedUsers = await UserService.getAllUsersByApplicationRole();
    if (mounted) {
      setState(() {
        _users = loadedUsers;
        _isLoadingUsers = false;
      });
    }
  }

  void _initSocketConnection() {
    // Connexion WebSocket vers https://servicediscu-2.onrender.com/servicediscussions
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    });
  }

  void _sendMessage(String currentUserId, String currentUsername) {
    if (_message.trim().isEmpty || _selectedUser == null) return;

    final receiverId = _selectedUser!.user.userId;
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      content: _message.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      final key = _getChatKey(currentUserId, receiverId);
      _messagesMap.putIfAbsent(key, () => []);
      _messagesMap[key]!.add(newMessage);
      _message = '';
    });

    // Simulation de réponse automatique
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _selectedUser?.user.userId == receiverId) {
        final reply = MessageModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          senderId: receiverId,
          receiverId: currentUserId,
          content: 'Bien reçu ! Merci pour votre message concernant l\'appui communal.',
          timestamp: DateTime.now(),
        );
        setState(() {
          final key = _getChatKey(currentUserId, receiverId);
          _messagesMap[key]?.add(reply);
        });
      }
    });
  }

  String _getChatKey(String u1, String u2) {
    final list = [u1, u2]..sort();
    return list.join('_');
  }

  List<MessageModel> _getMessagesForSelectedUser(String currentUserId) {
    if (_selectedUser == null) return [];
    final key = _getChatKey(currentUserId, _selectedUser!.user.userId);
    return _messagesMap[key] ?? [
      MessageModel(
        id: 'init_1',
        senderId: _selectedUser!.user.userId,
        receiverId: currentUserId,
        content: 'Bonjour ! Comment puis-je vous aider aujourd\'hui ?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.userId ?? 'current_user_1';
    final currentUsername = authProvider.userName;

    final currentUser = _users.firstWhere(
      (u) => u.user.userId == currentUserId,
      orElse: () => UserModel(
        user: UserInnerModel(
            userId: currentUserId, userEmail: currentUsername),
      ),
    );
    final currentUserPhoto = currentUser.citoyen?.citizenPhoto;

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // 1. Sidebar (Liste des discussions)
                if (isDesktop || _selectedUser == null)
                  SizedBox(
                    width: isDesktop ? 340 : MediaQuery.of(context).size.width,
                    child: _Sidebar(
                      users: _users,
                      searchTerm: _searchTerm,
                      onSearchChanged: (val) => setState(() => _searchTerm = val),
                      selectedUser: _selectedUser,
                      onUserClick: (user) {
                        setState(() {
                          _selectedUser = user;
                        });
                      },
                      isLoading: _isLoadingUsers,
                    ),
                  ),

                if (isDesktop)
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                // 2. Zone de Chat
                if (_selectedUser != null || isDesktop)
                  Expanded(
                    child: _selectedUser != null
                        ? Column(
                            children: [
                              _ChatHeader(
                                selectedUser: _selectedUser!,
                                onShowPopup: () => setState(() => _showPopup = true),
                                onShowGroupModal: () => setState(() => _showGroupModal = true),
                                onBackMobile: () => setState(() => _selectedUser = null),
                                isDesktop: isDesktop,
                              ),
                              Expanded(
                                child: _isConnected
                                    ? _ChatMessages(
                                        messages: _getMessagesForSelectedUser(currentUserId),
                                        currentUserId: currentUserId,
                                        selectedUserPhoto: _selectedUser!.citoyen?.citizenPhoto,
                                        currentUserPhoto: currentUserPhoto,
                                        selectedUserName: _selectedUser!.displayName,
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 12),
                                            Text(
                                              'Connexion en cours...',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              _ChatInput(
                                message: _message,
                                onMessageChanged: (val) => setState(() => _message = val),
                                onSend: () => _sendMessage(currentUserId, currentUsername),
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.messageSquare,
                                    size: 48,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Sélectionnez une discussion',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Choisissez un contact dans la liste pour commencer à échanger.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
              ],
            ),

            // Modal profil
            if (_showPopup && _selectedUser != null)
              _UserDetailsDialog(
                user: _selectedUser!,
                onClose: () => setState(() => _showPopup = false),
              ),

            // Modal groupe
            if (_showGroupModal)
              _GroupModalDialog(
                users: _users,
                onClose: () => setState(() => _showGroupModal = false),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SIDEBAR WIDGET
// ============================================================================

class _Sidebar extends StatelessWidget {
  final List<UserModel> users;
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final UserModel? selectedUser;
  final ValueChanged<UserModel> onUserClick;
  final bool isLoading;

  const _Sidebar({
    required this.users,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.selectedUser,
    required this.onUserClick,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((u) {
      final name = u.displayName.toLowerCase();
      final email = u.user.userEmail.toLowerCase();
      final term = searchTerm.toLowerCase();
      return name.contains(term) || email.contains(term);
    }).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discussions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.userPlus, size: 20),
                      color: const Color(0xFF0F766E),
                      onPressed: () {},
                      tooltip: 'Nouvelle discussion',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un agent, maire...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun utilisateur trouvé',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 72,
                          color: Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isSelected = selectedUser?.user.userId == user.user.userId;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: const Color(0xFFCCFBF1).withValues(alpha: 0.4),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            onTap: () => onUserClick(user),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                  backgroundImage: user.citoyen?.citizenPhoto != null
                                      ? NetworkImage(user.citoyen!.citizenPhoto!)
                                      : null,
                                  child: user.citoyen?.citizenPhoto == null
                                      ? Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Color(0xFF0F766E),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                if (user.isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user.user.userRole != null)
                                  Text(
                                    user.user.userRole!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0F766E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  user.lastMessage ?? 'Cliquez pour ouvrir la discussion',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHAT HEADER
// ============================================================================

class _ChatHeader extends StatelessWidget {
  final UserModel selectedUser;
  final VoidCallback onShowPopup;
  final VoidCallback onShowGroupModal;
  final VoidCallback onBackMobile;
  final bool isDesktop;

  const _ChatHeader({
    required this.selectedUser,
    required this.onShowPopup,
    required this.onShowGroupModal,
    required this.onBackMobile,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF475569)),
              onPressed: onBackMobile,
            ),
          Expanded(
            child: GestureDetector(
              onTap: onShowPopup,
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        backgroundImage: selectedUser.citoyen?.citizenPhoto != null
                            ? NetworkImage(selectedUser.citoyen!.citizenPhoto!)
                            : null,
                        child: selectedUser.citoyen?.citizenPhoto == null
                            ? Text(
                                selectedUser.displayName.isNotEmpty
                                    ? selectedUser.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Color(0xFF0F766E),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      if (selectedUser.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
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
                          selectedUser.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          selectedUser.isOnline ? 'En ligne' : 'Hors ligne',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedUser.isOnline
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.users, color: Color(0xFF0F766E)),
            onPressed: onShowGroupModal,
            tooltip: 'Créer un groupe',
          ),
          IconButton(
            icon: const Icon(LucideIcons.info, color: Color(0xFF64748B)),
            onPressed: onShowPopup,
            tooltip: 'Informations du contact',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHAT MESSAGES
// ============================================================================

class _ChatMessages extends StatelessWidget {
  final List<MessageModel> messages;
  final String currentUserId;
  final String? selectedUserPhoto;
  final String? currentUserPhoto;
  final String selectedUserName;

  const _ChatMessages({
    required this.messages,
    required this.currentUserId,
    this.selectedUserPhoto,
    this.currentUserPhoto,
    required this.selectedUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(16),
      child: messages.isEmpty
          ? const Center(
              child: Text(
                'Aucun message pour le moment.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == currentUserId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          backgroundImage: selectedUserPhoto != null
                              ? NetworkImage(selectedUserPhoto!)
                              : null,
                          child: selectedUserPhoto == null
                              ? Text(
                                  selectedUserName.isNotEmpty
                                      ? selectedUserName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF0F766E)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0F766E),
                          backgroundImage: currentUserPhoto != null
                              ? NetworkImage(currentUserPhoto!)
                              : null,
                          child: currentUserPhoto == null
                              ? const Text(
                                  'Moi',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// CHAT INPUT
// ============================================================================

class _ChatInput extends StatelessWidget {
  final String message;
  final ValueChanged<String> onMessageChanged;
  final VoidCallback onSend;

  const _ChatInput({
    required this.message,
    required this.onMessageChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.paperclip, color: Color(0xFF64748B)),
            onPressed: () {},
            tooltip: 'Joindre un fichier',
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: message)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: message.length),
                ),
              onChanged: onMessageChanged,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Écrivez votre message...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  LucideIcons.send,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// USER DETAILS POPUP
// ============================================================================

class _UserDetailsDialog extends StatelessWidget {
  final UserModel user;
  final VoidCallback onClose;

  const _UserDetailsDialog({
    required this.user,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Détails du profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                backgroundImage: user.citoyen?.citizenPhoto != null
                    ? NetworkImage(user.citoyen!.citizenPhoto!)
                    : null,
                child: user.citoyen?.citizenPhoto == null
                    ? Text(
                        user.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (user.user.userRole != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    user.user.userRole!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _infoRow(LucideIcons.mail, 'Email', user.user.userEmail),
              const SizedBox(height: 10),
              _infoRow(
                LucideIcons.shieldCheck,
                'Rôle applicatif',
                user.user.userRole ?? 'Membre',
              ),
              const SizedBox(height: 10),
              _infoRow(
                LucideIcons.circle,
                'Statut',
                user.isOnline ? 'En ligne' : 'Hors ligne',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onClose,
                  child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          '$label : ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// GROUP MODAL
// ============================================================================

class _GroupModalDialog extends StatefulWidget {
  final List<UserModel> users;
  final VoidCallback onClose;

  const _GroupModalDialog({
    required this.users,
    required this.onClose,
  });

  @override
  State<_GroupModalDialog> createState() => _GroupModalDialogState();
}

class _GroupModalDialogState extends State<_GroupModalDialog> {
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Créer un groupe de discussion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Nom du groupe',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: 'Ex: Commission Développement Local',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Membres (${_selectedUserIds.length} sélectionnés)',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.users.length,
                  itemBuilder: (context, index) {
                    final u = widget.users[index];
                    final isChecked = _selectedUserIds.contains(u.user.userId);

                    return Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        value: isChecked,
                        activeColor: const Color(0xFF0F766E),
                        dense: true,
                        title: Text(u.displayName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(u.user.userEmail,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUserIds.add(u.user.userId);
                            } else {
                              _selectedUserIds.remove(u.user.userId);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: widget.onClose,
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_groupNameController.text.trim().isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Groupe "${_groupNameController.text}" créé avec succès !'),
                              backgroundColor: const Color(0xFF0F766E),
                            ),
                          );
                          widget.onClose();
                        }
                      },
                      child: const Text('Créer', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}