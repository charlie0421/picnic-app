// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/material.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 언어 변경 시 강제 리빌드를 위한 전역 마커
/// 이 값이 변경되면 이를 감시하는 위젯들이 강제로 리빌드됨
int globalRebuildMarker = 0;

/// 로컬라이제이션 설정 클래스
class PicnicLibL10n {
  static bool _isInitialized = false;
  static final Map<String, Map<String, String>> _translations = {};
  static SharedPreferences? _prefs;
  static ProviderContainer? _container;
  static AppSetting? _appSetting;

  /// 지원되는 로케일 목록 (언어 코드만 사용)
  static const List<Locale> supportedLocales = [
    Locale('en'), // 영어
    Locale('ja'), // 일본어
    Locale('ko'), // 한국어
    Locale('zh'), // 중국어
    Locale('id'), // 인도네시아어
  ];

  /// 기본 로케일
  static const Locale defaultLocale = Locale('en');

  /// 현재 로케일 설정
  static void setCurrentLocale(String languageCode) {
    if (!_isInitialized) return;

    logger.i('언어 변경 시작 (PicnicLibL10n): $languageCode');

    // 유효한 언어 코드인지 검증
    final validLanguageCode = languageCode.trim().toLowerCase();
    if (!supportedLocales.any((l) => l.languageCode == validLanguageCode)) {
      logger.e('지원되지 않는 언어 코드: $validLanguageCode');
      return;
    }

    // SharedPreferences에 직접 저장 (중요: 비동기이지만 동기적으로 처리)
    try {
      _prefs?.setString('language', validLanguageCode);
      logger.i('SharedPreferences에 직접 저장: $validLanguageCode');
    } catch (e) {
      logger.e('SharedPreferences 저장 실패', error: e);
    }

    // AppSettings에 언어 설정 저장
    if (_appSetting != null) {
      logger.i('언어 설정 저장: $validLanguageCode');
      _appSetting!.setLanguage(validLanguageCode);
    }

    // 언어 변경 시 즉시 번역 적용을 위해 해당 언어 번역 로드
    try {
      // 비동기 작업이지만 UI 갱신을 즉시 하기 위해 동기적으로 호출
      loadTranslations(Locale(validLanguageCode));

      // 앱 전체 UI 갱신을 위한 방법
      final context = navigatorKey.currentContext;
      if (context != null) {
        // 앱 전체 리빌드를 강제로 실행
        // 이 방법은 위젯 트리 전체를 다시 빌드하도록 합니다
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 전체 앱 상태 리빌드 트리거
          try {
            // VoteHomePage 관련 Provider들을 모두 무효화
            final container = ProviderScope.containerOf(context, listen: false);

            // 다른 화면들의 provider 무효화
            try {
              // 중요: asyncVoteListProvider와 asyncRewardListProvider는 패밀리 프로바이더이므로
              // 직접 무효화는 어렵지만, 다른 provider를 무효화하는 것으로 비슷한 효과를 낼 수 있음
              container.invalidate(appInitializationProvider);
              container.invalidate(navigationInfoProvider);
              container.refresh(appSettingProvider);

              // 강제로 앱을 다시 빌드하여 모든 화면이 새 로케일을 감지하도록 함
              // navigatorKey.currentState?.setState(() {
              //   logger.i('앱 전체 리빌드 시도 - 현재 언어: $validLanguageCode');
              // });

              // 고급 기법: 위젯 마커를 이용한 강제 리빌드 유도
              final now = DateTime.now().millisecondsSinceEpoch;
              globalRebuildMarker = now;
              logger.i('전역 리빌드 마커 업데이트: $now (현재 언어: $validLanguageCode)');
            } catch (e) {
              logger.e('Provider 무효화 중 오류', error: e);
            }
          } catch (e) {
            logger.e('앱 리빌드 시도 중 오류', error: e);
          }
        });
      }

