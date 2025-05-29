import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/services/asset_loading_service.dart';
import 'package:picnic_lib/core/services/splash_screen_service.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/lazy_loading_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/startup_profiler.dart';
import 'package:picnic_lib/supabase_options.dart';

/// 앱 초기화 과정을 체계적으로 관리하는 클래스
///
/// 초기화 단계를 우선순위별로 분류하고 최적화된 순서로 실행하여
/// 앱 시작 시간을 최소화합니다.
class InitializationManager {
  static final InitializationManager _instance =
      InitializationManager._internal();
  factory InitializationManager() => _instance;
  InitializationManager._internal();

  final Map<String, bool> _completedStages = {};
  final Map<String, Completer<void>> _stageCompleters = {};
  final StartupProfiler _profiler = StartupProfiler();

  // 스플래시 스크린 서비스
  final SplashScreenService _splashService = SplashScreenService();

  /// 초기화 단계 정의
  static const String stageFlutterBindings = 'flutter_bindings';
  static const String stageScreenUtil = 'screen_util';
  static const String stageCriticalServices = 'critical_services';
  static const String stageAssetLoading = 'asset_loading';
  static const String stageDataServices = 'data_services';
  static const String stageAuthServices = 'auth_services';
  static const String stageReflection = 'reflection';
  static const String stageLazyLoading = 'lazy_loading';
  static const String stageAppWidget = 'app_widget';

