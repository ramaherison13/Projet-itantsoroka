import 'package:flutter/material.dart';

class FormNotificationWidget extends StatelessWidget {
  final String type; // "success" | "error"
  final String message;
  final VoidCallback? onDismiss;

  const FormNotificationWidget({
    super.key,
    required this.type,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = type == "success";
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isSuccess
        ? (isDarkMode ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50)
        : (isDarkMode ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50);

    final borderColor = isSuccess
        ? (isDarkMode ? Colors.green.shade800 : Colors.green.shade200)
        : (isDarkMode ? Colors.red.shade800 : Colors.red.shade200);

    final iconAndTextColor = isSuccess
        ? (isDarkMode ? Colors.green.shade400 : Colors.green.shade800)
        : (isDarkMode ? Colors.red.shade400 : Colors.red.shade800);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: isSuccess ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.cancel,
            color: iconAndTextColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: iconAndTextColor,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 20,
                color: iconAndTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}