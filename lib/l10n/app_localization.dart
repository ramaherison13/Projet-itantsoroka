import 'package:flutter/material.dart';
import 'app_fr_translations.dart';
import 'app_mg_translations.dart';

class AppLocalization {
  final Locale locale;
  AppLocalization(this.locale);

  static AppLocalization? of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  static const LocalizationsDelegate<AppLocalization> delegate = _AppLocalizationDelegate();

  late Map<String, dynamic> _localizedStrings;

  Future<bool> load() async {
    // Charger les traductions selon la locale
    if (locale.languageCode == 'mg') {
      _localizedStrings = malagasyTranslations; // Assurez-vous d'importer malagasyTranslations
    } else {
      _localizedStrings = frenchTranslations; // Assurez-vous d'importer frenchTranslations
    }
    return true;
  }

  String translate(String key) {
    // Gérer les clés imbriquées si nécessaire (ex: "nav_bar.doleance")
    if (key.contains('.')) {
      List<String> parts = key.split('.');
      dynamic current = _localizedStrings;
      for (String part in parts) {
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          return key;
        }
      }
      return current.toString();
    }
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'mg'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async {
    AppLocalization localization = AppLocalization(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => false;
}

// Extension pour faciliter l'appel dans les widgets (ex: context.tr('welcome'))
extension TranslationExtension on BuildContext {
  String tr(String key) {
    return AppLocalization.of(this)?.translate(key) ?? key;
  }
}