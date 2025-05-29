import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 성능 프로파일링 결과를 분석하는 유틸리티 클래스
///
/// StartupProfiler에서 수집된 데이터를 분석하여
/// 병목 지점을 식별하고 최적화 권장사항을 제공합니다.
class PerformanceAnalyzer {
  static const int _slowPhaseThresholdMs = 1000; // 1초 이상이면 느린 단계로 간주
  static const int _totalSlowStartupThresholdMs = 5000; // 5초 이상이면 느린 시작으로 간주
  static const double _significantPhaseRatio =
      0.15; // 전체 시간의 15% 이상이면 주요 단계로 간주

  /// 성능 결과를 분석하여 병목 지점과 권장사항을 제공합니다
  static PerformanceAnalysisResult analyzeStartupPerformance(
    Map<String, dynamic> performanceResults,
  ) {
    if (!kDebugMode) {
      return PerformanceAnalysisResult.empty();
    }

    try {
      final totalStartupTime =
          performanceResults['total_startup_time_ms'] as int? ?? 0;
      final phaseDurations =
          performanceResults['phase_durations'] as Map<String, dynamic>? ?? {};
      final additionalMetrics =
          performanceResults['additional_metrics'] as Map<String, dynamic>? ??
              {};

      // 단계별 성능 분석
      final phaseAnalysis = _analyzePhases(phaseDurations, totalStartupTime);

      // 병목 지점 식별
      final bottlenecks =
          _identifyBottlenecks(phaseDurations, totalStartupTime);

      // 전체 성능 평가
      final overallPerformance = _evaluateOverallPerformance(totalStartupTime);

      // 최적화 권장사항 생성
      final recommendations = _generateRecommendations(
        phaseDurations,
        bottlenecks,
        overallPerformance,
        additionalMetrics,
      );

      return PerformanceAnalysisResult(
        totalStartupTime: totalStartupTime,
        phaseAnalysis: phaseAnalysis,
        bottlenecks: bottlenecks,
        overallPerformance: overallPerformance,
        recommendations: recommendations,
        rawData: performanceResults,
      );
    } catch (e) {
      logger.e('성능 분석 중 오류 발생', error: e);
      return PerformanceAnalysisResult.empty();
    }
  }

  /// 단계별 성능을 분석합니다
  static List<PhaseAnalysis> _analyzePhases(
    Map<String, dynamic> phaseDurations,
    int totalStartupTime,
  ) {
    final analyses = <PhaseAnalysis>[];

    phaseDurations.forEach((phaseName, duration) {
      final durationMs = duration as int? ?? 0;
      final percentage =
          totalStartupTime > 0 ? (durationMs / totalStartupTime) * 100 : 0.0;

      final severity = _calculatePhaseSeverity(durationMs, percentage);
      final impact = _calculatePhaseImpact(percentage);

      analyses.add(PhaseAnalysis(
        phaseName: phaseName,
        durationMs: durationMs,
        percentage: percentage,
        severity: severity,
        impact: impact,
      ));
    });

    // 시간 순으로 정렬
    analyses.sort((a, b) => b.durationMs.compareTo(a.durationMs));

    return analyses;
  }

  /// 병목 지점을 식별합니다
  static List<BottleneckInfo> _identifyBottlenecks(
    Map<String, dynamic> phaseDurations,
    int totalStartupTime,
  ) {
    final bottlenecks = <BottleneckInfo>[];

    phaseDurations.forEach((phaseName, duration) {
      final durationMs = duration as int? ?? 0;
      final percentage =
          totalStartupTime > 0 ? (durationMs / totalStartupTime) * 100 : 0.0;

      // 병목 지점 기준
      if (durationMs > _slowPhaseThresholdMs ||
          percentage > _significantPhaseRatio * 100) {
        final severity = _calculateBottleneckSeverity(durationMs, percentage);

        bottlenecks.add(BottleneckInfo(
          phaseName: phaseName,
          durationMs: durationMs,
          percentage: percentage,
          severity: severity,
          description: _getBottleneckDescription(phaseName, durationMs),
        ));
      }
    });

    // 심각도 순으로 정렬
    bottlenecks.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return bottlenecks;
  }

