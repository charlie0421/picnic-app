import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:picnic_lib/core/services/cache_management_service.dart';
import 'package:picnic_lib/core/services/image_cache_service.dart';
import 'package:picnic_lib/core/services/image_memory_profiler.dart';
import 'package:picnic_lib/core/services/network_connection_manager.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/data_lazy_loader.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/startup_profiler.dart';
import 'package:picnic_lib/core/utils/widget_lazy_loader.dart';
import 'package:universal_platform/universal_platform.dart';

/// 지연 로딩을 관리하는 클래스
///
/// 앱 시작 시 필수가 아닌 서비스들의 초기화를 지연시켜
/// 앱 시작 시간을 단축시킵니다.
///
/// 새로운 기능:
/// - 위젯 지연 로딩 관리
/// - 데이터 지연 로딩 관리
/// - 통합된 지연 로딩 상태 추적
class LazyLoadingManager {
  static final LazyLoadingManager _instance = LazyLoadingManager._internal();
  factory LazyLoadingManager() => _instance;
  LazyLoadingManager._internal();

  final Map<String, bool> _loadedServices = {};
  final Map<String, Completer<void>> _loadingCompleters = {};
  bool _isInitialized = false;

  // 새로운 지연 로딩 시스템 통합
  final WidgetLazyLoader _widgetLoader = WidgetLazyLoader();
  final DataLazyLoader _dataLoader = DataLazyLoader();

