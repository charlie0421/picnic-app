import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:picnic_lib/generated/l10n.dart';

/// Picnic 라이브러리의 다국어 설정을 위한 delegate
class PicnicLibL10n {
  static LocalizationsDelegate<S> get delegate => S.delegate;

  static List<LocalizationsDelegate> get localizationsDelegates => [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static List<Locale> get supportedLocales => S.delegate.supportedLocales;
}
