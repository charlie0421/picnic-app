// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/material.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'dart:ui';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 전역 변수 추가
bool _isSettingLanguage = false;

/// 로컬라이제이션 설정 클래스
class PicnicLibL10n {
  static bool _isInitialized = false;
  static ProviderContainer? _container;

  /// 지원되는 로케일 목록 (언어 코드만 사용)
  static const List<Locale> supportedLocales = [
    Locale('en'), // 영어
    Locale('en', 'US'), // 미국 영어
    Locale('ja'), // 일본어
    Locale('ja', 'JP'), // 일본어 (일본)
    Locale('ko'), // 한국어
    Locale('ko', 'KR'), // 한국어 (한국)
    Locale('zh'), // 중국어
    Locale('zh', 'CN'), // 중국어 (중국)
    Locale('id'), // 인도네시아어
    Locale('id', 'ID'), // 인도네시아어 (인도네시아)
  ];

  /// 기본 로케일
  static const Locale defaultLocale = Locale('en');

  /// 현재 로케일 설정
  static void setCurrentLocale(String languageCode) {
    if (!_isInitialized || _isSettingLanguage) return;

    _isSettingLanguage = true;

    try {
      logger.i('언어 변경 시작 (PicnicLibL10n): $languageCode');
      loadTranslations(Locale(languageCode));
    } finally {
      _isSettingLanguage = false;
    }
  }

  /// 현재 로케일 가져오기
  static Locale getCurrentLocale() {
    if (!_isInitialized) return const Locale('en');
    return Locale(_getLanguage());
  }

  /// 현재 언어 코드 가져오기
  static String _getLanguage() {
    try {
      final setting = _container!.read(appSettingProvider);
      return setting.language;
    } catch (e) {
      logger.e('언어 코드 가져오기 실패', error: e);
      return 'en';
    }
  }

