import 'package:flutter/material.dart';
import 'auth_guard.dart'; // Importez le fichier AuthGuard créé précédemment

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final List<String>? roles;
  final bool isInitialized;
  final bool isAuthenticated;
  final dynamic user;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.roles,
    required this.isInitialized,
    required this.isAuthenticated,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard.protectRoute(
      context: context,
      child: child,
      isInitialized: isInitialized,
      isAuthenticated: isAuthenticated,
      requiredRoles: roles,
      user: user,
      loginRoute: '/auth/login',
      fallbackRoute: '/unauthorized',
    );
  }
}