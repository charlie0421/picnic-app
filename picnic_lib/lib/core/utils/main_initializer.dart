import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';
import 'package:picnic_lib/core/utils/firebase_analytics_utils.dart';

import 'package:picnic_lib/core/utils/supabase_health_check.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/services/consent_service.dart';

/// main.dart 파일에서 공통으로 사용되는 초기화 로직을 담은 유틸리티 클래스
///
/// 두 앱(picnic_app, ttja_app)의 main.dart 파일에서 중복되는 초기화 로직을
/// 추출하여 재사용성을 높이고 코드 중복을 줄입니다.
class MainInitializer {
  static final Completer<void> _sdkInitCompleter = Completer<void>();

  /// SDK 초기화 완료를 대기하는 Future
  /// App 위젯에서 await MainInitializer.sdkReady 로 사용
  static Future<void> get sdkReady => _sdkInitCompleter.future;

  /// 앱 초기화를 위한 main 함수 래퍼
  ///
  /// ANR 방지를 위해 runApp()을 최대한 빠르게 호출하고,
  /// SDK 초기화는 UI 표시 후 병렬로 진행합니다.
  static Future<void> initializeApp({
    required String environment,
    FirebaseOptions? firebaseOptions,
    required Widget Function() appBuilder,
  }) async {
    await runZonedGuarded(
      () async {
        try {
          logger.i('앱 초기화 시작...');

          // === Phase 1: runApp 전 최소 초기화 (ANR 방지) ===
          await AppInitializer.initializeBasics();
          await AppInitializer.initializeEnvironment(environment);
          await AppInitializer.initializeSentry();

          // 즉시 UI 표시 - SplashImage 위젯이 렌더링됨
          logger.i('앱 시작 중...');
          final appWidget = ProviderScope(
            observers: [LoggingObserver()],
            child: appBuilder(),
          );
          runApp(appWidget);
          logger.i('앱 UI 시작 완료 - SDK 초기화 계속 진행');

          // === Phase 2: runApp 후 SDK 병렬 초기화 ===
          await _initializeSDKs(firebaseOptions);
        } catch (e, s) {
          logger.e('초기화 중 오류 발생', error: e, stackTrace: s);
          if (!_sdkInitCompleter.isCompleted) {
            _sdkInitCompleter.complete();
          }
          rethrow;
        }
      },
      (Object error, StackTrace s) async {
        logger.e('치명적 오류 발생', error: error, stackTrace: s);
        await Sentry.captureException(error, stackTrace: s);
      },
    );
  }

  /// runApp() 이후 SDK 초기화를 병렬로 실행
  ///
  /// Group 1: 독립적인 SDK (Supabase, Firebase, WebP, Timezone, Privacy)
  /// Group 2: Group 1에 의존하는 SDK (Auth, Tapjoy, Branch, AdMob)
  static Future<void> _initializeSDKs(FirebaseOptions? firebaseOptions) async {
    try {
      // Group 1: 독립적인 SDK 병렬 초기화
      final group1 = <Future>[];
      group1.add(initializeSupabase());
      if (firebaseOptions != null) {
        group1.add(Firebase.initializeApp(options: firebaseOptions));
      }
      if (UniversalPlatform.isMobile) {
        group1.add(AppInitializer.initializeTimezone());
        group1.add(AppInitializer.initializePrivacyConsent());
      }
      await Future.wait(group1);
      logger.i('SDK Group 1 초기화 완료 (Supabase, Firebase, Timezone, Privacy)');

      // Supabase 헬스체크 (개발 환경에서만)
      if (kDebugMode) {
        await SupabaseHealthCheck.runHealthCheckOnAppStart();
      }

      // Group 2: Supabase/Firebase에 의존하는 SDK 병렬 초기화
      // Auth는 다른 SDK와 분리하여, Tapjoy/Branch/AdMob 실패가 인증 복구에 영향주지 않도록 함
      final authFuture = AppInitializer.initializeAuth();

      Future<void> otherSdksFuture = Future.value();
      if (UniversalPlatform.isMobile) {
        otherSdksFuture = Future.wait([
          AppInitializer.initializeTapjoy(),
          FlutterBranchSdk.init(
            enableLogging: true,
            branchAttributionLevel: BranchAttributionLevel.NONE,
          ),
          _initializeAdMob(),
        ]).then((_) {}).catchError((e, s) {
          // 광고/딥링크 SDK 실패는 앱 사용에 치명적이지 않으므로 로깅만
          logger.e('SDK Group 2 (non-auth) 초기화 실패', error: e, stackTrace: s);
        });
      }

      await Future.wait([authFuture, otherSdksFuture]);
      logger.i('SDK Group 2 초기화 완료 (Auth, Tapjoy, Branch, AdMob)');

      // Analytics 사용자 속성 설정 (Auth 완료 후)
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          await AppAnalytics.setUserAndSessionProperties(
            userId: user.id,
            locale: Intl.getCurrentLocale(),
          );
        }
      } catch (_) {}

      // Shorebird 패치 체크는 SplashImage 위젯에서 처리됨

      logger.i('모든 SDK 초기화 완료');
    } catch (e, s) {
      logger.e('SDK 초기화 중 오류 발생', error: e, stackTrace: s);
    } finally {
      if (!_sdkInitCompleter.isCompleted) {
        _sdkInitCompleter.complete();
      }
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

  /// AdMob 및 미디에이션 초기화
  static Future<void> _initializeAdMob() async {
    try {
      logger.i('AdMob 초기화 시작');

      // UMP 동의 확인 (MobileAds 초기화 전에)
      await ConsentService().initialize();
      logger.i('UMP 동의 확인 완료');

      // AdMob SDK 초기화
      final initStatus = await MobileAds.instance.initialize();

      // 미디에이션 어댑터 상태 로깅
      initStatus.adapterStatuses.forEach((adapter, status) {
        logger.i(
          '[AdMob] Adapter: $adapter, '
          'State: ${status.state}, '
          'Description: ${status.description}',
        );
      });

      logger.i('AdMob 초기화 완료 (어댑터 ${initStatus.adapterStatuses.length}개)');
    } catch (e, s) {
      logger.e('AdMob 초기화 실패', error: e, stackTrace: s);
    }
  }
}
