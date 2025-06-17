import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';

import 'package:picnic_lib/core/utils/supabase_health_check.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// main.dart 파일에서 공통으로 사용되는 초기화 로직을 담은 유틸리티 클래스
///
/// 두 앱(picnic_app, ttja_app)의 main.dart 파일에서 중복되는 초기화 로직을
/// 추출하여 재사용성을 높이고 코드 중복을 줄입니다.
class MainInitializer {
  /// 앱 초기화를 위한 main 함수 래퍼
  ///
  /// [environment] 환경 설정 ('prod', 'dev' 등)
  /// [firebaseOptions] Firebase 초기화 옵션
  /// [appBuilder] 초기화 완료 후 앱 위젯을 생성할 함수
  /// [loadGeneratedTranslations] 앱별 생성된 번역 파일 로드 함수
  /// [reflectableInitializer] 리플렉션 초기화 함수
  static Future<void> initializeApp({
    required String environment,
    required FirebaseOptions firebaseOptions,
    required Widget Function() appBuilder,
    required Future<void> Function(Locale) loadGeneratedTranslations,
    required Function() reflectableInitializer,
  }) async {
    await runZonedGuarded(() async {
      try {
        logger.i('앱 초기화 시작...');

        // Flutter 바인딩 초기화
        WidgetsFlutterBinding.ensureInitialized();

        // ScreenUtil 초기화 - 먼저 처리하여 다른 초기화 과정에서 사용 가능하도록 함
        await _initializeScreenUtil();

        // 기본 서비스 초기화
        await AppInitializer.initializeBasics();
        await AppInitializer.initializeEnvironment(environment);
        await AppInitializer.initializeSentry();

        // Supabase 초기화
        await initializeSupabase();

        // Supabase 헬스체크 실행 (개발 환경에서만)
        if (kDebugMode) {
          await SupabaseHealthCheck.runHealthCheckOnAppStart();
        }

        // 모바일 전용 초기화 로직
        if (UniversalPlatform.isMobile) {
          await AppInitializer.initializeWebP();
          await AppInitializer.initializeTapjoy();
        }

        // Firebase 초기화
        await Firebase.initializeApp(
          options: firebaseOptions,
        );

        // 인증 서비스 초기화
        await AppInitializer.initializeAuth();

        // 타임존 초기화 (모바일 전용)
        if (UniversalPlatform.isMobile) {
          await AppInitializer.initializeTimezone();
        }

        // 리플렉션 초기화
        reflectableInitializer();

        // 프라이버시 동의 초기화 (모바일 전용)
        if (UniversalPlatform.isMobile) {
          await AppInitializer.initializePrivacyConsent();
        }

        // Branch SDK 초기화 (모바일 전용)
        if (UniversalPlatform.isMobile) {
          await FlutterBranchSdk.init(
            enableLogging: true,
            branchAttributionLevel: BranchAttributionLevel.NONE,
          );
        }

        logger.i('앱 시작 중...');
        // 앱 위젯 생성 후 ProviderScope으로 래핑
        final appWidget = ProviderScope(
          observers: [LoggingObserver()],
          child: appBuilder(),
        );

        // Flutter의 runApp 호출 - 기본 Flutter 함수 사용
        runApp(appWidget);

        logger.i('앱 시작 완료');
      } catch (e, s) {
        logger.e('초기화 중 오류 발생', error: e, stackTrace: s);
        rethrow;
      }
    }, (Object error, StackTrace s) async {
      logger.e('치명적 오류 발생', error: error, stackTrace: s);
      await Sentry.captureException(error, stackTrace: s);
    });
  }

  /// ScreenUtil을 초기화하는 메서드
  /// 앱이 실행되기 전에 먼저 ScreenUtil 설정값을 초기화합니다.
  static Future<void> _initializeScreenUtil() async {
    try {
      logger.i('ScreenUtil 초기화 시작');

      // 디자인 사이즈 설정 (앱 빌더에서 사용하는 것과 동일한 값 사용)
      const designSize = Size(393, 852);

      // 화면 크기를 미리 계산하여 로깅 목적으로 사용
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final physicalSize = view.physicalSize;
      final devicePixelRatio = view.devicePixelRatio;
      final logicalSize = Size(
        physicalSize.width / devicePixelRatio,
        physicalSize.height / devicePixelRatio,
      );

      // 전역 ScreenUtil 설정 초기화 (메인 위젯이 없는 환경에서 사용 가능)
      ScreenUtil.configure(
        designSize: designSize,
        minTextAdapt: true,
        splitScreenMode: true,
      );

      logger.i('ScreenUtil 초기화 완료: 화면 크기 = $logicalSize, 디자인 크기 = $designSize');
    } catch (e, s) {
      // 초기화 실패 시에도 앱이 계속 실행되도록 예외 처리
      logger.e('ScreenUtil 초기화 실패 (앱은 계속 실행됨)', error: e, stackTrace: s);
    }
  }

  /// 언어 초기화를 비동기로 실행하는 유틸리티 메서드
  ///
  /// [ref] Riverpod WidgetRef
  /// [context] BuildContext
  /// [loadGeneratedTranslations] 앱별 생성된 번역 파일 로드 함수
  /// [callback] 초기화 완료 후 실행할 콜백 함수
  static Future<void> initializeLanguageAsync(
    WidgetRef ref,
    BuildContext context,
    Future<void> Function(Locale) loadGeneratedTranslations,
    Function(bool, String) callback,
  ) async {
    try {
      logger.i('언어 초기화 시작');

      // 앱 설정에서 현재 언어 가져오기 (또는 기본값으로 'ko' 사용)
      String language = 'ko';
      try {
        final appSetting = ref.read(appSettingProvider);
        if (appSetting.language.isNotEmpty) {
          language = appSetting.language;
        }
        logger.i('설정에서 언어 로드: $language');
      } catch (e) {
        logger.e('앱 설정에서 언어 로드 실패, 기본값 사용', error: e);
      }

      // 언어 초기화 실행
      final success = await LanguageInitializer.changeLanguage(
        ref,
        language,
        loadGeneratedTranslations,
      );

      // 콜백 함수 호출 (non-nullable이므로 null 체크 불필요)
      callback(success, language);

      logger.i('언어 초기화 ${success ? '성공' : '실패'}: $language');
    } catch (e, stackTrace) {
      logger.e('언어 초기화 중 오류 발생', error: e, stackTrace: stackTrace);

      // 오류 발생 시에도 콜백 호출
      callback(false, 'ko');
    }
  }
}
