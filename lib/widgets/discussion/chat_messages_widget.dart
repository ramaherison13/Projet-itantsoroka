import 'dart:async';
import 'package:flutter/material.dart';

class ChatMessageModel {
  final int? id;
  final String content;
  final String senderId;
  final String? receiverId;
  final String username;
  final String? createdAt;

  const ChatMessageModel({
    this.id,
    required this.content,
    required this.senderId,
    this.receiverId,
    required this.username,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      content: json['content']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString(),
      username: json['username']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class ChatMessagesWidget extends StatefulWidget {
  final String apiUrl;
  final String userA;
  final String? userB;
  final String? selectedUserPhoto;
  final String? currentUserPhoto;
  final List<ChatMessageModel> messages;
  final VoidCallback? onLoadMessages;

  const ChatMessagesWidget({
    super.key,
    required this.apiUrl,
    required this.userA,
    required this.userB,
    this.selectedUserPhoto,
    this.currentUserPhoto,
    required this.messages,
    this.onLoadMessages,
  });

  @override
  State<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends State<ChatMessagesWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (widget.onLoadMessages != null) {
        widget.onLoadMessages!();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatMessagesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getAvatarSrc(bool isMine, String username) {
    final avatarPhoto = isMine ? widget.currentUserPhoto : widget.selectedUserPhoto;
    final char = username.isNotEmpty ? username[0].toUpperCase() : "U";
    String avatarSrc = "https://via.placeholder.com/32?text=$char";

    if (avatarPhoto != null && avatarPhoto.trim().isNotEmpty) {
      final p = avatarPhoto.trim();
      if (p.startsWith('http://') || p.startsWith('https://')) {
        avatarSrc = p;
      } else {
        final clean = p.startsWith('/') ? p.substring(1) : p;
        avatarSrc = "${widget.apiUrl}/serviceupload/file/preview/$clean";
      }
    }
    return avatarSrc;
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return "";
    final DateTime? parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return "";
    final timeStr = parsed.toLocal().toString().split(' ')[1];
    return timeStr.substring(0, 5); // Format HH:mm
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
      child: widget.messages.isEmpty
          ? Center(
              child: Text(
                "Pas de messages pour le moment.",
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade400,
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.messages[index];
                final isMine = msg.senderId == widget.userA;
                final avatarSrc = _getAvatarSrc(isMine, msg.username);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMine) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(avatarSrc),
                          backgroundColor: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.blue
                                : (isDarkMode ? Colors.grey.shade700 : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMine
                                      ? Colors.white
                                      : (isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900),
                                ),
                              ),
                              if (msg.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMine
                                        ? Colors.white70
                                        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(avatarSrc),
                          backgroundColor: Colors.grey.shade300,
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