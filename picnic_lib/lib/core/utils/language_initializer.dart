import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/logger.dart';
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
          final deviceLocale = ui.PlatformDispatcher.instance.locale;
          final deviceLanguage = deviceLocale.languageCode;

          // 지원되는 언어인지 확인
          if (Setting.supportedLanguages.contains(deviceLanguage) ||
              Setting.supportedLanguages.contains(
                '${deviceLanguage}_${deviceLocale.countryCode}',
              )) {
            // zh_CN, zh_TW 등 지역 코드가 있는 경우 처리
            String detectedLanguage = deviceLanguage;
            if (deviceLanguage == 'zh') {
              if (deviceLocale.countryCode == 'TW') {
                detectedLanguage = 'zh_TW'; // Flutter 앱 형식
              } else {
                detectedLanguage = 'zh_CN'; // Flutter 앱 형식
              }
            } else if (deviceLanguage == 'bn') {
              detectedLanguage = 'bn_BD'; // Flutter 앱 형식
            } else if (deviceLocale.countryCode != null &&
                Setting.supportedLanguages.contains(
                  '${deviceLanguage}_${deviceLocale.countryCode}',
                )) {
              detectedLanguage =
                  '${deviceLanguage}_${deviceLocale.countryCode}';
            }

            targetLanguage = detectedLanguage;
            logger.i(
              '디바이스 언어 감지: $detectedLanguage (device: ${deviceLocale.languageCode}_${deviceLocale.countryCode})',
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

      return true;
    } catch (e, stackTrace) {
      logger.e('언어 변경 중 오류 발생', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
