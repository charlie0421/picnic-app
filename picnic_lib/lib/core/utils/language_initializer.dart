import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// 언어 초기화 및 관리를 위한 유틸리티 클래스
///
/// 언어 초기화 관련 로직을 포함하고 있으며, 두 앱(picnic_app, ttja_app)에서
/// 공통으로 사용되는 국제화(i18n) 처리를 통합합니다.
///
/// 주요 기능:
/// - 앱 시작 시 언어 초기화 (initializeLanguage)
/// - 사용자 요청 시 언어 변경 처리 (changeLanguage)
/// - 언어 로케일 관리 및 번역 리소스 로드
/// - 오류 발생 시 자동 복구 메커니즘
///
/// 기본 언어는 한국어('ko')로 설정되어 있으며,
/// 지원되지 않는 언어 요청 시 자동으로 한국어로 대체됩니다.
class LanguageInitializer {
  /// 앱의 언어를 초기화합니다.
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  /// [context] BuildContext - 화면 컨텍스트
  /// [loadGeneratedTranslations] 앱별 생성된 번역 로드 함수 (S.load)
  ///
  /// 반환값은 언어 초기화 성공 여부와 최종 설정된 언어입니다.
  ///
  /// 초기화 과정:
  /// 1. 저장된 언어 설정 로드 (기본값: 'ko')
  /// 2. Intl 기본 로케일 설정
  /// 3. 앱 설정에 언어 반영
  /// 4. 번역 데이터 로드 (로컬 번역, 앱 내부 생성 번역, PicnicLibL10n)
  /// 5. 오류 발생 시 한국어로 복구 시도
  static Future<(bool, String)> initializeLanguage(
      WidgetRef ref,
      BuildContext context,
      Future<void> Function(Locale) loadGeneratedTranslations,
      {String defaultLanguage = 'ko'}) async {
    logger.i('언어 초기화 시작');

    String language = defaultLanguage;

    try {
      // 앱 설정에서 저장된 언어 가져오기 시도
      final appSetting = ref.read(appSettingProvider);
      if (appSetting.language.isNotEmpty) {
        language = appSetting.language;
        logger.i('설정에서 로드한 언어: $language');
      } else {
        logger.i('설정된 언어 없음, 기본값 사용: $language');
      }

      // 언어 변경
      final success = await changeLanguage(
        ref,
        language,
        loadGeneratedTranslations,
      );

      if (success) {
        logger.i('언어 초기화 성공: $language');
      } else {
        logger.e('언어 초기화 실패, 기본값으로 재시도: $defaultLanguage');

        // 기본값으로 다시 시도
        if (language != defaultLanguage) {
          return await initializeLanguage(
            ref,
            context,
            loadGeneratedTranslations,
            defaultLanguage: defaultLanguage,
          );
        }
      }

      return (success, language);
    } catch (e, stackTrace) {
      logger.e('언어 초기화 중 오류 발생, 기본값 사용', error: e, stackTrace: stackTrace);

      try {
        // 오류 발생 시 언어를 'ko'로 설정하여 안전하게 시작
        await changeLanguage(ref, defaultLanguage, loadGeneratedTranslations);
        return (true, defaultLanguage);
      } catch (fallbackError) {
        logger.e('기본 언어 설정 중 심각한 오류 발생', error: fallbackError);
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
  ///
  /// 언어 변경 과정:
  /// 1. 앱 설정에 새 언어 저장
  /// 2. Intl 기본 로케일 설정
  /// 3. 로컬 및 앱 내부 번역 데이터 로드
  /// 4. PicnicLibL10n 언어 설정 업데이트
  static Future<bool> changeLanguage(
    WidgetRef ref,
    String language,
    Future<void> Function(Locale) loadGeneratedTranslations,
  ) async {
    logger.i('언어 변경 시작: $language');

    try {
      // 앱 설정 객체 가져오기
      final appSetting = ref.read(appSettingProvider);

      // 0. PicnicLibL10n 초기화 (최우선)
      try {
        // 앱 설정을 전달하여 초기화
        await PicnicLibL10n.initialize(appSetting);
        logger.i('PicnicLibL10n 초기화 완료');
      } catch (e) {
        logger.e('PicnicLibL10n 초기화 중 오류', error: e);
        // 오류가 발생해도 계속 진행 (기본 모드로 작동)
      }

      // 기본 로케일 설정
      Intl.defaultLocale = language;

      // 1. PicnicLib 기본 로케일 설정
      try {
        PicnicLibL10n.setCurrentLocale(language);
        logger.i('PicnicLibL10n 로케일 설정 완료: $language');
      } catch (e) {
        logger.e('PicnicLibL10n 로케일 설정 실패', error: e);
        // 실패해도 계속 진행
      }

      // 2. PicnicLibL10n를 통한 공통 번역 로드
      try {
        await PicnicLibL10n.loadTranslations(Locale(language));
        logger.i('PicnicLibL10n 번역 로드 완료: $language');
      } catch (e) {
        logger.e('PicnicLibL10n 번역 로드 실패', error: e);
        // 실패해도 계속 진행
      }

      // 3. 앱별 생성된 번역 로드
      try {
        await loadGeneratedTranslations(Locale(language));
        logger.i('앱별 생성된 번역 로드 완료: $language');
      } catch (e) {
        logger.e('앱별 생성된 번역 로드 실패', error: e);
        // 실패해도 계속 진행
      }

      // 앱 설정에 변경된 언어 반영
      ref.read(appSettingProvider.notifier).setLanguage(language);

      logger.i('언어 변경 완료: $language');
      return true;
    } catch (e, stackTrace) {
      logger.e('언어 변경 중 오류 발생', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
