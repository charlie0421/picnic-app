import 'dart:async';

import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';

/// OTA 방식으로 변환된 Crowdin 로컬라이제이션 클래스
/// 로컬 ARB 파일 대신 Crowdin 서버에서 직접 텍스트를 가져옴
class CrowdinLocalization implements AppLocalizations {
  @override
  final String localeName;

  CrowdinLocalization(String locale) : localeName = locale;

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

  // OTA 방식으로 텍스트 가져오기
  String _getText(String key) {
    // 1. 현재 로케일로 시도
    final text = Crowdin.getText(localeName, key);
    if (text != null && text.isNotEmpty) {
      return text.toString();
    }

    // 2. 영어로 폴백 시도
    final enText = Crowdin.getText('en', key);
    if (enText != null && enText.isNotEmpty) {
      return enText.toString();
    }

    // 3. 한국어로 폴백 시도
    final koText = Crowdin.getText('ko_KR', key);
    if (koText != null && koText.isNotEmpty) {
      return koText.toString();
    }

    // 4. 마지막 수단: 키 자체를 반환
    debugPrint('경고: 번역 없음 - $key (로케일: $localeName)');
    return key;
  }

  // 예시: 부족한 메서드 채우기
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      final memberName = invocation.memberName.toString().split('"')[1];
      return _getText(memberName);
    }
    return super.noSuchMethod(invocation);
  }
}

/// Crowdin 로컬라이제이션 델리게이트
class _CrowdinLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _CrowdinLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((e) => e.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    try {
      // Crowdin OTA 사용해 번역 로드
      await Crowdin.loadTranslations(locale);
      return CrowdinLocalization(locale.toString());
    } catch (e) {
      // 실패 시 에러 출력하고 기본 구현 제공
      debugPrint('Crowdin 번역 로드 실패: $e');
      return CrowdinLocalization(locale.toString());
    }
  }

  @override
  bool shouldReload(_CrowdinLocalizationsDelegate old) => false;
}
