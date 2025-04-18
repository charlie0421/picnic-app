import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// AppLocalizations는 앱 내 모든 현지화 문자열에 대한 인터페이스를 정의합니다.
/// 실제 구현은 OTA 방식으로 Crowdin에서 가져옵니다.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = locale;

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// 앱에서 사용할 로컬라이제이션 델리게이트 목록
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// 지원되는 로케일 목록
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('id'),
  ];
}

/// AppLocalizations 델리게이트
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// 주어진 로케일에 대한 AppLocalizations 구현체를 반환합니다.
/// 실제 구현은 CrowdinLocalization에서 처리합니다.
AppLocalizations lookupAppLocalizations(Locale locale) {
  // 실제 구현은 crowdin_localizations.dart에서 가져옵니다.
  throw FlutterError(
      'AppLocalizations를 직접 호출하지 마세요. CrowdinLocalization을 사용하세요.');
}
