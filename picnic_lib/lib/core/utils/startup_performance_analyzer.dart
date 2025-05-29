import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/startup_profiler.dart';

/// 앱 시작 성능을 종합적으로 분석하는 클래스
///
/// StartupProfiler의 데이터를 분석하여 병목 지점을 식별하고
/// 최적화 권장사항을 제공합니다.
class StartupPerformanceAnalyzer {
  static const String _reportFileName = 'startup_performance_report.json';
  static const String _baselineFileName = 'startup_baseline.json';

  // 성능 임계값 (밀리초)
  static const int _warningThreshold = 100;
  static const int _criticalThreshold = 300;
  static const int _totalStartupWarning = 2000;
  static const int _totalStartupCritical = 4000;

  /// 현재 성능 데이터를 분석합니다
  static Future<Map<String, dynamic>> analyzeCurrentPerformance() async {
    if (!kDebugMode) {
      logger.w('성능 분석은 디버그 모드에서만 실행됩니다');
      return {};
    }

    final profiler = StartupProfiler();
    final results = profiler.getResults();

    if (results.isEmpty) {
      logger.w('프로파일링 데이터가 없습니다. StartupProfiler가 실행되었는지 확인하세요.');
      return {};
    }

    final analysis = await _performAnalysis(results);
    await _saveReport(analysis);

    return analysis;
  }

  /// 성능 데이터를 분석하여 병목 지점을 식별합니다
  static Future<Map<String, dynamic>> _performAnalysis(
      Map<String, dynamic> rawData) async {
    final analysis = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'raw_data': rawData,
      'analysis': {},
      'bottlenecks': [],
      'recommendations': [],
      'performance_score': 0,
    };

    // 총 시작 시간 분석
    final totalStartupTime = rawData['total_startup_time_ms'] as int?;
    if (totalStartupTime != null) {
      analysis['analysis']['total_startup'] =
          _analyzeTotalStartup(totalStartupTime);
    }

    // 단계별 성능 분석
    final phaseDurations = rawData['phase_durations'] as Map<String, dynamic>?;
    if (phaseDurations != null) {
      analysis['analysis']['phases'] = _analyzePhases(phaseDurations);
      analysis['bottlenecks'] = _identifyBottlenecks(phaseDurations);
    }

    // 권장사항 생성
    analysis['recommendations'] = _generateRecommendations(analysis);

    // 성능 점수 계산
    analysis['performance_score'] = _calculatePerformanceScore(analysis);

    // 기준선과 비교 (있는 경우)
    final baseline = await _loadBaseline();
    if (baseline != null) {
      analysis['comparison'] = _compareWithBaseline(rawData, baseline);
    }

