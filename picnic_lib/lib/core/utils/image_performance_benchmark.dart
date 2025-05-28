import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 이미지 성능 벤치마크 도구
/// 기존 시스템과 새로운 최적화 시스템의 성능을 비교 측정합니다.
class ImagePerformanceBenchmark {
  static final ImagePerformanceBenchmark _instance =
      ImagePerformanceBenchmark._internal();
  factory ImagePerformanceBenchmark() => _instance;
  ImagePerformanceBenchmark._internal();

  // 성능 측정 데이터
  final List<ImageLoadMetric> _loadMetrics = [];
  final List<MemoryUsageSnapshot> _memorySnapshots = [];

  // 벤치마크 설정
  late BenchmarkConfig _config;
  bool _isRunning = false;
  Timer? _memoryMonitorTimer;

  /// 벤치마크 초기화
  void initialize({BenchmarkConfig? config}) {
    _config = config ?? BenchmarkConfig.defaultConfig();
    // 디버그 모드에서만 로그 출력
    if (kDebugMode) {
      logger.throttledWarn(
        'ImagePerformanceBenchmark 초기화 완료',
        'benchmark_init',
        throttleDuration: const Duration(minutes: 30), // 30분마다 한 번만 출력
      );
    }
  }

  /// 벤치마크 시작
  void startBenchmark({String? testName}) {
    if (_isRunning) {
      // 디버그 모드에서만 경고 출력
      if (kDebugMode) {
        logger.throttledWarn(
          '벤치마크가 이미 실행 중입니다',
          'benchmark_already_running',
          throttleDuration: const Duration(minutes: 5),
        );
      }
      return;
    }

    _isRunning = true;
    _loadMetrics.clear();
    _memorySnapshots.clear();

    // 메모리 모니터링 시작
    _startMemoryMonitoring();

    // 초기 메모리 스냅샷
    _takeMemorySnapshot('benchmark_start');

    // 디버그 모드에서만 로그 출력
    if (kDebugMode) {
      logger.throttledWarn(
        '이미지 성능 벤치마크 시작: ${testName ?? 'unnamed'}',
        'benchmark_start_${testName ?? 'unnamed'}',
        throttleDuration: const Duration(minutes: 10),
      );
    }
  }

  /// 벤치마크 중지
  BenchmarkResult stopBenchmark({String? testName}) {
    if (!_isRunning) {
      // 디버그 모드에서만 경고 출력
      if (kDebugMode) {
        logger.throttledWarn(
          '벤치마크가 실행 중이 아닙니다',
          'benchmark_not_running',
          throttleDuration: const Duration(minutes: 5),
        );
      }
      return BenchmarkResult.empty();
    }

    _isRunning = false;
    _stopMemoryMonitoring();

    // 최종 메모리 스냅샷
    _takeMemorySnapshot('benchmark_end');

    final result = _generateBenchmarkResult(testName ?? 'unnamed');

    // 디버그 모드에서만 로그 출력
    if (kDebugMode) {
      logger.throttledWarn(
        '이미지 성능 벤치마크 완료: ${testName ?? 'unnamed'}',
        'benchmark_complete_${testName ?? 'unnamed'}',
        throttleDuration: const Duration(minutes: 10),
      );
    }

    return result;
  }

  /// 이미지 로딩 시작 추적
  void trackImageLoadStart(String imageUrl, {Map<String, dynamic>? metadata}) {
    if (!_isRunning) return;

    final metric = ImageLoadMetric(
      imageUrl: imageUrl,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    _loadMetrics.add(metric);
  }

  /// 이미지 로딩 완료 추적
  void trackImageLoadComplete(
    String imageUrl,
    bool success, {
    int? imageSizeBytes,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isRunning) return;

    // 해당 URL의 시작 메트릭 찾기
    final startMetric = _loadMetrics
        .where((m) => m.imageUrl == imageUrl && m.endTime == null)
        .lastOrNull;

    if (startMetric != null) {
      startMetric.endTime = DateTime.now();
      startMetric.success = success;
      startMetric.imageSizeBytes = imageSizeBytes;
      startMetric.metadata.addAll(metadata ?? {});
    }
  }

  /// 메모리 모니터링 시작
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(_config.memoryCheckInterval, (timer) {
      _takeMemorySnapshot('periodic_check');
    });
  }

