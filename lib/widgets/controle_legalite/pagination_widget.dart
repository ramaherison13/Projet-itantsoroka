import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton Précédent
          ElevatedButton(
            onPressed: currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
              disabledForegroundColor: textColor.withValues(alpha: 0.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
            ),
            child: const Text('Précédent', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),

          // Numéros de page
          Wrap(
            spacing: 8,
            children: List.generate(totalPages, (index) {
              final pageNum = index + 1;
              final isSelected = currentPage == pageNum;

              return InkWell(
                onTap: () => onPageChange(pageNum),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: isDarkMode
                                ? [Colors.green.shade500, Colors.teal.shade500]
                                : [Colors.green.shade600, Colors.teal.shade600],
                          )
                        : null,
                    color: isSelected ? null : backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? null : Border.all(color: borderColor),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),

          // Bouton Suivant
          ElevatedButton(
            onPressed: currentPage < totalPages ? () => onPageChange(currentPage + 1) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
              disabledForegroundColor: textColor.withValues(alpha: 0.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
            ),
            child: const Text('Suivant', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}