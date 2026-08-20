import 'package:flutter/material.dart';

class StatisticsCardsWidget extends StatelessWidget {
  final int total;
  final int pending;
  final int accepted;
  final int observation;
  final bool loading;

  const StatisticsCardsWidget({
    super.key,
    required this.total,
    required this.pending,
    required this.accepted,
    required this.observation,
    this.loading = false,
  });

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color borderColor,
    required Color iconColor,
    required Color iconBgColor,
    required Color subtitleColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
          (index) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    }

    final pendingPercent = total > 0 ? ((pending / total) * 100).toStringAsFixed(0) : '0';
    final acceptedPercent = total > 0 ? ((accepted / total) * 100).toStringAsFixed(0) : '0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildCard(
              context: context,
              title: 'Actes soumis',
              value: total.toString(),
              subtitle: 'Total général',
              icon: Icons.description_outlined,
              borderColor: Colors.blue.shade500,
              iconColor: Colors.blue.shade600,
              iconBgColor: isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
              subtitleColor: Colors.blue.shade600,
              isDarkMode: isDarkMode,
            ),
            _buildCard(
              context: context,
              title: 'En attente',
              value: pending.toString(),
              subtitle: '$pendingPercent% du total',
              icon: Icons.access_time,
              borderColor: Colors.amber.shade500,
              iconColor: Colors.amber.shade600,
              iconBgColor: isDarkMode ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50,
              subtitleColor: Colors.amber.shade600,
              isDarkMode: isDarkMode,
            ),
            _buildCard(
              context: context,
              title: 'Acceptés',
              value: accepted.toString(),
              subtitle: '$acceptedPercent% du total',
              icon: Icons.check,
              borderColor: Colors.green.shade500,
              iconColor: Colors.green.shade600,
              iconBgColor: isDarkMode ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50,
              subtitleColor: Colors.green.shade600,
              isDarkMode: isDarkMode,
            ),
            _buildCard(
              context: context,
              title: 'Observations',
              value: observation.toString(),
              subtitle: 'Total général',
              icon: Icons.chat_bubble_outline,
              borderColor: Colors.orange.shade500,
              iconColor: Colors.orange.shade600,
              iconBgColor: isDarkMode ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50,
              subtitleColor: Colors.orange.shade600,
              isDarkMode: isDarkMode,
            ),
          ],
        );
      },
    );
  }
}