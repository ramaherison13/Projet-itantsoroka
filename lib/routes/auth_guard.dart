import 'package:flutter/material.dart';

class AuthGuard {
  // Normalise un slug de rôle (supprime les espaces et remplace par des tirets)
  static String? normalizeRoleSlug(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'\s+'), '-');
  }

  // Récupère la liste des slugs de rôles de l'utilisateur
  static List<String> getUserRoleSlugs(dynamic user) {
    if (user == null) return [];

    final directRoles = user['roles'] is List ? user['roles'] : [];
    final appUserRoles = user['appUserRoles'] is List ? user['appUserRoles'] : [];

    final directSlugs = directRoles
        .map((r) => r is Map ? (r['role_slug'] ?? r['role']?['role_slug'] ?? r['slug']) : null)
        .map(normalizeRoleSlug)
        .where((slug) => slug != null)
        .cast<String>()
        .toList();

    final appUserSlugs = appUserRoles
        .map((ur) => ur is Map ? (ur['role']?['role_slug'] ?? ur['role_slug']) : null)
        .map(normalizeRoleSlug)
        .where((slug) => slug != null)
        .cast<String>()
        .toList();

    return <String>{...directSlugs, ...appUserSlugs}.toList();
  }

  // Widget ou fonction de vérification d'authentification et des rôles
  static Widget protectRoute({
    required BuildContext context,
    required Widget child,
    required bool isInitialized,
    required bool isAuthenticated,
    List<String>? requiredRoles,
    dynamic user,
    String loginRoute = '/auth/login',
    String fallbackRoute = '/',
  }) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isAuthenticated || user == null) {
      // Redirection vers la page de connexion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, loginRoute);
      });
      return const SizedBox.shrink();
    }

    if (requiredRoles != null && requiredRoles.isNotEmpty) {
      final userRoleSlugs = getUserRoleSlugs(user);
      final hasPermission = requiredRoles.any((role) => userRoleSlugs.contains(role));

      if (!hasPermission) {
        // Redirection vers la page par défaut si non autorisé
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, fallbackRoute);
        });
        return const SizedBox.shrink();
      }
    }

    return child;
  }
}