  /// 메모리 모니터링 중지
  void _stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
  }

  /// 메모리 스냅샷 생성
  void _takeMemorySnapshot(String label) {
    final imageCache = PaintingBinding.instance.imageCache;

    final snapshot = MemoryUsageSnapshot(
      timestamp: DateTime.now(),
      label: label,
      imageCacheSize: imageCache.currentSizeBytes,
      imageCacheCount: imageCache.liveImageCount,
      maxImageCacheSize: imageCache.maximumSizeBytes,
    );

    _memorySnapshots.add(snapshot);
  }

  /// 벤치마크 결과 생성
  BenchmarkResult _generateBenchmarkResult(String testName) {
    final completedMetrics =
        _loadMetrics.where((m) => m.endTime != null).toList();

    if (completedMetrics.isEmpty) {
      return BenchmarkResult.empty();
    }

    // 로딩 시간 통계
    final loadTimes = completedMetrics
        .map((m) => m.endTime!.difference(m.startTime).inMilliseconds)
        .toList();

    final averageLoadTime = loadTimes.isNotEmpty
        ? loadTimes.reduce((a, b) => a + b) / loadTimes.length
        : 0.0;

    final minLoadTime =
        loadTimes.isNotEmpty ? loadTimes.reduce((a, b) => a < b ? a : b) : 0;
    final maxLoadTime =
        loadTimes.isNotEmpty ? loadTimes.reduce((a, b) => a > b ? a : b) : 0;

    // 성공률 계산
    final successCount = completedMetrics.where((m) => m.success).length;
    final successRate = successCount / completedMetrics.length;

    // 메모리 사용량 통계
    final memorySizes = _memorySnapshots.map((s) => s.imageCacheSize).toList();
    final averageMemoryUsage = memorySizes.isNotEmpty
        ? memorySizes.reduce((a, b) => a + b) / memorySizes.length
        : 0.0;

    final maxMemoryUsage = memorySizes.isNotEmpty
        ? memorySizes.reduce((a, b) => a > b ? a : b)
        : 0;

    // 이미지 크기 통계
    final imageSizes = completedMetrics
        .where((m) => m.imageSizeBytes != null)
        .map((m) => m.imageSizeBytes!)
        .toList();

    final averageImageSize = imageSizes.isNotEmpty
        ? imageSizes.reduce((a, b) => a + b) / imageSizes.length
        : 0.0;

    return BenchmarkResult(
      testName: testName,
      totalImages: completedMetrics.length,
      successfulLoads: successCount,
      failedLoads: completedMetrics.length - successCount,
      successRate: successRate,
      averageLoadTimeMs: averageLoadTime,
      minLoadTimeMs: minLoadTime.toDouble(),
      maxLoadTimeMs: maxLoadTime.toDouble(),
      averageMemoryUsageMB: averageMemoryUsage / (1024 * 1024),
      maxMemoryUsageMB: maxMemoryUsage / (1024 * 1024),
      averageImageSizeKB: averageImageSize / 1024,
      memorySnapshots: List.from(_memorySnapshots),
      loadMetrics: List.from(completedMetrics),
      timestamp: DateTime.now(),
    );
  }

  /// 두 벤치마크 결과 비교
  static BenchmarkComparison compare(
    BenchmarkResult baseline,
    BenchmarkResult optimized,
  ) {
    final loadTimeImprovement = baseline.averageLoadTimeMs > 0
        ? ((baseline.averageLoadTimeMs - optimized.averageLoadTimeMs) /
                baseline.averageLoadTimeMs) *
            100
        : 0.0;

    final memoryImprovement = baseline.averageMemoryUsageMB > 0
        ? ((baseline.averageMemoryUsageMB - optimized.averageMemoryUsageMB) /
                baseline.averageMemoryUsageMB) *
            100
        : 0.0;

    final successRateChange =
        (optimized.successRate - baseline.successRate) * 100;

    return BenchmarkComparison(
      baseline: baseline,
      optimized: optimized,
      loadTimeImprovementPercent: loadTimeImprovement,
      memoryUsageImprovementPercent: memoryImprovement,
      successRateChangePercent: successRateChange,
      generatedAt: DateTime.now(),
    );
  }

  /// 벤치마크 리포트 출력
  void printBenchmarkReport(BenchmarkResult result) {
    // 디버그 모드에서만 리포트 출력
    if (kDebugMode) {
      logger.throttledWarn('''
=== 이미지 성능 벤치마크 리포트 ===
테스트명: ${result.testName}
측정 시간: ${result.timestamp}

📊 로딩 성능:
- 총 이미지 수: ${result.totalImages}
- 성공률: ${(result.successRate * 100).toStringAsFixed(1)}%
- 평균 로딩 시간: ${result.averageLoadTimeMs.toStringAsFixed(1)}ms
- 최소 로딩 시간: ${result.minLoadTimeMs.toStringAsFixed(1)}ms
- 최대 로딩 시간: ${result.maxLoadTimeMs.toStringAsFixed(1)}ms

💾 메모리 사용량:
- 평균 메모리 사용량: ${result.averageMemoryUsageMB.toStringAsFixed(1)}MB
- 최대 메모리 사용량: ${result.maxMemoryUsageMB.toStringAsFixed(1)}MB

📷 이미지 크기:
- 평균 이미지 크기: ${result.averageImageSizeKB.toStringAsFixed(1)}KB

=====================================
''', 'benchmark_report_${result.testName}',
          throttleDuration: const Duration(minutes: 15));
    }
  }

  /// 비교 리포트 출력
  void printComparisonReport(BenchmarkComparison comparison) {
    // 디버그 모드에서만 리포트 출력
    if (kDebugMode) {
      logger.throttledWarn('''
=== 이미지 최적화 효과 비교 리포트 ===

🚀 성능 개선:
- 로딩 시간: ${comparison.loadTimeImprovementPercent.toStringAsFixed(1)}% 개선
- 메모리 사용량: ${comparison.memoryUsageImprovementPercent.toStringAsFixed(1)}% 개선
- 성공률: ${comparison.successRateChangePercent >= 0 ? '+' : ''}${comparison.successRateChangePercent.toStringAsFixed(1)}% 변화

📈 상세 비교:
기존 시스템:
- 평균 로딩 시간: ${comparison.baseline.averageLoadTimeMs.toStringAsFixed(1)}ms
- 평균 메모리 사용량: ${comparison.baseline.averageMemoryUsageMB.toStringAsFixed(1)}MB
- 성공률: ${(comparison.baseline.successRate * 100).toStringAsFixed(1)}%

최적화 시스템:
- 평균 로딩 시간: ${comparison.optimized.averageLoadTimeMs.toStringAsFixed(1)}ms
- 평균 메모리 사용량: ${comparison.optimized.averageMemoryUsageMB.toStringAsFixed(1)}MB
- 성공률: ${(comparison.optimized.successRate * 100).toStringAsFixed(1)}%

=====================================
''', 'comparison_report', throttleDuration: const Duration(minutes: 15));
    }
  }

  /// 리소스 정리
  void dispose() {
    _stopMemoryMonitoring();
    _loadMetrics.clear();
    _memorySnapshots.clear();
    _isRunning = false;

    // 디버그 모드에서만 로그 출력
    if (kDebugMode) {
      logger.throttledWarn(
        'ImagePerformanceBenchmark 리소스 정리 완료',
        'benchmark_dispose',
        throttleDuration: const Duration(minutes: 30),
      );
    }
  }
}

