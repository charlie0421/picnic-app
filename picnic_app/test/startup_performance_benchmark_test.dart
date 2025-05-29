import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/startup_performance_analyzer.dart';
import 'package:picnic_lib/core/utils/startup_profiler.dart';

/// 앱 시작 성능 벤치마크 테스트
///
/// 이 테스트는 앱 시작 성능을 여러 번 측정하여
/// 평균 성능과 성능 변동성을 확인합니다.
void main() {
  group('앱 시작 성능 벤치마크', () {
    late StartupProfiler profiler;

    setUp(() {
      profiler = StartupProfiler();
      profiler.reset();
    });

    tearDown(() {
      profiler.reset();
    });

    test('시작 성능 기준선 측정', () async {
      // Given
      const testIterations = 5;
      final measurements = <Map<String, dynamic>>[];

      // When - 여러 번 측정하여 평균값 계산
      for (int i = 0; i < testIterations; i++) {
        profiler.reset();

        // 시뮬레이션된 앱 시작 과정
        await _simulateAppStartup(profiler);

        final results = profiler.getResults();
        if (results.isNotEmpty) {
          measurements.add(results);
        }

        // 측정 간 간격
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Then
      expect(measurements.length, equals(testIterations));

      // 평균 성능 계산
      final averageMetrics = _calculateAverageMetrics(measurements);

      // 성능 변동성 확인 (표준편차가 평균의 30% 이하여야 함)
      final variabilityCheck = _checkPerformanceVariability(measurements);

      // 결과 출력
      debugPrint('📊 성능 벤치마크 결과:');
      debugPrint('평균 총 시작 시간: ${averageMetrics['total_startup_time_ms']}ms');
      debugPrint('성능 변동성: ${variabilityCheck['coefficient_of_variation']}%');

      // 성능 변동성이 30% 이하인지 확인
      expect(variabilityCheck['coefficient_of_variation'], lessThan(30.0));

      // 결과를 파일로 저장
      await _saveBenchmarkResults(averageMetrics, variabilityCheck);
    });

    test('성능 분석 시스템 검증', () async {
      // Given
      await _simulateAppStartup(profiler);

      // When
      final analysis =
          await StartupPerformanceAnalyzer.analyzeCurrentPerformance();

      // Then
      expect(analysis, isNotEmpty);
      expect(analysis['performance_score'], isA<int>());
      expect(analysis['analysis'], isNotEmpty);
      expect(analysis['recommendations'], isA<List>());

      // 성능 점수가 0-100 범위인지 확인
      final score = analysis['performance_score'] as int;
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));

      debugPrint('성능 점수: $score/100');
    });

    test('병목 지점 식별 테스트', () async {
      // Given - 의도적으로 느린 단계 시뮬레이션
      profiler.startProfiling();

      profiler.startPhase('fast_phase');
      await Future.delayed(const Duration(milliseconds: 50));
      profiler.endPhase('fast_phase');

      profiler.startPhase('slow_phase');
      await Future.delayed(const Duration(milliseconds: 400)); // 임계값 초과
      profiler.endPhase('slow_phase');

      profiler.markFirstFrame();
      profiler.finishProfiling();

      // When
      final analysis =
          await StartupPerformanceAnalyzer.analyzeCurrentPerformance();

      // Then
      final bottlenecks = analysis['bottlenecks'] as List<dynamic>;
      expect(bottlenecks, isNotEmpty);

      // slow_phase가 병목으로 식별되었는지 확인
      final slowPhaseBottleneck = bottlenecks.firstWhere(
        (b) => b['phase'] == 'slow_phase',
        orElse: () => null,
      );
      expect(slowPhaseBottleneck, isNotNull);
      expect(slowPhaseBottleneck['severity'], equals('critical'));
    });

    test('기준선 비교 기능 테스트', () async {
      // Given - 기준선 생성
      await _simulateAppStartup(profiler);
      await StartupPerformanceAnalyzer.saveAsBaseline();

      // When - 새로운 측정 (약간 다른 성능)
      profiler.reset();
      profiler.startProfiling();

      profiler.startPhase('test_phase');
      await Future.delayed(const Duration(milliseconds: 120)); // 기준선보다 느림
      profiler.endPhase('test_phase');

      profiler.markFirstFrame();
      profiler.finishProfiling();

      final analysis =
          await StartupPerformanceAnalyzer.analyzeCurrentPerformance();

      // Then
      expect(analysis['comparison'], isNotNull);
      final comparison = analysis['comparison'] as Map<String, dynamic>;
      expect(comparison['improved'], isA<List>());
      expect(comparison['degraded'], isA<List>());
      expect(comparison['unchanged'], isA<List>());

      // 정리
      await _cleanupTestFiles();
    });
  });
}

