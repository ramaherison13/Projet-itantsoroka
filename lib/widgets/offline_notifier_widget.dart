import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'alert_context.dart';

class OfflineNotifierWidget extends StatefulWidget {
  final Widget child;

  const OfflineNotifierWidget({super.key, required this.child});

  @override
  State<OfflineNotifierWidget> createState() => _OfflineNotifierWidgetState();
}

class _OfflineNotifierWidgetState extends State<OfflineNotifierWidget> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    
    // Vérification initiale
    final results = await connectivity.checkConnectivity();
    _handleConnectivityChange(results);

    // Écoute des changements de connexion
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isOffline = results.isEmpty || results.every((result) => result == ConnectivityResult.none);

    if (isOffline) {
      _wasOffline = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AlertProvider.of(context).showAlert(
            "Vous êtes hors ligne. Votre connexion réseau est instable.",
            type: AlertType.warning,
            duration: const Duration(milliseconds: 200000),
            action: AlertAction(
              label: "Réessayer",
              onClick: () {
                // Action de rechargement ou nouvelle vérification
              },
            ),
          );
        }
      });
    } else if (_wasOffline) {
      _wasOffline = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AlertProvider.of(context).showAlert(
            "Connexion Internet rétablie.",
            type: AlertType.success,
            duration: const Duration(milliseconds: 200000),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}