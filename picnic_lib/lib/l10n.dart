// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/material.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/providers/locale_state_provider.dart';

/// 로컬라이제이션 설정 클래스
class PicnicLibL10n {
  /// 지원되는 로케일 목록
  static const supportedLocales = [
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('id'),
  ];

  /// 로컬라이제이션 델리게이트 목록
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// Crowdin OTA 초기화
  static Future<void> initialize({
    required String distributionHash,
    Duration updatesInterval = const Duration(minutes: 15),
  }) async {
    await Crowdin.init(
      distributionHash: distributionHash,
      connectionType: InternetConnectionType.any,
      updatesInterval: updatesInterval,
    );
  }

  /// 특정 로케일의 번역 로드
  static Future<void> loadTranslations(Locale locale) async {
    try {
      await Crowdin.loadTranslations(locale);
    } catch (e) {
      debugPrint('Crowdin 번역 로드 실패: $e');
    }
  }

  /// 모든 지원 로케일의 번역 미리 로드
  static Future<void> preloadTranslations() async {
    try {
      for (final locale in supportedLocales) {
        await loadTranslations(locale);
      }
    } catch (e) {
      debugPrint('번역 미리 로드 중 오류 발생: $e');
    }
  }
}

/// 번역 텍스트 가져오기
String t(String key, [List<String>? args]) {
  final locale = ProviderContainer().read(localeStateProvider);
  String? translatedText = Crowdin.getText(locale.languageCode, key);

  if (translatedText == null || translatedText.isEmpty) {
    translatedText = Crowdin.getText('en', key);
  }

  if (translatedText == null || translatedText.isEmpty) {
    translatedText = Crowdin.getText('ko', key);
  }

  String finalText = translatedText ?? key;

  if (args != null) {
    for (int i = 0; i < args.length; i++) {
      finalText = finalText.replaceAll('{$i}', args[i]);
    }
  }

  return finalText;
}

/// 현재 로케일의 언어 코드 가져오기
String getLocaleLanguage() {
  return PlatformDispatcher.instance.locale.languageCode;
}

/// JSON에서 로케일별 텍스트 가져오기
String getLocaleTextFromJson(Map<String, dynamic> json) {
  if (json.isEmpty) return '';

  final locale = getLocaleLanguage();
  return json[locale] ?? json['en'] ?? '';
}
