import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/services/cache_management_service.dart';
import 'package:picnic_lib/core/services/image_cache_service.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';

/// 이미지 처리 전용 메모리 프로파일러
/// 이미지 로딩, 캐싱, 처리 과정에서의 메모리 사용량을 모니터링하고 최적화합니다.
class ImageMemoryProfiler {
  static final ImageMemoryProfiler _instance = ImageMemoryProfiler._internal();
  factory ImageMemoryProfiler() => _instance;
  ImageMemoryProfiler._internal();

  // 의존성
  final MemoryProfiler _memoryProfiler = MemoryProfiler.instance;
  final ImageCacheService _cacheService = ImageCacheService();
  final CacheManagementService _cacheManagementService =
      CacheManagementService();

  // 모니터링 상태
  bool _isEnabled = false;
  bool _isRealTimeMonitoringEnabled = false;

  // 타이머
  Timer? _realTimeMonitorTimer;
  Timer? _leakDetectionTimer;

  // 메모리 추적
  final Map<String, ImageMemoryTracker> _imageTrackers = {};
  final List<ImageMemoryEvent> _memoryEvents = [];
  final List<MemoryLeakSuspicion> _leakSuspicions = [];

  // 설정
  late ImageMemoryProfilerConfig _config;

  // 통계
  ImageMemoryStats? _lastStats;
  DateTime? _lastStatsTime;

  /// 초기화
  void initialize({ImageMemoryProfilerConfig? config}) {
    _config = config ?? ImageMemoryProfilerConfig.defaultConfig();
    _isEnabled = true;

    // 기본 메모리 프로파일러 초기화
    _memoryProfiler.initialize(enabled: true);

    // 실시간 모니터링 시작
    if (_config.enableRealTimeMonitoring) {
      startRealTimeMonitoring();
    }

    // 메모리 누수 감지 시작
    if (_config.enableLeakDetection) {
      startLeakDetection();
    }

    logger.i('ImageMemoryProfiler 초기화 완료');
  }

  /// 실시간 모니터링 시작
  void startRealTimeMonitoring() {
    if (_isRealTimeMonitoringEnabled) return;

    _isRealTimeMonitoringEnabled = true;
    _realTimeMonitorTimer = Timer.periodic(_config.monitoringInterval, (timer) {
      _performRealTimeCheck();
    });

    logger.i('이미지 메모리 실시간 모니터링 시작');
  }

  /// 실시간 모니터링 중지
  void stopRealTimeMonitoring() {
    _isRealTimeMonitoringEnabled = false;
    _realTimeMonitorTimer?.cancel();
    _realTimeMonitorTimer = null;

    logger.i('이미지 메모리 실시간 모니터링 중지');
  }

  /// 메모리 누수 감지 시작
  void startLeakDetection() {
    _leakDetectionTimer =
        Timer.periodic(_config.leakDetectionInterval, (timer) {
      _performLeakDetection();
    });

    logger.i('이미지 메모리 누수 감지 시작');
  }

  /// 메모리 누수 감지 중지
  void stopLeakDetection() {
    _leakDetectionTimer?.cancel();
    _leakDetectionTimer = null;

    logger.i('이미지 메모리 누수 감지 중지');
  }

