import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

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
      final targetLanguage = appSetting.language.isNotEmpty
          ? appSetting.language
          : defaultLanguage;

      // 언어 변경 시도
      final success =
          await changeLanguage(ref, targetLanguage, loadGeneratedTranslations);
      if (success) {
        return (true, targetLanguage);
      }

      // 실패 시 기본 언어로 재시도 (다른 언어인 경우에만)
      if (targetLanguage != defaultLanguage) {
        final fallbackSuccess = await changeLanguage(
            ref, defaultLanguage, loadGeneratedTranslations);
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
      final appSetting = ref.read(appSettingProvider);
      final locale = Locale(language);

      // Intl 기본 로케일 설정
      Intl.defaultLocale = language;

      // 앱별 생성된 번역 로드 (AppLocalizations 사용)
      await loadGeneratedTranslations(locale);

      // 앱 설정에 언어 반영
      ref.read(appSettingProvider.notifier).setLanguage(language);

      return true;
    } catch (e, stackTrace) {
      logger.e('언어 변경 중 오류 발생', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
