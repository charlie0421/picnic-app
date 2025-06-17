import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:universal_platform/universal_platform.dart';
import 'dart:async';

/// 전역 언어 상태 변수 업데이트를 위한 콜백 타입
typedef UpdateLanguageCallback = void Function(
    bool isInitialized, String currentLanguage);

/// 언어 변경 및 앱 리로드 관리를 위한 유틸리티 클래스
///
/// 두 앱(picnic_app, ttja_app)에서 공통으로 사용되는 언어 변경 관련 코드를
/// 통합하고, 언어 변경 시 앱을 효과적으로 리로드하는 메커니즘을 제공합니다.
class LanguageManager {
  /// 언어 변경 및 앱 리로드 처리
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  /// [context] BuildContext - Phoenix를 통한 앱 리로드에 사용
  /// [language] 변경할 언어 코드 ('ko', 'en', 'ja' 등)
  /// [loadGeneratedTranslations] 앱별 생성된 번역 로드 함수 (S.load)
  /// [callback] 전역 언어 상태 변수 업데이트 콜백 (옵션)
  /// [shouldReload] 언어 변경 후 앱 리로드 여부 (기본값: true)
  ///
  /// 반환값은 언어 변경 성공 여부입니다.
  static Future<bool> changeAppLanguage(WidgetRef ref, BuildContext context,
      String language, Future<void> Function(Locale) loadGeneratedTranslations,
      {UpdateLanguageCallback? callback, bool shouldReload = true}) async {
    // 언어코드가 비어 있으면 한국어로 설정
    final effectiveLanguage = language.isEmpty ? 'ko' : language;

    logger.i('언어 변경 시작: $effectiveLanguage (리로드 예정: $shouldReload)');
    bool success = false;

    try {
      // LanguageInitializer를 통한 언어 변경
      success = await LanguageInitializer.changeLanguage(
        ref,
        effectiveLanguage,
        loadGeneratedTranslations,
      );

      if (!success) {
        logger.e('언어 변경 실패: $effectiveLanguage');
        return false;
      }

      // 전역 언어 상태 업데이트 콜백 호출
      if (callback != null) {
        callback(true, effectiveLanguage);
      }

      // 앱 리로드 (필요한 경우)
      if (shouldReload && success) {
        _reloadApp(context);
      }

      logger.i('언어 변경 완료: $effectiveLanguage');
      return true;
    } catch (e) {
      logger.e('언어 변경 중 오류 발생', error: e);
      return false;
    }
  }

  /// 앱 리로드 처리
  ///
  /// [context] BuildContext - Phoenix 리로드에 사용
  ///
  /// Phoenix를 사용하여 앱을 안전하게 리로드합니다.
  /// 실패 시 폴백 메커니즘을 제공합니다.
  static void _reloadApp(BuildContext context) {
    try {
      // Phoenix를 사용하여 앱 리로드 (정상적인 상태 리셋)
      if (context.mounted) {
        logger.i('Phoenix를 통한 앱 리로드 시작');

        // 컨텍스트 유효성 재확인 및 최상위 컨텍스트 사용
        final navigatorContext =
            Navigator.of(context, rootNavigator: true).context;

        // 비동기 처리로 현재 프레임 완료 후 재시작
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorContext.mounted) {
            try {
              // Phoenix.rebirth 실행 전 상태 확인
              logger.i('Phoenix.rebirth 실행 - 컨텍스트 유효성 확인됨');

              Phoenix.rebirth(navigatorContext);
              logger.i('Phoenix.rebirth 성공적으로 호출됨');

              // 성공 시에는 앱이 재시작되므로 이후 코드는 실행되지 않음
            } catch (e) {
              logger.e('Phoenix.rebirth 호출 실패: $e');
              _fallbackReload();
            }
          } else {
            logger.w('Navigator 컨텍스트가 더 이상 유효하지 않음');
            _fallbackReload();
          }
        });