  /// 이미지 로딩 시작 추적
  void trackImageLoadStart(String imageUrl, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return;

    final tracker = ImageMemoryTracker(
      imageUrl: imageUrl,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    _imageTrackers[imageUrl] = tracker;

    // 메모리 스냅샷 생성
    _memoryProfiler.takeSnapshot(
      'image_load_start_${imageUrl.hashCode}',
      metadata: {
        'imageUrl': imageUrl,
        'operation': 'load_start',
        ...metadata ?? {},
      },
      level: MemoryProfiler.snapshotLevelLow,
    );

    _recordMemoryEvent(ImageMemoryEventType.loadStart, imageUrl, metadata);
  }

  /// 이미지 로딩 완료 추적
  void trackImageLoadComplete(
    String imageUrl,
    Uint8List? imageBytes, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    final tracker = _imageTrackers[imageUrl];
    if (tracker == null) {
      logger.w('이미지 로딩 추적기를 찾을 수 없음: $imageUrl');
      return;
    }

    // 로딩 시간 계산
    final loadDuration = DateTime.now().difference(tracker.startTime);
    tracker.loadDuration = loadDuration;
    tracker.imageSizeBytes = imageBytes?.length ?? 0;
    tracker.isLoaded = true;

    // 메모리 스냅샷 생성
    _memoryProfiler.takeSnapshot(
      'image_load_complete_${imageUrl.hashCode}',
      metadata: {
        'imageUrl': imageUrl,
        'operation': 'load_complete',
        'loadDurationMs': loadDuration.inMilliseconds,
        'imageSizeBytes': tracker.imageSizeBytes,
        ...metadata ?? {},
      },
      level: MemoryProfiler.snapshotLevelMedium,
    );

    _recordMemoryEvent(ImageMemoryEventType.loadComplete, imageUrl, {
      'loadDurationMs': loadDuration.inMilliseconds,
      'imageSizeBytes': tracker.imageSizeBytes,
      ...metadata ?? {},
    });

    // 성능 분석
    _analyzeLoadPerformance(tracker);
  }

  /// 이미지 처리 시작 추적
  void trackImageProcessingStart(
    String imageUrl,
    String operation, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    _memoryProfiler.takeSnapshot(
      'image_processing_start_${imageUrl.hashCode}_$operation',
      metadata: {
        'imageUrl': imageUrl,
        'operation': 'processing_start',
        'processingType': operation,
        ...metadata ?? {},
      },
      level: MemoryProfiler.snapshotLevelMedium,
    );

    _recordMemoryEvent(ImageMemoryEventType.processingStart, imageUrl, {
      'processingType': operation,
      ...metadata ?? {},
    });
  }

  /// 이미지 처리 완료 추적
  void trackImageProcessingComplete(
    String imageUrl,
    String operation,
    Uint8List? resultBytes, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    _memoryProfiler.takeSnapshot(
      'image_processing_complete_${imageUrl.hashCode}_$operation',
      metadata: {
        'imageUrl': imageUrl,
        'operation': 'processing_complete',
        'processingType': operation,
        'resultSizeBytes': resultBytes?.length ?? 0,
        ...metadata ?? {},
      },
      level: MemoryProfiler.snapshotLevelMedium,
    );

    _recordMemoryEvent(ImageMemoryEventType.processingComplete, imageUrl, {
      'processingType': operation,
      'resultSizeBytes': resultBytes?.length ?? 0,
      ...metadata ?? {},
    });
  }

  /// 이미지 캐시 이벤트 추적
  void trackCacheEvent(
    String imageUrl,
    ImageCacheEventType eventType, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    _memoryProfiler.takeSnapshot(
      'image_cache_${eventType.name}_${imageUrl.hashCode}',
      metadata: {
        'imageUrl': imageUrl,
        'operation': 'cache_${eventType.name}',
        ...metadata ?? {},
      },
      level: MemoryProfiler.snapshotLevelLow,
    );

    _recordMemoryEvent(ImageMemoryEventType.cacheEvent, imageUrl, {
      'cacheEventType': eventType.name,
      ...metadata ?? {},
    });
  }

  /// 실시간 메모리 체크 수행
  void _performRealTimeCheck() {
    final currentStats = _generateCurrentStats();

    // 이전 통계와 비교
    if (_lastStats != null) {
      _analyzeMemoryTrends(currentStats);
    }

    _lastStats = currentStats;
    _lastStatsTime = DateTime.now();

    // 메모리 압박 상태 확인
    if (currentStats.isMemoryPressure) {
      _handleMemoryPressure(currentStats);
    }

    // 성능 저하 확인
    if (currentStats.averageLoadTime > _config.slowLoadThreshold) {
      _handleSlowPerformance(currentStats);
    }
  }

  /// 메모리 누수 감지 수행
  void _performLeakDetection() {
    final suspicions = <MemoryLeakSuspicion>[];

    // 오래된 추적기 확인
    final now = DateTime.now();
    for (final entry in _imageTrackers.entries) {
      final tracker = entry.value;
      final age = now.difference(tracker.startTime);

      if (age > _config.maxImageLifetime && tracker.isLoaded) {
        suspicions.add(MemoryLeakSuspicion(
          imageUrl: entry.key,
          suspicionType: MemoryLeakType.longLivedImage,
          detectedAt: now,
          severity: MemoryLeakSeverity.medium,
          description: '이미지가 ${age.inMinutes}분 동안 메모리에 유지되고 있습니다',
          recommendation: '이미지 캐시에서 제거하거나 메모리 해제를 확인하세요',
        ));
      }
    }

    // 메모리 증가 패턴 확인
    if (_memoryEvents.length >= 10) {
      final recentEvents = _memoryEvents.length > 10
          ? _memoryEvents.skip(_memoryEvents.length - 10).toList()
          : _memoryEvents.toList();
      final memoryGrowth = _analyzeMemoryGrowthPattern(recentEvents);

      if (memoryGrowth > _config.memoryGrowthThreshold) {
        suspicions.add(MemoryLeakSuspicion(
          imageUrl: 'multiple',
          suspicionType: MemoryLeakType.continuousGrowth,
          detectedAt: now,
          severity: MemoryLeakSeverity.high,
          description:
              '지속적인 메모리 증가가 감지되었습니다 (+${memoryGrowth.toStringAsFixed(1)}MB)',
          recommendation: '이미지 캐시 정리 또는 메모리 해제 로직을 확인하세요',
        ));
      }
    }

    // 새로운 의심 사례 추가
    for (final suspicion in suspicions) {
      if (!_leakSuspicions.any((existing) =>
          existing.imageUrl == suspicion.imageUrl &&
          existing.suspicionType == suspicion.suspicionType)) {
        _leakSuspicions.add(suspicion);

        logger.w('메모리 누수 의심: ${suspicion.description}');

        // 중요한 경우 스냅샷 생성
        if (suspicion.severity == MemoryLeakSeverity.high) {
          _memoryProfiler.takeSnapshot(
            'memory_leak_suspicion_${suspicion.imageUrl.hashCode}',
            metadata: {
              'suspicionType': suspicion.suspicionType.name,
              'severity': suspicion.severity.name,
              'description': suspicion.description,
            },
            level: MemoryProfiler.snapshotLevelHigh,
          );
        }
      }
    }

    // 오래된 의심 사례 정리
    _leakSuspicions.removeWhere((suspicion) =>
        now.difference(suspicion.detectedAt) > const Duration(hours: 1));
  }

  /// 메모리 이벤트 기록
  void _recordMemoryEvent(
    ImageMemoryEventType type,
    String imageUrl,
    Map<String, dynamic>? metadata,
  ) {
    final event = ImageMemoryEvent(
      type: type,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _memoryEvents.add(event);

    // 최근 1000개 이벤트만 유지
    if (_memoryEvents.length > 1000) {
      _memoryEvents.removeAt(0);
    }
  }

  /// 로딩 성능 분석
  void _analyzeLoadPerformance(ImageMemoryTracker tracker) {
    if (tracker.loadDuration != null) {
      final loadTimeMs = tracker.loadDuration!.inMilliseconds;

      if (loadTimeMs > _config.slowLoadThreshold.inMilliseconds) {
        // throttling을 사용하여 로그 출력 빈도 제한
        final throttleKey = 'slow_load_${tracker.imageUrl.hashCode}';
        logger.throttledWarn(
          '느린 이미지 로딩 감지: ${tracker.imageUrl}, ${loadTimeMs}ms',
          throttleKey,
          throttleDuration: const Duration(minutes: 5), // 5분마다 한 번만 출력
        );

        // 최적화 제안도 throttling 적용
        final suggestions = _generateOptimizationSuggestions(tracker);
        for (final suggestion in suggestions) {
          final suggestionKey =
              'suggestion_${suggestion.type.toString()}_${tracker.imageUrl.hashCode}';
          logger.throttledWarn(
            '최적화 제안: ${suggestion.description}',
            suggestionKey,
            throttleDuration: const Duration(minutes: 10), // 10분마다 한 번만 출력
          );
        }
      }
    }
  }

  /// 메모리 트렌드 분석
  void _analyzeMemoryTrends(ImageMemoryStats currentStats) {
    if (_lastStats == null) return;

    final memoryIncrease =
        currentStats.totalMemoryUsage - _lastStats!.totalMemoryUsage;
    final timeElapsed = DateTime.now().difference(_lastStatsTime!);

    // 메모리 증가율 계산 (MB/분)
    final memoryIncreaseRate = memoryIncrease / timeElapsed.inMinutes;

    if (memoryIncreaseRate > _config.memoryGrowthThreshold) {
      // throttling 적용하여 로그 출력 빈도 제한
      logger.throttledWarn(
        '빠른 메모리 증가 감지: +${memoryIncreaseRate.toStringAsFixed(2)}MB/분',
        'memory_growth_trend',
        throttleDuration: const Duration(minutes: 3), // 3분마다 한 번만 출력
      );
    }
  }

  /// 메모리 압박 상태 처리
  void _handleMemoryPressure(ImageMemoryStats stats) {
    // throttling 적용
    logger.throttledWarn(
      '이미지 메모리 압박 상태 감지',
      'memory_pressure',
      throttleDuration: const Duration(minutes: 2), // 2분마다 한 번만 출력
    );

    // 자동 캐시 정리 수행
    _cacheManagementService.invalidateCache(
      reason: CacheInvalidationReason.memoryPressure,
      force: true,
    );

    // 긴급 스냅샷 생성
    _memoryProfiler.takeSnapshot(
      'image_memory_pressure_${DateTime.now().millisecondsSinceEpoch}',
      metadata: {
        'totalMemoryUsage': stats.totalMemoryUsage,
        'imageCacheSize': stats.imageCacheSize,
        'activeImages': stats.activeImageCount,
      },
      level: MemoryProfiler.snapshotLevelCritical,
    );
  }

  /// 성능 저하 처리
  void _handleSlowPerformance(ImageMemoryStats stats) {
    // throttling 적용
    logger.throttledWarn(
      '이미지 로딩 성능 저하 감지',
      'slow_performance',
      throttleDuration: const Duration(minutes: 5), // 5분마다 한 번만 출력
    );

    // 성능 최적화 제안 생성 (throttling 적용)
    final suggestions = _generatePerformanceOptimizations(stats);
    for (final suggestion in suggestions) {
      final suggestionKey = 'perf_suggestion_${suggestion.type.toString()}';
      logger.throttledWarn(
        '성능 최적화 제안: ${suggestion.description}',
        suggestionKey,
        throttleDuration: const Duration(minutes: 10), // 10분마다 한 번만 출력
      );
    }
  }

  /// 현재 통계 생성
  ImageMemoryStats _generateCurrentStats() {
    final cacheStats = _cacheService.getCacheStats();
    final activeTrackers =
        _imageTrackers.values.where((t) => t.isLoaded).length;

    final recentLoadTimes = _memoryEvents
        .where((e) => e.type == ImageMemoryEventType.loadComplete)
        .where((e) =>
            DateTime.now().difference(e.timestamp) < const Duration(minutes: 5))
        .map((e) => e.metadata['loadDurationMs'] as int? ?? 0)
        .where((duration) => duration > 0)
        .toList();

    final averageLoadTime = recentLoadTimes.isNotEmpty
        ? Duration(
            milliseconds: recentLoadTimes.reduce((a, b) => a + b) ~/
                recentLoadTimes.length)
        : Duration.zero;

    return ImageMemoryStats(
      totalMemoryUsage: cacheStats.sizeMB.toDouble(),
      imageCacheSize: cacheStats.sizeMB.toDouble(),
      activeImageCount: activeTrackers,
      averageLoadTime: averageLoadTime,
      isMemoryPressure: cacheStats.isMemoryPressure,
      timestamp: DateTime.now(),
    );
  }

  /// 메모리 증가 패턴 분석
  double _analyzeMemoryGrowthPattern(List<ImageMemoryEvent> events) {
    if (events.length < 2) return 0.0;

    // 간단한 메모리 증가 계산 (실제로는 더 복잡한 분석 필요)
    final firstEvent = events.first;
    final lastEvent = events.last;
    lastEvent.timestamp.difference(firstEvent.timestamp);

    // 이벤트 수를 기반으로 한 대략적인 메모리 증가 추정
    return events.length * 0.5; // 이벤트당 0.5MB 증가로 가정
  }

  /// 최적화 제안 생성
  List<ImageOptimizationSuggestion> _generateOptimizationSuggestions(
    ImageMemoryTracker tracker,
  ) {
    final suggestions = <ImageOptimizationSuggestion>[];

    if (tracker.imageSizeBytes > 5 * 1024 * 1024) {
      // 5MB 이상
      suggestions.add(ImageOptimizationSuggestion(
        type: ImageOptimizationType.compression,
        description: '이미지 크기가 큽니다. 압축을 고려하세요',
        expectedImprovement: '로딩 시간 30-50% 단축',
        priority: OptimizationPriority.high,
      ));
    }

    if (tracker.loadDuration != null &&
        tracker.loadDuration!.inMilliseconds > 2000) {
      suggestions.add(ImageOptimizationSuggestion(
        type: ImageOptimizationType.preloading,
        description: '로딩 시간이 깁니다. 프리로딩을 고려하세요',
        expectedImprovement: '사용자 체감 로딩 시간 제거',
        priority: OptimizationPriority.medium,
      ));
    }

    return suggestions;
  }

  /// 성능 최적화 제안 생성
  List<ImageOptimizationSuggestion> _generatePerformanceOptimizations(
    ImageMemoryStats stats,
  ) {
    final suggestions = <ImageOptimizationSuggestion>[];

    if (stats.activeImageCount > 50) {
      suggestions.add(ImageOptimizationSuggestion(
        type: ImageOptimizationType.cacheManagement,
        description: '활성 이미지가 많습니다. 캐시 정리를 고려하세요',
        expectedImprovement: '메모리 사용량 20-30% 감소',
        priority: OptimizationPriority.high,
      ));
    }

    if (stats.averageLoadTime > const Duration(milliseconds: 1000)) {
      suggestions.add(ImageOptimizationSuggestion(
        type: ImageOptimizationType.formatOptimization,
        description: '평균 로딩 시간이 깁니다. 이미지 포맷 최적화를 고려하세요',
        expectedImprovement: '로딩 시간 40-60% 단축',
        priority: OptimizationPriority.high,
      ));
    }

    return suggestions;
  }

  /// 메모리 리포트 생성
  ImageMemoryReport generateReport() {
    final currentStats = _generateCurrentStats();
    final recentEvents = _memoryEvents.length > 100
        ? _memoryEvents.skip(_memoryEvents.length - 100).toList()
        : _memoryEvents.toList();
    final activeSuspicions = _leakSuspicions
        .where((s) =>
            DateTime.now().difference(s.detectedAt) < const Duration(hours: 1))
        .toList();

    return ImageMemoryReport(
      stats: currentStats,
      recentEvents: recentEvents,
      leakSuspicions: activeSuspicions,
      optimizationSuggestions: _generatePerformanceOptimizations(currentStats),
      generatedAt: DateTime.now(),
    );
  }

  /// 리소스 정리
  void dispose() {
    stopRealTimeMonitoring();
    stopLeakDetection();
    _imageTrackers.clear();
    _memoryEvents.clear();
    _leakSuspicions.clear();
    logger.i('ImageMemoryProfiler 리소스 정리 완료');
  }
}

/// 이미지 메모리 프로파일러 설정
class ImageMemoryProfilerConfig {
  final bool enableRealTimeMonitoring;
  final bool enableLeakDetection;
  final Duration monitoringInterval;
  final Duration leakDetectionInterval;
  final Duration slowLoadThreshold;
  final Duration maxImageLifetime;
  final double memoryGrowthThreshold; // MB/분

  const ImageMemoryProfilerConfig({
    required this.enableRealTimeMonitoring,
    required this.enableLeakDetection,
    required this.monitoringInterval,
    required this.leakDetectionInterval,
    required this.slowLoadThreshold,
    required this.maxImageLifetime,
    required this.memoryGrowthThreshold,
  });

  factory ImageMemoryProfilerConfig.defaultConfig() {
    return const ImageMemoryProfilerConfig(
      enableRealTimeMonitoring: true,
      enableLeakDetection: true,
      monitoringInterval: Duration(seconds: 30),
      leakDetectionInterval: Duration(minutes: 2),
      slowLoadThreshold: Duration(milliseconds: 1500),
      maxImageLifetime: Duration(minutes: 10),
      memoryGrowthThreshold: 5.0, // 5MB/분
    );
  }
}

/// 이미지 메모리 추적기
class ImageMemoryTracker {
  final String imageUrl;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  Duration? loadDuration;
  int imageSizeBytes = 0;
  bool isLoaded = false;

  ImageMemoryTracker({
    required this.imageUrl,
    required this.startTime,
    required this.metadata,
  });
}

/// 이미지 메모리 이벤트
class ImageMemoryEvent {
  final ImageMemoryEventType type;
  final String imageUrl;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ImageMemoryEvent({
    required this.type,
    required this.imageUrl,
    required this.timestamp,
    required this.metadata,
  });
}

/// 이미지 메모리 이벤트 타입
enum ImageMemoryEventType {
  loadStart,
  loadComplete,
  processingStart,
  processingComplete,
  cacheEvent,
}

/// 이미지 캐시 이벤트 타입
enum ImageCacheEventType {
  hit,
  miss,
  eviction,
  cleanup,
}

/// 메모리 누수 의심 사례
class MemoryLeakSuspicion {
  final String imageUrl;
  final MemoryLeakType suspicionType;
  final DateTime detectedAt;
  final MemoryLeakSeverity severity;
  final String description;
  final String recommendation;

  const MemoryLeakSuspicion({
    required this.imageUrl,
    required this.suspicionType,
    required this.detectedAt,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

/// 메모리 누수 타입
enum MemoryLeakType {
  longLivedImage,
  continuousGrowth,
  unusualPattern,
}

/// 메모리 누수 심각도
enum MemoryLeakSeverity {
  low,
  medium,
  high,
  critical,
}

/// 이미지 메모리 통계
class ImageMemoryStats {
  final double totalMemoryUsage; // MB
  final double imageCacheSize; // MB
  final int activeImageCount;
  final Duration averageLoadTime;
  final bool isMemoryPressure;
  final DateTime timestamp;

  const ImageMemoryStats({
    required this.totalMemoryUsage,
    required this.imageCacheSize,
    required this.activeImageCount,
    required this.averageLoadTime,
    required this.isMemoryPressure,
    required this.timestamp,
  });
}

/// 이미지 최적화 제안
class ImageOptimizationSuggestion {
  final ImageOptimizationType type;
  final String description;
  final String expectedImprovement;
  final OptimizationPriority priority;

  const ImageOptimizationSuggestion({
    required this.type,
    required this.description,
    required this.expectedImprovement,
    required this.priority,
  });
}

/// 이미지 최적화 타입
enum ImageOptimizationType {
  compression,
  preloading,
  cacheManagement,
  formatOptimization,
}

/// 최적화 우선순위
enum OptimizationPriority {
  low,
  medium,
  high,
  critical,
}

/// 이미지 메모리 리포트
class ImageMemoryReport {
  final ImageMemoryStats stats;
  final List<ImageMemoryEvent> recentEvents;
  final List<MemoryLeakSuspicion> leakSuspicions;
  final List<ImageOptimizationSuggestion> optimizationSuggestions;
  final DateTime generatedAt;

  const ImageMemoryReport({
    required this.stats,
    required this.recentEvents,
    required this.leakSuspicions,
    required this.optimizationSuggestions,
    required this.generatedAt,
  });
}