  /// 전체 성능을 평가합니다
  static OverallPerformance _evaluateOverallPerformance(int totalStartupTime) {
    if (totalStartupTime <= 2000) {
      return OverallPerformance.excellent;
    } else if (totalStartupTime <= 3000) {
      return OverallPerformance.good;
    } else if (totalStartupTime <= _totalSlowStartupThresholdMs) {
      return OverallPerformance.fair;
    } else if (totalStartupTime <= 8000) {
      return OverallPerformance.poor;
    } else {
      return OverallPerformance.critical;
    }
  }

  /// 최적화 권장사항을 생성합니다
  static List<OptimizationRecommendation> _generateRecommendations(
    Map<String, dynamic> phaseDurations,
    List<BottleneckInfo> bottlenecks,
    OverallPerformance overallPerformance,
    Map<String, dynamic> additionalMetrics,
  ) {
    final recommendations = <OptimizationRecommendation>[];

    // 병목 지점 기반 권장사항
    for (final bottleneck in bottlenecks) {
      final phaseRecommendations =
          _getPhaseSpecificRecommendations(bottleneck.phaseName);
      recommendations.addAll(phaseRecommendations);
    }

    // 전체 성능 기반 권장사항
    if (overallPerformance.index >= OverallPerformance.poor.index) {
      recommendations.addAll(_getGeneralOptimizationRecommendations());
    }

    // 중복 제거
    final uniqueRecommendations = <OptimizationRecommendation>[];
    final seenTitles = <String>{};

    for (final rec in recommendations) {
      if (!seenTitles.contains(rec.title)) {
        seenTitles.add(rec.title);
        uniqueRecommendations.add(rec);
      }
    }

    return uniqueRecommendations;
  }

  /// 단계별 심각도를 계산합니다
  static PhaseSeverity _calculatePhaseSeverity(
      int durationMs, double percentage) {
    if (durationMs > 3000 || percentage > 40) {
      return PhaseSeverity.critical;
    } else if (durationMs > 2000 || percentage > 25) {
      return PhaseSeverity.high;
    } else if (durationMs > _slowPhaseThresholdMs || percentage > 15) {
      return PhaseSeverity.medium;
    } else {
      return PhaseSeverity.low;
    }
  }

  /// 단계별 영향도를 계산합니다
  static PhaseImpact _calculatePhaseImpact(double percentage) {
    if (percentage > 30) {
      return PhaseImpact.major;
    } else if (percentage > 15) {
      return PhaseImpact.significant;
    } else if (percentage > 5) {
      return PhaseImpact.moderate;
    } else {
      return PhaseImpact.minor;
    }
  }

  /// 병목 지점 심각도를 계산합니다
  static BottleneckSeverity _calculateBottleneckSeverity(
      int durationMs, double percentage) {
    if (durationMs > 4000 || percentage > 50) {
      return BottleneckSeverity.critical;
    } else if (durationMs > 2500 || percentage > 30) {
      return BottleneckSeverity.high;
    } else if (durationMs > 1500 || percentage > 20) {
      return BottleneckSeverity.medium;
    } else {
      return BottleneckSeverity.low;
    }
  }

  /// 병목 지점 설명을 생성합니다
  static String _getBottleneckDescription(String phaseName, int durationMs) {
    final descriptions = {
      'firebase':
          'Firebase 초기화가 ${durationMs}ms 소요되었습니다. 네트워크 연결이나 Firebase 설정을 확인하세요.',
      'supabase': 'Supabase 초기화가 ${durationMs}ms 소요되었습니다. 데이터베이스 연결을 최적화하세요.',
      'image_cache_services':
          '이미지 캐시 서비스 초기화가 ${durationMs}ms 소요되었습니다. 캐시 설정을 검토하세요.',
      'memory_profiler':
          '메모리 프로파일러 초기화가 ${durationMs}ms 소요되었습니다. 디버그 모드에서만 활성화하세요.',
      'basic_services':
          '기본 서비스 초기화가 ${durationMs}ms 소요되었습니다. 필수 서비스만 초기화하도록 최적화하세요.',
      'language_init': '언어 초기화가 ${durationMs}ms 소요되었습니다. 번역 파일 로딩을 최적화하세요.',
    };

    return descriptions[phaseName] ??
        '$phaseName 단계가 ${durationMs}ms 소요되어 성능에 영향을 주고 있습니다.';
  }