        // Phoenix.rebirth 실패 감지를 위한 타이머 (더 짧은 시간으로 조정)
        Timer(const Duration(milliseconds: 1500), () {
          // 만약 이 코드가 실행되면 Phoenix.rebirth가 제대로 작동하지 않은 것일 수 있음
          logger.w('Phoenix.rebirth 후 1.5초가 지났음 - 재시작이 실패했을 가능성');
          logger.w('앱이 여전히 실행 중입니다. 사용자에게 수동 재시작을 안내할 수 있습니다.');
        });
      } else {
        logger.e('앱 리로드 요청 시 컨텍스트가 유효하지 않음');
        _fallbackReload();
      }
    } catch (e, stackTrace) {
      logger.e('앱 리로드 중 오류 발생', error: e, stackTrace: stackTrace);
      // 오류 발생 시 기본 리로드 메커니즘으로 폴백
      _fallbackReload();
    }
  }

  /// 폴백 리로드 메커니즘
  ///
  /// Phoenix 리로드 실패 시 사용되는 기본 리로드 메커니즘
  static void _fallbackReload() {
    logger.i('폴백 리로드 메커니즘 시작');

    // 모바일/웹 구분 처리
    if (UniversalPlatform.isWeb) {
      // 웹의 경우 직접적 리로드는 사용자 경험 저하 가능성이 있으므로 경고 로그만 출력
      logger.w(
          '웹에서 강제 리로드는 지원되지 않으며, 언어 변경이 일부 적용되지 않을 수 있습니다. 페이지 새로고침이 필요할 수 있습니다.');
    } else {
      // 모바일인 경우 지연 후 상태 정리 (최소한의 방어 조치)
      Future.delayed(const Duration(milliseconds: 200), () {
        logger.i('모바일 앱 상태 정리 및 재설정');
        // 상태 정리 로직은 앱 특성에 따라 구현 필요
      });
    }
  }

  /// 현재 언어 설정 가져오기
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  ///
  /// 현재 앱에 설정된 언어 코드를 반환합니다.
  static String getCurrentLanguage(WidgetRef ref) {
    final currentLanguage = ref.read(appSettingProvider).language;
    return currentLanguage.isNotEmpty ? currentLanguage : 'ko';
  }

  /// 언어 코드에 해당하는 로케일 객체 생성
  ///
  /// [languageCode] 언어 코드 ('ko', 'en', 'ja' 등)
  ///
  /// 언어 코드에 해당하는 Locale 객체를 반환합니다.
  /// 지원되지 않거나 빈 언어 코드인 경우 기본값(한국어)을 사용합니다.
  static Locale getLocaleFromLanguageCode(String? languageCode) {
    // null이거나 빈 문자열이면 기본값 사용
    if (languageCode == null || languageCode.isEmpty) {
      return const Locale('ko');
    }

    // 지원되는 언어 목록
    final supportedLanguages = getSupportedLanguages();

    // 지원되는 언어인지 확인
    if (supportedLanguages.contains(languageCode)) {
      return Locale(languageCode);
    } else {
      // 지원되지 않는 언어면 기본값 반환
      logger.w('지원되지 않는 언어 코드: $languageCode, 기본값(ko)으로 대체');
      return const Locale('ko');
    }
  }

  /// 지원되는 언어 목록 가져오기
  ///
  /// 앱에서 지원하는 언어 코드 목록을 반환합니다.
  static List<String> getSupportedLanguages() {
    // 상수로 지원 언어 목록 정의
    return ['ko', 'en', 'ja', 'zh', 'id'];
  }

  /// 언어 코드에 해당하는 표시 이름 가져오기
  ///
  /// [languageCode] 언어 코드 ('ko', 'en', 'ja' 등)
  ///
  /// 언어 코드에 해당하는 표시 이름을 반환합니다 (예: 'ko' -> '한국어').
  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'zh':
        return '中文';
      case 'id':
        return 'Bahasa Indonesia';
      default:
        return '한국어';
    }
  }
}
