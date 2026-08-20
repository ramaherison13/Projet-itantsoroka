import 'package:flutter/material.dart';

class ActeSuccesModalWidget extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String reference;
  final String dateTime;
  final bool darkMode;

  const ActeSuccesModalWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.reference,
    required this.dateTime,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final Color bgColor = darkMode ? Colors.grey.shade900 : Colors.white;
    final Color textColor = darkMode ? Colors.grey.shade200 : Colors.grey.shade800;
    final Color subTextColor = darkMode ? Colors.grey.shade400 : Colors.grey.shade500;
    final Color borderColor = darkMode ? Colors.grey.shade700 : Colors.grey.shade200;

    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Icône succès
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Message principal
              Text(
                'Votre acte a été soumis avec succès le $dateTime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Informations référence et statut
              DefaultTextStyle(
                style: TextStyle(fontSize: 14, color: subTextColor),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Référence : '),
                        GestureDetector(
                          onTap: () {
                            // Action lors du clic sur la référence si nécessaire
                          },
                          child: Text(
                            reference,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Statut initial : '),
                        Text(
                          'Reçu',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Ligne info accusé
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mail, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Accusé de réception envoyé automatiquement par notification et email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ✅ Boutons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'D’accord, compris',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      foregroundColor: darkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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