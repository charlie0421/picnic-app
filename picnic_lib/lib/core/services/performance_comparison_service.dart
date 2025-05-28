import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:picnic_lib/core/services/image_cache_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 성능 비교 분석을 위한 서비스
/// 기존 시스템과 최적화된 시스템의 성능을 비교하고 개선 효과를 측정합니다.
class PerformanceComparisonService {
  static final PerformanceComparisonService _instance =
      PerformanceComparisonService._internal();
  factory PerformanceComparisonService() => _instance;
  PerformanceComparisonService._internal();

  // 의존성

  // 성능 측정 데이터
  final List<PerformanceMeasurement> _measurements = [];
  PerformanceBaseline? _baseline;

  /// 기준점 설정
  Future<void> setBaseline({
    required String testName,
    Map<String, dynamic>? metadata,
  }) async {
    logger.i('성능 기준점 설정 시작: $testName');

    final measurement = await _takeMeasurement(testName, metadata);
    _baseline = PerformanceBaseline(
      testName: testName,
      timestamp: DateTime.now(),
      measurement: measurement,
      metadata: metadata ?? {},
    );

    // SharedPreferences에 저장
    await _saveBaseline();

    logger.i('성능 기준점 설정 완료: $testName');
  }

  /// 기준점 로드
  Future<void> loadBaseline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baselineJson = prefs.getString('performance_baseline');

