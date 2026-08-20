import 'dart:async';
import 'package:flutter/material.dart';

enum AlertType { success, error, info, warning }

class AlertAction {
  final String label;
  final VoidCallback onClick;

  AlertAction({required this.label, required this.onClick});
}

class AlertModel {
  final int id;
  final String message;
  final AlertType type;
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

class AlertProvider extends StatefulWidget {
  final Widget child;

  const AlertProvider({super.key, required this.child});

  static AlertProviderState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_AlertInheritedWidget>();
    assert(result != null, 'No AlertProvider found in context');
    return result!.state;
  }

  @override
  State<AlertProvider> createState() => AlertProviderState();
}

class AlertProviderState extends State<AlertProvider> {
  final List<AlertModel> _alerts = [];
  int _idCounter = 0;

  void showAlert(
    String message, {
    AlertType type = AlertType.info,
    Duration duration = const Duration(seconds: 5),
    AlertAction? action,
  }) {
    final id = ++_idCounter;
    final alert = AlertModel(
      id: id,
      message: message,
      type: type,
      duration: duration,
      action: action,
    );

    setState(() {
      _alerts.add(alert);
    });

    Timer(duration, () {
      if (mounted) {
        setState(() {
          _alerts.removeWhere((a) => a.id == id);
        });
      }
    });
  }

  Color _getBackgroundColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Colors.green.shade100;
      case AlertType.error:
        return Colors.red.shade100;
      case AlertType.warning:
        return Colors.amber.shade100;
      case AlertType.info:
        return Colors.blue.shade100;
    }
  }

  Color _getTextColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Colors.green.shade800;
      case AlertType.error:
        return Colors.red.shade800;
      case AlertType.warning:
        return Colors.amber.shade900;
      case AlertType.info:
        return Colors.blue.shade800;
    }
  }

  Color _getBorderColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Colors.green.shade500;
      case AlertType.error:
        return Colors.red.shade500;
      case AlertType.warning:
        return Colors.amber.shade500;
      case AlertType.info:
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
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _alerts.map((alert) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
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
                                      ),
                                    ),
                                    if (alert.action != null) ...[
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          alert.action!.onClick();
                                          setState(() {
                                            _alerts.removeWhere((a) => a.id == alert.id);
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                                          foregroundColor: _getTextColor(alert.type),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          alert.action!.label,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _alerts.removeWhere((a) => a.id == alert.id);
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: _getTextColor(alert.type),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
  bool updateShouldNotify(_AlertInheritedWidget oldWidget) => oldWidget.state != state;
}

AlertProviderState useAlert(BuildContext context) {
  return AlertProvider.of(context);
}