  /// 지연 로딩 매니저를 초기화합니다
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    logger.i('🔄 LazyLoadingManager 초기화됨 (위젯 & 데이터 지연 로딩 포함)');
  }

  /// 앱 시작 후 백그라운드에서 비필수 서비스들을 초기화합니다
  Future<void> startBackgroundInitialization({
    bool enableMemoryProfiler = false,
  }) async {
    if (!_isInitialized) {
      logger.w('LazyLoadingManager가 초기화되지 않았습니다');
      return;
    }

    logger.i('🚀 백그라운드 서비스 초기화 시작 (통합 지연 로딩)');
    final profiler = StartupProfiler();

    // 우선순위 0: 위젯과 데이터 지연 로딩 시스템 활성화
    _activateLazyLoadingSystems();

    // 우선순위 1: 이미지 관련 서비스 (사용자가 빠르게 접할 수 있음)
    unawaited(_loadImageServices());

    // 우선순위 2: 네트워크 관련 서비스
    unawaited(_loadNetworkServices());

    // 우선순위 3: 메모리 프로파일링 (디버그 모드에서만)
    if (enableMemoryProfiler || kDebugMode) {
      unawaited(_loadMemoryProfilingServices());
    }

    // 우선순위 4: 모바일 전용 서비스들
    if (UniversalPlatform.isMobile) {
      unawaited(_loadMobileServices());
    }

    // 우선순위 5: 기타 서비스들
    unawaited(_loadMiscellaneousServices());

    logger.i('✅ 백그라운드 서비스 초기화 스케줄링 완료 (통합 지연 로딩)');
  }

  /// 위젯과 데이터 지연 로딩 시스템을 활성화합니다
  void _activateLazyLoadingSystems() {
    logger.i('🎯 위젯 & 데이터 지연 로딩 시스템 활성화');

    // 유휴 시간에 위젯 미리 로드 시작
    _widgetLoader.preloadOnIdle();

    // 유휴 시간에 데이터 미리 로드 시작
    _dataLoader.preloadOnIdle();

    logger.i('✅ 위젯 & 데이터 지연 로딩 시스템 활성화 완료');
  }

  /// 이미지 관련 서비스들을 로드합니다
  Future<void> _loadImageServices() async {
    const serviceName = 'image_services';
    if (_loadedServices[serviceName] == true) return;

    final completer = _getOrCreateCompleter(serviceName);
    if (completer.isCompleted) return;

    try {
      logger.i('🖼️ 이미지 서비스 초기화 시작');

      // 네트워크 연결 관리자 초기화
      await NetworkConnectionManager().initialize();
      logger.i('네트워크 연결 관리자 초기화 완료');

      // 이미지 캐시 서비스 초기화
      ImageCacheService().initialize();
      logger.i('이미지 캐시 서비스 초기화 완료');

      // Flutter 기본 이미지 캐시 최적화
      _optimizeFlutterImageCache();

      _loadedServices[serviceName] = true;
      completer.complete();
      logger.i('✅ 이미지 서비스 초기화 완료');
    } catch (e) {
      logger.e('이미지 서비스 초기화 실패', error: e);
      completer.completeError(e);
    }
  }

  /// 네트워크 관련 서비스들을 로드합니다
  Future<void> _loadNetworkServices() async {
    const serviceName = 'network_services';
    if (_loadedServices[serviceName] == true) return;

    final completer = _getOrCreateCompleter(serviceName);
    if (completer.isCompleted) return;

    try {
      logger.i('🌐 네트워크 서비스 초기화 시작');

      // 이미 이미지 서비스에서 NetworkConnectionManager가 초기화되었을 수 있음
      if (!_loadedServices.containsKey('image_services')) {
        await NetworkConnectionManager().initialize();
      }

      _loadedServices[serviceName] = true;
      completer.complete();
      logger.i('✅ 네트워크 서비스 초기화 완료');
    } catch (e) {
      logger.e('네트워크 서비스 초기화 실패', error: e);
      completer.completeError(e);
    }
  }

  /// 메모리 프로파일링 서비스들을 로드합니다
  Future<void> _loadMemoryProfilingServices() async {
    const serviceName = 'memory_profiling_services';
    if (_loadedServices[serviceName] == true) return;

    final completer = _getOrCreateCompleter(serviceName);
    if (completer.isCompleted) return;

    try {
      logger.i('🧠 메모리 프로파일링 서비스 초기화 시작');

      // 메모리 프로파일러 초기화
      MemoryProfiler.instance.initialize(enabled: true);
      logger.i('메모리 프로파일러 초기화 완료');

      // 이미지 메모리 프로파일러 초기화
      ImageMemoryProfiler().initialize();
      logger.i('이미지 메모리 프로파일러 초기화 완료');

      // 캐시 관리 서비스 초기화
      await CacheManagementService().initialize();
      logger.i('캐시 관리 서비스 초기화 완료');

      _loadedServices[serviceName] = true;
      completer.complete();
      logger.i('✅ 메모리 프로파일링 서비스 초기화 완료');
    } catch (e) {
      logger.e('메모리 프로파일링 서비스 초기화 실패', error: e);
      completer.completeError(e);
    }
  }

  /// 모바일 전용 서비스들을 로드합니다
  Future<void> _loadMobileServices() async {
    const serviceName = 'mobile_services';
    if (_loadedServices[serviceName] == true) return;

    final completer = _getOrCreateCompleter(serviceName);
    if (completer.isCompleted) return;

    try {
      logger.i('📱 모바일 서비스 초기화 시작');

      // WebP 초기화
      await AppInitializer.initializeWebP();
      logger.i('WebP 초기화 완료');

      // Tapjoy 초기화
      await AppInitializer.initializeTapjoy();
      logger.i('Tapjoy 초기화 완료');

      // 타임존 초기화
      await AppInitializer.initializeTimezone();
      logger.i('타임존 초기화 완료');

      // 프라이버시 동의 초기화
      await AppInitializer.initializePrivacyConsent();
      logger.i('프라이버시 동의 초기화 완료');

      _loadedServices[serviceName] = true;
      completer.complete();
      logger.i('✅ 모바일 서비스 초기화 완료');
    } catch (e) {
      logger.e('모바일 서비스 초기화 실패', error: e);
      completer.completeError(e);
    }
  }

  /// 기타 서비스들을 로드합니다
  Future<void> _loadMiscellaneousServices() async {
    const serviceName = 'miscellaneous_services';
    if (_loadedServices[serviceName] == true) return;

    final completer = _getOrCreateCompleter(serviceName);
    if (completer.isCompleted) return;

    try {
      logger.i('🔧 기타 서비스 초기화 시작');

      // Branch SDK 초기화 (모바일 전용)
      if (UniversalPlatform.isMobile) {
        await FlutterBranchSdk.init(
          enableLogging: true,
          branchAttributionLevel: BranchAttributionLevel.NONE,
        );
        logger.i('Branch SDK 초기화 완료');
      }

      _loadedServices[serviceName] = true;
      completer.complete();
      logger.i('✅ 기타 서비스 초기화 완료');
    } catch (e) {
      logger.e('기타 서비스 초기화 실패', error: e);
      completer.completeError(e);
    }
  }

  /// 특정 서비스가 로드될 때까지 대기합니다
  Future<void> waitForService(String serviceName) async {
    if (_loadedServices[serviceName] == true) {
      return;
    }

    final completer = _getOrCreateCompleter(serviceName);
    await completer.future;
  }

  /// 특정 서비스가 로드되었는지 확인합니다
  bool isServiceLoaded(String serviceName) {
    return _loadedServices[serviceName] == true;
  }

  /// 모든 서비스가 로드될 때까지 대기합니다
  Future<void> waitForAllServices() async {
    final futures = _loadingCompleters.values.map((c) => c.future);
    await Future.wait(futures, eagerError: false);
  }

  /// 로드된 서비스들의 상태를 반환합니다
  Map<String, bool> getServiceStatus() {
    return Map.from(_loadedServices);
  }

  /// Completer를 가져오거나 생성합니다
  Completer<void> _getOrCreateCompleter(String serviceName) {
    return _loadingCompleters.putIfAbsent(serviceName, () => Completer<void>());
  }

  /// 지연 로딩 매니저를 리셋합니다 (테스트용)
  void reset() {
    _loadedServices.clear();
    _loadingCompleters.clear();
    _isInitialized = false;
  }

  /// 특정 서비스를 강제로 로드합니다
  Future<void> forceLoadService(String serviceName) async {
    switch (serviceName) {
      case 'image_services':
        await _loadImageServices();
        break;
      case 'network_services':
        await _loadNetworkServices();
        break;
      case 'memory_profiling_services':
        await _loadMemoryProfilingServices();
        break;
      case 'mobile_services':
        await _loadMobileServices();
        break;
      case 'miscellaneous_services':
        await _loadMiscellaneousServices();
        break;
      default:
        logger.w('알 수 없는 서비스: $serviceName');
    }
  }

  /// Flutter 기본 이미지 캐시 최적화
  static void _optimizeFlutterImageCache() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;

      // 플랫폼별 캐시 크기 설정
      if (UniversalPlatform.isWeb) {
        // 웹에서는 상대적으로 큰 캐시 허용
        imageCache.maximumSize = 300;
        imageCache.maximumSizeBytes = 150 * 1024 * 1024; // 150MB
      } else if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
        // 모바일에서는 메모리 효율성 중시
        imageCache.maximumSize = 200;
        imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
      } else {
        // 데스크톱 환경
        imageCache.maximumSize = 400;
        imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200MB
      }

      logger.i('Flutter 이미지 캐시 최적화 완료: '
          '최대 ${imageCache.maximumSize}개 이미지, '
          '${imageCache.maximumSizeBytes ~/ (1024 * 1024)}MB');
    } catch (e) {
      logger.e('Flutter 이미지 캐시 최적화 실패', error: e);
    }
  }

  /// 위젯 지연 로딩 관련 메서드들

  /// 지연 로딩할 위젯을 등록합니다
  void registerLazyWidget({
    required String id,
    required Widget Function() builder,
    LazyLoadPriority priority = LazyLoadPriority.normal,
    Duration? delay,
    bool preloadOnIdle = false,
  }) {
    _widgetLoader.registerLazyWidget(
      id: id,
      builder: builder,
      priority: priority,
      delay: delay,
      preloadOnIdle: preloadOnIdle,
    );
  }

  /// 위젯을 즉시 로드합니다
  Widget loadWidget(String id) {
    return _widgetLoader.loadWidget(id);
  }

  /// 위젯 로드를 예약합니다
  void scheduleWidgetLoad(String id, {Duration? customDelay}) {
    _widgetLoader.scheduleWidgetLoad(id, customDelay: customDelay);
  }

  /// 특정 위젯이 로드되었는지 확인합니다
  bool isWidgetLoaded(String id) {
    return _widgetLoader.isWidgetLoaded(id);
  }

  /// 위젯 지연 로딩 상태를 반환합니다
  Map<String, dynamic> getWidgetStatus() {
    return _widgetLoader.getStatus();
  }

  /// 데이터 지연 로딩 관련 메서드들

  /// 지연 로딩할 데이터를 등록합니다
  void registerLazyData<T>({
    required String id,
    required Future<T> Function() loader,
    DataLoadPriority priority = DataLoadPriority.normal,
    Duration? delay,
    bool preloadOnIdle = false,
    bool cacheResult = true,
    Duration? cacheExpiry,
    int maxRetries = 3,
  }) {
    _dataLoader.registerLazyData<T>(
      id: id,
      loader: loader,
      priority: priority,
      delay: delay,
      preloadOnIdle: preloadOnIdle,
      cacheResult: cacheResult,
      cacheExpiry: cacheExpiry,
      maxRetries: maxRetries,
    );
  }

  /// 데이터를 즉시 로드합니다
  Future<T?> loadData<T>(String id) {
    return _dataLoader.loadData<T>(id);
  }

  /// 데이터 로드를 예약합니다
  void scheduleDataLoad(String id, {Duration? customDelay}) {
    _dataLoader.scheduleDataLoad(id, customDelay: customDelay);
  }

  /// 특정 데이터가 로드되었는지 확인합니다
  bool isDataLoaded(String id) {
    return _dataLoader.isDataLoaded(id);
  }

  /// 특정 데이터가 로딩 중인지 확인합니다
  bool isDataLoading(String id) {
    return _dataLoader.isDataLoading(id);
  }

  /// 캐시된 데이터를 무효화합니다
  void invalidateDataCache(String id) {
    _dataLoader.invalidateCache(id);
  }

  /// 모든 데이터 캐시를 무효화합니다
  void invalidateAllDataCache() {
    _dataLoader.invalidateAllCache();
  }

  /// 실패한 데이터 로드를 재시도합니다
  Future<T?> retryFailedDataLoad<T>(String id) {
    return _dataLoader.retryFailedLoad<T>(id);
  }

  /// 데이터 지연 로딩 상태를 반환합니다
  Map<String, dynamic> getDataStatus() {
    return _dataLoader.getStatus();
  }

  /// 통합 상태 관리

  /// 전체 지연 로딩 상태를 반환합니다
  Map<String, dynamic> getFullLazyLoadingStatus() {
    return {
      'services': getServiceStatus(),
      'widgets': getWidgetStatus(),
      'data': getDataStatus(),
      'is_initialized': _isInitialized,
    };
  }

  /// 모든 지연 로딩 시스템을 정리합니다
  void disposeAll() {
    _widgetLoader.dispose();
    _dataLoader.dispose();
    reset();
    logger.i('🧹 모든 지연 로딩 시스템 정리 완료');
  }
}
