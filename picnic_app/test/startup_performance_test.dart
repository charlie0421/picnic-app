// ignore_for_file: avoid_print

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_app/main.dart' as app;
import 'package:picnic_lib/core/utils/startup_profiler.dart';

/// 앱 시작 성능을 측정하는 통합 테스트
///
/// 이 테스트는 실제 디바이스에서 앱의 시작 성능을 측정하고
/// 성능 메트릭을 수집합니다.
void main() {
  group('앱 시작 성능 테스트', () {
    testWidgets('앱 시작 시간 측정', (WidgetTester tester) async {
      final profiler = StartupProfiler();

      // 성능 측정 시작
      profiler.startProfiling();

      // Timeline 이벤트 시작
      developer.Timeline.startSync('startup_performance_test');

      try {
        // 앱 시작
        profiler.startPhase('app_main');
        app.main();
        profiler.endPhase('app_main');

        // 첫 번째 프레임이 렌더링될 때까지 대기
        profiler.startPhase('first_frame_wait');
        await tester.pumpAndSettle(const Duration(seconds: 10));
        profiler.endPhase('first_frame_wait');

        // 첫 번째 프레임 마킹
        profiler.markFirstFrame();

        // 스플래시 화면이 사라질 때까지 대기
        profiler.startPhase('splash_screen_wait');
        await tester.pumpAndSettle(const Duration(seconds: 5));
        profiler.endPhase('splash_screen_wait');

        // 메모리 사용량 측정
        final memoryMetrics = await profiler.measureMemoryUsage();

        // 결과 출력
        profiler.finishProfiling();

        // 성능 결과 검증
        final results = profiler.getResults();

        // 기본 검증
        expect(results['total_startup_time_ms'], isNotNull);
        expect(results['phase_durations'], isNotNull);

        // 성능 기준 검증 (예시)
        final totalStartupTime = results['total_startup_time_ms'] as int?;
        if (totalStartupTime != null) {
          // 시작 시간이 10초를 넘지 않아야 함 (예시 기준)
          expect(totalStartupTime, lessThan(10000),
              reason: '앱 시작 시간이 너무 깁니다: ${totalStartupTime}ms');

          // 성능 결과를 파일로 저장 (CI/CD에서 활용 가능)
          await _savePerformanceResults(results, memoryMetrics);
        }

        print('📊 성능 측정 완료:');
        print('총 시작 시간: ${totalStartupTime}ms');
        print('메모리 메트릭: $memoryMetrics');
      } finally {
        developer.Timeline.finishSync();
      }
    });

    testWidgets('앱 시작 성능 벤치마크', (WidgetTester tester) async {
      const int iterations = 3; // 여러 번 측정하여 평균값 계산
      final List<Map<String, dynamic>> results = [];

      for (int i = 0; i < iterations; i++) {
        print('🔄 벤치마크 반복 ${i + 1}/$iterations');

        final profiler = StartupProfiler();
        profiler.startProfiling();

        // 앱 재시작 시뮬레이션
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          null,
          (data) {},
        );

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        profiler.markFirstFrame();
        profiler.finishProfiling();

        results.add(profiler.getResults());

        // 다음 반복을 위한 정리
        profiler.reset();

        // 잠시 대기
        await Future.delayed(const Duration(seconds: 1));
      }

      // 평균 성능 계산
      final averageResults = _calculateAveragePerformance(results);
      print('📈 평균 성능 결과: $averageResults');

      // 성능 변동성 검증
      final performanceVariation = _calculatePerformanceVariation(results);
      print('📊 성능 변동성: $performanceVariation');

      // 성능 변동성이 너무 크지 않아야 함 (예시: 30% 이내)
      expect(performanceVariation, lessThan(0.3),
          reason:
              '성능 변동성이 너무 큽니다: ${(performanceVariation * 100).toStringAsFixed(1)}%');
    });
  });
}

/// 성능 결과를 파일로 저장
Future<void> _savePerformanceResults(
  Map<String, dynamic> results,
  Map<String, dynamic> memoryMetrics,
) async {
  try {
    final timestamp = DateTime.now().toIso8601String();
    final performanceData = {
      'timestamp': timestamp,
      'startup_performance': results,
      'memory_metrics': memoryMetrics,
      'device_info': await _getDeviceInfo(),
    };

    // 테스트 결과 디렉토리에 저장
    final file = File('test_results/startup_performance_$timestamp.json');
    await file.create(recursive: true);
    await file.writeAsString(performanceData.toString());

    print('📁 성능 결과 저장됨: ${file.path}');
  } catch (e) {
    print('⚠️ 성능 결과 저장 실패: $e');
  }
}

/// 디바이스 정보 수집
Future<Map<String, dynamic>> _getDeviceInfo() async {
  return {
    'platform': Platform.operatingSystem,
    'version': Platform.operatingSystemVersion,
    'is_debug': kDebugMode,
    'is_profile': kProfileMode,
    'is_release': kReleaseMode,
  };
}

/// 여러 측정 결과의 평균 계산
Map<String, dynamic> _calculateAveragePerformance(
    List<Map<String, dynamic>> results) {
  if (results.isEmpty) return {};

  final totalStartupTimes = results
      .map((r) => r['total_startup_time_ms'] as int? ?? 0)
      .where((time) => time > 0)
      .toList();

  if (totalStartupTimes.isEmpty) return {};

  final averageStartupTime =
      totalStartupTimes.reduce((a, b) => a + b) / totalStartupTimes.length;

  return {
    'average_startup_time_ms': averageStartupTime.round(),
    'min_startup_time_ms': totalStartupTimes.reduce((a, b) => a < b ? a : b),
    'max_startup_time_ms': totalStartupTimes.reduce((a, b) => a > b ? a : b),
    'sample_count': totalStartupTimes.length,
  };
}

/// 성능 변동성 계산 (표준편차 / 평균)
double _calculatePerformanceVariation(List<Map<String, dynamic>> results) {
  final startupTimes = results
      .map((r) => r['total_startup_time_ms'] as int? ?? 0)
      .where((time) => time > 0)
      .map((time) => time.toDouble())
      .toList();

  if (startupTimes.length < 2) return 0.0;

  final mean = startupTimes.reduce((a, b) => a + b) / startupTimes.length;
  final variance = startupTimes
          .map((time) => (time - mean) * (time - mean))
          .reduce((a, b) => a + b) /
      startupTimes.length;

  final standardDeviation = sqrt(variance);

  return standardDeviation / mean; // 변동계수 (Coefficient of Variation)
}
