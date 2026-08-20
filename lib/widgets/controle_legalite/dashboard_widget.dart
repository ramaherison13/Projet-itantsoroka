import 'package:flutter/material.dart';
import 'dashboard_card_widget.dart';

class DashboardWidget extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool loading;
  final String? error;

  const DashboardWidget({
    super.key,
    required this.stats,
    required this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            error!,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Aucune donnée disponible pour ce district.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final totalActes = stats!['total'] ?? 0;
    final parStatut = stats!['par_statut'] as Map<String, dynamic>? ?? {};
    final actesAcceptes = parStatut['accepte'] ?? 0;
    final actesRejetes = parStatut['rejete'] ?? 0;
    final actesEnCours = parStatut['en_cours'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);

          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              DashboardCardWidget(
                title: 'Total des actes',
                value: totalActes.toString(),
                comparison: 'par rapport au mois précédent',
                percentage: '5%',
                isIncrease: true,
                icon: const Icon(Icons.description_outlined, color: Colors.orange, size: 24),
                borderColor: Colors.orange,
                iconBgColor: Colors.orange.shade100,
              ),
              DashboardCardWidget(
                title: 'Actes acceptés',
                value: actesAcceptes.toString(),
                comparison: 'par rapport au mois précédent',
                percentage: '12%',
                isIncrease: true,
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
                borderColor: Colors.green,
                iconBgColor: Colors.green.shade100,
              ),
              DashboardCardWidget(
                title: 'Actes rejetés',
                value: actesRejetes.toString(),
                comparison: 'par rapport au mois précédent',
                percentage: '4%',
                isIncrease: false,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
                borderColor: Colors.red,
                iconBgColor: Colors.red.shade100,
              ),
              DashboardCardWidget(
                title: 'En cours de traitement',
                value: actesEnCours.toString(),
                comparison: 'par rapport au mois précédent',
                percentage: '8%',
                isIncrease: true,
                icon: const Icon(Icons.access_time, color: Colors.blue, size: 24),
                borderColor: Colors.blue,
                iconBgColor: Colors.blue.shade100,
              ),
            ],
          );
        },
      ),
    );
  }
}