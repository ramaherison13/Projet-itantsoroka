import 'package:flutter/material.dart';
import 'package:itantsoroka/core/admin_theme.dart';

class UserCardProfile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String apiBaseUrl;

  const UserCardProfile({
    super.key,
    required this.data,
    required this.apiBaseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;

    final citoyen = data['citoyen'] is Map ? data['citoyen'] as Map<String, dynamic> : {};
    final user = data['user'] is Map ? data['user'] as Map<String, dynamic> : data;

    final String? citizenPhoto = citoyen['citizen_photo']?.toString();
    final String photoUrl = (citizenPhoto != null && citizenPhoto.trim().isNotEmpty)
        ? "$apiBaseUrl/serviceupload/file/preview/${Uri.encodeComponent(citizenPhoto.trim())}"
        : "";

    final String firstName = (citoyen['citizen_first_name'] ?? citoyen['citizen_name'] ?? user['user_first_name'] ?? '').toString();
    final String lastName = (citoyen['citizen_last_name'] ?? citoyen['citizen_lastname'] ?? '').toString();
    final String fullName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : (user['user_pseudo'] ?? 'Nom inconnu').toString();

    final String citizenCard = (citoyen['citizen_cin'] ?? citoyen['citizen_national_card_number'] ?? 'N/A').toString();
    final String userPhone = (user['user_phone'] ?? 'N/A').toString();
    final String citizenAddress = (citoyen['citizen_adress'] ?? citoyen['citizen_address'] ?? 'N/A').toString();
    final String userEmail = (user['user_email'] ?? user['email'] ?? 'N/A').toString();

    final List appUserRoles = user['appUserRoles'] as List? ?? [];
    final List<String> roles = appUserRoles
        .map<String>((r) => r['role']?['role_name']?.toString() ?? r['role_slug']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AdminTheme.surfaceDark : AdminTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
          border: Border.all(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight),
          boxShadow: AdminTheme.shadowMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Photo de profil / Avatar
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AdminTheme.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AdminTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _fallbackAvatar(initial),
                      )
                    : _fallbackAvatar(initial),
              ),
            ),
            const SizedBox(height: 14),

            // Nom & Prénom
            Text(
              fullName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (user['user_pseudo'] != null && user['user_pseudo'] != fullName) ...[
              const SizedBox(height: 2),
              Text(
                '@${user['user_pseudo']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AdminTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 14),
            Divider(color: isDark ? AdminTheme.borderDark : AdminTheme.borderLight, height: 1),
            const SizedBox(height: 14),

            // Informations détaillées
            Column(
              children: [
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'CIN',
                  text: citizenCard,
                  isDark: isDark,
                  isCode: true,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  text: userEmail,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  text: userPhone,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Adresse',
                  text: citizenAddress,
                  isDark: isDark,
                ),
              ],
            ),

            // Rôles
            if (roles.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: roles.map((r) => AdminTheme.badge(r, AdminTheme.primaryLight)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String text,
    required bool isDark,
    bool isCode = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark ? AdminTheme.textMutedDark : AdminTheme.textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          '$label :',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AdminTheme.textSecondaryDark : AdminTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontFamily: isCode ? 'monospace' : null,
              color: isDark ? AdminTheme.textPrimaryDark : AdminTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}