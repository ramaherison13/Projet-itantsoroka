import 'package:flutter/material.dart';

class FormSelectWidget extends StatelessWidget {
  final String id;
  final String name;
  final String label;
  final String value;
  final List<Map<String, String>> options;
  final bool required;
  final String? error;
  final bool? touched;
  final ValueChanged<String?> onChange;
  final VoidCallback? onBlur;
  final String? placeholder;

  const FormSelectWidget({
    super.key,
    required this.id,
    required this.name,
    required this.label,
    required this.value,
    required this.options,
    this.required = false,
    this.error,
    this.touched,
    required this.onChange,
    this.onBlur,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = (error != null && error!.isNotEmpty) && (touched ?? true);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String? dropdownValue = value.isEmpty ? null : value;

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
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          onChanged: (val) {
            if (val != null) onChange(val);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
          ),
          hint: placeholder != null
              ? Text(
                  placeholder!,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                )
              : null,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label'] ?? ''),
            );
          }).toList(),
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
        ],
      ],
    );
  }
}