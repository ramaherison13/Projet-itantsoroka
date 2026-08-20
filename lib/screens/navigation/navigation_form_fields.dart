import 'package:flutter/material.dart';

class RoleModel {
  final int roleId;
  final String roleName;
  final String roleSlug;

  RoleModel({
    required this.roleId,
    required this.roleName,
    required this.roleSlug,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: json['role_id'] ?? json['id'] ?? 0,
      roleName: json['role_name'] ?? '',
      roleSlug: json['role_slug'] ?? '',
    );
  }
}

class NavigationFormFieldsWidget extends StatelessWidget {
  final TextEditingController labelController;
  final TextEditingController pathController;
  final TextEditingController iconController;
  final TextEditingController componentController;
  final TextEditingController orderController;
  
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  
  final bool navigationShow;
  final ValueChanged<bool> onShowChanged;

  final List<RoleModel> availableRoles;
  final List<RoleModel> filteredRoles;
  final List<int> selectedRoles;
  final String searchRole;
  final ValueChanged<String> onSearchRoleChanged;
  final Function(int) onRoleToggle;

  final String? labelError;
  final String? pathError;
  final String? iconError;
  final String? categoryError;
  final String? rolesError;

  const NavigationFormFieldsWidget({
    super.key,
    required this.labelController,
    required this.pathController,
    required this.iconController,
    required this.componentController,
    required this.orderController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.navigationShow,
    required this.onShowChanged,
    required this.availableRoles,
    required this.filteredRoles,
    required this.selectedRoles,
    required this.searchRole,
    required this.onSearchRoleChanged,
    required this.onRoleToggle,
    this.labelError,
    this.pathError,
    this.iconError,
    this.categoryError,
    this.rolesError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom
        TextFormField(
          controller: labelController,
          decoration: InputDecoration(
            labelText: "Nom *",
            hintText: "Ex: Tableau de bord",
            errorText: labelError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),

        // Route
        TextFormField(
          controller: pathController,
          decoration: InputDecoration(
            labelText: "Route *",
            hintText: "Ex: /dashboard",
            errorText: pathError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),

        // Icône
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: iconController,
                decoration: InputDecoration(
                  labelText: "Icône *",
                  hintText: "Ex: fa-solid fa-house",
                  errorText: iconError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            if (iconController.text.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Icon(Icons.star, color: Colors.blue), // Remplacement de l'icône web par défaut
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Module et Composant
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: "Module *",
                  errorText: categoryError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: "idistrika", child: Text("I-Distrika")),
                  DropdownMenuItem(value: "itantsorika", child: Text("I-Tantsorika")),
                  DropdownMenuItem(value: "admin", child: Text("Administration")),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: componentController,
                decoration: InputDecoration(
                  labelText: "Composant (optionnel)",
                  hintText: "Ex: DashboardComponent",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Ordre d'affichage
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: orderController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Ordre d'affichage",
              helperText: "Détermine l'ordre dans le menu",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Visibilité
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text("Afficher dans le menu", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Désactiver pour masquer temporairement cette navigation"),
              value: navigationShow,
              onChanged: onShowChanged,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Sélection des rôles
        const Text("Rôles requis *", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          onChanged: onSearchRoleChanged,
          decoration: InputDecoration(
            labelText: "Rechercher un rôle...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            border: Border.all(color: rolesError != null ? Colors.red : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: filteredRoles.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text("Aucun rôle trouvé", style: TextStyle(color: Colors.grey))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredRoles.length,
                  itemBuilder: (context, index) {
                    final role = filteredRoles[index];
                    final isChecked = selectedRoles.contains(role.roleId);
                    return Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        title: Text(role.roleName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(role.roleSlug, style: const TextStyle(fontSize: 12)),
                        value: isChecked,
                        onChanged: (_) => onRoleToggle(role.roleId),
                      ),
                    );
                  },
                ),
        ),
        if (rolesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(rolesError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),

        // Chips des rôles sélectionnés
        if (selectedRoles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedRoles.map((roleId) {
              final role = availableRoles.firstWhere(
                (r) => r.roleId == roleId,
                orElse: () => RoleModel(roleId: roleId, roleName: 'Inconnu', roleSlug: ''),
              );
              return Chip(
                label: Text(role.roleName),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => onRoleToggle(roleId),
                backgroundColor: Colors.blue.shade50,
                labelStyle: TextStyle(color: Colors.blue.shade800),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}