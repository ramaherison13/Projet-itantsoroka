import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_fr_translations.dart';
import 'app_mg_translations.dart';

class AppLocalization {
  final Locale locale;
  AppLocalization(this.locale);

  static AppLocalization? of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  static const LocalizationsDelegate<AppLocalization> delegate = _AppLocalizationDelegate();
  static const LocalizationsDelegate<MaterialLocalizations> materialDelegate = _MgMaterialLocalizationsDelegate();
  static const LocalizationsDelegate<CupertinoLocalizations> cupertinoDelegate = _MgCupertinoLocalizationsDelegate();

  late Map<String, dynamic> _localizedStrings;

  Future<bool> load() async {
    if (locale.languageCode == 'mg') {
      _localizedStrings = malagasyTranslations;
    } else {
      _localizedStrings = frenchTranslations;
    }
    return true;
  }

  String translate(String key) {
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

class _MgMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MgMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mg';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('fr', 'FR'));
  }

  @override
  bool shouldReload(_MgMaterialLocalizationsDelegate old) => false;
}

class _MgCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _MgCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mg';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('fr', 'FR'));
  }

  @override
  bool shouldReload(_MgCupertinoLocalizationsDelegate old) => false;
}

extension TranslationExtension on BuildContext {
  String tr(String key) {
    return AppLocalization.of(this)?.translate(key) ?? key;
  }

  String trDynamic(dynamic raw) {
    if (raw == null) return "";
    if (raw is Map) {
      final code = AppLocalization.of(this)?.locale.languageCode ?? 'fr';
      if (raw.containsKey(code) && raw[code] != null && raw[code].toString().isNotEmpty) {
        return raw[code].toString();
      }
      final fr = raw['fr'];
      if (fr != null && fr.toString().isNotEmpty) return fr.toString();
      final mg = raw['mg'];
      if (mg != null && mg.toString().isNotEmpty) return mg.toString();
      final en = raw['en'];
      if (en != null && en.toString().isNotEmpty) return en.toString();
      if (raw.values.isNotEmpty && raw.values.first != null) {
        return raw.values.first.toString();
      }
      return "";
    }
    final String str = raw.toString();
    final translated = tr(str);
    return translated != str ? translated : str;
  }
}