import 'package:flutter/material.dart';

class PieChartCardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool loading;
  final String? error;
  final String? selectedPeriode;
  final String? selectedCommuneId;
  final String? selectedStatut;

  const PieChartCardWidget({
    super.key,
    required this.data,
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
        child: const Center(child: CircularProgressIndicator()),
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

    String description = "Ce graphique permet de visualiser la répartition des actes";
    if (selectedPeriode != null && selectedPeriode != "toutes") {
      description += " pour la période : $selectedPeriode.";
    } else if (selectedCommuneId != null) {
      description += " dans la commune sélectionnée.";
    } else {
      description += " du district de l’utilisateur connecté.";
    }
    if (selectedStatut != null && selectedStatut!.isNotEmpty) {
      description += " (Filtré par statut : $selectedStatut)";
    }

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
                child: const Icon(Icons.eco, size: 20, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Text(
                "Répartition des actes",
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;

              List<Widget> chartAndLegend = [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: data.isEmpty
                      ? Center(child: Text("Aucune donnée", style: TextStyle(color: subtitleColor)))
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(180, 180),
                              painter: PieChartPainter(data: data),
                            ),
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16, width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((entry) {
                    final color = _parseColor(entry['color']?.toString() ?? '#000000');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${entry['name']} : ",
                            style: TextStyle(fontSize: 13, color: textColor),
                          ),
                          Text(
                            "${entry['value']}",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ];

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: chartAndLegend,
                );
              } else {
                return Column(
                  children: chartAndLegend,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }
}

class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35;

    double total = 0;
    for (var item in data) {
      total += (item['value'] as num?)?.toDouble() ?? 0.0;
    }

    if (total == 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 20, paint);
      return;
    }

    double startAngle = -90 * 3.1415926535 / 180;

    for (var item in data) {
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      if (value <= 0) continue;

      final sweepAngle = (value / total) * 2 * 3.1415926535;
      paint.color = _parseColor(item['color']?.toString() ?? '#000000');

      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 20),
        startAngle,
        sweepAngle - 0.05, // petit espace pour simuler le paddingAngle
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }
}