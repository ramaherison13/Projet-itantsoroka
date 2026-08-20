import 'package:flutter/material.dart';
import 'avatar_widget.dart';
import 'types.dart';

Color getFallbackColor(String userId) {
  final colors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.pink, Colors.teal, Colors.indigo, Colors.red,
  ];
  int index = userId.hashCode.abs() % colors.length;
  return colors[index];
}

class ChatHeaderWidget extends StatelessWidget {
  final User? selectedUser;
  final ValueChanged<bool> setShowPopup;
  final ValueChanged<bool> setShowGroupModal;

  const ChatHeaderWidget({
    super.key,
    required this.selectedUser,
    required this.setShowPopup,
    required this.setShowGroupModal,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userData = selectedUser?.user;
    final userId = userData?.userId?.toString() ?? "fallback";
    final userPseudo = userData?.userPseudo ?? "Utilisateur";
    final avatarChar = userPseudo.isNotEmpty ? userPseudo[0].toUpperCase() : "U";
    final avatarSrc = "https://via.placeholder.com/40?text=$avatarChar";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.grey.shade800, Colors.grey.shade700]
              : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (userData != null) ...[
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: AvatarWidget(
                          src: avatarSrc,
                          alt: userPseudo,
                          size: 40,
                          fallbackColor: getFallbackColor(userId),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 12,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
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
                ],
                Expanded(
                  child: Text(
                    selectedUser != null ? userPseudo : "Sélectionnez une conversation",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setShowPopup(true),
                icon: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  hoverColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setShowGroupModal(true),
                icon: Icon(
                  Icons.group_outlined,
                  size: 20,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  hoverColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}