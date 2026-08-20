import 'package:flutter/material.dart';

class RoleModel {
  final int roleId;
  final String roleName;
  final String roleSlug;

  const RoleModel({
    required this.roleId,
    required this.roleName,
    required this.roleSlug,
  });
}

class RoleSelectorWidget extends StatelessWidget {
  final List<RoleModel> availableRoles;
  final List<dynamic> selectedRoles;
  final String searchQuery;
  final String? error;
  final bool? touched;
  final ValueChanged<String> onSearchChange;
  final ValueChanged<int> onRoleToggle;

  const RoleSelectorWidget({
    super.key,
    required this.availableRoles,
    required this.selectedRoles,
    required this.searchQuery,
    this.error,
    this.touched,
    required this.onSearchChange,
    required this.onRoleToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = (error != null && error!.isNotEmpty) && (touched ?? true);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filteredRoles = availableRoles.where((role) {
      return role.roleName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Rôles requis",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: searchQuery,
              selection: TextSelection.collapsed(offset: searchQuery.length),
            ),
          ),
          onChanged: onSearchChange,
          decoration: InputDecoration(
            hintText: "Rechercher un rôle...",
            hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, size: 20, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 256),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade700 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Colors.red : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
            ),
          ),
          child: filteredRoles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_outlined, size: 48, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "Aucun rôle trouvé",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredRoles.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final role = filteredRoles[index];
                    final bool isChecked = selectedRoles.contains(role.roleId) ||
                        selectedRoles.contains(role.roleId.toString());

                    return InkWell(
                      onTap: () => onRoleToggle(role.roleId),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: isChecked,
                                onChanged: (_) => onRoleToggle(role.roleId),
                                activeColor: Colors.blue.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.roleName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    role.roleSlug,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (selectedRoles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedRoles.map((roleId) {
              final int numRoleId = roleId is String ? int.tryParse(roleId) ?? 0 : roleId;
              final roleMatch = availableRoles.firstWhere(
                (r) => r.roleId == numRoleId,
                orElse: () => RoleModel(roleId: numRoleId, roleName: 'Role #$numRoleId', roleSlug: ''),
              );

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      roleMatch.roleName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => onRoleToggle(numRoleId),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.red.shade400 : Colors.red.shade600,
            ),
          ),
        ],
      ],
    );
  }
}