/// 벤치마크 설정
class BenchmarkConfig {
  final Duration memoryCheckInterval;
  final int maxMetricsCount;

  const BenchmarkConfig({
    required this.memoryCheckInterval,
    required this.maxMetricsCount,
  });

  factory BenchmarkConfig.defaultConfig() {
    return const BenchmarkConfig(
      memoryCheckInterval: Duration(seconds: 5),
      maxMetricsCount: 1000,
    );
  }
}

/// 이미지 로딩 메트릭
class ImageLoadMetric {
  final String imageUrl;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  DateTime? endTime;
  bool success = false;
  int? imageSizeBytes;

  ImageLoadMetric({
    required this.imageUrl,
    required this.startTime,
    required this.metadata,
  });

  Duration? get loadDuration => endTime?.difference(startTime);
}

/// 메모리 사용량 스냅샷
class MemoryUsageSnapshot {
  final DateTime timestamp;
  final String label;
  final int imageCacheSize;
  final int imageCacheCount;
  final int maxImageCacheSize;

  const MemoryUsageSnapshot({
    required this.timestamp,
    required this.label,
    required this.imageCacheSize,
    required this.imageCacheCount,
    required this.maxImageCacheSize,
  });

  double get memoryUsageRatio => imageCacheSize / maxImageCacheSize;
  double get sizeMB => imageCacheSize / (1024 * 1024);
}

