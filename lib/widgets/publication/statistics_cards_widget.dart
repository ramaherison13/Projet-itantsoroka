import 'package:flutter/material.dart';

class StatisticsCardsWidget extends StatelessWidget {
  final List<dynamic> publications;
  final String Function(double amount) formatBudget;

  const StatisticsCardsWidget({
    super.key,
    required this.publications,
    required this.formatBudget,
  });

  String _getStatusValue(dynamic status) {
    if (status == null) return '';
    if (status is String) return status;
    if (status is Map) {
      return status['fr']?.toString() ?? status.values.first?.toString() ?? '';
    }
    return status.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final eventCount = publications.where((p) => p.type == 'event').length;
    final projectCount = publications.where((p) => p.type == 'project').length;
    final ongoingProjectCount = publications.where((p) => p.type == 'project' && _getStatusValue(p.status) == 'en_cours').length;
    
    final totalBudget = publications
        .where((p) => p.type == 'project')
        .fold<double>(0.0, (sum, p) {
          final budget = double.tryParse(p.budget?.toString() ?? '0') ?? 0.0;
          return sum + budget;
        });

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        // Événements et actualité
        _buildStatCard(
          context: context,
          isDarkMode: isDarkMode,
          title: 'Événements et actualité',
          value: eventCount.toString(),
          icon: Icons.calendar_today,
          gradient: const [Colors.blue, Colors.blueAccent],
        ),

        // Projets
        _buildStatCard(
          context: context,
          isDarkMode: isDarkMode,
          title: 'Projets',
          value: projectCount.toString(),
          icon: Icons.folder_open,
          gradient: const [Colors.green, Colors.greenAccent],
        ),

        // En cours
        _buildStatCard(
          context: context,
          isDarkMode: isDarkMode,
          title: 'Projet en cours',
          value: ongoingProjectCount.toString(),
          icon: Icons.trending_up,
          gradient: const [Colors.orange, Colors.deepOrange],
        ),

        // Budget total
        _buildStatCard(
          context: context,
          isDarkMode: isDarkMode,
          title: 'Budget total',
          value: formatBudget(totalBudget),
          icon: Icons.account_balance_wallet,
          gradient: const [Colors.purple, Colors.purpleAccent],
          isBudget: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required bool isDarkMode,
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    bool isBudget = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isBudget ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
            ),
          ),
        ],
      ),
    );
  }
}