  /// 단계별 최적화 권장사항을 반환합니다
  static List<OptimizationRecommendation> _getPhaseSpecificRecommendations(
      String phaseName) {
    final recommendations = <String, List<OptimizationRecommendation>>{
      'firebase': [
        OptimizationRecommendation(
          title: 'Firebase 초기화 최적화',
          description: 'Firebase 서비스를 필요한 것만 초기화하고, 지연 로딩을 고려하세요.',
          priority: RecommendationPriority.high,
          estimatedImpact: 'Firebase 초기화 시간을 30-50% 단축 가능',
        ),
      ],
      'supabase': [
        OptimizationRecommendation(
          title: 'Supabase 연결 최적화',
          description: 'Supabase 연결 풀링을 사용하고, 불필요한 초기 쿼리를 제거하세요.',
          priority: RecommendationPriority.high,
          estimatedImpact: 'Supabase 초기화 시간을 40-60% 단축 가능',
        ),
      ],
      'image_cache_services': [
        OptimizationRecommendation(
          title: '이미지 캐시 최적화',
          description: '이미지 캐시 크기를 조정하고, 백그라운드에서 초기화하세요.',
          priority: RecommendationPriority.medium,
          estimatedImpact: '이미지 캐시 초기화 시간을 20-40% 단축 가능',
        ),
      ],
      'language_init': [
        OptimizationRecommendation(
          title: '언어 초기화 최적화',
          description: '번역 파일을 압축하고, 기본 언어만 먼저 로드하세요.',
          priority: RecommendationPriority.medium,
          estimatedImpact: '언어 초기화 시간을 25-45% 단축 가능',
        ),
      ],
    };

    return recommendations[phaseName] ?? [];
  }

  /// 일반적인 최적화 권장사항을 반환합니다
  static List<OptimizationRecommendation>
      _getGeneralOptimizationRecommendations() {
    return [
      OptimizationRecommendation(
        title: '지연 로딩 구현',
        description: '필수가 아닌 서비스들을 앱 시작 후에 백그라운드에서 초기화하세요.',
        priority: RecommendationPriority.high,
        estimatedImpact: '전체 시작 시간을 30-50% 단축 가능',
      ),
      OptimizationRecommendation(
        title: '에셋 최적화',
        description: '시작 시 필요한 에셋만 로드하고, 나머지는 필요할 때 로드하세요.',
        priority: RecommendationPriority.medium,
        estimatedImpact: '에셋 로딩 시간을 20-40% 단축 가능',
      ),
      OptimizationRecommendation(
        title: '스플래시 화면 최적화',
        description: '스플래시 화면을 단순화하고, 네이티브 스플래시를 사용하세요.',
        priority: RecommendationPriority.low,
        estimatedImpact: '사용자 체감 시작 시간 개선',
      ),
    ];
  }

  /// 분석 결과를 파일로 저장합니다
  static Future<void> saveAnalysisReport(
    PerformanceAnalysisResult analysis,
    String filePath,
  ) async {
    try {
      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'analysis': analysis.toJson(),
      };

      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(report));

      logger.i('성능 분석 보고서 저장됨: $filePath');
    } catch (e) {
      logger.e('성능 분석 보고서 저장 실패', error: e);
    }
  }

  /// 분석 결과를 콘솔에 출력합니다
  static void printAnalysisReport(PerformanceAnalysisResult analysis) {
    if (!kDebugMode) return;

    logger.i('🔍 성능 분석 보고서');
    logger.i('=' * 60);

    // 전체 성능 평가
    logger.i('📊 전체 성능: ${analysis.overallPerformance.displayName}');
    logger.i('⏱️ 총 시작 시간: ${analysis.totalStartupTime}ms');

    // 병목 지점
    if (analysis.bottlenecks.isNotEmpty) {
      logger.i('\n🚨 병목 지점:');
      for (final bottleneck in analysis.bottlenecks) {
        logger.i(
            '  • ${bottleneck.phaseName}: ${bottleneck.durationMs}ms (${bottleneck.percentage.toStringAsFixed(1)}%)');
        logger.i('    심각도: ${bottleneck.severity.displayName}');
      }
    }

    // 단계별 분석
    logger.i('\n📋 단계별 분석:');
    for (final phase in analysis.phaseAnalysis) {
      logger.i(
          '  • ${phase.phaseName}: ${phase.durationMs}ms (${phase.percentage.toStringAsFixed(1)}%)');
    }

    // 최적화 권장사항
    if (analysis.recommendations.isNotEmpty) {
      logger.i('\n💡 최적화 권장사항:');
      for (final rec in analysis.recommendations) {
        logger.i('  ${rec.priority.emoji} ${rec.title}');
        logger.i('    ${rec.description}');
        logger.i('    예상 효과: ${rec.estimatedImpact}');
      }
    }

    logger.i('=' * 60);
  }
}

