import 'package:flutter/material.dart';

class FormFieldWidget extends StatelessWidget {
  final String name;
  final String label;
  final String type; // "text", "textarea", etc.
  final TextEditingController? controller;
  final String? placeholder;
  final String? Function(String?)? validation;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const FormFieldWidget({
    super.key,
    required this.name,
    required this.label,
    this.type = 'text',
    this.controller,
    this.placeholder,
    this.validation,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    final int maxLines = type == 'textarea' ? 4 : 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: validation,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : const Color(0xFF098e00),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  errorText!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}