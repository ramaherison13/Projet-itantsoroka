import 'package:flutter/material.dart';

class ChatInputWidget extends StatelessWidget {
  final String content;
  final ValueChanged<String> setMessage;
  final String senderId;
  final String username;
  final int groupId;
  final String receiverId;
  final Function(Map<String, dynamic>)? onSendMessage; // Simulation de l'émission socket

  const ChatInputWidget({
    super.key,
    required this.content,
    required this.setMessage,
    required this.senderId,
    required this.username,
    required this.groupId,
    required this.receiverId,
    this.onSendMessage,
  });

  void _handleSend() {
    if (content.trim().isEmpty) return;

    final payload = {
      'content': content,
      'username': username,
      'groupId': groupId,
      'receiverId': receiverId,
      'senderId': senderId,
    };

    if (onSendMessage != null) {
      onSendMessage!(payload);
    }
    
    debugPrint("📤 Message envoyé: $payload");
    setMessage("");
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: content,
                  selection: TextSelection.collapsed(offset: content.length),
                ),
              ),
              onChanged: setMessage,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: "Écrire un message...",
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _handleSend,
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.all(12),
              shape: const CircleBorder(),
              hoverColor: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}