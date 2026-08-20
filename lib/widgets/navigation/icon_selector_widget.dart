import 'package:flutter/material.dart';

class IconSelectorWidget extends StatelessWidget {
  final String value;
  final String? error;
  final bool? touched;
  final ValueChanged<String> onChange;
  final VoidCallback? onBlur;
  final ValueChanged<String> onIconSelect;

  const IconSelectorWidget({
    super.key,
    required this.value,
    this.error,
    this.touched,
    required this.onChange,
    this.onBlur,
    required this.onIconSelect,
  });

  static const List<Map<String, dynamic>> popularIcons = [
    {"name": "Home", "icon": Icons.home},
    {"name": "Dashboard", "icon": Icons.show_chart},
    {"name": "Users", "icon": Icons.group},
    {"name": "Settings", "icon": Icons.settings},
    {"name": "Calendar", "icon": Icons.calendar_today},
    {"name": "Documents", "icon": Icons.description},
    {"name": "Messages", "icon": Icons.message},
    {"name": "Analytics", "icon": Icons.pie_chart},
    {"name": "Profile", "icon": Icons.person},
    {"name": "Reports", "icon": Icons.insert_chart},
  ];

  IconData _getIconData(String iconName) {
    for (var item in popularIcons) {
      if (item['icon'].toString() == iconName || item['name'].toString().toLowerCase() == iconName.toLowerCase()) {
        return item['icon'] as IconData;
      }
    }
    return Icons.star;
  }

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
              "Icône",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController.fromValue(
                  TextEditingValue(
                    text: value,
                    selection: TextSelection.collapsed(offset: value.length),
                  ),
                ),
                onChanged: onChange,
                decoration: InputDecoration(
                  hintText: "Ex: Home",
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
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
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade200,
                  ),
                ),
                child: Icon(
                  _getIconData(value),
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600,
                  size: 24,
                ),
              ),
            ],
          ],
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
        const SizedBox(height: 12),
        Text(
          "Icônes populaires:",
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularIcons.map((item) {
            final String itemName = item['name'] as String;
            final IconData itemIcon = item['icon'] as IconData;
            final bool isSelected = value == itemName;

            return InkWell(
              onTap: () => onIconSelect(itemName),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade100)
                      : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade500
                        : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      itemIcon,
                      size: 16,
                      color: isSelected
                          ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700)
                          : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700)
                            : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}