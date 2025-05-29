import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picnic_lib/core/services/font_optimization_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 에셋 로딩 우선순위
enum AssetPriority {
  critical, // 앱 시작에 필수
  high, // 첫 화면에서 사용
  normal, // 일반적으로 사용
  low, // 특정 기능에서만 사용
}

/// 에셋 타입
enum AssetType {
  font,
  image,
  icon,
  animation,
}

/// 에셋 메타데이터
class AssetMetadata {
  final String path;
  final AssetType type;
  final AssetPriority priority;
  final int? estimatedSizeBytes;
  final List<String> dependencies;
  final bool preloadOnIdle;

  const AssetMetadata({
    required this.path,
    required this.type,
    required this.priority,
    this.estimatedSizeBytes,
    this.dependencies = const [],
    this.preloadOnIdle = false,
  });
}

/// 에셋 로딩 상태
enum AssetLoadingState {
  notLoaded,
  loading,
  loaded,
  failed,
}

/// 에셋 로딩 결과
class AssetLoadingResult {
  final String path;
  final AssetLoadingState state;
  final DateTime? loadTime;
  final Duration? loadDuration;
  final String? error;
  final int? sizeBytes;

  const AssetLoadingResult({
    required this.path,
    required this.state,
    this.loadTime,
    this.loadDuration,
    this.error,
    this.sizeBytes,
  });
}

/// 에셋 로딩 최적화 서비스
///
/// 앱 시작 시간을 개선하기 위해 에셋 로딩을 최적화합니다:
/// - 중요한 에셋만 시작 시 로드
/// - 나머지 에셋은 필요할 때 지연 로딩
/// - 폰트 서브셋팅 및 조건부 로딩
/// - 메모리 효율적인 에셋 관리
class AssetLoadingService {
  static final AssetLoadingService _instance = AssetLoadingService._internal();
  factory AssetLoadingService() => _instance;
  AssetLoadingService._internal();

  // 에셋 로딩 상태 추적
  final Map<String, AssetLoadingResult> _loadingResults = {};
  final Map<String, Completer<void>> _loadingCompleters = {};

  // 에셋 메타데이터 레지스트리
  final Map<String, AssetMetadata> _assetRegistry = {};

  // 로딩 큐 (우선순위별)
  final Map<AssetPriority, List<String>> _loadingQueues = {
    AssetPriority.critical: [],
    AssetPriority.high: [],
    AssetPriority.normal: [],
    AssetPriority.low: [],
  };

  // 폰트 최적화 서비스
  final FontOptimizationService _fontService = FontOptimizationService();

  // 동시 로딩 제한
  static const int _maxConcurrentLoads = 3;
  int _currentLoads = 0;

  // 초기화 상태
  bool _isInitialized = false;
  Completer<void>? _initializationCompleter;

  /// 서비스 초기화
  Future<void> initialize({String language = 'ko'}) async {
    if (_isInitialized) return;

    _initializationCompleter ??= Completer<void>();

    try {
      logger.i('🎨 에셋 로딩 서비스 초기화 시작');

      // 폰트 최적화 서비스 초기화 (병렬 실행)
      final fontInitFuture = _fontService.initialize(language: language);

      // 에셋 메타데이터 등록
      _registerAssetMetadata();

      // 중요한 에셋들만 즉시 로드 (폰트는 FontOptimizationService에서 처리)
      final assetLoadFuture = _loadCriticalAssets();

      // 폰트와 에셋 로딩을 병렬로 실행
      await Future.wait([fontInitFuture, assetLoadFuture]);

      // 백그라운드에서 고우선순위 에셋 로드 시작
      unawaited(_loadHighPriorityAssets());

      _isInitialized = true;
      _initializationCompleter!.complete();

      logger.i('✅ 에셋 로딩 서비스 초기화 완료');
    } catch (e, stackTrace) {
      logger.e('에셋 로딩 서비스 초기화 실패', error: e, stackTrace: stackTrace);
      _initializationCompleter!.completeError(e, stackTrace);
      rethrow;
    }
  }

