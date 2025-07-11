// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 전역 변수 추가
bool _isSettingLanguage = false;

/// 로컬라이제이션 설정 클래스 (로컬 번역만 사용)
class PicnicLibL10n {
  static bool _isInitialized = false;
  static Setting? _currentSetting;
  static String _currentLanguage = 'ko'; // 기본 언어

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
    if (!_isInitialized || _isSettingLanguage) {
      logger.w('PicnicLibL10n이 완전히 초기화되지 않았거나 이미 언어 설정 중입니다.');
      return;
    }

    _isSettingLanguage = true;

    try {
      logger.i('언어 변경 시작 (PicnicLibL10n): $languageCode');
      _currentLanguage = languageCode;
    } finally {
      _isSettingLanguage = false;
    }
  }

  /// 현재 로케일 가져오기
  static Locale getCurrentLocale() {
    if (!_isInitialized) {
      logger.w('PicnicLibL10n이 완전히 초기화되지 않았습니다. 기본 로케일(en) 사용');
      return const Locale('en');
    }
    return Locale(_getLanguage());
  }

  /// 현재 언어 코드 가져오기
  static String _getLanguage() {
    try {
      // _currentSetting이 있으면 사용, 없으면 _currentLanguage 사용
      if (_currentSetting != null) {
        return _currentSetting!.language;
      }
      return _currentLanguage;
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

  /// 로컬 번역 시스템 초기화
  static Future<void> initialize(Setting appSetting,
      [ProviderContainer? container]) async {
    try {
      logger.i('PicnicLibL10n 로컬 번역 시스템 초기화 시작');

      // 앱 설정 객체 저장
      _currentSetting = appSetting;
      _currentLanguage =
          appSetting.language.isNotEmpty ? appSetting.language : 'ko';

      // 로컬 번역만 사용하므로 바로 초기화 완료
      _isInitialized = true;
      logger.i('PicnicLibL10n 로컬 번역 시스템 초기화 완료 (언어: $_currentLanguage)');
    } catch (e, s) {
      logger.e('PicnicLibL10n 초기화 실패', error: e, stackTrace: s);

      // 초기화 실패 시에도 기본 설정으로 작동하도록 함
      _currentSetting = appSetting;
      _currentLanguage =
          appSetting.language.isNotEmpty ? appSetting.language : 'ko';
      _isInitialized = true;

      logger.w('PicnicLibL10n 기본 모드로 초기화됨 (언어: $_currentLanguage)');
    }
  }

  /// 특정 로케일의 번역 로드 (로컬 번역만 사용)
  static Future<void> loadTranslations(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      logger.w('지원되지 않는 로케일: ${locale.languageCode}');
      locale = defaultLocale;
    }

    try {
      final languageCode = locale.languageCode;
      logger.i('로컬 번역 로드 시작: $languageCode');

      // 로컬 번역이므로 즉시 완료
      logger.i('로컬 번역 로드 완료: $languageCode');
    } catch (e, s) {
      logger.e('번역 로드 실패', error: e, stackTrace: s);
      rethrow;
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
