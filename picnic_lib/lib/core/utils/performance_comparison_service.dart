import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/services/asset_loading_service.dart';
import 'package:picnic_lib/core/services/font_optimization_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/startup_performance_analyzer.dart';
import 'package:universal_platform/universal_platform.dart';

/// 성능 비교 데이터 구조
class PerformanceComparison {
  final DateTime timestamp;
  final PerformanceMetrics beforeOptimization;
  final PerformanceMetrics afterOptimization;
  final Map<String, dynamic> improvements;
  final List<String> recommendedNextSteps;

  const PerformanceComparison({
    required this.timestamp,
    required this.beforeOptimization,
    required this.afterOptimization,
    required this.improvements,
    required this.recommendedNextSteps,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'beforeOptimization': beforeOptimization.toJson(),
        'afterOptimization': afterOptimization.toJson(),
        'improvements': improvements,
        'recommendedNextSteps': recommendedNextSteps,
      };

  factory PerformanceComparison.fromJson(Map<String, dynamic> json) =>
      PerformanceComparison(
        timestamp: DateTime.parse(json['timestamp']),
        beforeOptimization:
            PerformanceMetrics.fromJson(json['beforeOptimization']),
        afterOptimization:
            PerformanceMetrics.fromJson(json['afterOptimization']),
        improvements: Map<String, dynamic>.from(json['improvements']),
        recommendedNextSteps: List<String>.from(json['recommendedNextSteps']),
      );
}

/// 확장된 성능 메트릭
class PerformanceMetrics {
  final double totalStartupTime;
  final Map<String, double> stageTimings;
  final MemoryMetrics memoryUsage;
  final AssetMetrics assetMetrics;
  final UserExperienceMetrics uxMetrics;
  final int performanceScore;
  final List<String> bottlenecks;

  const PerformanceMetrics({
    required this.totalStartupTime,
    required this.stageTimings,
    required this.memoryUsage,
    required this.assetMetrics,
    required this.uxMetrics,
    required this.performanceScore,
    required this.bottlenecks,
  });

  Map<String, dynamic> toJson() => {
        'totalStartupTime': totalStartupTime,
        'stageTimings': stageTimings,
        'memoryUsage': memoryUsage.toJson(),
        'assetMetrics': assetMetrics.toJson(),
        'uxMetrics': uxMetrics.toJson(),
        'performanceScore': performanceScore,
        'bottlenecks': bottlenecks,
      };

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      PerformanceMetrics(
        totalStartupTime: json['totalStartupTime'].toDouble(),
        stageTimings: Map<String, double>.from(json['stageTimings']),
        memoryUsage: MemoryMetrics.fromJson(json['memoryUsage']),
        assetMetrics: AssetMetrics.fromJson(json['assetMetrics']),
        uxMetrics: UserExperienceMetrics.fromJson(json['uxMetrics']),
        performanceScore: json['performanceScore'],
        bottlenecks: List<String>.from(json['bottlenecks']),
      );
}

/// 메모리 사용량 메트릭
class MemoryMetrics {
  final double totalMemoryUsage; // MB
  final double fontMemoryUsage; // MB
  final double assetMemoryUsage; // MB
  final double appMemoryUsage; // MB

  const MemoryMetrics({
    required this.totalMemoryUsage,
    required this.fontMemoryUsage,
    required this.assetMemoryUsage,
    required this.appMemoryUsage,
  });

  Map<String, dynamic> toJson() => {
        'totalMemoryUsage': totalMemoryUsage,
        'fontMemoryUsage': fontMemoryUsage,
        'assetMemoryUsage': assetMemoryUsage,
        'appMemoryUsage': appMemoryUsage,
      };

  factory MemoryMetrics.fromJson(Map<String, dynamic> json) => MemoryMetrics(
        totalMemoryUsage: json['totalMemoryUsage'].toDouble(),
        fontMemoryUsage: json['fontMemoryUsage'].toDouble(),
        assetMemoryUsage: json['assetMemoryUsage'].toDouble(),
        appMemoryUsage: json['appMemoryUsage'].toDouble(),
      );
}

/// 에셋 로딩 메트릭
class AssetMetrics {
  final int totalAssets;
  final int criticalAssetsLoaded;
  final double assetLoadingTime;
  final double fontLoadingTime;
  final Map<String, int> assetsByPriority;

