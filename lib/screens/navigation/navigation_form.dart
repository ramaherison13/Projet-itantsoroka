import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class NavigationFormWidget extends StatefulWidget {
  final VoidCallback onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Map<String, dynamic>? editingItem;
  final String baseUrl;
  final int appId;
  final String? token;

  const NavigationFormWidget({
    super.key,
    required this.onAdd,
    required this.onEdit,
    this.editingItem,
    required this.baseUrl,
    required this.appId,
    this.token,
  });

  @override
  _NavigationFormWidgetState createState() => _NavigationFormWidgetState();
}

class _NavigationFormWidgetState extends State<NavigationFormWidget> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelController;
  late TextEditingController _pathController;
  late TextEditingController _iconController;
  late TextEditingController _componentController;
  late TextEditingController _orderController;

  String? _selectedCategory;
  bool _navigationShow = true;
  List<int> _requiredRoles = [];

  List<RoleModel> _availableRoles = [];
  bool _loading = false;
  String? _submitError;
  bool _submitSuccess = false;
  String _searchRole = '';

  final List<Map<String, String>> _categoryOptions = [
    {'value': 'idistrika', 'label': 'I-Distrika'},
    {'value': 'itantsorika', 'label': 'I-Tantsorika'},
    {'value': 'admin', 'label': 'Administration'},
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _pathController = TextEditingController();
    _iconController = TextEditingController();
    _componentController = TextEditingController();
    _orderController = TextEditingController(text: '1');

    _fetchRoles().then((_) {
      if (widget.editingItem != null) {
        _populateFields(widget.editingItem!);
      }
    });
  }

  void _populateFields(Map<String, dynamic> item) {
    _labelController.text = item['navigation_label_key'] ?? item['nameKey'] ?? '';
    _pathController.text = item['navigation_path'] ?? item['path'] ?? '';
    _iconController.text = item['navigation_icon'] ?? item['icon'] ?? '';
    _componentController.text = item['navigation_component'] ?? item['component'] ?? '';
    _orderController.text = (item['navigation_order'] ?? item['order'] ?? 1).toString();
    _selectedCategory = item['navigation_category'] ?? item['category'];
    _navigationShow = item['navigation_show'] ?? item['isShow'] ?? true;

    var rawRoles = item['requiredRoles'] ?? [];
    List<int> roleIds = [];
    for (var r in rawRoles) {
      if (r is int) {
        roleIds.add(r);
      } else {
        // Si les rôles sont des slugs ou des noms, on cherche l'ID correspondant
        final found = _availableRoles.where((role) => role.roleSlug == r.toString() || role.roleName == r.toString());
        if (found.isNotEmpty) {
          roleIds.add(found.first.roleId);
        }
      }
    }
    setState(() {
      _requiredRoles = roleIds;
    });
  }

  Future<void> _fetchRoles() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}/roles'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List rolesList = data['roles'] ?? data;
        setState(() {
          _availableRoles = rolesList.map((r) => RoleModel.fromJson(r)).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur récupération rôles: $e");
    }
  }

  void _resetForm() {
    _labelController.clear();
    _pathController.clear();
    _iconController.clear();
    _componentController.clear();
    _orderController.text = '1';
    setState(() {
      _selectedCategory = null;
      _navigationShow = true;
      _requiredRoles = [];
      _submitError = null;
      _submitSuccess = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _submitError = "Veuillez corriger les erreurs avant de soumettre");
      return;
    }

    if (_requiredRoles.isEmpty) {
      setState(() => _submitError = "Au moins un rôle est requis");
      return;
    }

    setState(() {
      _loading = true;
      _submitError = null;
      _submitSuccess = false;
    });

    final payload = {
      "navigation_label_key": _labelController.text,
      "navigation_path": _pathController.text,
      "navigation_icon": _iconController.text,
      "navigation_category_label_key": "string",
      "requiredRoles": _requiredRoles,
      "navigation_component": _componentController.text,
      "navigation_show": _navigationShow,
      "navigation_category": _selectedCategory,
      "navigation_order": int.tryParse(_orderController.text) ?? 1,
      "app_id": widget.appId,
    };

    try {
      if (widget.editingItem != null) {
        widget.onEdit(payload);
      } else {
        final res = await http.post(
          Uri.parse('${widget.baseUrl}/navigation'),
          headers: {
            'Content-Type': 'application/json',
            if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode(payload),
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          widget.onAdd();
        } else {
          throw Exception("Erreur lors de la création");
        }
      }

      setState(() => _submitSuccess = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _submitSuccess = false);
      });

      if (widget.editingItem == null) {
        _resetForm();
      }
    } catch (e) {
      setState(() => _submitError = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoles = _availableRoles.where((r) => r.roleName.toLowerCase().contains(_searchRole.toLowerCase())).toList();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_submitSuccess)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green[50], border: Border.all(color: Colors.green.shade200), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  widget.editingItem != null ? "Navigation mise à jour avec succès !" : "Navigation ajoutée avec succès !",
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            if (_submitError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(8)),
                child: Text(_submitError!, style: const TextStyle(color: Colors.red)),
              ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(labelText: "Nom *", hintText: "Ex: Tableau de bord"),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Le nom est requis";
                      if (val.length < 2) return "Minimum 2 caractères";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _pathController,
                    decoration: const InputDecoration(labelText: "Route *", hintText: "Ex: /dashboard"),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "La route est requise";
                      if (!val.startsWith("/")) return "Doit commencer par /";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(labelText: "Icône *", hintText: "Ex: fas fa-home"),
              validator: (val) => (val == null || val.trim().isEmpty) ? "L'icône est requise" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: "Module *"),
                    items: _categoryOptions.map((cat) {
                      return DropdownMenuItem(value: cat['value'], child: Text(cat['label']!));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    validator: (val) => (val == null || val.isEmpty) ? "Le module est requis" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _componentController,
                    decoration: const InputDecoration(labelText: "Composant", hintText: "Ex: DashboardComponent"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Ordre d'affichage", helperText: "Ordre dans le menu"),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Afficher dans le menu"),
              subtitle: const Text("Désactiver pour masquer temporairement"),
              value: _navigationShow,
              onChanged: (val) => setState(() => _navigationShow = val),
            ),
            const SizedBox(height: 16),
            const Text("Rôles requis *", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: "Rechercher un rôle...", prefixIcon: Icon(Icons.search)),
              onChanged: (val) => setState(() => _searchRole = val),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: filteredRoles.map((role) {
                final isSelected = _requiredRoles.contains(role.roleId);
                return FilterChip(
                  label: Text(role.roleName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _requiredRoles.add(role.roleId);
                      } else {
                        _requiredRoles.remove(role.roleId);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.editingItem != null ? Colors.orange : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(widget.editingItem != null ? "Mettre à jour" : "Ajouter la navigation", style: const TextStyle(color: Colors.white)),
                  ),
                ),
                if (widget.editingItem == null) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _loading ? null : _resetForm,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
                    child: const Text("Réinitialiser"),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}