  /// 에셋 메타데이터 등록
  void _registerAssetMetadata() {
    // 폰트는 FontOptimizationService에서 처리하므로 제외

    // 중요한 이미지들 (시작 시 필요)
    _registerAsset(AssetMetadata(
      path: 'assets/splash.webp',
      type: AssetType.image,
      priority: AssetPriority.critical,
      estimatedSizeBytes: 23000,
    ));

    // 로그인 관련 아이콘들 (첫 화면에서 사용)
    _registerAsset(AssetMetadata(
      path: 'assets/icons/login/',
      type: AssetType.icon,
      priority: AssetPriority.high,
      preloadOnIdle: true,
    ));

    // 하단 네비게이션 아이콘들
    _registerAsset(AssetMetadata(
      path: 'assets/icons/bottom/',
      type: AssetType.icon,
      priority: AssetPriority.high,
      preloadOnIdle: true,
    ));

    // 헤더 아이콘들
    _registerAsset(AssetMetadata(
      path: 'assets/icons/header/',
      type: AssetType.icon,
      priority: AssetPriority.normal,
      preloadOnIdle: true,
    ));

    // 기타 아이콘들 (필요할 때 로드)
    _registerAsset(AssetMetadata(
      path: 'assets/icons/post/',
      type: AssetType.icon,
      priority: AssetPriority.low,
    ));

    _registerAsset(AssetMetadata(
      path: 'assets/icons/vote/',
      type: AssetType.icon,
      priority: AssetPriority.low,
    ));

    _registerAsset(AssetMetadata(
      path: 'assets/icons/store/',
      type: AssetType.icon,
      priority: AssetPriority.low,
    ));

    _registerAsset(AssetMetadata(
      path: 'assets/icons/fortune/',
      type: AssetType.icon,
      priority: AssetPriority.low,
    ));
  }

  /// 에셋 등록
  void _registerAsset(AssetMetadata metadata) {
    _assetRegistry[metadata.path] = metadata;
    _loadingQueues[metadata.priority]!.add(metadata.path);
  }

  /// 중요한 에셋들 즉시 로드
  Future<void> _loadCriticalAssets() async {
    final criticalAssets = _loadingQueues[AssetPriority.critical]!;

    logger.i('🚀 중요 에셋 로딩 시작 (${criticalAssets.length}개)');

    final futures = <Future<void>>[];
    for (final assetPath in criticalAssets) {
      futures.add(_loadAsset(assetPath));
    }

    await Future.wait(futures);
    logger.i('✅ 중요 에셋 로딩 완료');
  }