/// 성능 분석 결과를 담는 클래스
class PerformanceAnalysisResult {
  final int totalStartupTime;
  final List<PhaseAnalysis> phaseAnalysis;
  final List<BottleneckInfo> bottlenecks;
  final OverallPerformance overallPerformance;
  final List<OptimizationRecommendation> recommendations;
  final Map<String, dynamic> rawData;

  const PerformanceAnalysisResult({
    required this.totalStartupTime,
    required this.phaseAnalysis,
    required this.bottlenecks,
    required this.overallPerformance,
    required this.recommendations,
    required this.rawData,
  });

  factory PerformanceAnalysisResult.empty() {
    return const PerformanceAnalysisResult(
      totalStartupTime: 0,
      phaseAnalysis: [],
      bottlenecks: [],
      overallPerformance: OverallPerformance.unknown,
      recommendations: [],
      rawData: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_startup_time': totalStartupTime,
      'phase_analysis': phaseAnalysis.map((p) => p.toJson()).toList(),
      'bottlenecks': bottlenecks.map((b) => b.toJson()).toList(),
      'overall_performance': overallPerformance.name,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'raw_data': rawData,
    };
  }
}

/// 단계별 분석 정보
class PhaseAnalysis {
  final String phaseName;
  final int durationMs;
  final double percentage;
  final PhaseSeverity severity;
  final PhaseImpact impact;

  const PhaseAnalysis({
    required this.phaseName,
    required this.durationMs,
    required this.percentage,
    required this.severity,
    required this.impact,
  });

  Map<String, dynamic> toJson() {
    return {
      'phase_name': phaseName,
      'duration_ms': durationMs,
      'percentage': percentage,
      'severity': severity.name,
      'impact': impact.name,
    };
  }
}

/// 병목 지점 정보
class BottleneckInfo {
  final String phaseName;
  final int durationMs;
  final double percentage;
  final BottleneckSeverity severity;
  final String description;

  const BottleneckInfo({
    required this.phaseName,
    required this.durationMs,
    required this.percentage,
    required this.severity,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'phase_name': phaseName,
      'duration_ms': durationMs,
      'percentage': percentage,
      'severity': severity.name,
      'description': description,
    };
  }
}

/// 최적화 권장사항
class OptimizationRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;
  final String estimatedImpact;

  const OptimizationRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedImpact,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority.name,
      'estimated_impact': estimatedImpact,
    };
  }
}

/// 전체 성능 평가
enum OverallPerformance {
  excellent('우수'),
  good('양호'),
  fair('보통'),
  poor('나쁨'),
  critical('심각'),
  unknown('알 수 없음');

  const OverallPerformance(this.displayName);
  final String displayName;
}

/// 단계별 심각도
enum PhaseSeverity {
  low('낮음'),
  medium('보통'),
  high('높음'),
  critical('심각');

  const PhaseSeverity(this.displayName);
  final String displayName;
}

/// 단계별 영향도
enum PhaseImpact {
  minor('미미'),
  moderate('보통'),
  significant('상당'),
  major('주요');

  const PhaseImpact(this.displayName);
  final String displayName;
}

/// 병목 지점 심각도
enum BottleneckSeverity {
  low('낮음'),
  medium('보통'),
  high('높음'),
  critical('심각');

  const BottleneckSeverity(this.displayName);
  final String displayName;
}

/// 권장사항 우선순위
enum RecommendationPriority {
  low('낮음', '💡'),
  medium('보통', '⚠️'),
  high('높음', '🚨');

  const RecommendationPriority(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}
