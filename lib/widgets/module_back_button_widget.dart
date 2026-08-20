import 'package:flutter/material.dart';

class BackRule {
  final RegExp pattern;
  final String to;
  final String label;

  BackRule({required this.pattern, required this.to, required this.label});
}

class ModuleBackButtonWidget extends StatelessWidget {
  final String currentPath;
  final ValueChanged<String> onNavigate;

  const ModuleBackButtonWidget({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  static final List<BackRule> _rules = [
    BackRule(
      pattern: RegExp(r'^/Generer-rapport', caseSensitive: false),
      to: '/rapportTpg',
      label: 'Retour aux rapports TPG',
    ),
    BackRule(
      pattern: RegExp(r'^/Details-rapport', caseSensitive: false),
      to: '/rapportTpg',
      label: 'Retour aux rapports TPG',
    ),
    BackRule(
      pattern: RegExp(r'^/', caseSensitive: false),
      to: '/services',
      label: 'Retour aux services',
    ),
    BackRule(
      pattern: RegExp(r'^/itantsorika/publier/(projet|evenement|actualite)', caseSensitive: false),
      to: '/itantsorika/publier',
      label: 'Retour à la publication',
    ),
    BackRule(
      pattern: RegExp(r'^/itantsorika/editPublication/', caseSensitive: false),
      to: '/itantsorika/gererPublication',
      label: 'Retour aux publications',
    ),
    BackRule(
      pattern: RegExp(r'^/itantsorika/ajoutdocument', caseSensitive: false),
      to: '/itantsorika/documents',
      label: 'Retour aux documents',
    ),
    BackRule(
      pattern: RegExp(r'^/itantsorika/', caseSensitive: false),
      to: '/itantsorika-services',
      label: 'Retour aux services I-Tantsorika',
    ),
  ];

  static final List<RegExp> _hiddenPaths = [
    RegExp(r'^/?$', caseSensitive: false),
    RegExp(r'^/services$', caseSensitive: false),
    RegExp(r'^/itantsorika$', caseSensitive: false),
    RegExp(r'^/itantsorika-services$', caseSensitive: false),
    RegExp(r'^/modules$', caseSensitive: false),
  ];

  @override
  Widget build(BuildContext context) {
    if (_hiddenPaths.any((regex) => regex.hasMatch(currentPath))) {
      return const SizedBox.shrink();
    }

    BackRule? backRule;
    for (var rule in _rules) {
      if (rule.pattern.hasMatch(currentPath)) {
        backRule = rule;
        break;
      }
    }

    if (backRule == null) {
      return const SizedBox.shrink();
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => onNavigate(backRule!.to),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFFF1ECEC).withValues(alpha: 0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isDarkMode ? Colors.transparent : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Affichage adaptatif (simulant le comportement responsive sm:hidden / hidden sm:inline)
                    bool isSmallScreen = MediaQuery.of(context).size.width < 640;
                    return Text(
                      isSmallScreen ? "Retour" : backRule!.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}