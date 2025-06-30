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
      loadTranslations(Locale(languageCode));
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

  /// Crowdin OTA 초기화
  static Future<void> initialize(Setting appSetting,
      [ProviderContainer? container]) async {
    try {
      logger.i('PicnicLibL10n 초기화 시작');

      // 앱 설정 객체 저장
      _currentSetting = appSetting;
      _currentLanguage =
          appSetting.language.isNotEmpty ? appSetting.language : 'ko';

      // SharedPreferences 초기화
      logger.i('SharedPreferences 초기화 완료');

      // Crowdin 초기화 시도
      try {
        await Crowdin.init(
          distributionHash: Constants.crowdinDistributionHash,
          connectionType: InternetConnectionType.any,
          updatesInterval: const Duration(minutes: 15),
        );
        logger.i('Crowdin 초기화 완료: ${Constants.crowdinDistributionHash}');
      } catch (crowdinError) {
        logger.e('Crowdin 초기화 실패, 기본 번역으로 계속 진행', error: crowdinError);
        // Crowdin 초기화가 실패해도 계속 진행
      }

      // 초기화 완료 플래그 설정
      _isInitialized = true;
      logger.i('PicnicLibL10n 초기화 완료 (언어: $_currentLanguage)');
    } catch (e, s) {
      logger.e('PicnicLibL10n 초기화 실패', error: e, stackTrace: s);

      // 초기화 실패 시에도 기본 설정으로 작동하도록 함
      _currentSetting = appSetting;
      _currentLanguage =
          appSetting.language.isNotEmpty ? appSetting.language : 'ko';
      _isInitialized = true; // 기본 기능은 작동하도록 설정

      logger.w('PicnicLibL10n 기본 모드로 초기화됨 (언어: $_currentLanguage)');
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

      // Crowdin에서 직접 가져오기
      final translation = Crowdin.getText(languageCode, key);
      if (translation != null && translation.isNotEmpty) {
        return translation;
      }

      // 번역 실패 시 최후의 대안으로 하드코딩된 기본값 시도
      if (key == 'app_name') return 'TTJA';
      if (key.startsWith('nav_')) return key.substring(4).toUpperCase();
      if (key.startsWith('label_')) {
        final parts = key.split('_');
        if (parts.length > 1) {
          return parts.sublist(1).map((part) => _capitalize(part)).join(' ');
        }
      }

      // 모든 시도가 실패하면 키 반환
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
      // 초기화 안 된 경우에도 키를 기반으로 가능한 의미있는 문자열 반환
      logger.w('PicnicLibL10n이 완전히 초기화되지 않았습니다! 키: $key');

      // 키에서 의미 있는 텍스트 추출 시도
      if (key.contains('_')) {
        final parts = key.split('_');
        if (parts.length > 1) {
          // label_vote_upcoming -> Vote Upcoming 형태로 변환
          return parts.sublist(1).map((part) => _capitalize(part)).join(' ');
        }
      }

      return key;
    }

    try {
      // 현재 언어 코드 가져오기
      final languageCode = _getLanguage();

      // Crowdin에서 직접 가져오기
      String? translatedText = Crowdin.getText(languageCode, key);
      if (translatedText != null && translatedText.isNotEmpty) {
        // 디버깅: compatibility 관련 키의 경우 로그 출력
        if (key.contains('compatibility')) {
          logger
              .d('🌟 Crowdin 번역 로드됨: [$languageCode] $key -> $translatedText');
          if (args != null && args.isNotEmpty) {
            logger.d('🌟 매개변수: $args');
          }
        }
        final result = _formatTranslation(translatedText, args);
        if (key.contains('compatibility') && args != null && args.isNotEmpty) {
          logger.d('🌟 최종 결과: $result');
        }
        return result;
      }

      // 기본 영어로 시도
      if (languageCode != 'en') {
        translatedText = Crowdin.getText('en', key);
        if (translatedText != null && translatedText.isNotEmpty) {
          logger.d('영어 번역 사용: $key -> $translatedText');
          return _formatTranslation(translatedText, args);
        }
      }

      // Crowdin에서 찾지 못한 경우 기본 번역으로 폴백
      final fallbackText = _getFallbackTranslation(key, languageCode);
      if (fallbackText != null) {
        logger.d('기본 번역 사용: $key -> $fallbackText');
        return _formatTranslation(fallbackText, args);
      }

      // 모든 번역이 실패한 경우
      if (key.contains('compatibility')) {
        logger.w('🚨 Compatibility 키가 어디서도 찾아지지 않음: [$languageCode] $key');
      }

      return _formatTranslation(key, args);
    } catch (e, s) {
      logger.e('번역 과정에서 오류 발생: $key', error: e, stackTrace: s);
      return _formatTranslation(key, args);
    }
  }

  /// 기본 번역 제공 (Crowdin 실패 시 사용)
  static String? _getFallbackTranslation(String key, String languageCode) {
    // 한국어 기본 번역
    if (languageCode == 'ko') {
      switch (key) {
        case 'compatibility_purchase_message':
          return '나와 {artistName}의 궁합 점수가 궁금하다면? 🎯';
        case 'compatibility_empty_state_title':
          return '아직 궁합을 확인하지 않았어요';
        case 'compatibility_empty_state_subtitle':
          return '좋아하는 아티스트와의 궁합을 확인해보세요!';
        case 'label_reply':
          return '답글';
        case 'post_comment_action_show_translation':
          return '번역 보기';
        case 'post_comment_action_show_original':
          return '원문 보기';
        case 'post_comment_action_translate':
          return '번역하기';
        case 'post_comment_reported_comment':
          return '신고된 댓글';
        case 'post_comment_deleted_comment':
          return '삭제된 댓글';
        case 'post_comment_content_more':
          return '더보기';
        case 'post_comment_translated':
          return '번역됨';
        case 'error_action_failed':
          return '작업이 실패했습니다.';
        case 'label_hint_comment':
          return '댓글을 입력하세요';
        case 'common_retry_label':
          return '다시 시도';
        case 'label_retry':
          return '다시 시도';
        case 'popup_label_delete':
          return '삭제';
        case 'label_title_report':
          return '신고';
        case 'dialog_caution':
          return '주의';
      }
    }

    // 영어 기본 번역
    switch (key) {
      case 'compatibility_purchase_message':
        return 'Curious about compatibility score with {artistName}? 🎯';
      case 'compatibility_empty_state_title':
        return 'No compatibility checked yet';
      case 'compatibility_empty_state_subtitle':
        return 'Check compatibility with your favorite artist!';
      case 'label_reply':
        return 'Reply';
      case 'post_comment_action_show_translation':
        return 'Show Translation';
      case 'post_comment_action_show_original':
        return 'Show Original';
      case 'post_comment_action_translate':
        return 'Translate';
      case 'post_comment_reported_comment':
        return 'Reported Comment';
      case 'post_comment_deleted_comment':
        return 'Deleted Comment';
      case 'post_comment_content_more':
        return 'Show More';
      case 'post_comment_translated':
        return 'Translated';
      case 'error_action_failed':
        return 'Action failed';
      case 'label_hint_comment':
        return 'Write a comment';
      case 'common_retry_label':
        return 'Retry';
      case 'label_retry':
        return 'Retry';
      case 'popup_label_delete':
        return 'Delete';
      case 'label_title_report':
        return 'Report';
      case 'dialog_caution':
        return 'Caution';
    }

    return null;
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

  // 디버깅: compatibility 관련일 때 로그 출력
  if (text.contains('compatibility') || text.contains('궁합')) {
    logger.d('🔄 포맷팅 시작: "$text" with args: $args');
  }

  // Map 타입 처리 (이름 기반 플레이스홀더)
  args.forEach((key, value) {
    final placeholder = '{$key}';
    final beforeReplace = result;
    result = result.replaceAll(placeholder, value);

    // 디버깅: compatibility 관련일 때 각 치환 과정 로그
    if (text.contains('compatibility') || text.contains('궁합')) {
      logger.d(
          '🔄 치환: "$placeholder" -> "$value" | "$beforeReplace" -> "$result"');
    }
  });

  // 디버깅: 최종 결과
  if (text.contains('compatibility') || text.contains('궁합')) {
    logger.d('🔄 포맷팅 완료: "$result"');
  }

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