      if (baselineJson != null) {
        final data = jsonDecode(baselineJson);
        _baseline = PerformanceBaseline.fromJson(data);
        logger.i('성능 기준점 로드 완료: ${_baseline?.testName}');
      }
    } catch (e) {
      logger.e('성능 기준점 로드 실패', error: e);
    }
  }

  /// 기준점 저장
  Future<void> _saveBaseline() async {
    if (_baseline == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final baselineJson = jsonEncode(_baseline!.toJson());
      await prefs.setString('performance_baseline', baselineJson);
    } catch (e) {
      logger.e('성능 기준점 저장 실패', error: e);
    }
  }

  /// 현재 성능 측정
  Future<PerformanceMeasurement> measureCurrentPerformance({
    required String testName,
    Map<String, dynamic>? metadata,
  }) async {
    logger.i('현재 성능 측정 시작: $testName');

    final measurement = await _takeMeasurement(testName, metadata);
    _measurements.add(measurement);

    logger.i('현재 성능 측정 완료: $testName');
    return measurement;
  }

  /// 성능 측정 실행
  Future<PerformanceMeasurement> _takeMeasurement(
    String testName,
    Map<String, dynamic>? metadata,
  ) async {
    final startTime = DateTime.now();

    // 시스템 메모리 정보
    final systemMemory = await _getSystemMemoryInfo();

    // 이미지 캐시 통계
    final cacheStats = ImageCacheService().getCacheStats();

    // 성능 벤치마크 통계
    final benchmarkStats = null; // _benchmark.getStats();

    // 메모리 프로파일러 통계
    final memoryStats = null; // _memoryProfiler.getStats();

    // Flutter 이미지 캐시 정보
    final flutterImageCache = _getFlutterImageCacheInfo();

    final endTime = DateTime.now();
    final measurementDuration = endTime.difference(startTime);

    return PerformanceMeasurement(
      testName: testName,
      timestamp: startTime,
      measurementDuration: measurementDuration,
      systemMemory: systemMemory,
      cacheStats: cacheStats,
      benchmarkStats: benchmarkStats,
      memoryStats: memoryStats,
      flutterImageCache: flutterImageCache,
      metadata: metadata ?? {},
    );
  }

  /// 시스템 메모리 정보 수집
  Future<SystemMemoryInfo> _getSystemMemoryInfo() async {
    try {
      // Flutter의 메모리 정보는 제한적이므로 가능한 정보만 수집
      final runtimeType = kDebugMode ? 'debug' : 'release';

      return SystemMemoryInfo(
        totalMemoryMB: 0, // 플랫폼별로 구현 필요
        usedMemoryMB: 0, // 플랫폼별로 구현 필요
        availableMemoryMB: 0, // 플랫폼별로 구현 필요
        buildType: runtimeType,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      logger.e('시스템 메모리 정보 수집 실패', error: e);
      return SystemMemoryInfo(
        totalMemoryMB: 0,
        usedMemoryMB: 0,
        availableMemoryMB: 0,
        buildType: 'unknown',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Flutter 이미지 캐시 정보 수집
  FlutterImageCacheInfo _getFlutterImageCacheInfo() {
    final imageCache = PaintingBinding.instance.imageCache;

    return FlutterImageCacheInfo(
      currentSizeBytes: imageCache.currentSizeBytes,
      maximumSizeBytes: imageCache.maximumSizeBytes,
      currentImageCount: imageCache.liveImageCount,
      maximumImageCount: imageCache.maximumSize,
      pendingImageCount: imageCache.pendingImageCount,
      timestamp: DateTime.now(),
    );
  }

  /// 성능 비교 리포트 생성
  PerformanceComparisonReport generateComparisonReport({
    PerformanceMeasurement? currentMeasurement,
  }) {
    if (_baseline == null) {
      throw StateError('기준점이 설정되지 않았습니다. setBaseline()을 먼저 호출하세요.');
    }

    final current = currentMeasurement ?? _measurements.lastOrNull;
    if (current == null) {
      throw StateError('비교할 측정 데이터가 없습니다.');
    }

    return PerformanceComparisonReport(
      baseline: _baseline!,
      current: current,
      improvements: _calculateImprovements(_baseline!.measurement, current),
      generatedAt: DateTime.now(),
    );
  }

  /// 개선 효과 계산
  PerformanceImprovements _calculateImprovements(
    PerformanceMeasurement baseline,
    PerformanceMeasurement current,
  ) {
    // 메모리 사용량 개선
    final memoryImprovement = _calculateMemoryImprovement(baseline, current);

    // 로딩 성능 개선
    final loadingImprovement = _calculateLoadingImprovement(baseline, current);

    // 캐시 성능 개선
    final cacheImprovement = _calculateCacheImprovement(baseline, current);

    return PerformanceImprovements(
      memoryImprovement: memoryImprovement,
      loadingImprovement: loadingImprovement,
      cacheImprovement: cacheImprovement,
    );
  }

  /// 메모리 사용량 개선 계산
  MemoryImprovement _calculateMemoryImprovement(
    PerformanceMeasurement baseline,
    PerformanceMeasurement current,
  ) {
    final baselineBytes = baseline.flutterImageCache.currentSizeBytes;
    final currentBytes = current.flutterImageCache.currentSizeBytes;

    final absoluteReduction = baselineBytes - currentBytes;
    final percentageReduction =
        baselineBytes > 0 ? (absoluteReduction / baselineBytes) * 100 : 0.0;

    return MemoryImprovement(
      baselineMemoryMB: baselineBytes / (1024 * 1024),
      currentMemoryMB: currentBytes / (1024 * 1024),
      absoluteReductionMB: absoluteReduction / (1024 * 1024),
      percentageReduction: percentageReduction,
    );
  }

  /// 로딩 성능 개선 계산
  LoadingImprovement _calculateLoadingImprovement(
    PerformanceMeasurement baseline,
    PerformanceMeasurement current,
  ) {
    final baselineAvgTime = baseline.benchmarkStats?.averageLoadTime ?? 0.0;
    final currentAvgTime = current.benchmarkStats?.averageLoadTime ?? 0.0;

    final timeReduction = baselineAvgTime - currentAvgTime;
    final percentageImprovement =
        baselineAvgTime > 0 ? (timeReduction / baselineAvgTime) * 100 : 0.0;

    final baselineSuccessRate = baseline.benchmarkStats?.successRate ?? 0.0;
    final currentSuccessRate = current.benchmarkStats?.successRate ?? 0.0;

    return LoadingImprovement(
      baselineAverageTimeMs: baselineAvgTime,
      currentAverageTimeMs: currentAvgTime,
      timeReductionMs: timeReduction,
      percentageImprovement: percentageImprovement,
      baselineSuccessRate: baselineSuccessRate,
      currentSuccessRate: currentSuccessRate,
    );
  }

  /// 캐시 성능 개선 계산
  CacheImprovement _calculateCacheImprovement(
    PerformanceMeasurement baseline,
    PerformanceMeasurement current,
  ) {
    final baselineHitRate = baseline.cacheStats?.hitRate ?? 0.0;
    final currentHitRate = current.cacheStats?.hitRate ?? 0.0;

    final hitRateImprovement = currentHitRate - baselineHitRate;

    return CacheImprovement(
      baselineHitRate: baselineHitRate,
      currentHitRate: currentHitRate,
      hitRateImprovement: hitRateImprovement,
    );
  }

  /// 리포트를 JSON으로 내보내기
  Map<String, dynamic> exportReportAsJson(PerformanceComparisonReport report) {
    return report.toJson();
  }

  /// 리포트를 사람이 읽기 쉬운 형태로 포맷팅
  String formatReportAsText(PerformanceComparisonReport report) {
    final buffer = StringBuffer();

    buffer.writeln('📊 성능 비교 리포트');
    buffer.writeln('=' * 50);
    buffer.writeln();

    // 기본 정보
    buffer.writeln('🔍 테스트 정보');
    buffer.writeln('기준점: ${report.baseline.testName}');
    buffer.writeln('현재: ${report.current.testName}');
    buffer.writeln('생성일: ${report.generatedAt}');
    buffer.writeln();

    // 메모리 개선
    final memory = report.improvements.memoryImprovement;
    buffer.writeln('💾 메모리 사용량');
    buffer.writeln('기준점: ${memory.baselineMemoryMB.toStringAsFixed(2)} MB');
    buffer.writeln('현재: ${memory.currentMemoryMB.toStringAsFixed(2)} MB');
    buffer.writeln('절약: ${memory.absoluteReductionMB.toStringAsFixed(2)} MB '
        '(${memory.percentageReduction.toStringAsFixed(1)}%)');
    buffer.writeln();

    // 로딩 성능 개선
    final loading = report.improvements.loadingImprovement;
    buffer.writeln('⚡ 로딩 성능');
    buffer.writeln(
        '기준점 평균: ${loading.baselineAverageTimeMs.toStringAsFixed(1)} ms');
    buffer.writeln(
        '현재 평균: ${loading.currentAverageTimeMs.toStringAsFixed(1)} ms');
    buffer.writeln('개선: ${loading.timeReductionMs.toStringAsFixed(1)} ms '
        '(${loading.percentageImprovement.toStringAsFixed(1)}%)');
    buffer.writeln('성공률: ${loading.baselineSuccessRate.toStringAsFixed(1)}% → '
        '${loading.currentSuccessRate.toStringAsFixed(1)}%');
    buffer.writeln();

    // 캐시 성능 개선
    final cache = report.improvements.cacheImprovement;
    buffer.writeln('🗄️ 캐시 성능');
    buffer.writeln('기준점 히트율: ${cache.baselineHitRate.toStringAsFixed(1)}%');
    buffer.writeln('현재 히트율: ${cache.currentHitRate.toStringAsFixed(1)}%');
    buffer.writeln('개선: ${cache.hitRateImprovement.toStringAsFixed(1)}%p');
    buffer.writeln();

    return buffer.toString();
  }

  /// 모든 측정 데이터 클리어
  void clearMeasurements() {
    _measurements.clear();
    logger.i('모든 성능 측정 데이터가 클리어되었습니다.');
  }

  /// 통계 정보 가져오기
  Map<String, dynamic> getStatistics() {
    return {
      'total_measurements': _measurements.length,
      'has_baseline': _baseline != null,
      'baseline_test_name': _baseline?.testName,
      'latest_measurement': _measurements.lastOrNull?.testName,
    };
  }
}

// 데이터 클래스들
class PerformanceBaseline {
  final String testName;
  final DateTime timestamp;
  final PerformanceMeasurement measurement;
  final Map<String, dynamic> metadata;

  PerformanceBaseline({
    required this.testName,
    required this.timestamp,
    required this.measurement,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'testName': testName,
        'timestamp': timestamp.toIso8601String(),
        'measurement': measurement.toJson(),
        'metadata': metadata,
      };

  factory PerformanceBaseline.fromJson(Map<String, dynamic> json) =>
      PerformanceBaseline(
        testName: json['testName'],
        timestamp: DateTime.parse(json['timestamp']),
        measurement: PerformanceMeasurement.fromJson(json['measurement']),
        metadata: Map<String, dynamic>.from(json['metadata']),
      );
}

class PerformanceMeasurement {
  final String testName;
  final DateTime timestamp;
  final Duration measurementDuration;
  final SystemMemoryInfo systemMemory;
  final dynamic cacheStats; // ImageCacheStats
  final dynamic benchmarkStats; // BenchmarkStats
  final dynamic memoryStats; // ImageMemoryStats
  final FlutterImageCacheInfo flutterImageCache;
  final Map<String, dynamic> metadata;

  PerformanceMeasurement({
    required this.testName,
    required this.timestamp,
    required this.measurementDuration,
    required this.systemMemory,
    required this.cacheStats,
    required this.benchmarkStats,
    required this.memoryStats,
    required this.flutterImageCache,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'testName': testName,
        'timestamp': timestamp.toIso8601String(),
        'measurementDurationMs': measurementDuration.inMilliseconds,
        'systemMemory': systemMemory.toJson(),
        'flutterImageCache': flutterImageCache.toJson(),
        'metadata': metadata,
      };

  factory PerformanceMeasurement.fromJson(Map<String, dynamic> json) =>
      PerformanceMeasurement(
        testName: json['testName'],
        timestamp: DateTime.parse(json['timestamp']),
        measurementDuration:
            Duration(milliseconds: json['measurementDurationMs']),
        systemMemory: SystemMemoryInfo.fromJson(json['systemMemory']),
        cacheStats: null,
        benchmarkStats: null,
        memoryStats: null,
        flutterImageCache:
            FlutterImageCacheInfo.fromJson(json['flutterImageCache']),
        metadata: Map<String, dynamic>.from(json['metadata']),
      );
}

class SystemMemoryInfo {
  final double totalMemoryMB;
  final double usedMemoryMB;
  final double availableMemoryMB;
  final String buildType;
  final DateTime timestamp;

  SystemMemoryInfo({
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.buildType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'totalMemoryMB': totalMemoryMB,
        'usedMemoryMB': usedMemoryMB,
        'availableMemoryMB': availableMemoryMB,
        'buildType': buildType,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SystemMemoryInfo.fromJson(Map<String, dynamic> json) =>
      SystemMemoryInfo(
        totalMemoryMB: json['totalMemoryMB'],
        usedMemoryMB: json['usedMemoryMB'],
        availableMemoryMB: json['availableMemoryMB'],
        buildType: json['buildType'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class FlutterImageCacheInfo {
  final int currentSizeBytes;
  final int maximumSizeBytes;
  final int currentImageCount;
  final int maximumImageCount;
  final int pendingImageCount;
  final DateTime timestamp;

  FlutterImageCacheInfo({
    required this.currentSizeBytes,
    required this.maximumSizeBytes,
    required this.currentImageCount,
    required this.maximumImageCount,
    required this.pendingImageCount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'currentSizeBytes': currentSizeBytes,
        'maximumSizeBytes': maximumSizeBytes,
        'currentImageCount': currentImageCount,
        'maximumImageCount': maximumImageCount,
        'pendingImageCount': pendingImageCount,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FlutterImageCacheInfo.fromJson(Map<String, dynamic> json) =>
      FlutterImageCacheInfo(
        currentSizeBytes: json['currentSizeBytes'],
        maximumSizeBytes: json['maximumSizeBytes'],
        currentImageCount: json['currentImageCount'],
        maximumImageCount: json['maximumImageCount'],
        pendingImageCount: json['pendingImageCount'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class PerformanceComparisonReport {
  final PerformanceBaseline baseline;
  final PerformanceMeasurement current;
  final PerformanceImprovements improvements;
  final DateTime generatedAt;

  PerformanceComparisonReport({
    required this.baseline,
    required this.current,
    required this.improvements,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'baseline': baseline.toJson(),
        'current': current.toJson(),
        'improvements': improvements.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };
}

class PerformanceImprovements {
  final MemoryImprovement memoryImprovement;
  final LoadingImprovement loadingImprovement;
  final CacheImprovement cacheImprovement;

  PerformanceImprovements({
    required this.memoryImprovement,
    required this.loadingImprovement,
    required this.cacheImprovement,
  });

  Map<String, dynamic> toJson() => {
        'memoryImprovement': memoryImprovement.toJson(),
        'loadingImprovement': loadingImprovement.toJson(),
        'cacheImprovement': cacheImprovement.toJson(),
      };
}

class MemoryImprovement {
  final double baselineMemoryMB;
  final double currentMemoryMB;
  final double absoluteReductionMB;
  final double percentageReduction;

  MemoryImprovement({
    required this.baselineMemoryMB,
    required this.currentMemoryMB,
    required this.absoluteReductionMB,
    required this.percentageReduction,
  });

  Map<String, dynamic> toJson() => {
        'baselineMemoryMB': baselineMemoryMB,
        'currentMemoryMB': currentMemoryMB,
        'absoluteReductionMB': absoluteReductionMB,
        'percentageReduction': percentageReduction,
      };
}

class LoadingImprovement {
  final double baselineAverageTimeMs;
  final double currentAverageTimeMs;
  final double timeReductionMs;
  final double percentageImprovement;
  final double baselineSuccessRate;
  final double currentSuccessRate;

  LoadingImprovement({
    required this.baselineAverageTimeMs,
    required this.currentAverageTimeMs,
    required this.timeReductionMs,
    required this.percentageImprovement,
    required this.baselineSuccessRate,
    required this.currentSuccessRate,
  });

  Map<String, dynamic> toJson() => {
        'baselineAverageTimeMs': baselineAverageTimeMs,
        'currentAverageTimeMs': currentAverageTimeMs,
        'timeReductionMs': timeReductionMs,
        'percentageImprovement': percentageImprovement,
        'baselineSuccessRate': baselineSuccessRate,
        'currentSuccessRate': currentSuccessRate,
      };
}

class CacheImprovement {
  final double baselineHitRate;
  final double currentHitRate;
  final double hitRateImprovement;

  CacheImprovement({
    required this.baselineHitRate,
    required this.currentHitRate,
    required this.hitRateImprovement,
  });

  Map<String, dynamic> toJson() => {
        'baselineHitRate': baselineHitRate,
        'currentHitRate': currentHitRate,
        'hitRateImprovement': hitRateImprovement,
      };
}

// 확장 메서드
extension ListExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
