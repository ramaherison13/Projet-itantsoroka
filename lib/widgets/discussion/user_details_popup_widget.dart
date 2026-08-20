import 'package:flutter/material.dart';
import 'types.dart';

class UserDetailsPopupWidget extends StatelessWidget {
  final User user;
  final VoidCallback onClose;

  const UserDetailsPopupWidget({
    super.key,
    required this.user,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final pseudo = user.user?.userPseudo ?? user.userPseudo ?? "Inconnu";
    final status = user.user?.status ?? "Hors ligne";
    final lastSeen = user.user?.lastSeen ?? "Inconnue";

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
              "Détails de l'utilisateur",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
                children: [
                  const TextSpan(
                    text: "Pseudo: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "$pseudo\n"),
                  const TextSpan(
                    text: "Statut: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "$status\n"),
                  const TextSpan(
                    text: "Dernière activité: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: lastSeen),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Fermer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}