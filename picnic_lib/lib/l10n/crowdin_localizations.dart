// ignore_for_file: unused_import

import 'dart:convert';

import 'app_localizations.dart';

import 'package:crowdin_sdk/crowdin_sdk.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CrowdinLocalization extends AppLocalizations {
  final AppLocalizations _fallbackTexts;

  CrowdinLocalization(super.locale, AppLocalizations fallbackTexts)
      : _fallbackTexts = fallbackTexts;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _CrowdinLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;

  @override
  String get appTitle =>
      Crowdin.getText(localeName, 'appTitle') ?? _fallbackTexts.appTitle;
}

class _CrowdinLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _CrowdinLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.delegate
      .load(locale)
      .then((fallback) => CrowdinLocalization(locale.toString(), fallback));

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale);

  @override
  bool shouldReload(_CrowdinLocalizationsDelegate old) => false;
}