  const AssetMetrics({
    required this.totalAssets,
    required this.criticalAssetsLoaded,
    required this.assetLoadingTime,
    required this.fontLoadingTime,
    required this.assetsByPriority,
  });

  Map<String, dynamic> toJson() => {
        'totalAssets': totalAssets,
        'criticalAssetsLoaded': criticalAssetsLoaded,
        'assetLoadingTime': assetLoadingTime,
        'fontLoadingTime': fontLoadingTime,
        'assetsByPriority': assetsByPriority,
      };

  factory AssetMetrics.fromJson(Map<String, dynamic> json) => AssetMetrics(
        totalAssets: json['totalAssets'],
        criticalAssetsLoaded: json['criticalAssetsLoaded'],
        assetLoadingTime: json['assetLoadingTime'].toDouble(),
        fontLoadingTime: json['fontLoadingTime'].toDouble(),
        assetsByPriority: Map<String, int>.from(json['assetsByPriority']),
      );
}

/// 사용자 경험 메트릭
class UserExperienceMetrics {
  final double timeToFirstFrame;
  final double timeToInteractive;
  final double splashScreenDuration;
  final bool hasProgressIndicator;
  final bool hasSmoothTransitions;

  const UserExperienceMetrics({
    required this.timeToFirstFrame,
    required this.timeToInteractive,
    required this.splashScreenDuration,
    required this.hasProgressIndicator,
    required this.hasSmoothTransitions,
  });

  Map<String, dynamic> toJson() => {
        'timeToFirstFrame': timeToFirstFrame,
        'timeToInteractive': timeToInteractive,
        'splashScreenDuration': splashScreenDuration,
        'hasProgressIndicator': hasProgressIndicator,
        'hasSmoothTransitions': hasSmoothTransitions,
      };

  factory UserExperienceMetrics.fromJson(Map<String, dynamic> json) =>
      UserExperienceMetrics(
        timeToFirstFrame: json['timeToFirstFrame'].toDouble(),
        timeToInteractive: json['timeToInteractive'].toDouble(),
        splashScreenDuration: json['splashScreenDuration'].toDouble(),
        hasProgressIndicator: json['hasProgressIndicator'],
        hasSmoothTransitions: json['hasSmoothTransitions'],
      );
}

/// 성능 비교 서비스
///
/// 최적화 전후의 성능을 비교하고 상세한 분석을 제공합니다:
/// - 시작 시간 개선 측정
/// - 메모리 사용량 변화 분석
/// - 에셋 로딩 최적화 효과 측정
/// - 사용자 경험 개선 평가
/// - 종합 성능 보고서 생성
class PerformanceComparisonService {
  static final PerformanceComparisonService _instance =
      PerformanceComparisonService._internal();
  factory PerformanceComparisonService() => _instance;
  PerformanceComparisonService._internal();

  DateTime? _measurementStartTime;

  /// 성능 비교 측정 시작
  void startMeasurement() {
    _measurementStartTime = DateTime.now();
    logger.i('📊 성능 비교 측정 시작');
  }