      logger.i('언어 변경 완료 (PicnicLibL10n): $validLanguageCode');
    } catch (e) {
      logger.e('언어 변경 중 오류 발생', error: e);
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
      // Container가 있으면 Container에서 읽기
      if (_container != null) {
        final setting = _container!.read(appSettingProvider);
        return setting.language;
      }

      // SharedPreferences에서 직접 읽기
      if (_prefs != null) {
        final savedLanguage = _prefs!.getString('language');
        if (savedLanguage != null && savedLanguage.isNotEmpty) {
          return savedLanguage;
        }
      }

      return 'en';
    } catch (e) {
      logger.e('언어 코드 가져오기 실패', error: e);
      return 'en';
    }
  }

  /// 저장된 로케일 로드
  static Future<Locale> loadSavedLocale() async {
    try {
      // SharedPreferences가 초기화되지 않았으면 초기화
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
        logger.i('SharedPreferences 초기화 완료');
      }

      // 저장된 언어 코드 읽기
      final savedLanguage = _prefs!.getString('language');
      logger.i('저장된 언어 코드: $savedLanguage');

      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        // 유효한 언어 코드인지 확인
        if (supportedLocales.any((l) => l.languageCode == savedLanguage)) {
          logger.i('유효한 저장된 언어 발견: $savedLanguage');

          final locale = Locale(savedLanguage);

          // 번역 로드
          try {
            await loadTranslations(locale);
            logger.i('저장된 언어로 번역 로드 완료: $savedLanguage');
          } catch (e) {
            logger.e('저장된 언어 번역 로드 실패', error: e);
          }

          return locale;
        } else {
          logger.w('저장된 언어가 지원되지 않음: $savedLanguage');
        }
      } else {
        logger.i('저장된 언어 없음, 기본값 사용: ${defaultLocale.languageCode}');
      }
    } catch (e) {
      logger.e('저장된 로케일 로드 오류', error: e);
    }

    // 기본 로케일 사용
    await loadTranslations(defaultLocale);
    return defaultLocale;
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
    if (_isInitialized) {
      logger.i('이미 초기화됨, 건너뜀');
      return;
    }

    try {
      logger.i('PicnicLibL10n 초기화 시작');

      // 앱 설정 객체와 컨테이너 저장
      _appSetting = appSetting;
      _container = container;

      // SharedPreferences 초기화
      _prefs = await SharedPreferences.getInstance();
      logger.i('SharedPreferences 초기화 완료');

      // Crowdin 초기화
      await Crowdin.init(
        distributionHash: Constants.crowdinDistributionHash,
        connectionType: InternetConnectionType.any,
        updatesInterval: const Duration(minutes: 15),
      );
      logger.i('Crowdin 초기화 완료: ${Constants.crowdinDistributionHash}');

      // 저장된 로케일 로드
      final savedLocale = await loadSavedLocale();
      logger.i('저장된 로케일 로드 완료: ${savedLocale.languageCode}');

      // 번역 로드
      await loadTranslations(savedLocale);
      logger.i('번역 로드 완료: ${savedLocale.languageCode}');

      // AppSetting의 language 값을 로드된 로케일과 동기화
      if (_appSetting != null) {
        final currentLanguage = _getLanguage();
        if (currentLanguage != savedLocale.languageCode) {
          logger
              .i('앱 설정 언어 동기화: $currentLanguage → ${savedLocale.languageCode}');
          _appSetting!.setLanguage(savedLocale.languageCode);
        } else {
          logger.i('앱 설정 언어 이미 동기화됨: $currentLanguage');
        }
      }

      _isInitialized = true;
      logger.i('PicnicLibL10n 초기화 완료: ${savedLocale.languageCode}');
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
      await Crowdin.loadTranslations(Locale(languageCode));

      // 번역 데이터를 메모리에 캐시
      _translations[languageCode] = {};
      final testKeys = [
        'nav_vote',
        'label_vote_upcoming',
        'label_mypage_notice',
        'label_vote_reward_list',
        'label_vote_vote_gather',
        'nav_picchart',
        'nav_media',
        'nav_store',
        'label_mypage_charge_history',
        'label_mypage_customer_center',
        'label_setting_language',
        'label_mypage_setting',
        'label_mypage_my_artist',
        'label_mypage_vote_history',
        'page_title_mypage'
      ];

      for (final key in testKeys) {
        final translation = Crowdin.getText(languageCode, key);
        if (translation != null && translation.isNotEmpty) {
          _translations[languageCode]![key] = translation;
        }
      }
      logger.i('번역 로드 완료: $languageCode');
    } catch (e) {
      logger.e('번역 로드 실패', error: e);
      rethrow;
    }
  }

  /// 번역 텍스트 가져오기
  static String getText(String languageCode, String key) {
    if (!_isInitialized) return key;

    try {
      // 캐시된 번역에서 찾기
      final translations = _translations[languageCode];
      if (translations != null && translations.containsKey(key)) {
        return translations[key]!;
      }

      // Crowdin에서 직접 가져오기
      final translation = Crowdin.getText(languageCode, key);
      if (translation != null && translation.isNotEmpty) {
        return translation;
      }

      // 기본 언어(영어)로 시도
      if (languageCode != 'en') {
        final enTranslation = Crowdin.getText('en', key);
        if (enTranslation != null && enTranslation.isNotEmpty) {
          return enTranslation;
        }
      }

      return key;
    } catch (e) {
      return key;
    }
  }

  static String t(String key, [List<String>? args]) {
    if (!_isInitialized) return key;

    try {
      final languageCode = _getLanguage();
      String? translatedText = PicnicLibL10n.getText(languageCode, key);
      if (translatedText.isNotEmpty) {
        return _formatTranslation(translatedText, args);
      }

      if (languageCode != 'en') {
        translatedText = PicnicLibL10n.getText('en', key);
        if (translatedText.isNotEmpty) {
          return _formatTranslation(translatedText, args);
        }
      }

      return _formatTranslation(key, args);
    } catch (e) {
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
String _formatTranslation(String text, List<String>? args) {
  if (args == null || args.isEmpty) return text;

  String result = text;
  for (int i = 0; i < args.length; i++) {
    result = result.replaceAll('{$i}', args[i]);
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

  final locale = getLocaleLanguage();
  return json[locale] ?? json['en'] ?? '';
}

/// 전역 번역 함수
String t(String key, [List<String>? args]) {
  return PicnicLibL10n.t(key, args);
}
