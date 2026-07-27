import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/services/locale_service.dart';

/// 언어 초기화 및 관리를 위한 유틸리티 클래스
class LanguageInitializer {
  /// 앱의 언어를 초기화합니다.
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  /// [loadGeneratedTranslations] 앱별 생성된 번역 로드 함수 (S.load)
  /// [defaultLanguage] 기본 언어 (기본값: 'ko')
  ///
  /// 반환값은 언어 초기화 성공 여부와 최종 설정된 언어입니다.
  static Future<(bool, String)> initializeLanguage(
    WidgetRef ref,
    Future<void> Function(Locale) loadGeneratedTranslations, {
    String defaultLanguage = 'ko',
  }) async {
    try {
      // 저장된 언어 설정 로드
      final appSetting = ref.read(appSettingProvider);
      String targetLanguage = appSetting.language.isNotEmpty
          ? appSetting.language
          : defaultLanguage;

      // 저장된 언어가 없으면 디바이스 언어 감지
      if (appSetting.language.isEmpty ||
          appSetting.language == defaultLanguage) {
        try {
          // 디바이스의 시스템 로케일 가져오기
          // (WidgetsBinding 경유 - 테스트에서 주입 가능하고 프로덕션에서는
          //  ui.PlatformDispatcher.instance 와 동일한 객체다)
          final deviceLocale =
              WidgetsBinding.instance.platformDispatcher.locale;
          final detectedLanguage = resolveDeviceLanguage(deviceLocale);

          // 지원되는 언어인 경우에만 적용한다. null 이면 기본 언어로 남는다.
          if (detectedLanguage != null) {
            targetLanguage = detectedLanguage;
            logger.i(
              '디바이스 언어 감지: $detectedLanguage (device: ${deviceLocale.toLanguageTag()})',
            );

            // 디바이스 언어를 로컬 스토리지에 저장
            await const Setting().load(); // Setting 인스턴스 생성
            ref.read(appSettingProvider.notifier).setLanguage(detectedLanguage);
          }
        } catch (e) {
          logger.w('디바이스 언어 감지 실패, 기본값 사용', error: e);
        }
      }

      // 언어 변경 시도
      final success = await changeLanguage(
        ref,
        targetLanguage,
        loadGeneratedTranslations,
      );
      if (success) {
        // 처음 실행 시 디바이스 언어 감지한 경우 DB 업데이트
        if (appSetting.language.isEmpty ||
            appSetting.language == defaultLanguage) {
          try {
            await ref
                .read(userInfoProvider.notifier)
                .updateLanguage(targetLanguage);
          } catch (e) {
            logger.w('user_profiles.language 업데이트 실패 (초기화)', error: e);
          }
        }
        return (true, targetLanguage);
      }

      // 실패 시 기본 언어로 재시도 (다른 언어인 경우에만)
      if (targetLanguage != defaultLanguage) {
        final fallbackSuccess = await changeLanguage(
          ref,
          defaultLanguage,
          loadGeneratedTranslations,
        );
        return (fallbackSuccess, defaultLanguage);
      }

      return (false, defaultLanguage);
    } catch (e, stackTrace) {
      logger.e('언어 초기화 중 오류 발생', error: e, stackTrace: stackTrace);

      // 최종 폴백: 기본 언어로 설정
      try {
        await changeLanguage(ref, defaultLanguage, loadGeneratedTranslations);
        return (true, defaultLanguage);
      } catch (fallbackError) {
        return (false, defaultLanguage);
      }
    }
  }

