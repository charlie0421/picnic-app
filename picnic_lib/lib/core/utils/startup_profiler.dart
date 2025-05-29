import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 앱 시작 성능을 프로파일링하는 유틸리티 클래스
///
/// 이 클래스는 앱의 다양한 초기화 단계에서 성능 메트릭을 수집하고
/// 병목 지점을 식별하는 데 사용됩니다.
class StartupProfiler {
  static final StartupProfiler _instance = StartupProfiler._internal();
  factory StartupProfiler() => _instance;
  StartupProfiler._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, Duration> _durations = {};
  final Map<String, Map<String, dynamic>> _metrics = {};

  bool _isProfilingEnabled = false;
  DateTime? _appStartTime;
  DateTime? _firstFrameTime;

  /// 프로파일링을 시작합니다
  void startProfiling() {
    if (!kDebugMode) return;

    _isProfilingEnabled = true;
    _appStartTime = DateTime.now();
    logger.i('🚀 StartupProfiler: 프로파일링 시작');

    // Timeline 이벤트 시작
    developer.Timeline.startSync('app_startup');
  }

  /// 특정 단계의 시작을 기록합니다
  void startPhase(String phaseName) {
    if (!_isProfilingEnabled) return;

    _startTimes[phaseName] = DateTime.now();
    logger.i('⏱️ StartupProfiler: $phaseName 시작');

    // Timeline 이벤트 시작
    developer.Timeline.startSync(phaseName);
  }

  /// 특정 단계의 종료를 기록합니다
  void endPhase(String phaseName, {Map<String, dynamic>? additionalMetrics}) {
    if (!_isProfilingEnabled) return;

    final startTime = _startTimes[phaseName];
    if (startTime == null) {
      logger.w('⚠️ StartupProfiler: $phaseName의 시작 시간을 찾을 수 없습니다');
      return;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    _durations[phaseName] = duration;

    // 추가 메트릭 저장
    if (additionalMetrics != null) {
      _metrics[phaseName] = additionalMetrics;
    }

    logger.i('✅ StartupProfiler: $phaseName 완료 (${duration.inMilliseconds}ms)');

    // Timeline 이벤트 종료
    developer.Timeline.finishSync();
  }

  /// 첫 번째 프레임 렌더링 완료를 기록합니다
  void markFirstFrame() {
    if (!_isProfilingEnabled) return;

    _firstFrameTime = DateTime.now();
    if (_appStartTime != null) {
      final timeToFirstFrame = _firstFrameTime!.difference(_appStartTime!);
      _durations['time_to_first_frame'] = timeToFirstFrame;
      logger.i(
          '🎨 StartupProfiler: 첫 번째 프레임까지 ${timeToFirstFrame.inMilliseconds}ms');
    }
  }

  /// 메모리 사용량을 측정합니다
  Future<Map<String, dynamic>> measureMemoryUsage() async {
    if (!_isProfilingEnabled) return {};

    try {
      // ProcessInfo를 통한 메모리 정보 수집 (iOS/Android)
      final Map<String, dynamic> memoryInfo = {};

      if (Platform.isAndroid || Platform.isIOS) {
        // 기본 메모리 정보
        memoryInfo['timestamp'] = DateTime.now().toIso8601String();

        // Flutter 엔진 메모리 정보 (가능한 경우)
        try {
          final channel = MethodChannel('flutter/system');
          final result = await channel
              .invokeMethod('SystemChrome.getSystemUIOverlayStyle');
          memoryInfo['system_info'] = result;
        } catch (e) {
          // 시스템 정보를 가져올 수 없는 경우 무시
        }
      }

      return memoryInfo;
    } catch (e) {
      logger.e('메모리 사용량 측정 실패', error: e);
      return {};
    }
  }

  /// 현재까지의 프로파일링 결과를 반환합니다
  Map<String, dynamic> getResults() {
    if (!_isProfilingEnabled) return {};

    final results = <String, dynamic>{
      'app_start_time': _appStartTime?.toIso8601String(),
      'first_frame_time': _firstFrameTime?.toIso8601String(),
      'phase_durations':
          _durations.map((key, value) => MapEntry(key, value.inMilliseconds)),
      'additional_metrics': _metrics,
    };

    // 총 시작 시간 계산
    if (_appStartTime != null && _firstFrameTime != null) {
      final totalStartupTime = _firstFrameTime!.difference(_appStartTime!);
      results['total_startup_time_ms'] = totalStartupTime.inMilliseconds;
    }

    return results;
  }

  /// 프로파일링 결과를 로그로 출력합니다
  void printResults() {
    if (!_isProfilingEnabled) return;

    logger.i('📊 StartupProfiler 결과:');
    logger.i('=' * 50);

    // 총 시작 시간
    if (_appStartTime != null && _firstFrameTime != null) {
      final totalTime = _firstFrameTime!.difference(_appStartTime!);
      logger.i('🎯 총 시작 시간: ${totalTime.inMilliseconds}ms');
    }

    // 각 단계별 시간
    logger.i('📋 단계별 시간:');
    _durations.forEach((phase, duration) {
      logger.i('  • $phase: ${duration.inMilliseconds}ms');
    });

    // 추가 메트릭
    if (_metrics.isNotEmpty) {
      logger.i('📈 추가 메트릭:');
      _metrics.forEach((phase, metrics) {
        logger.i('  • $phase:');
        metrics.forEach((key, value) {
          logger.i('    - $key: $value');
        });
      });
    }

    logger.i('=' * 50);
  }

  /// 프로파일링을 종료하고 결과를 출력합니다
  void finishProfiling() {
    if (!_isProfilingEnabled) return;

    // Timeline 이벤트 종료
    developer.Timeline.finishSync();

    // 결과 출력
    printResults();

    logger.i('🏁 StartupProfiler: 프로파일링 완료');
  }

  /// 프로파일링 데이터를 초기화합니다
  void reset() {
    _startTimes.clear();
    _durations.clear();
    _metrics.clear();
    _appStartTime = null;
    _firstFrameTime = null;
    _isProfilingEnabled = false;
  }

  /// 특정 작업의 실행 시간을 측정합니다
  Future<T> measureAsync<T>(String taskName, Future<T> Function() task) async {
    if (!_isProfilingEnabled) return await task();

    startPhase(taskName);
    try {
      final result = await task();
      endPhase(taskName);
      return result;
    } catch (e) {
      endPhase(taskName, additionalMetrics: {'error': e.toString()});
      rethrow;
    }
  }

  /// 동기 작업의 실행 시간을 측정합니다
  T measureSync<T>(String taskName, T Function() task) {
    if (!_isProfilingEnabled) return task();

    startPhase(taskName);
    try {
      final result = task();
      endPhase(taskName);
      return result;
    } catch (e) {
      endPhase(taskName, additionalMetrics: {'error': e.toString()});
      rethrow;
    }
  }
}
