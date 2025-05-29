import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/initialization_manager.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/core/utils/lazy_loading_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/startup_performance_analyzer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// main.dart 파일에서 공통으로 사용되는 초기화 로직을 담은 유틸리티 클래스
///
/// 새로운 InitializationManager를 사용하여 더욱 체계적이고 최적화된
/// 초기화 과정을 제공합니다.
class MainInitializer {
  /// 앱 초기화를 위한 main 함수 래퍼 (리팩토링된 버전)
  ///
  /// [environment] 환경 설정 ('prod', 'dev' 등)
  /// [firebaseOptions] Firebase 초기화 옵션
  /// [appBuilder] 초기화 완료 후 앱 위젯을 생성할 함수
  /// [loadGeneratedTranslations] 앱별 생성된 번역 파일 로드 함수
  /// [reflectableInitializer] 리플렉션 초기화 함수
  /// [enableMemoryProfiler] 메모리 프로파일러 활성화 여부
  static Future<void> initializeApp({
    required String environment,
    required FirebaseOptions firebaseOptions,
    required Widget Function() appBuilder,
    required Future<bool> Function(Locale) loadGeneratedTranslations,
    required void Function() reflectableInitializer,
    bool enableMemoryProfiler = false,
  }) async {
    await runZonedGuarded(() async {
      try {
        logger.i('🚀 리팩토링된 앱 초기화 시작...');

        // InitializationManager를 사용한 체계적 초기화
        final initManager = InitializationManager();

        final appWidget = await initManager.initializeApp(
          environment: environment,
          firebaseOptions: firebaseOptions,
          appBuilder: appBuilder,
          loadGeneratedTranslations: loadGeneratedTranslations,
          reflectableInitializer: reflectableInitializer,
          enableMemoryProfiler: enableMemoryProfiler,
        );

        // 앱 실행
        runApp(appWidget);

        // 첫 번째 프레임 렌더링 완료 후 성능 분석
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          initManager.markFirstFrame();

          // 성능 분석 수행 (백그라운드에서)
          unawaited(_performPostInitializationAnalysis(initManager));
        });

        logger.i('✅ 리팩토링된 앱 초기화 완료');
      } catch (e, stackTrace) {
        logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
        rethrow;
      }
    }, (Object error, StackTrace stackTrace) async {
      logger.e('치명적 오류 발생', error: error, stackTrace: stackTrace);
      await Sentry.captureException(error, stackTrace: stackTrace);
    });
  }

  /// 초기화 완료 후 성능 분석을 수행합니다
  static Future<void> _performPostInitializationAnalysis(
      InitializationManager initManager) async {
    try {
      logger.i('🔍 리팩토링된 앱 시작 성능 분석 시작...');

      // 잠시 대기 (프로파일링 데이터가 완전히 수집될 때까지)
      await Future.delayed(const Duration(milliseconds: 500));

      // 성능 분석 수행
      final analysis =
          await StartupPerformanceAnalyzer.analyzeCurrentPerformance();

      if (analysis.isNotEmpty) {
        // 분석 결과 출력
        StartupPerformanceAnalyzer.printAnalysis(analysis);

        // 초기화 단계별 상태 로깅
        _logInitializationStatus(initManager);

        // 첫 실행인 경우 기준선으로 저장
        await _saveBaselineIfNeeded();
      }
    } catch (e) {
      logger.e('성능 분석 중 오류 발생', error: e);
    }
  }

  /// 초기화 단계별 상태를 로깅합니다
  static void _logInitializationStatus(InitializationManager initManager) {
    final status = initManager.getInitializationStatus();
    logger.i('📋 초기화 단계별 완료 상태:');

    final executionOrder = InitializationDependencies.getExecutionOrder();
    for (final stage in executionOrder) {
      final isCompleted = status[stage] == true;
      final emoji = isCompleted ? '✅' : '❌';
      logger.i('  $emoji $stage');
    }
  }

  /// 필요한 경우 현재 성능을 기준선으로 저장합니다
  static Future<void> _saveBaselineIfNeeded() async {
    try {
      final baselineFile = File('startup_baseline.json');
      if (!await baselineFile.exists()) {
        await StartupPerformanceAnalyzer.saveAsBaseline();
        logger.i('📊 첫 실행으로 현재 성능을 기준선으로 저장했습니다');
      }
    } catch (e) {
      logger.e('기준선 저장 중 오류 발생', error: e);
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
    Future<bool> Function(Locale) loadGeneratedTranslations,
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

      // 콜백 함수 호출
      callback(success, language);

      logger.i('언어 초기화 ${success ? '성공' : '실패'}: $language');
    } catch (e, stackTrace) {
      logger.e('언어 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      callback(false, 'ko');
    }
  }

  /// 특정 초기화 단계가 완료되었는지 확인하는 유틸리티 메서드
  static bool isInitializationStageCompleted(String stageName) {
    final initManager = InitializationManager();
    return initManager.isStageCompleted(stageName);
  }

  /// 특정 초기화 단계의 완료를 기다리는 유틸리티 메서드
  static Future<void> waitForInitializationStage(String stageName) async {
    final initManager = InitializationManager();
    await initManager.waitForStage(stageName);
  }

  /// 여러 초기화 단계의 완료를 기다리는 유틸리티 메서드
  static Future<void> waitForInitializationStages(
      List<String> stageNames) async {
    final initManager = InitializationManager();
    await initManager.waitForStages(stageNames);
  }

  /// 특정 지연 로딩 서비스가 필요할 때 호출하는 유틸리티 메서드
  ///
  /// [serviceName] 로드할 서비스 이름
  /// 사용 가능한 서비스: 'image_services', 'network_services',
  /// 'memory_profiling_services', 'mobile_services', 'miscellaneous_services'
  static Future<void> ensureServiceLoaded(String serviceName) async {
    // 먼저 지연 로딩 단계가 완료되었는지 확인
    await waitForInitializationStage(InitializationManager.stageLazyLoading);

    final lazyManager = LazyLoadingManager();

    if (!lazyManager.isServiceLoaded(serviceName)) {
      logger.i('서비스 로딩 대기 중: $serviceName');
      await lazyManager.waitForService(serviceName);
      logger.i('서비스 로딩 완료: $serviceName');
    }
  }

  /// 모든 지연 로딩 서비스가 완료될 때까지 대기하는 유틸리티 메서드
  ///
  /// 주로 테스트나 특별한 상황에서 사용
  static Future<void> waitForAllLazyServices() async {
    await waitForInitializationStage(InitializationManager.stageLazyLoading);

    final lazyManager = LazyLoadingManager();
    logger.i('모든 지연 로딩 서비스 완료 대기 중...');
    await lazyManager.waitForAllServices();
    logger.i('모든 지연 로딩 서비스 완료');
  }

  /// 지연 로딩 서비스 상태를 확인하는 유틸리티 메서드
  static Map<String, bool> getLazyServiceStatus() {
    final lazyManager = LazyLoadingManager();
    return lazyManager.getServiceStatus();
  }

  /// 전체 초기화 상태를 확인하는 유틸리티 메서드
  static Map<String, dynamic> getFullInitializationStatus() {
    final initManager = InitializationManager();
    final lazyManager = LazyLoadingManager();

    return {
      'initialization_stages': initManager.getInitializationStatus(),
      'lazy_services': lazyManager.getServiceStatus(),
      'execution_order': InitializationDependencies.getExecutionOrder(),
    };
  }
}
