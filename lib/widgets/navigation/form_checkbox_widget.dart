import 'package:flutter/material.dart';

class FormCheckboxWidget extends StatelessWidget {
  final String id;
  final String name;
  final String label;
  final String? description;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const FormCheckboxWidget({
    super.key,
    required this.id,
    required this.name,
    required this.label,
    this.description,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.grey.shade50;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900;
    final descriptionColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                onChanged: onChanged,
                activeColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: descriptionColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}