  /// 앱 초기화를 실행합니다
  Future<Widget> initializeApp({
    required String environment,
    required FirebaseOptions firebaseOptions,
    required Widget Function() appBuilder,
    required Future<bool> Function(Locale) loadGeneratedTranslations,
    required void Function() reflectableInitializer,
    bool enableMemoryProfiler = false,
    SplashScreenConfig? splashConfig,
  }) async {
    _profiler.startProfiling();
    logger.i('🚀 체계적 앱 초기화 시작...');

    // 스플래시 스크린 서비스 초기화
    if (splashConfig != null) {
      _splashService.initialize(
        config: splashConfig,
        isStageCompletedFn: isStageCompleted,
      );
    }

    try {
      // 1단계: Flutter 바인딩 (필수, 즉시)
      await _executeStage(stageFlutterBindings, () async {
        WidgetsFlutterBinding.ensureInitialized();
      });

      // 2단계: ScreenUtil (UI 관련 작업에 필요)
      await _executeStage(stageScreenUtil, () async {
        await _initializeScreenUtil();
      });

      // 3단계: 중요 서비스 (환경, Sentry 등)
      await _executeStage(stageCriticalServices, () async {
        await AppInitializer.initializeBasics();
        await AppInitializer.initializeEnvironment(environment);
        await AppInitializer.initializeSentry();
      });

      // 4단계: 에셋 로딩 (중요한 에셋만 즉시 로드)
      await _executeStage(stageAssetLoading, () async {
        final assetService = AssetLoadingService();
        await assetService.initialize();

        // 유휴 시간에 추가 에셋 프리로드 예약
        assetService.preloadOnIdle();
      });

      // 5단계: 데이터 서비스 (Supabase, Firebase)
      await _executeStage(stageDataServices, () async {
        // Supabase와 Firebase를 병렬로 초기화
        await Future.wait([
          initializeSupabase(),
          Firebase.initializeApp(options: firebaseOptions),
        ]);
      });

      // 6단계: 인증 서비스
      await _executeStage(stageAuthServices, () async {
        await AppInitializer.initializeAuth();
      });

      // 7단계: 리플렉션 (동기 작업)
      await _executeStage(stageReflection, () async {
        reflectableInitializer();
      });

      // 8단계: 지연 로딩 설정
      await _executeStage(stageLazyLoading, () async {
        final lazyManager = LazyLoadingManager();
        lazyManager.initialize();

        // 백그라운드에서 비필수 서비스 시작
        unawaited(lazyManager.startBackgroundInitialization(
          enableMemoryProfiler: enableMemoryProfiler,
        ));
      });

      // 9단계: 앱 위젯 생성
      late Widget appWidget;
      await _executeStage(stageAppWidget, () async {
        appWidget = ProviderScope(child: appBuilder());
      });

      logger.i('✅ 체계적 앱 초기화 완료');

      // 스플래시 완료 대기 (필요시)
      if (splashConfig != null) {
        await _splashService.waitForCompletion();
      }

      return appWidget;
    } catch (e, stackTrace) {
      _profiler.endPhase('initialization_error', additionalMetrics: {
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 특정 초기화 단계를 실행합니다
  Future<void> _executeStage(
      String stageName, Future<void> Function() stageFunction) async {
    if (_completedStages[stageName] == true) {
      logger.d('단계 이미 완료됨: $stageName');
      return;
    }

    // 이미 진행 중인 단계라면 완료를 기다림
    if (_stageCompleters.containsKey(stageName)) {
      await _stageCompleters[stageName]!.future;
      return;
    }

    final completer = Completer<void>();
    _stageCompleters[stageName] = completer;

    try {
      _profiler.startPhase(stageName);
      logger.d('단계 시작: $stageName');

      await stageFunction();

      _profiler.endPhase(stageName);
      _completedStages[stageName] = true;
      completer.complete();

      logger.d('단계 완료: $stageName');
    } catch (e) {
      _profiler.endPhase('${stageName}_error', additionalMetrics: {
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });
      completer.completeError(e);
      logger.e('단계 실패: $stageName', error: e);
      rethrow;
    }
  }

  /// ScreenUtil을 초기화합니다
  Future<void> _initializeScreenUtil() async {
    try {
      const designSize = Size(393, 852);

      final window = WidgetsBinding.instance.window;
      final physicalSize = window.physicalSize;
      final devicePixelRatio = window.devicePixelRatio;
      final logicalSize = Size(
        physicalSize.width / devicePixelRatio,
        physicalSize.height / devicePixelRatio,
      );

      ScreenUtil.configure(
        designSize: designSize,
        minTextAdapt: true,
        splitScreenMode: true,
      );

      logger.d('ScreenUtil 초기화 완료: 화면=$logicalSize, 디자인=$designSize');
    } catch (e) {
      logger.e('ScreenUtil 초기화 실패', error: e);
      // 실패해도 앱 실행은 계속
    }
  }

  /// 특정 단계가 완료되었는지 확인합니다
  bool isStageCompleted(String stageName) {
    return _completedStages[stageName] == true;
  }

  /// 특정 단계의 완료를 기다립니다
  Future<void> waitForStage(String stageName) async {
    if (_completedStages[stageName] == true) {
      return;
    }

    final completer = _stageCompleters[stageName];
    if (completer != null) {
      await completer.future;
    }
  }

  /// 여러 단계의 완료를 기다립니다
  Future<void> waitForStages(List<String> stageNames) async {
    await Future.wait(stageNames.map((stage) => waitForStage(stage)));
  }

  /// 초기화 상태를 리셋합니다 (주로 테스트용)
  void reset() {
    _completedStages.clear();
    _stageCompleters.clear();
    _profiler.reset();
    _splashService.dispose();
  }

  /// 현재 초기화 상태를 반환합니다
  Map<String, bool> getInitializationStatus() {
    return Map.from(_completedStages);
  }

  /// 프로파일러를 반환합니다
  StartupProfiler get profiler => _profiler;

  /// 스플래시 서비스를 반환합니다
  SplashScreenService get splashService => _splashService;

  /// 첫 번째 프레임 렌더링을 기록합니다
  void markFirstFrame() {
    _profiler.markFirstFrame();
    _profiler.finishProfiling();
  }
}

/// 초기화 단계별 의존성을 정의하는 클래스
class InitializationDependencies {
  static const Map<String, List<String>> dependencies = {
    InitializationManager.stageScreenUtil: [
      InitializationManager.stageFlutterBindings
    ],
    InitializationManager.stageCriticalServices: [
      InitializationManager.stageFlutterBindings
    ],
    InitializationManager.stageAssetLoading: [
      InitializationManager.stageScreenUtil,
      InitializationManager.stageCriticalServices,
    ],
    InitializationManager.stageDataServices: [
      InitializationManager.stageCriticalServices
    ],
    InitializationManager.stageAuthServices: [
      InitializationManager.stageDataServices
    ],
    InitializationManager.stageReflection: [
      InitializationManager.stageCriticalServices
    ],
    InitializationManager.stageLazyLoading: [
      InitializationManager.stageDataServices,
      InitializationManager.stageAuthServices,
      InitializationManager.stageAssetLoading,
    ],
    InitializationManager.stageAppWidget: [
      InitializationManager.stageScreenUtil,
      InitializationManager.stageReflection,
      InitializationManager.stageLazyLoading,
    ],
  };

  /// 특정 단계의 의존성을 확인합니다
  static List<String> getDependencies(String stageName) {
    return dependencies[stageName] ?? [];
  }

  /// 의존성 순서대로 단계를 정렬합니다
  static List<String> getExecutionOrder() {
    return [
      InitializationManager.stageFlutterBindings,
      InitializationManager.stageScreenUtil,
      InitializationManager.stageCriticalServices,
      InitializationManager.stageAssetLoading,
      InitializationManager.stageDataServices,
      InitializationManager.stageAuthServices,
      InitializationManager.stageReflection,
      InitializationManager.stageLazyLoading,
      InitializationManager.stageAppWidget,
    ];
  }
}
