import 'package:flutter/material.dart';

class FormInputWidget extends StatelessWidget {
  final String id;
  final String name;
  final String label;
  final TextInputType keyboardType;
  final dynamic value;
  final String? placeholder;
  final bool required;
  final double? min;
  final String? error;
  final bool? touched;
  final ValueChanged<String> onChange;
  final VoidCallback? onBlur;
  final String className;
  final String? helpText;

  const FormInputWidget({
    super.key,
    required this.id,
    required this.name,
    required this.label,
    this.keyboardType = TextInputType.text,
    required this.value,
    this.placeholder,
    this.required = false,
    this.min,
    this.error,
    this.touched,
    required this.onChange,
    this.onBlur,
    this.className = "",
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = (error != null && error!.isNotEmpty) && (touched ?? true);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: value?.toString() ?? '',
              selection: TextSelection.collapsed(offset: (value?.toString() ?? '').length),
            ),
          ),
          onChanged: onChange,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: hasError
                ? const Icon(Icons.error, color: Colors.red)
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.red.shade400 : Colors.red.shade600,
            ),
          ),
        ] else if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText!,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}