    return analysis;
  }

  /// 총 시작 시간을 분석합니다
  static Map<String, dynamic> _analyzeTotalStartup(int totalTime) {
    String status;
    String message;

    if (totalTime < _totalStartupWarning) {
      status = 'good';
      message = '앱 시작 시간이 양호합니다';
    } else if (totalTime < _totalStartupCritical) {
      status = 'warning';
      message = '앱 시작 시간이 다소 느립니다';
    } else {
      status = 'critical';
      message = '앱 시작 시간이 매우 느립니다';
    }

    return {
      'duration_ms': totalTime,
      'status': status,
      'message': message,
      'target_time_ms': _totalStartupWarning,
    };
  }

  /// 각 단계별 성능을 분석합니다
  static Map<String, dynamic> _analyzePhases(Map<String, dynamic> phases) {
    final analysis = <String, dynamic>{};

    phases.forEach((phase, duration) {
      final durationMs = duration as int;
      String status;
      String message;

      if (durationMs < _warningThreshold) {
        status = 'good';
        message = '성능이 양호합니다';
      } else if (durationMs < _criticalThreshold) {
        status = 'warning';
        message = '최적화가 필요합니다';
      } else {
        status = 'critical';
        message = '심각한 성능 문제가 있습니다';
      }

      analysis[phase] = {
        'duration_ms': durationMs,
        'status': status,
        'message': message,
        'percentage': 0, // 나중에 계산
      };
    });

    // 각 단계의 비율 계산
    final totalTime =
        phases.values.fold<int>(0, (sum, duration) => sum + (duration as int));
    if (totalTime > 0) {
      analysis.forEach((phase, data) {
        final duration = data['duration_ms'] as int;
        data['percentage'] = ((duration / totalTime) * 100).round();
      });
    }

    return analysis;
  }

  /// 병목 지점을 식별합니다
  static List<Map<String, dynamic>> _identifyBottlenecks(
      Map<String, dynamic> phases) {
    final bottlenecks = <Map<String, dynamic>>[];

    // 가장 오래 걸리는 단계들을 식별
    final sortedPhases = phases.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    for (final entry in sortedPhases) {
      final phase = entry.key;
      final duration = entry.value as int;

      if (duration >= _criticalThreshold) {
        bottlenecks.add({
          'phase': phase,
          'duration_ms': duration,
          'severity': 'critical',
          'impact': 'high',
          'description': '$phase 단계에서 ${duration}ms의 긴 지연이 발생했습니다',
        });
      } else if (duration >= _warningThreshold) {
        bottlenecks.add({
          'phase': phase,
          'duration_ms': duration,
          'severity': 'warning',
          'impact': 'medium',
          'description': '$phase 단계에서 ${duration}ms의 지연이 발생했습니다',
        });
      }
    }

    return bottlenecks;
  }

  /// 최적화 권장사항을 생성합니다
  static List<Map<String, dynamic>> _generateRecommendations(
      Map<String, dynamic> analysis) {
    final recommendations = <Map<String, dynamic>>[];

    // 총 시작 시간 기반 권장사항
    final totalAnalysis =
        analysis['analysis']['total_startup'] as Map<String, dynamic>?;
    if (totalAnalysis != null && totalAnalysis['status'] != 'good') {
      recommendations.add({
        'type': 'general',
        'priority': 'high',
        'title': '전체 시작 시간 최적화',
        'description':
            '앱 시작 시간을 ${totalAnalysis['target_time_ms']}ms 이하로 줄이는 것을 목표로 하세요',
        'actions': [
          '지연 로딩 구현',
          '불필요한 초기화 작업 제거',
          '에셋 로딩 최적화',
          '스플래시 스크린 개선',
        ],
      });
    }

    // 병목 지점 기반 권장사항
    final bottlenecks = analysis['bottlenecks'] as List<dynamic>?;
    if (bottlenecks != null) {
      for (final bottleneck in bottlenecks) {
        final phase = bottleneck['phase'] as String;
        final severity = bottleneck['severity'] as String;

        recommendations.add({
          'type': 'bottleneck',
          'priority': severity == 'critical' ? 'high' : 'medium',
          'title': '$phase 단계 최적화',
          'description': bottleneck['description'],
          'actions': _getPhaseSpecificActions(phase),
        });
      }
    }

    // 일반적인 최적화 권장사항
    recommendations.add({
      'type': 'general',
      'priority': 'low',
      'title': '일반적인 성능 최적화',
      'description': '앱 성능을 더욱 향상시키기 위한 일반적인 방법들',
      'actions': [
        '이미지 압축 및 최적화',
        '불필요한 위젯 리빌드 방지',
        '메모리 사용량 모니터링',
        '네트워크 요청 최적화',
      ],
    });

    return recommendations;
  }

  /// 특정 단계에 대한 구체적인 액션을 반환합니다
  static List<String> _getPhaseSpecificActions(String phase) {
    switch (phase.toLowerCase()) {
      case 'flutter_bindings':
        return [
          'Flutter 엔진 초기화 최적화',
          '불필요한 바인딩 제거',
        ];
      case 'firebase_init':
        return [
          'Firebase 지연 초기화 구현',
          '필요한 Firebase 서비스만 초기화',
          'Firebase 설정 최적화',
        ];
      case 'supabase_init':
        return [
          'Supabase 연결 풀 최적화',
          '초기 데이터 로딩 지연',
          'Supabase 클라이언트 설정 최적화',
        ];
      case 'image_cache':
        return [
          '이미지 캐시 크기 최적화',
          '이미지 압축 설정 조정',
          '불필요한 이미지 프리로딩 제거',
        ];
      case 'auth_service':
        return [
          '인증 상태 확인 지연',
          '토큰 검증 최적화',
          '인증 관련 네트워크 요청 최적화',
        ];
      default:
        return [
          '해당 단계의 초기화 로직 검토',
          '불필요한 작업 제거',
          '비동기 처리 최적화',
        ];
    }
  }

  /// 성능 점수를 계산합니다 (0-100)
  static int _calculatePerformanceScore(Map<String, dynamic> analysis) {
    int score = 100;

    // 총 시작 시간 기반 점수 차감
    final totalAnalysis =
        analysis['analysis']['total_startup'] as Map<String, dynamic>?;
    if (totalAnalysis != null) {
      final status = totalAnalysis['status'] as String;
      switch (status) {
        case 'warning':
          score -= 20;
          break;
        case 'critical':
          score -= 40;
          break;
      }
    }

    // 병목 지점 기반 점수 차감
    final bottlenecks = analysis['bottlenecks'] as List<dynamic>?;
    if (bottlenecks != null) {
      for (final bottleneck in bottlenecks) {
        final severity = bottleneck['severity'] as String;
        switch (severity) {
          case 'warning':
            score -= 10;
            break;
          case 'critical':
            score -= 20;
            break;
        }
      }
    }

    return score.clamp(0, 100);
  }

  /// 기준선과 비교합니다
  static Map<String, dynamic> _compareWithBaseline(
      Map<String, dynamic> current, Map<String, dynamic> baseline) {
    final comparison = <String, dynamic>{
      'improved': [],
      'degraded': [],
      'unchanged': [],
    };

    final currentPhases = current['phase_durations'] as Map<String, dynamic>?;
    final baselinePhases = baseline['phase_durations'] as Map<String, dynamic>?;

    if (currentPhases != null && baselinePhases != null) {
      currentPhases.forEach((phase, currentDuration) {
        final baselineDuration = baselinePhases[phase] as int?;
        if (baselineDuration != null) {
          final diff = (currentDuration as int) - baselineDuration;
          final percentChange = ((diff / baselineDuration) * 100).round();

          if (diff.abs() < 10) {
            // 10ms 이하는 변화 없음으로 간주
            comparison['unchanged'].add({
              'phase': phase,
              'current_ms': currentDuration,
              'baseline_ms': baselineDuration,
              'change_ms': diff,
            });
          } else if (diff < 0) {
            comparison['improved'].add({
              'phase': phase,
              'current_ms': currentDuration,
              'baseline_ms': baselineDuration,
              'change_ms': diff,
              'percent_change': percentChange,
            });
          } else {
            comparison['degraded'].add({
              'phase': phase,
              'current_ms': currentDuration,
              'baseline_ms': baselineDuration,
              'change_ms': diff,
              'percent_change': percentChange,
            });
          }
        }
      });
    }

    return comparison;
  }

  /// 분석 보고서를 저장합니다
  static Future<void> _saveReport(Map<String, dynamic> analysis) async {
    try {
      final file = File(_reportFileName);
      await file.writeAsString(jsonEncode(analysis));
      logger.i('성능 분석 보고서가 $_reportFileName에 저장되었습니다');
    } catch (e) {
      logger.e('보고서 저장 실패', error: e);
    }
  }

  /// 기준선 데이터를 로드합니다
  static Future<Map<String, dynamic>?> _loadBaseline() async {
    try {
      final file = File(_baselineFileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      logger.e('기준선 데이터 로드 실패', error: e);
    }
    return null;
  }

  /// 현재 성능 데이터를 기준선으로 저장합니다
  static Future<void> saveAsBaseline() async {
    final profiler = StartupProfiler();
    final results = profiler.getResults();

    if (results.isEmpty) {
      logger.w('기준선으로 저장할 프로파일링 데이터가 없습니다');
      return;
    }

    try {
      final file = File(_baselineFileName);
      await file.writeAsString(jsonEncode(results));
      logger.i('현재 성능 데이터가 기준선으로 $_baselineFileName에 저장되었습니다');
    } catch (e) {
      logger.e('기준선 저장 실패', error: e);
    }
  }

  /// 분석 결과를 콘솔에 출력합니다
  static void printAnalysis(Map<String, dynamic> analysis) {
    if (!kDebugMode) return;

    logger.i('📊 앱 시작 성능 분석 결과');
    logger.i('=' * 60);

    // 성능 점수
    final score = analysis['performance_score'] as int;
    logger.i('🎯 성능 점수: $score/100');

    // 총 시작 시간
    final totalAnalysis =
        analysis['analysis']['total_startup'] as Map<String, dynamic>?;
    if (totalAnalysis != null) {
      final duration = totalAnalysis['duration_ms'] as int;
      final status = totalAnalysis['status'] as String;
      final statusEmoji = status == 'good'
          ? '✅'
          : status == 'warning'
              ? '⚠️'
              : '❌';
      logger.i(
          '$statusEmoji 총 시작 시간: ${duration}ms (${totalAnalysis['message']})');
    }

    // 병목 지점
    final bottlenecks = analysis['bottlenecks'] as List<dynamic>?;
    if (bottlenecks != null && bottlenecks.isNotEmpty) {
      logger.i('🚨 병목 지점:');
      for (final bottleneck in bottlenecks) {
        final phase = bottleneck['phase'] as String;
        final duration = bottleneck['duration_ms'] as int;
        final severity = bottleneck['severity'] as String;
        final emoji = severity == 'critical' ? '🔴' : '🟡';
        logger.i('  $emoji $phase: ${duration}ms');
      }
    }

    // 권장사항
    final recommendations = analysis['recommendations'] as List<dynamic>?;
    if (recommendations != null && recommendations.isNotEmpty) {
      logger.i('💡 최적화 권장사항:');
      for (final rec in recommendations.take(3)) {
        // 상위 3개만 표시
        final title = rec['title'] as String;
        final priority = rec['priority'] as String;
        final emoji = priority == 'high'
            ? '🔥'
            : priority == 'medium'
                ? '⚡'
                : '💡';
        logger.i('  $emoji $title');
      }
    }

    logger.i('=' * 60);
  }
}