  /// 고우선순위 에셋들 백그라운드 로드
  Future<void> _loadHighPriorityAssets() async {
    // 잠시 대기 (앱 시작 완료 후)
    await Future.delayed(const Duration(milliseconds: 500));

    final highPriorityAssets = _loadingQueues[AssetPriority.high]!;

    logger.i('⚡ 고우선순위 에셋 백그라운드 로딩 시작 (${highPriorityAssets.length}개)');

    for (final assetPath in highPriorityAssets) {
      if (_currentLoads < _maxConcurrentLoads) {
        unawaited(_loadAsset(assetPath));
      } else {
        // 큐가 가득 찬 경우 잠시 대기
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// 개별 에셋 로드
  Future<void> _loadAsset(String assetPath) async {
    if (_loadingResults[assetPath]?.state == AssetLoadingState.loaded) {
      return; // 이미 로드됨
    }

    if (_loadingCompleters.containsKey(assetPath)) {
      return _loadingCompleters[assetPath]!.future; // 이미 로딩 중
    }

    final completer = Completer<void>();
    _loadingCompleters[assetPath] = completer;
    _currentLoads++;

    final startTime = DateTime.now();

    try {
      _loadingResults[assetPath] = AssetLoadingResult(
        path: assetPath,
        state: AssetLoadingState.loading,
      );

      final metadata = _assetRegistry[assetPath];
      if (metadata == null) {
        throw Exception('에셋 메타데이터를 찾을 수 없음: $assetPath');
      }

      // 에셋 타입별 로딩 (폰트는 FontOptimizationService에서 처리)
      switch (metadata.type) {
        case AssetType.font:
          // 폰트는 FontOptimizationService에서 처리
          logger.d('폰트 로딩은 FontOptimizationService에서 처리: $assetPath');
          break;
        case AssetType.image:
        case AssetType.icon:
          await _preloadImage(assetPath);
          break;
        case AssetType.animation:
          // 애니메이션 에셋 로딩 (필요시 구현)
          break;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _loadingResults[assetPath] = AssetLoadingResult(
        path: assetPath,
        state: AssetLoadingState.loaded,
        loadTime: endTime,
        loadDuration: duration,
      );

      logger.d('에셋 로드 완료: $assetPath (${duration.inMilliseconds}ms)');
      completer.complete();
    } catch (e) {
      _loadingResults[assetPath] = AssetLoadingResult(
        path: assetPath,
        state: AssetLoadingState.failed,
        error: e.toString(),
      );

      logger.e('에셋 로드 실패: $assetPath', error: e);
      completer.completeError(e);
    } finally {
      _loadingCompleters.remove(assetPath);
      _currentLoads--;
    }
  }

  /// 이미지 프리로드
  Future<void> _preloadImage(String imagePath) async {
    try {
      final image = AssetImage(imagePath);

      // BuildContext가 없는 경우를 대비한 안전한 프리로드
      final binding = WidgetsBinding.instance;
      if (binding.renderViewElement != null) {
        await precacheImage(image, binding.renderViewElement!);
        logger.d('이미지 프리로드 완료: $imagePath');
      } else {
        // BuildContext가 없는 경우 이미지 데이터만 로드
        final imageData = await rootBundle.load(imagePath);
        logger
            .d('이미지 데이터 로드 완료: $imagePath (${imageData.lengthInBytes} bytes)');
      }
    } catch (e) {
      logger.e('이미지 프리로드 실패: $imagePath', error: e);
      rethrow;
    }
  }

  /// 폰트 로드 (FontOptimizationService 위임)
  Future<void> waitForFont(String fontFamily, FontWeight weight) async {
    return _fontService.waitForFont(fontFamily, weight);
  }

  /// 특정 폰트가 로드되었는지 확인
  bool isFontLoaded(String fontFamily, FontWeight weight) {
    return _fontService.isFontLoaded(fontFamily, weight);
  }

  /// 언어 변경
  Future<void> changeLanguage(String language) async {
    await _fontService.changeLanguage(language);
  }

  /// 유휴 시간에 에셋 프리로드
  void preloadOnIdle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 2), () {
        // 에셋 프리로드
        _preloadIdleAssets();

        // 폰트 프리로드
        _fontService.preloadRemainingFonts();
      });
    });
  }

  /// 유휴 시간 에셋 프리로드
  Future<void> _preloadIdleAssets() async {
    final idleAssets = _assetRegistry.entries
        .where(
            (entry) => entry.value.preloadOnIdle && !isAssetLoaded(entry.key))
        .map((entry) => entry.key)
        .toList();

    logger.i('🔄 유휴 시간 에셋 프리로드 시작 (${idleAssets.length}개)');

    for (final assetPath in idleAssets) {
      if (_currentLoads < _maxConcurrentLoads) {
        unawaited(_loadAsset(assetPath));
        // 부하 분산을 위해 잠시 대기
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// 특정 에셋이 로드되었는지 확인
  bool isAssetLoaded(String assetPath) {
    return _loadingResults[assetPath]?.state == AssetLoadingState.loaded;
  }

  /// 우선순위별 에셋 로드
  Future<void> loadAssetsByPriority(AssetPriority priority) async {
    final assets = _loadingQueues[priority]!;

    final futures = <Future<void>>[];
    for (final assetPath in assets) {
      if (!isAssetLoaded(assetPath)) {
        futures.add(_loadAsset(assetPath));
      }
    }

    await Future.wait(futures);
  }

  /// 로딩 통계 반환 (폰트 통계 포함)
  Map<String, dynamic> getLoadingStats() {
    final assetStats = <AssetLoadingState, int>{};
    int totalSize = 0;
    Duration totalLoadTime = Duration.zero;

    for (final result in _loadingResults.values) {
      assetStats[result.state] = (assetStats[result.state] ?? 0) + 1;

      if (result.sizeBytes != null) {
        totalSize += result.sizeBytes!;
      }

      if (result.loadDuration != null) {
        totalLoadTime += result.loadDuration!;
      }
    }

    // 폰트 통계 가져오기
    final fontStats = _fontService.getLoadingStats();

    return {
      'assets': {
        'totalAssets': _assetRegistry.length,
        'loadedAssets': assetStats[AssetLoadingState.loaded] ?? 0,
        'loadingAssets': assetStats[AssetLoadingState.loading] ?? 0,
        'failedAssets': assetStats[AssetLoadingState.failed] ?? 0,
        'totalSizeBytes': totalSize,
        'totalLoadTimeMs': totalLoadTime.inMilliseconds,
        'averageLoadTimeMs': _loadingResults.isNotEmpty
            ? totalLoadTime.inMilliseconds / _loadingResults.length
            : 0,
      },
      'fonts': fontStats,
      'combined': {
        'totalItems': _assetRegistry.length + (fontStats['totalFonts'] as int),
        'totalLoadedItems': (assetStats[AssetLoadingState.loaded] ?? 0) +
            (fontStats['loadedFonts'] as int),
        'totalSizeBytes': totalSize + (fontStats['totalSizeBytes'] as int),
      }
    };
  }

  /// 메모리 정리
  void dispose() {
    _loadingResults.clear();
    _loadingCompleters.clear();
    _loadingQueues.clear();
    _assetRegistry.clear();
    _fontService.dispose();
    _isInitialized = false;
    _initializationCompleter = null;
  }
}
