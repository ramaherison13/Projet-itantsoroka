import 'package:flutter/material.dart';

class Section1Widget extends StatefulWidget {
  final List<Map<String, dynamic>> communes;
  final bool loading;
  final String? error;
  final dynamic selectedCommuneId;
  final ValueChanged<dynamic> onCommuneChanged;
  final ValueChanged<String?> onStatutChanged;
  final ValueChanged<String?> onPeriodeChanged;
  final VoidCallback onRefresh;
  final VoidCallback onExport;

  const Section1Widget({
    super.key,
    required this.communes,
    required this.loading,
    this.error,
    required this.selectedCommuneId,
    required this.onCommuneChanged,
    required this.onStatutChanged,
    required this.onPeriodeChanged,
    required this.onRefresh,
    required this.onExport,
  });

  @override
  State<Section1Widget> createState() => _Section1WidgetState();
}

class _Section1WidgetState extends State<Section1Widget> {
  String? _selectedStatut;
  String? _selectedPeriode;
  String? _selectedTypeActe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 240,
          margin: const EdgeInsets.only(top: 20, bottom: 40),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            image: const DecorationImage(
              image: AssetImage('assets/images/table.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black54,
                BlendMode.multiply,
              ),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tableau de bord',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      height: 6,
                      width: 120,
                      color: const Color(0xFFE98C21),
                      margin: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    const Text(
                      'Suivez les tendances...',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -30,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          const Text(
                            'Filtrer par :',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                          ),
                          const SizedBox(width: 12),
                          // Dropdown Commune
                          DropdownButton<dynamic>(
                            value: widget.selectedCommuneId == "" ? null : widget.selectedCommuneId,
                            hint: const Text("Toutes les communes", style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("Toutes les communes", style: TextStyle(fontSize: 13))),
                              ...widget.communes.map((c) => DropdownMenuItem(
                                    value: c['id'],
                                    child: Text(c['nom'].toString(), style: const TextStyle(fontSize: 13)),
                                  )),
                            ],
                            onChanged: widget.onCommuneChanged,
                          ),
                          if (widget.loading) const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Chargement...", style: TextStyle(fontSize: 10))),
                          if (widget.error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("Erreur", style: TextStyle(fontSize: 10, color: Colors.red))),
                        ],
                      ),

                      // Dropdown Type d'acte
                      DropdownButton<String>(
                        value: _selectedTypeActe,
                        hint: const Text("Tous les types d'actes", style: TextStyle(fontSize: 13)),
                        items: const [
                          DropdownMenuItem(value: null, child: Text("Tous les types d'actes", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "Arrêté", child: Text("Arrêté", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "Décision", child: Text("Décision", style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedTypeActe = val);
                        },
                      ),

                      // Dropdown Statut
                      DropdownButton<String>(
                        value: _selectedStatut,
                        hint: const Text("Tous les statuts", style: TextStyle(fontSize: 13)),
                        items: const [
                          DropdownMenuItem(value: null, child: Text("Tous les statuts", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "En cours", child: Text("En cours", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "Accepté", child: Text("Accepté", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "Rejeté", child: Text("Rejeté", style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedStatut = val);
                          widget.onStatutChanged(val);
                        },
                      ),

                      // Dropdown Période
                      DropdownButton<String>(
                        value: _selectedPeriode,
                        hint: const Text("Toutes les périodes", style: TextStyle(fontSize: 13)),
                        items: const [
                          DropdownMenuItem(value: null, child: Text("Toutes les périodes", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "jour", child: Text("jour", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "semaine", child: Text("semaine", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "Mois", child: Text("Mois", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "Année", child: Text("Année", style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedPeriode = val);
                          widget.onPeriodeChanged(val);
                        },
                      ),

                      // Boutons d'actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onRefresh,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Actualiser", style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: widget.onExport,
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text("Exporter", style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}