/// 벤치마크 결과
class BenchmarkResult {
  final String testName;
  final int totalImages;
  final int successfulLoads;
  final int failedLoads;
  final double successRate;
  final double averageLoadTimeMs;
  final double minLoadTimeMs;
  final double maxLoadTimeMs;
  final double averageMemoryUsageMB;
  final double maxMemoryUsageMB;
  final double averageImageSizeKB;
  final List<MemoryUsageSnapshot> memorySnapshots;
  final List<ImageLoadMetric> loadMetrics;
  final DateTime timestamp;

  const BenchmarkResult({
    required this.testName,
    required this.totalImages,
    required this.successfulLoads,
    required this.failedLoads,
    required this.successRate,
    required this.averageLoadTimeMs,
    required this.minLoadTimeMs,
    required this.maxLoadTimeMs,
    required this.averageMemoryUsageMB,
    required this.maxMemoryUsageMB,
    required this.averageImageSizeKB,
    required this.memorySnapshots,
    required this.loadMetrics,
    required this.timestamp,
  });

  factory BenchmarkResult.empty() {
    return BenchmarkResult(
      testName: 'empty',
      totalImages: 0,
      successfulLoads: 0,
      failedLoads: 0,
      successRate: 0.0,
      averageLoadTimeMs: 0.0,
      minLoadTimeMs: 0.0,
      maxLoadTimeMs: 0.0,
      averageMemoryUsageMB: 0.0,
      maxMemoryUsageMB: 0.0,
      averageImageSizeKB: 0.0,
      memorySnapshots: [],
      loadMetrics: [],
      timestamp: DateTime.now(),
    );
  }
}

/// 벤치마크 비교 결과
class BenchmarkComparison {
  final BenchmarkResult baseline;
  final BenchmarkResult optimized;
  final double loadTimeImprovementPercent;
  final double memoryUsageImprovementPercent;
  final double successRateChangePercent;
  final DateTime generatedAt;

  const BenchmarkComparison({
    required this.baseline,
    required this.optimized,
    required this.loadTimeImprovementPercent,
    required this.memoryUsageImprovementPercent,
    required this.successRateChangePercent,
    required this.generatedAt,
  });

  bool get hasImprovement =>
      loadTimeImprovementPercent > 0 || memoryUsageImprovementPercent > 0;

  String get improvementSummary {
    final improvements = <String>[];

    if (loadTimeImprovementPercent > 0) {
      improvements
          .add('로딩 시간 ${loadTimeImprovementPercent.toStringAsFixed(1)}% 개선');
    }

    if (memoryUsageImprovementPercent > 0) {
      improvements.add(
          '메모리 사용량 ${memoryUsageImprovementPercent.toStringAsFixed(1)}% 개선');
    }

    if (successRateChangePercent > 0) {
      improvements
          .add('성공률 ${successRateChangePercent.toStringAsFixed(1)}% 향상');
    }

    return improvements.isNotEmpty ? improvements.join(', ') : '개선 효과 없음';
  }
}