  /// 현재 성능 측정 및 분석
  Future<PerformanceMetrics> measureCurrentPerformance() async {
    logger.i('📈 현재 성능 측정 중...');

    // StartupPerformanceAnalyzer로 기본 성능 측정
    final analysisResult =
        await StartupPerformanceAnalyzer.analyzeCurrentPerformance();

    // 메모리 사용량 측정
    final memoryMetrics = await _measureMemoryUsage();

    // 에셋 메트릭 수집
    final assetMetrics = await _collectAssetMetrics();

    // 사용자 경험 메트릭 수집
    final uxMetrics = _collectUserExperienceMetrics();

    return PerformanceMetrics(
      totalStartupTime:
          (analysisResult['raw_data']?['total_startup_time_ms'] ?? 0.0)
              .toDouble(),
      stageTimings: Map<String, double>.from((analysisResult['raw_data']
                  ?['phase_durations'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {}),
      memoryUsage: memoryMetrics,
      assetMetrics: assetMetrics,
      uxMetrics: uxMetrics,
      performanceScore: analysisResult['performance_score'] ?? 0,
      bottlenecks: List<String>.from((analysisResult['bottlenecks'] as List?)
              ?.map((b) => b['phase'] ?? b['step'] ?? '') ??
          []),
    );
  }

  /// 메모리 사용량 측정
  Future<MemoryMetrics> _measureMemoryUsage() async {
    try {
      // 플랫폼별 메모리 정보 수집
      double totalMemory = 0.0;
      double appMemory = 0.0;

      if (!kIsWeb && !UniversalPlatform.isWeb) {
        // 모바일 플랫폼에서 메모리 정보 수집
        // 실제 구현에서는 더 정확한 메모리 측정 API를 사용해야 함
        final info = ProcessInfo.currentRss;
        appMemory = info / (1024 * 1024); // MB로 변환
        totalMemory = appMemory * 1.5; // 추정값
      }

      // 폰트 메모리 사용량 계산
      final fontService = FontOptimizationService();
      final fontStats = fontService.getLoadingStats();
      double fontMemory = (fontStats['totalSizeBytes'] as int) / (1024 * 1024);

      // 에셋 메모리 사용량 계산
      final assetService = AssetLoadingService();
      final assetStats = assetService.getLoadingStats();
      double assetMemory =
          (assetStats['assets']['totalSizeBytes'] as int) / (1024 * 1024);

      return MemoryMetrics(
        totalMemoryUsage: totalMemory,
        fontMemoryUsage: fontMemory,
        assetMemoryUsage: assetMemory,
        appMemoryUsage: appMemory,
      );
    } catch (e) {
      logger.e('메모리 사용량 측정 실패', error: e);
      return const MemoryMetrics(
        totalMemoryUsage: 0.0,
        fontMemoryUsage: 0.0,
        assetMemoryUsage: 0.0,
        appMemoryUsage: 0.0,
      );
    }
  }

  /// 에셋 메트릭 수집
  Future<AssetMetrics> _collectAssetMetrics() async {
    try {
      final assetService = AssetLoadingService();
      final fontService = FontOptimizationService();

      final assetStats = assetService.getLoadingStats();
      final fontStats = fontService.getLoadingStats();

      final combinedStats = assetStats['combined'] as Map<String, dynamic>;
      final assetData = assetStats['assets'] as Map<String, dynamic>;

      return AssetMetrics(
        totalAssets: combinedStats['totalItems'] ?? 0,
        criticalAssetsLoaded: combinedStats['totalLoadedItems'] ?? 0,
        assetLoadingTime: (assetData['totalLoadTimeMs'] ?? 0.0).toDouble(),
        fontLoadingTime: (fontStats['totalLoadTimeMs'] ?? 0.0).toDouble(),
        assetsByPriority: {
          'total': combinedStats['totalItems'] ?? 0,
          'loaded': combinedStats['totalLoadedItems'] ?? 0,
          'fonts': fontStats['loadedFonts'] ?? 0,
          'assets': assetData['loadedAssets'] ?? 0,
        },
      );
    } catch (e) {
      logger.e('에셋 메트릭 수집 실패', error: e);
      return const AssetMetrics(
        totalAssets: 0,
        criticalAssetsLoaded: 0,
        assetLoadingTime: 0.0,
        fontLoadingTime: 0.0,
        assetsByPriority: {},
      );
    }
  }

  /// 사용자 경험 메트릭 수집
  UserExperienceMetrics _collectUserExperienceMetrics() {
    final elapsedTime = _measurementStartTime != null
        ? DateTime.now()
            .difference(_measurementStartTime!)
            .inMilliseconds
            .toDouble()
        : 0.0;

    return UserExperienceMetrics(
      timeToFirstFrame: elapsedTime * 0.6, // 추정값
      timeToInteractive: elapsedTime,
      splashScreenDuration: 2000.0, // 2초 설정값
      hasProgressIndicator: true, // 구현됨
      hasSmoothTransitions: true, // 구현됨
    );
  }

  /// 성능 비교 수행
  Future<PerformanceComparison> comparePerformance() async {
    logger.i('🔍 성능 비교 분석 시작');

    // 베이스라인 로드
    final baseline = await _loadBaseline();
    if (baseline == null) {
      throw Exception('베이스라인 데이터를 찾을 수 없습니다. 먼저 초기 성능 분석을 실행해주세요.');
    }

    // 현재 성능 측정
    final currentMetrics = await measureCurrentPerformance();

    // 개선사항 계산
    final improvements = _calculateImprovements(baseline, currentMetrics);

    // 다음 단계 추천
    final nextSteps = _generateRecommendations(currentMetrics, improvements);

    final comparison = PerformanceComparison(
      timestamp: DateTime.now(),
      beforeOptimization: baseline,
      afterOptimization: currentMetrics,
      improvements: improvements,
      recommendedNextSteps: nextSteps,
    );

    // 비교 결과 저장
    await _saveComparison(comparison);

    return comparison;
  }

  /// 베이스라인 데이터 로드
  Future<PerformanceMetrics?> _loadBaseline() async {
    try {
      final baselineFile = File('scripts/performance_baseline.json');
      if (!await baselineFile.exists()) {
        return null;
      }

      final jsonData = await baselineFile.readAsString();
      final data = jsonDecode(jsonData);
      return PerformanceMetrics.fromJson(data);
    } catch (e) {
      logger.e('베이스라인 로드 실패', error: e);
      return null;
    }
  }

  /// 개선사항 계산
  Map<String, dynamic> _calculateImprovements(
    PerformanceMetrics before,
    PerformanceMetrics after,
  ) {
    final improvements = <String, dynamic>{};

    // 시간 개선사항
    final timeImprovement = before.totalStartupTime - after.totalStartupTime;
    final timeImprovementPercent = before.totalStartupTime > 0
        ? (timeImprovement / before.totalStartupTime) * 100
        : 0.0;

    improvements['startup_time'] = {
      'improvement_ms': timeImprovement,
      'improvement_percent': timeImprovementPercent,
      'before': before.totalStartupTime,
      'after': after.totalStartupTime,
    };

    // 메모리 개선사항
    final memoryImprovement = before.memoryUsage.totalMemoryUsage -
        after.memoryUsage.totalMemoryUsage;
    final memoryImprovementPercent = before.memoryUsage.totalMemoryUsage > 0
        ? (memoryImprovement / before.memoryUsage.totalMemoryUsage) * 100
        : 0.0;

    improvements['memory_usage'] = {
      'improvement_mb': memoryImprovement,
      'improvement_percent': memoryImprovementPercent,
      'before': before.memoryUsage.totalMemoryUsage,
      'after': after.memoryUsage.totalMemoryUsage,
    };

    // 에셋 로딩 개선사항
    final fontMemoryImprovement =
        before.memoryUsage.fontMemoryUsage - after.memoryUsage.fontMemoryUsage;
    improvements['font_optimization'] = {
      'memory_saved_mb': fontMemoryImprovement,
      'before': before.memoryUsage.fontMemoryUsage,
      'after': after.memoryUsage.fontMemoryUsage,
    };

    // 성능 점수 개선
    final scoreImprovement = after.performanceScore - before.performanceScore;
    improvements['performance_score'] = {
      'improvement_points': scoreImprovement,
      'before': before.performanceScore,
      'after': after.performanceScore,
    };

    // 병목 현상 개선
    improvements['bottlenecks'] = {
      'before_count': before.bottlenecks.length,
      'after_count': after.bottlenecks.length,
      'resolved': before.bottlenecks
          .where((b) => !after.bottlenecks.contains(b))
          .toList(),
      'remaining': after.bottlenecks,
    };

    return improvements;
  }

  /// 추천사항 생성
  List<String> _generateRecommendations(
    PerformanceMetrics current,
    Map<String, dynamic> improvements,
  ) {
    final recommendations = <String>[];

    // 성능 점수 기반 추천
    if (current.performanceScore < 80) {
      recommendations.add('성능 점수가 80점 미만입니다. 추가 최적화가 필요합니다.');
    }

    // 시작 시간 기반 추천
    if (current.totalStartupTime > 3000) {
      recommendations.add('앱 시작 시간이 3초를 초과합니다. 추가 지연 로딩을 고려해보세요.');
    }

    // 메모리 사용량 기반 추천
    if (current.memoryUsage.totalMemoryUsage > 100) {
      recommendations.add('메모리 사용량이 100MB를 초과합니다. 메모리 최적화를 고려해보세요.');
    }

    // 병목 현상 기반 추천
    if (current.bottlenecks.isNotEmpty) {
      recommendations
          .add('남은 병목 현상들을 해결해보세요: ${current.bottlenecks.join(", ")}');
    }

    // 개선사항이 없는 경우
    final timeImprovement =
        improvements['startup_time']['improvement_percent'] ?? 0.0;
    if (timeImprovement < 5) {
      recommendations.add('추가적인 마이크로 최적화나 코드 스플리팅을 고려해보세요.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('성능이 우수합니다! 현재 최적화를 유지하세요.');
    }

    return recommendations;
  }

  /// 비교 결과 저장
  Future<void> _saveComparison(PerformanceComparison comparison) async {
    try {
      final comparisonFile = File('scripts/performance_comparison.json');
      await comparisonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(comparison.toJson()),
      );

      logger.i('성능 비교 결과 저장 완료: ${comparisonFile.path}');
    } catch (e) {
      logger.e('성능 비교 결과 저장 실패', error: e);
    }
  }

  /// 성능 비교 보고서 생성
  String generateReport(PerformanceComparison comparison) {
    final buffer = StringBuffer();

    buffer.writeln('# 🚀 성능 최적화 비교 보고서');
    buffer.writeln('');
    buffer.writeln('**측정 일시:** ${comparison.timestamp.toLocal()}');
    buffer.writeln('');

    // 시작 시간 개선
    final startupImprovement = comparison.improvements['startup_time'];
    buffer.writeln('## ⏱️ 앱 시작 시간 개선');
    buffer.writeln(
        '- **이전:** ${startupImprovement['before'].toStringAsFixed(0)}ms');
    buffer.writeln(
        '- **이후:** ${startupImprovement['after'].toStringAsFixed(0)}ms');
    buffer.writeln(
        '- **개선:** ${startupImprovement['improvement_ms'].toStringAsFixed(0)}ms (${startupImprovement['improvement_percent'].toStringAsFixed(1)}%)');
    buffer.writeln('');

    // 메모리 사용량 개선
    final memoryImprovement = comparison.improvements['memory_usage'];
    buffer.writeln('## 🧠 메모리 사용량 개선');
    buffer.writeln(
        '- **이전:** ${memoryImprovement['before'].toStringAsFixed(1)}MB');
    buffer.writeln(
        '- **이후:** ${memoryImprovement['after'].toStringAsFixed(1)}MB');
    buffer.writeln(
        '- **개선:** ${memoryImprovement['improvement_mb'].toStringAsFixed(1)}MB (${memoryImprovement['improvement_percent'].toStringAsFixed(1)}%)');
    buffer.writeln('');

    // 폰트 최적화
    final fontOptimization = comparison.improvements['font_optimization'];
    buffer.writeln('## 🔤 폰트 최적화');
    buffer.writeln(
        '- **이전:** ${fontOptimization['before'].toStringAsFixed(1)}MB');
    buffer
        .writeln('- **이후:** ${fontOptimization['after'].toStringAsFixed(1)}MB');
    buffer.writeln(
        '- **절약:** ${fontOptimization['memory_saved_mb'].toStringAsFixed(1)}MB');
    buffer.writeln('');

    // 성능 점수
    final scoreImprovement = comparison.improvements['performance_score'];
    buffer.writeln('## 📊 성능 점수');
    buffer.writeln('- **이전:** ${scoreImprovement['before']}점');
    buffer.writeln('- **이후:** ${scoreImprovement['after']}점');
    buffer.writeln('- **개선:** +${scoreImprovement['improvement_points']}점');
    buffer.writeln('');

    // 병목 현상 해결
    final bottleneckImprovement = comparison.improvements['bottlenecks'];
    buffer.writeln('## 🔧 병목 현상 해결');
    buffer.writeln('- **이전 병목:** ${bottleneckImprovement['before_count']}개');
    buffer.writeln('- **현재 병목:** ${bottleneckImprovement['after_count']}개');
    if (bottleneckImprovement['resolved'].isNotEmpty) {
      buffer.writeln(
          '- **해결된 병목:** ${bottleneckImprovement['resolved'].join(", ")}');
    }
    if (bottleneckImprovement['remaining'].isNotEmpty) {
      buffer.writeln(
          '- **남은 병목:** ${bottleneckImprovement['remaining'].join(", ")}');
    }
    buffer.writeln('');

    // 추천사항
    buffer.writeln('## 💡 추천사항');
    for (final recommendation in comparison.recommendedNextSteps) {
      buffer.writeln('- $recommendation');
    }

    return buffer.toString();
  }
}