  /// 디바이스 로케일을 앱이 지원하는 언어 코드로 변환한다.
  /// 지원하지 않는 언어면 null 을 돌려주고, 호출부는 기본 언어를 유지한다.
  ///
  /// 조회는 정규화된(canonical) 코드로 한다. `Setting.supportedLanguages` 는
  /// 지역 없는 `zh` / `bn` 을 일부러 빼기 때문에, 디바이스가 준 코드를 그대로
  /// 넣으면 지역 코드가 없는 중국어/벵골어 기기가 전부 미지원으로 떨어졌다.
  ///
  /// 1. 지역 코드가 있으면 `<lang>_<REGION>` 을 정규화해서 먼저 찾는다.
  ///    (`zh_TW` 처럼 지역 변형을 실제로 서비스하는 언어를 잡는다)
  /// 2. 실패하면 지역 없는 언어 코드를 정규화해서 찾는다.
  ///    (`en_GB` → `en` 처럼 우리가 안 가진 지역은 언어 단위로 떨어뜨린다)
  @visibleForTesting
  static String? resolveDeviceLanguage(ui.Locale deviceLocale) {
    final supported = Setting.supportedLanguages;
    final region = _lookupRegion(deviceLocale);

    if (region != null && region.isNotEmpty) {
      final regional = canonicalLanguageCode(
        '${deviceLocale.languageCode}_$region',
      );
      if (supported.contains(regional)) return regional;
    }

    final language = canonicalLanguageCode(deviceLocale.languageCode);
    return supported.contains(language) ? language : null;
  }

  /// 조회에 사용할 지역 코드. 지역 정보가 전혀 없으면 null.
  ///
  /// 중국어는 지역보다 표기 체계(scriptCode)가 우선한다. iOS/Android 모두
  /// "중국어(간체) + 홍콩" 같은 조합을 `zh-Hans-HK` 로 보고하는데, 지역만
  /// 보면 번체로 잘못 판정된다. 어떤 지역이 간체/번체인지에 대한 규칙 자체는
  /// [canonicalLanguageCode] 가 단독으로 갖고 있고, 여기서는 "표기 체계가
  /// 지역을 이긴다"만 정한다. scriptCode 는 `ui.Locale` 에만 있는 개념이라
  /// 문자열 코드를 받는 [canonicalLanguageCode] 로 내릴 수 없다.
  static String? _lookupRegion(ui.Locale deviceLocale) {
    if (deviceLocale.languageCode == 'zh') {
      switch (deviceLocale.scriptCode) {
        case 'Hans':
          return 'CN';
        case 'Hant':
          return 'TW';
      }
    }
    return deviceLocale.countryCode;
  }

  /// 앱의 언어를 변경합니다.
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  /// [language] 변경할 언어 코드 (예: 'ko', 'en', 'ja')
  /// [loadGeneratedTranslations] 앱별 생성된 번역 로드 함수 (S.load)
  ///
  /// 반환값은 언어 변경 성공 여부입니다.
  static Future<bool> changeLanguage(
    WidgetRef ref,
    String language,
    Future<void> Function(Locale) loadGeneratedTranslations,
  ) async {
    try {
      ref.read(appSettingProvider);
      final locale = Locale(language);

      // Intl 기본 로케일 설정
      Intl.defaultLocale = language;

      // 앱별 생성된 번역 로드 (AppLocalizations 사용)
      await loadGeneratedTranslations(locale);

      // 앱 설정에 언어 반영
      ref.read(appSettingProvider.notifier).setLanguage(language);

      // LocaleService에도 현재 언어 업데이트
      LocaleService.instance.updateLanguageCode(language);
      logger.i('LocaleService 초기화: $language');

      // user_profiles.language 업데이트 (로그인한 사용자인 경우에만)
      try {
        await ref.read(userInfoProvider.notifier).updateLanguage(language);
      } catch (e) {
        // 로그인하지 않은 경우나 업데이트 실패는 무시 (앱 동작에는 영향 없음)
        logger.w('user_profiles.language 업데이트 실패 (언어 변경)', error: e);
      }

      // 푸시 토큰에 새 언어 설정 업데이트 (비동기, fire-and-forget)
      // ignore: unawaited_futures
      PushTokenService.refreshTokenWithLanguage();

      return true;
    } catch (e, stackTrace) {
      logger.e('언어 변경 중 오류 발생', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
