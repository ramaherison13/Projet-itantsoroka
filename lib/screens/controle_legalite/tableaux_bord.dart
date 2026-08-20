import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// COMPOSANT SECTION 1 (En-tête / Statistiques globales)
// -----------------------------------------------------------------------------
class Section1TableauBord extends StatelessWidget {
  const Section1TableauBord({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Tableau de bord - Contrôle de Légalité",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 4),
          Text(
            "Vue d'ensemble des actes soumis et de leur état d'avancement",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANT DASHBOARD (Grille de cartes / Statistiques)
// -----------------------------------------------------------------------------
class DashboardCardsWidget extends StatelessWidget {
  const DashboardCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard("Total Actes", "124", Colors.blue),
        _buildStatCard("En cours", "45", Colors.orange),
        _buildStatCard("Acceptés", "60", Colors.green),
        _buildStatCard("Rejetés", "12", Colors.red),
        _buildStatCard("Observations", "7", Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANT PIE CHART CARD (Graphique circulaire)
// -----------------------------------------------------------------------------
class PieChartCardWidget extends StatelessWidget {
  const PieChartCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Répartition par Statut", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  "[ Graphique Circulaire / PieChart ]",
                  style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANT BAR CHART CARD (Graphique en barres)
// -----------------------------------------------------------------------------
class BarChartCardWidget extends StatelessWidget {
  const BarChartCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Évolution des Soumissions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  "[ Graphique en Barres / BarChart ]",
                  style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAGE PRINCIPALE : TABLEAUX DE BORD
// -----------------------------------------------------------------------------
class TableauxBordPage extends StatelessWidget {
  const TableauxBordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 (En-tête)
            const Section1TableauBord(),
            const SizedBox(height: 24),

            // Cartes du Dashboard (Grid)
            const DashboardCardsWidget(),
            const SizedBox(height: 24),

            // Section des graphiques (PieChart et BarChart)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(child: PieChartCardWidget()),
                      SizedBox(width: 16),
                      Expanded(child: BarChartCardWidget()),
                    ],
                  );
                } else {
                  return Column(
                    children: const [
                      PieChartCardWidget(),
                      SizedBox(height: 16),
                      BarChartCardWidget(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}