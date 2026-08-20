import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final String searchTerm;
  final ValueChanged<String> onSearchChange;

  const SearchBarWidget({
    super.key,
    required this.searchTerm,
    required this.onSearchChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextField(
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: searchTerm,
            selection: TextSelection.collapsed(offset: searchTerm.length),
          ),
        ),
        onChanged: onSearchChange,
        style: TextStyle(
          fontSize: 15,
          color: isDarkMode ? Colors.white : Colors.grey.shade900,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher par titre, commune...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search,
              size: 20,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.green,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}