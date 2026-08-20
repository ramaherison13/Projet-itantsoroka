import 'package:flutter/material.dart';

// Modèle représentant une action d'alerte
class AlertAction {
  final String label;
  final VoidCallback onClick;

  AlertAction({required this.label, required this.onClick});
}

// Modèle pour une alerte individuelle
class AlertModel {
  final int id;
  final String message;
  final String type; // 'success', 'error', 'info', 'warning'
  final Duration duration;
  final AlertAction? action;

  AlertModel({
    required this.id,
    required this.message,
    required this.type,
    required this.duration,
    this.action,
  });
}

// InheritedWidget pour propager l'état des alertes dans l'arbre des widgets
class AlertProvider extends StatefulWidget {
  final Widget child;

  const AlertProvider({super.key, required this.child});

  static AlertProviderState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_AlertInheritedWidget>();
    assert(result != null, 'No AlertProvider found in context');
    return result!.state;
  }

  @override
  AlertProviderState createState() => AlertProviderState();
}

class AlertProviderState extends State<AlertProvider> {
  final List<AlertModel> _alerts = [];
  int _idCounter = 0;

  void showAlert(
    String message, {
    String type = "info",
    int durationMs = 5000,
    AlertAction? action,
  }) {
    final id = ++_idCounter;
    final alert = AlertModel(
      id: id,
      message: message,
      type: type,
      duration: Duration(milliseconds: durationMs),
      action: action,
    );

    setState(() {
      _alerts.add(alert);
    });

    Future.delayed(alert.duration, () {
      if (mounted) {
        setState(() {
          _alerts.removeWhere((a) => a.id == id);
        });
      }
    });
  }

  void _removeAlert(int id) {
    setState(() {
      _alerts.removeWhere((a) => a.id == id);
    });
  }

  Color _getBackgroundColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green.shade200;
      case 'error':
        return Colors.red.shade200;
      case 'warning':
        return Colors.yellow.shade200;
      case 'info':
      default:
        return Colors.blue.shade200;
    }
  }

  Color _getTextColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green.shade800;
      case 'error':
        return Colors.red.shade800;
      case 'warning':
        return Colors.yellow.shade800;
      case 'info':
      default:
        return Colors.blue.shade800;
    }
  }

  Color _getBorderColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green.shade500;
      case 'error':
        return Colors.red.shade500;
      case 'warning':
        return Colors.yellow.shade500;
      case 'info':
      default:
        return Colors.blue.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AlertInheritedWidget(
      state: this,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _alerts.map((alert) {
                    return Container(
                      width: 320,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(alert.type),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: _getBorderColor(alert.type),
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.message,
                                  style: TextStyle(
                                    color: _getTextColor(alert.type),
                                    fontSize: 14,
                                  ),
                                ),
                                if (alert.action != null) ...[
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      alert.action!.onClick();
                                      _removeAlert(alert.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                                      foregroundColor: _getTextColor(alert.type),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                    ),
                                    child: Text(alert.action!.label,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _removeAlert(alert.id),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: _getTextColor(alert.type),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertInheritedWidget extends InheritedWidget {
  final AlertProviderState state;

  const _AlertInheritedWidget({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AlertInheritedWidget oldWidget) => true;
}

// Fonction utilitaire pour consommer l'alerte (équivalent de useAlert)
AlertProviderState useAlert(BuildContext context) {
  return AlertProvider.of(context);
}