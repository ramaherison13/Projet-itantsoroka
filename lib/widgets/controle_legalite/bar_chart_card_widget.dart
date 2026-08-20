import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartCardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> barData;
  final bool loading;
  final String? error;
  final String? selectedPeriode;
  final String? selectedCommuneId;
  final String? selectedStatut;

  const BarChartCardWidget({
    super.key,
    required this.barData,
    required this.loading,
    this.error,
    this.selectedPeriode,
    this.selectedCommuneId,
    this.selectedStatut,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.grey.shade800;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500;

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            error!,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    String description = "Ce graphique montre la répartition des actes selon leur type";
    if (selectedPeriode != null && selectedPeriode != "toutes") {
      description += " pour la période : $selectedPeriode.";
    } else if (selectedCommuneId != null) {
      description += " dans la commune sélectionnée.";
    } else {
      description += " du district de l’utilisateur connecté.";
    }
    if (selectedStatut != null && selectedStatut!.isNotEmpty) {
      description += " (Filtré par statut : $selectedStatut).";
    }

    // Calcul de la valeur maximale pour l'axe Y
    double maxY = 10;
    for (var item in barData) {
      final val = (item['documents'] as num?)?.toDouble() ?? 0.0;
      if (val > maxY) maxY = val;
    }
    maxY = (maxY * 1.2).ceilToDouble(); // Marge en haut

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, size: 20, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Text(
                "Répartition par type d’acte",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: barData.isEmpty
                ? Center(child: Text("Aucune donnée disponible", style: TextStyle(color: subtitleColor)))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: barData.length * 70.0 > 300 ? barData.length * 70.0 : 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => isDarkMode ? Colors.grey.shade700 : Colors.blueGrey.shade800,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final item = barData[group.x.toInt()];
                                return BarTooltipItem(
                                  "${item['name']}\n",
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: "${rod.toY.toInt()} actes",
                                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < 0 || value.toInt() >= barData.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final name = barData[value.toInt()]['name']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        name,
                                        style: TextStyle(fontSize: 10, color: subtitleColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: 10, color: subtitleColor),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: barData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final val = (item['documents'] as num?)?.toDouble() ?? 0.0;

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: val,
                                  color: Colors.amber.shade500,
                                  width: 24,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}