  /// 로컬라이제이션 델리게이트 목록
  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates {
    return [
      _PicnicLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
  }

  /// Crowdin OTA 초기화
  static Future<void> initialize(AppSetting appSetting,
      [ProviderContainer? container]) async {
    try {
      logger.i('PicnicLibL10n 초기화 시작');

      // 앱 설정 객체와 컨테이너 저장
      _container = container;

      // SharedPreferences 초기화
      logger.i('SharedPreferences 초기화 완료');

      // Crowdin 초기화
      await Crowdin.init(
        distributionHash: Constants.crowdinDistributionHash,
        connectionType: InternetConnectionType.any,
        updatesInterval: const Duration(minutes: 15),
      );
      logger.i('Crowdin 초기화 완료: ${Constants.crowdinDistributionHash}');

      _isInitialized = true;
      logger.i('PicnicLibL10n 초기화 완료');
    } catch (e, s) {
      _isInitialized = false;
      logger.e('PicnicLibL10n 초기화 실패', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 특정 로케일의 번역 로드
  static Future<void> loadTranslations(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      logger.w('지원되지 않는 로케일: ${locale.languageCode}');
      locale = defaultLocale;
    }

    try {
      final languageCode = locale.languageCode;
      logger.i('번역 로드 시작: $languageCode');

      // Crowdin 번역 로드
      await Crowdin.loadTranslations(Locale(languageCode));

      // 기본 번역 키 설정
      final testKeys = [
        'app_name',
        'nav_vote',
      ];

      // 각 키의 번역 로드 테스트 (디버깅 목적)
      int successCount = 0;
      for (final key in testKeys) {
        final translation = Crowdin.getText(languageCode, key);
        if (translation != null && translation.isNotEmpty) {
          successCount++;
        } else {
          logger.w('번역 로드 실패: [$languageCode] $key');
        }
      }

      logger
          .i('번역 로드 완료: $languageCode, 성공률: $successCount/${testKeys.length}');
    } catch (e, s) {
      logger.e('번역 로드 실패', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 번역 텍스트 가져오기
  static String getText(String languageCode, String key) {
    if (!_isInitialized) {
      logger.w('PicnicLibL10n이 초기화되지 않았습니다 (getText): $key');
      return key;
    }

    try {
      // 디버깅을 위한 언어 코드 확인
      if (!supportedLocales.any((l) => l.languageCode == languageCode)) {
        logger.w('지원되지 않는 언어 코드: $languageCode, $key에 대한 번역 시도');
        languageCode = 'en'; // 기본값으로 영어 사용
      }

      // 2. Crowdin에서 직접 가져오기
      Crowdin.getText(languageCode, key);

      // 4. 번역 실패 시 최후의 대안으로 하드코딩된 기본값 시도
      if (key == 'app_name') return 'TTJA';
      if (key.startsWith('nav_')) return key.substring(4).toUpperCase();
      if (key.startsWith('label_')) {
        final parts = key.split('_');
        if (parts.length > 1) {
          return parts.sublist(1).map((part) => _capitalize(part)).join(' ');
        }
      }

      // 5. 모든 시도가 실패하면 키 반환
      logger.w('번역을 찾을 수 없음: [$languageCode] $key');
      return key;
    } catch (e, s) {
      logger.e('번역 가져오기 중 오류: $key', error: e, stackTrace: s);
      return key;
    }
  }

  // 문자열의 첫 글자를 대문자로 변환
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String t(String key, [Map<String, String>? args]) {
    if (!_isInitialized) {
      // 초기화 안 된 경우 로그 추가
      logger.e('PicnicLibL10n이 초기화되지 않았습니다! 키: $key');
      return key;
    }

    try {
      // 현재 언어 코드 로깅
      final languageCode = _getLanguage();

      // Crowdin에서 직접 가져오기
      String? translatedText = Crowdin.getText(languageCode, key);
      if (translatedText != null && translatedText.isNotEmpty) {
        return _formatTranslation(translatedText, args);
      }

      // 기본 영어로 시도
      if (languageCode != 'en') {
        translatedText = Crowdin.getText('en', key);
        if (translatedText != null && translatedText.isNotEmpty) {
          logger.d('영어 번역 사용: $key -> $translatedText');
          return _formatTranslation(translatedText, args);
        }
      }

      // 번역 못 찾음
      logger.w('번역을 찾을 수 없음: $key');
      return _formatTranslation(key, args);
    } catch (e, s) {
      logger.e('번역 과정에서 오류 발생: $key', error: e, stackTrace: s);
      return _formatTranslation(key, args);
    }
  }
}

/// 커스텀 로컬라이제이션 델리게이트
class _PicnicLocalizationsDelegate extends LocalizationsDelegate<dynamic> {
  const _PicnicLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return PicnicLibL10n.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<dynamic> load(Locale locale) async {
    return null;
  }

  @override
  bool shouldReload(_PicnicLocalizationsDelegate old) => false;
}

/// 번역 텍스트 포맷팅
String _formatTranslation(String text, Map<String, String>? args) {
  if (args == null || args.isEmpty) return text;

  String result = text;

  // Map 타입 처리 (이름 기반 플레이스홀더)
  args.forEach((key, value) {
    final placeholder = '{$key}';
    result = result.replaceAll(placeholder, value);
  });

  return result;
}

/// 현재 로케일의 언어 코드 가져오기
String getLocaleLanguage() {
  return PlatformDispatcher.instance.locale.languageCode;
}

/// JSON에서 로케일별 텍스트 가져오기
String getLocaleTextFromJson(Map<String, dynamic> json) {
  if (json.isEmpty) return '';

  final locale = PicnicLibL10n.getCurrentLocale().languageCode;
  return json[locale] ?? json['en'] ?? '';
}

/// 전역 번역 함수
String t(String key, [Map<String, String>? args]) {
  return PicnicLibL10n.t(key, args);
}