/// 앱 시작 과정을 시뮬레이션합니다
Future<void> _simulateAppStartup(StartupProfiler profiler) async {
  profiler.startProfiling();

  // Flutter 바인딩 초기화 시뮬레이션
  profiler.startPhase('flutter_bindings');
  await Future.delayed(const Duration(milliseconds: 80));
  profiler.endPhase('flutter_bindings');

  // 기본 서비스 초기화 시뮬레이션
  profiler.startPhase('basic_services');
  await Future.delayed(const Duration(milliseconds: 120));
  profiler.endPhase('basic_services');

  // Firebase 초기화 시뮬레이션
  profiler.startPhase('firebase_init');
  await Future.delayed(const Duration(milliseconds: 200));
  profiler.endPhase('firebase_init');

  // Supabase 초기화 시뮬레이션
  profiler.startPhase('supabase_init');
  await Future.delayed(const Duration(milliseconds: 150));
  profiler.endPhase('supabase_init');

  // 인증 서비스 시뮬레이션
  profiler.startPhase('auth_service');
  await Future.delayed(const Duration(milliseconds: 100));
  profiler.endPhase('auth_service');

  // 앱 위젯 생성 시뮬레이션
  profiler.startPhase('app_widget_creation');
  await Future.delayed(const Duration(milliseconds: 50));
  profiler.endPhase('app_widget_creation');

  profiler.markFirstFrame();
  profiler.finishProfiling();
}

/// 여러 측정값의 평균을 계산합니다
Map<String, dynamic> _calculateAverageMetrics(
    List<Map<String, dynamic>> measurements) {
  if (measurements.isEmpty) return {};

  final averages = <String, dynamic>{};

  // 총 시작 시간 평균
  final totalTimes = measurements
      .map((m) => m['total_startup_time_ms'] as int?)
      .where((t) => t != null)
      .cast<int>()
      .toList();

  if (totalTimes.isNotEmpty) {
    averages['total_startup_time_ms'] =
        (totalTimes.reduce((a, b) => a + b) / totalTimes.length).round();
  }

  // 단계별 평균 계산
  final allPhases = <String>{};
  for (final measurement in measurements) {
    final phases = measurement['phase_durations'] as Map<String, dynamic>?;
    if (phases != null) {
      allPhases.addAll(phases.keys);
    }
  }

  final phaseAverages = <String, dynamic>{};
  for (final phase in allPhases) {
    final phaseTimes = measurements
        .map((m) =>
            (m['phase_durations'] as Map<String, dynamic>?)?[phase] as int?)
        .where((t) => t != null)
        .cast<int>()
        .toList();

    if (phaseTimes.isNotEmpty) {
      phaseAverages[phase] =
          (phaseTimes.reduce((a, b) => a + b) / phaseTimes.length).round();
    }
  }

  averages['phase_durations'] = phaseAverages;

  return averages;
}

/// 성능 변동성을 확인합니다
Map<String, dynamic> _checkPerformanceVariability(
    List<Map<String, dynamic>> measurements) {
  if (measurements.length < 2) return {'coefficient_of_variation': 0.0};

  final totalTimes = measurements
      .map((m) => m['total_startup_time_ms'] as int?)
      .where((t) => t != null)
      .cast<int>()
      .toList();

  if (totalTimes.isEmpty) return {'coefficient_of_variation': 0.0};

  // 평균 계산
  final mean = totalTimes.reduce((a, b) => a + b) / totalTimes.length;

  // 표준편차 계산
  final variance =
      totalTimes.map((t) => (t - mean) * (t - mean)).reduce((a, b) => a + b) /
          totalTimes.length;
  final standardDeviation = sqrt(variance);

  // 변동계수 계산 (표준편차 / 평균 * 100)
  final coefficientOfVariation = (standardDeviation / mean) * 100;

  return {
    'mean': mean,
    'standard_deviation': standardDeviation,
    'coefficient_of_variation': coefficientOfVariation,
    'min': totalTimes.reduce((a, b) => a < b ? a : b),
    'max': totalTimes.reduce((a, b) => a > b ? a : b),
  };
}

/// 벤치마크 결과를 파일로 저장합니다
Future<void> _saveBenchmarkResults(
  Map<String, dynamic> averageMetrics,
  Map<String, dynamic> variabilityCheck,
) async {
  final results = {
    'timestamp': DateTime.now().toIso8601String(),
    'average_metrics': averageMetrics,
    'variability_analysis': variabilityCheck,
    'test_environment': {
      'debug_mode': kDebugMode,
      'platform': Platform.operatingSystem,
    },
  };

  try {
    final file = File('startup_benchmark_results.json');
    await file.writeAsString(jsonEncode(results));
    debugPrint('벤치마크 결과가 startup_benchmark_results.json에 저장되었습니다');
  } catch (e) {
    debugPrint('벤치마크 결과 저장 실패: $e');
  }
}

/// 테스트 파일들을 정리합니다
Future<void> _cleanupTestFiles() async {
  final filesToCleanup = [
    'startup_baseline.json',
    'startup_performance_report.json',
    'startup_benchmark_results.json',
  ];

  for (final filename in filesToCleanup) {
    try {
      final file = File(filename);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('파일 정리 실패 ($filename): $e');
    }
  }
}
