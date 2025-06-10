import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stack_trace/stack_trace.dart';

/// [MemoryProfiler]는 앱의 메모리 사용량을 모니터링하고 프로파일링하기 위한 유틸리티 클래스입니다.
/// 특히 이미지 처리 작업에서 메모리 누수를 감지하는데 초점을 맞추고 있습니다.
class MemoryProfiler {
  MemoryProfiler._();
  static final MemoryProfiler instance = MemoryProfiler._();

  bool _isEnabled = false;
  bool _isInitialized = false;
  bool _isAutoSnapshotEnabled = false;
  Timer? _autoSnapshotTimer;

  // 메모리 스냅샷 저장소
  final Map<String, MemorySnapshot> _snapshots = {};

  // 스냅샷 관리 설정
  static const int _maxSnapshots = 30; // 최대 스냅샷 개수 (감소)
  static const int _maxAutoSnapshots = 5; // 자동 스냅샷 최대 개수 (대폭 감소)
// 메모리 변화 임계값 (MB) 증가

  // 마지막 스냅샷 정보 (조건부 생성용)
  MemorySnapshot? _lastSnapshot;

  // 전역 스냅샷 생성 제한
  DateTime? _lastGlobalSnapshotTime;
  static const int _globalSnapshotCooldownSeconds = 2; // 전역 스냅샷 생성 최소 간격

  // 스냅샷 중요도 레벨
  static const int snapshotLevelLow = 0; // 낮은 중요도 (자주 발생하는 일상적인 이벤트)
  static const int snapshotLevelMedium = 1; // 중간 중요도 (주요 사용자 상호작용)
  static const int snapshotLevelHigh = 2; // 높은 중요도 (중요한 앱 상태 변경)
  static const int snapshotLevelCritical = 3; // 최고 중요도 (메모리 누수 의심 지점)

  /// 메모리 프로파일러 활성화 상태
  bool get isEnabled => _isEnabled;

  /// 자동 스냅샷 활성화 상태
  bool get isAutoSnapshotEnabled => _isAutoSnapshotEnabled;

  /// 메모리 프로파일러 초기화
  /// [enabled]가 true면 메모리 프로파일링을 활성화합니다.
  /// [enableAutoSnapshot]이 true면 자동 스냅샷 캡처를 활성화합니다.
  /// [autoSnapshotIntervalSeconds]는 자동 스냅샷 캡처 간격(초)입니다.
  void initialize({
    bool enabled = false,
    bool enableAutoSnapshot = false,
    int autoSnapshotIntervalSeconds = 300, // 기본값을 5분으로 변경
  }) {
    if (_isInitialized) return;

    _isEnabled = enabled;
    _isAutoSnapshotEnabled = enableAutoSnapshot;
    _isInitialized = true;

    if (_isEnabled) {
      logger.i('메모리 프로파일러가 활성화되었습니다.');

      // 앱 라이프사이클 이벤트에 리스너 추가 (바인딩이 초기화된 후에 호출해야 함)
      WidgetsBinding.instance.addObserver(_MemoryProfilerObserver(this));

      // 초기 메모리 스냅샷 생성
      takeSnapshot('app_start', level: snapshotLevelHigh);

      // 자동 스냅샷 타이머 설정
      if (_isAutoSnapshotEnabled) {
        _startAutoSnapshot(intervalSeconds: autoSnapshotIntervalSeconds);
      }
    }
  }

  /// 메모리 프로파일러를 리셋하고 초기화합니다.
  ///
  /// 모든 스냅샷과 타이머를 지우고 기본 상태로 되돌립니다.
  /// 테스트 환경에서 주로 사용됩니다.
  void reset() {
    // 타이머 정지
    _stopAutoSnapshot();

    // 스냅샷 저장소 초기화
    _snapshots.clear();
    _lastSnapshot = null; // 마지막 스냅샷 정보 초기화

    logger.i('메모리 프로파일러 리셋 완료');

    // 초기화 상태만 유지하고 다른 상태는 기본값으로 설정
    _isEnabled = false;
    _isAutoSnapshotEnabled = false;
  }

  /// 메모리 프로파일러 활성화/비활성화
  void setEnabled(bool enabled) {
    if (!_isInitialized) {
      logger.w('메모리 프로파일러가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
      return;
    }

    _isEnabled = enabled;
    logger.i('메모리 프로파일러 ${enabled ? '활성화' : '비활성화'}');

    if (_isEnabled) {
      takeSnapshot('profiler_enabled', level: snapshotLevelMedium);
    }
  }

  /// 자동 스냅샷 캡처 활성화/비활성화
  void setAutoSnapshotEnabled(bool enabled, {int intervalSeconds = 300}) {
    // 기본값을 5분으로 변경
    if (!_isInitialized) {
      logger.w('메모리 프로파일러가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
      return;
    }

    _isAutoSnapshotEnabled = enabled;
    logger.i('자동 스냅샷 ${enabled ? '활성화' : '비활성화'}');

    if (_isAutoSnapshotEnabled) {
      _startAutoSnapshot(intervalSeconds: intervalSeconds);
    } else {
      _stopAutoSnapshot();
    }
  }

  /// 자동 스냅샷 타이머 시작
  void _startAutoSnapshot({int intervalSeconds = 600}) {
    // 기본값을 10분으로 변경 (더 긴 간격)
    _stopAutoSnapshot(); // 이전 타이머가 있다면 정지

    _autoSnapshotTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) {
        if (_isEnabled && _isAutoSnapshotEnabled) {
          final snapshotLabel =
              'auto_snapshot_${DateTime.now().millisecondsSinceEpoch}';

          // 조건부 스냅샷 생성: 메모리 변화가 임계값 이상일 때만 생성
          if (_shouldCreateAutoSnapshot()) {
            takeSnapshot(snapshotLabel,
                level: snapshotLevelLow,
                includeStackTrace: false); // 스택 트레이스 비활성화
            logger.t('자동 스냅샷 생성됨 (메모리 변화 감지)');
          } else {
            logger.t('자동 스냅샷 건너뜀 (변화량 부족 또는 시간 간격 부족)');
          }
        }
      },
    );

    logger.i('자동 스냅샷이 $intervalSeconds초 간격으로 시작되었습니다.');
  }

  /// 자동 스냅샷 생성 여부를 결정합니다.
  bool _shouldCreateAutoSnapshot() {
    if (_lastSnapshot == null) return true;

    // 최소 시간 간격 확인 (60초 미만이면 생성하지 않음) - 더 엄격하게 변경
    final timeSinceLastSnapshot =
        DateTime.now().difference(_lastSnapshot!.timestamp);
    if (timeSinceLastSnapshot.inSeconds < 60) {
      return false;
    }

    final currentHeapUsage = _getHeapUsage();
    final lastHeapUsage = _lastSnapshot!.heapUsage;

    // 메모리 변화량 계산 (MB 단위) - 임계값을 10MB로 증가
    final heapChangeMB =
        (currentHeapUsage.used - lastHeapUsage.used).abs() / (1024 * 1024);

    return heapChangeMB >= 10; // 10MB 이상 변화가 있을 때만 스냅샷 생성
  }

  /// 자동 스냅샷 타이머 정지
  void _stopAutoSnapshot() {
    _autoSnapshotTimer?.cancel();
    _autoSnapshotTimer = null;
  }

  /// 현재 메모리 상태의 스냅샷을 생성하고 저장합니다.
  /// [label]은 스냅샷을 식별하는 고유한 이름입니다.
  /// [metadata]는 스냅샷과 함께 저장될 추가 정보입니다.
  /// [level]은 스냅샷의 중요도 레벨입니다.
  /// [includeStackTrace]가 true면 호출 스택 정보를 포함합니다.
  MemorySnapshot? takeSnapshot(
    String label, {
    Map<String, dynamic>? metadata,
    int level = snapshotLevelMedium,
    bool includeStackTrace = false,
  }) {
    if (!_isEnabled) return null;

    // 전역 스냅샷 생성 제한 (중요도가 높은 경우는 예외)
    final now = DateTime.now();
    if (level < snapshotLevelHigh && _lastGlobalSnapshotTime != null) {
      final timeSinceLastGlobal = now.difference(_lastGlobalSnapshotTime!);
      if (timeSinceLastGlobal.inSeconds < _globalSnapshotCooldownSeconds) {
        logger.d('전역 스냅샷 생성 제한으로 건너뜀: $label');
        return null;
      }
    }

    try {
      // 스냅샷 저장소 크기 확인 및 정리
      _cleanupSnapshots();

      // 현재 메모리 사용량 정보 수집
      final heapUsage = _getHeapUsage();
      final imageCache = _getImageCacheStats();

      // 호출 스택 정보 수집 (중요도가 높은 경우에만)
      List<String>? stackTraceLines;
      if (includeStackTrace && level >= snapshotLevelMedium) {
        final trace = Trace.current(2); // 현재 스택 트레이스 (2단계 위로 시작)
        stackTraceLines = trace.frames
            .take(10)
            .map((frame) => frame.toString())
            .toList(); // 최대 10개 프레임만 저장
      }

      final snapshot = MemorySnapshot(
        label: label,
        timestamp: DateTime.now(),
        metadata: {
          ...metadata ?? {},
          'level': level,
          if (stackTraceLines != null) 'stackTrace': stackTraceLines,
        },
        heapUsage: heapUsage,
        imageCacheStats: imageCache,
      );

      _snapshots[label] = snapshot;
      _lastSnapshot = snapshot; // 마지막 스냅샷 업데이트
      _lastGlobalSnapshotTime = now; // 전역 스냅샷 시간 업데이트

      // 중요도에 따라 로깅 레벨 다르게 설정
      switch (level) {
        case snapshotLevelLow:
          // 낮은 중요도는 로깅하지 않음 (자동 스냅샷 등)
          break;
        case snapshotLevelMedium:
          // 중간 중요도는 디버그 레벨로만 로깅
          logger.d(
              '메모리 스냅샷 생성: $label, 힙 사용량: ${heapUsage.used ~/ (1024 * 1024)}MB');
          break;
        case snapshotLevelHigh:
          logger.i(
              '중요 메모리 스냅샷 생성: $label, 힙 사용량: ${heapUsage.used ~/ (1024 * 1024)}MB');
          break;
        case snapshotLevelCritical:
          logger.w(
              '긴급 메모리 스냅샷 생성: $label, 힙 사용량: ${heapUsage.used ~/ (1024 * 1024)}MB');
          break;
      }

      return snapshot;
    } catch (e, stackTrace) {
      logger.e('메모리 스냅샷 생성 실패: $label', error: e, stackTrace: stackTrace);
      Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 스냅샷 저장소를 정리합니다.
  void _cleanupSnapshots() {
    // 전체 스냅샷 개수가 최대치를 초과하면 정리
    if (_snapshots.length >= _maxSnapshots) {
      _removeOldestSnapshots(_maxSnapshots ~/ 2); // 절반 정도 제거
    }

    // 자동 스냅샷이 너무 많으면 정리
    final autoSnapshots = _snapshots.entries
        .where((entry) => entry.key.startsWith('auto_snapshot_'))
        .toList();

    if (autoSnapshots.length > _maxAutoSnapshots) {
      // 오래된 자동 스냅샷부터 제거
      autoSnapshots
          .sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      final toRemove = autoSnapshots.length - _maxAutoSnapshots;

      for (int i = 0; i < toRemove; i++) {
        _snapshots.remove(autoSnapshots[i].key);
      }

      logger.d('오래된 자동 스냅샷 $toRemove개를 정리했습니다.');
    }
  }

  /// 가장 오래된 스냅샷들을 제거합니다.
  void _removeOldestSnapshots(int count) {
    if (_snapshots.length <= count) return;

    final sortedSnapshots = _snapshots.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    // 중요도가 낮은 것부터 우선 제거
    final toRemove = <String>[];

    for (final entry in sortedSnapshots) {
      if (toRemove.length >= count) break;

      final level = entry.value.metadata['level'] ?? snapshotLevelMedium;
      if (level <= snapshotLevelLow) {
        toRemove.add(entry.key);
      }
    }

    // 여전히 부족하면 시간순으로 제거
    if (toRemove.length < count) {
      for (final entry in sortedSnapshots) {
        if (toRemove.length >= count) break;
        if (!toRemove.contains(entry.key)) {
          final level = entry.value.metadata['level'] ?? snapshotLevelMedium;
          if (level < snapshotLevelCritical) {
            // 중요한 스냅샷은 보존
            toRemove.add(entry.key);
          }
        }
      }
    }

    for (final key in toRemove) {
      _snapshots.remove(key);
    }

    if (toRemove.isNotEmpty) {
      logger.d('오래된 스냅샷 ${toRemove.length}개를 정리했습니다.');
    }
  }

  /// 모든 스냅샷을 반환합니다.
  List<MemorySnapshot> getAllSnapshots() {
    if (!_isEnabled) return [];
    return _snapshots.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// 특정 레벨 이상의 스냅샷을 반환합니다.
  List<MemorySnapshot> getSnapshotsByLevel(int minLevel) {
    if (!_isEnabled) return [];
    return _snapshots.values
        .where((snapshot) => (snapshot.metadata['level'] ?? 0) >= minLevel)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// 특정 기간 내의 스냅샷을 반환합니다.
  List<MemorySnapshot> getSnapshotsInTimeRange(DateTime start, DateTime end) {
    if (!_isEnabled) return [];
    return _snapshots.values
        .where((snapshot) =>
            snapshot.timestamp.isAfter(start) &&
            snapshot.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// 두 스냅샷 간의 차이를 계산하여 반환합니다.
  /// [beforeLabel]과 [afterLabel]은 비교할 스냅샷의 레이블입니다.
  MemoryDiff? calculateDiff(String beforeLabel, String afterLabel) {
    if (!_isEnabled) return null;

    final before = _snapshots[beforeLabel];
    final after = _snapshots[afterLabel];

    if (before == null || after == null) {
      logger.w('스냅샷을 찾을 수 없습니다: $beforeLabel 또는 $afterLabel');
      return null;
    }

    try {
      final heapDiff = HeapUsage(
        used: after.heapUsage.used - before.heapUsage.used,
        capacity: after.heapUsage.capacity - before.heapUsage.capacity,
        external: after.heapUsage.external - before.heapUsage.external,
      );

      final imageCacheDiff = ImageCacheStats(
        liveImages: after.imageCacheStats.liveImages -
            before.imageCacheStats.liveImages,
        sizeBytes:
            after.imageCacheStats.sizeBytes - before.imageCacheStats.sizeBytes,
      );

      final diff = MemoryDiff(
        beforeLabel: beforeLabel,
        afterLabel: afterLabel,
        timeDiff: after.timestamp.difference(before.timestamp),
        heapDiff: heapDiff,
        imageCacheDiff: imageCacheDiff,
      );

      _logMemoryDiff(diff);
      return diff;
    } catch (e, stackTrace) {
      logger.e('메모리 차이 계산 실패: $beforeLabel -> $afterLabel',
          error: e, stackTrace: stackTrace);
      Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 특정 동작 전후의 메모리 상태를 비교합니다.
  /// [label]은 작업을 식별하는 고유한 이름입니다.
  /// [action]은 메모리 사용량을 측정할 작업입니다.
  /// [metadata]는 스냅샷과 함께 저장될 추가 정보입니다.
  /// [level]은 스냅샷의 중요도 레벨입니다.
  Future<MemoryDiff?> profileAction(
    String label,
    Future<void> Function() action, {
    Map<String, dynamic>? metadata,
    int level = snapshotLevelMedium,
  }) async {
    if (!_isEnabled) {
      await action();
      return null;
    }

    final beforeLabel = '${label}_before';
    final afterLabel = '${label}_after';

    try {
      // 스냅샷 생성 빈도 제한 (같은 라벨로 5초 이내 중복 호출 방지) - 더 엄격하게 변경
      final now = DateTime.now();
      final recentSnapshot = _snapshots[beforeLabel];
      if (recentSnapshot != null &&
          now.difference(recentSnapshot.timestamp).inSeconds < 5) {
        logger.d('profileAction 스냅샷 생성 건너뜀 (중복 호출): $label');
        await action();
        return null;
      }

      takeSnapshot(beforeLabel,
          metadata: metadata,
          level: level,
          includeStackTrace: level >= snapshotLevelHigh);
      await action();
      takeSnapshot(afterLabel,
          metadata: metadata,
          level: level,
          includeStackTrace: level >= snapshotLevelHigh);

      // 가비지 컬렉션을 유도하여 GC를 간접적으로 요청 (중요한 작업에서만)
      if (kDebugMode && level >= snapshotLevelHigh) {
        // 메모리 압박을 유도하여 GC를 간접적으로 요청
        await _triggerGarbageCollection();
        await Future.delayed(const Duration(milliseconds: 500));
        takeSnapshot('${afterLabel}_gc',
            metadata: metadata, level: level, includeStackTrace: true);
        return calculateDiff(beforeLabel, '${afterLabel}_gc');
      }

      return calculateDiff(beforeLabel, afterLabel);
    } catch (e, stackTrace) {
      logger.e('작업 프로파일링 실패: $label', error: e, stackTrace: stackTrace);
      Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 이미지 작업에 특화된 프로파일링 메서드
  /// [imageUrl]은 처리 중인 이미지의 URL입니다.
  /// [action]은 이미지 처리 작업입니다.
  /// [imageSize]는 이미지의 크기(바이트)입니다.
  Future<MemoryDiff?> profileImageAction(
    String imageUrl,
    Future<void> Function() action, {
    int? imageSize,
    int level = snapshotLevelMedium,
  }) async {
    final sanitizedUrl = _sanitizeUrl(imageUrl);
    final metadata = {
      'imageUrl': sanitizedUrl,
      'imageSize': imageSize,
      'type': 'image_operation',
    };

    return profileAction(
      'image_${_getImageOperationId(sanitizedUrl)}',
      action,
      metadata: metadata,
      level: level,
    );
  }

  /// 스냅샷을 모두 지웁니다.
  void clearSnapshots() {
    if (!_isEnabled) return;
    _snapshots.clear();
    logger.i('메모리 스냅샷 초기화 완료');
  }

  /// 특정 레이블의 스냅샷을 지웁니다.
  bool removeSnapshot(String label) {
    if (!_isEnabled) return false;
    final removed = _snapshots.remove(label);
    return removed != null;
  }

  /// 메모리 누수 감지 로직을 수행합니다.
  /// [threshold]는 메모리 누수로 간주할 크기 임계값(MB)입니다.
  Future<List<MemoryLeakReport>> detectLeaks({int thresholdMB = 10}) async {
    if (!_isEnabled) return [];

    final leaks = <MemoryLeakReport>[];

    // 가비지 컬렉션을 위한 지연
    if (kDebugMode) {
      await _triggerGarbageCollection();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final snapshot = takeSnapshot(
      'leak_detection',
      level: snapshotLevelHigh,
      includeStackTrace: true,
    );
    if (snapshot == null) return [];

    // 이미지 캐시가 너무 큰 경우 경고
    final imageCacheMB = snapshot.imageCacheStats.sizeBytes ~/ (1024 * 1024);
    if (imageCacheMB > thresholdMB) {
      leaks.add(MemoryLeakReport(
        source: 'ImageCache',
        sizeMB: imageCacheMB,
        details: '이미지 캐시 크기가 ${imageCacheMB}MB로 임계값 ${thresholdMB}MB를 초과했습니다.',
        timestamp: DateTime.now(),
        stackTrace: snapshot.metadata['stackTrace'] as List<String>?,
      ));
    }

    // 스냅샷 간 메모리 증가량 분석
    final snapshots = _snapshots.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (snapshots.length < 2) return leaks;

    for (int i = 1; i < snapshots.length; i++) {
      final before = snapshots[i - 1];
      final after = snapshots[i];

      // 메모리 증가량 계산 (MB 단위)
      final heapIncreaseMB =
          (after.heapUsage.used - before.heapUsage.used) ~/ (1024 * 1024);

      // 임계값을 초과하는 메모리 증가가 있으면 잠재적 누수로 보고
      if (heapIncreaseMB > thresholdMB) {
        final timeDiff = after.timestamp.difference(before.timestamp);

        // 메타데이터에서 작업 유형 확인
        final operationType = after.metadata['type'] ?? 'unknown';
        final imageUrl = after.metadata['imageUrl'] as String?;

        String source = 'Unknown';
        String details =
            '스냅샷 ${before.label}와 ${after.label} 사이에 ${heapIncreaseMB}MB의 메모리 증가가 감지되었습니다.';

        // 작업 유형이 이미지 관련이면 추가 정보 제공
        if (operationType == 'image_operation' && imageUrl != null) {
          source = 'ImageProcessing';
          details =
              '이미지 처리($imageUrl) 중 ${heapIncreaseMB}MB의 메모리 증가가 감지되었습니다. 소요 시간: ${timeDiff.inMilliseconds}ms';
        }

        leaks.add(MemoryLeakReport(
          source: source,
          sizeMB: heapIncreaseMB,
          details: details,
          timestamp: after.timestamp,
          stackTrace: after.metadata['stackTrace'] as List<String>?,
        ));
      }
    }

    // 누수 감지 결과 로깅
    if (leaks.isEmpty) {
      logger.i('메모리 누수가 감지되지 않았습니다.');
    } else {
      for (final leak in leaks) {
        logger.w(
            '메모리 누수 감지: [${leak.source}] ${leak.sizeMB}MB - ${leak.details}');

        // 스택 트레이스가 있으면 로깅
        if (leak.stackTrace != null && leak.stackTrace!.isNotEmpty) {
          logger.w('발생 위치:\n${leak.stackTrace!.join('\n')}');
        }
      }
    }

    return leaks;
  }

  // 가비지 컬렉션을 간접적으로 유도합니다
  Future<void> _triggerGarbageCollection() async {
    // 메모리 압박을 생성하여 가비지 컬렉션을 간접적으로 유도
    final list = <List<int>>[];
    try {
      for (int i = 0; i < 5; i++) {
        list.add(List<int>.filled(1000000, 0));
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      // 메모리 부족 예외가 발생할 수 있음 (무시)
    }
    // 참조 제거
    list.clear();
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // 현재 힙 사용량 정보를 가져옵니다.
  HeapUsage _getHeapUsage() {
    try {
      // 간단하게 정적 추정으로 대체
      final imageCache = PaintingBinding.instance.imageCache;
      final heapUsage = HeapUsage(
        used: imageCache.currentSizeBytes.toDouble() * 1.5, // 추정치
        capacity: 256 * 1024 * 1024, // 추정치 (256MB)
        external: 0, // 알 수 없음
      );
      return heapUsage;
    } catch (e) {
      // 에러 발생 시 기본값 반환
      return HeapUsage(
        used: 0,
        capacity: 0,
        external: 0,
      );
    }
  }

  // 현재 이미지 캐시 통계를 반환합니다.
  ///
  /// 이미지 캐시에 있는 이미지 수와 크기 정보를 제공합니다.
  /// 테스트에서 이미지 캐시 상태 확인에 사용됩니다.
  ImageCacheStats getImageCacheStats() {
    return _getImageCacheStats();
  }

  // 이미지 캐시 통계를 가져옵니다.
  ImageCacheStats _getImageCacheStats() {
    final cache = PaintingBinding.instance.imageCache;
    final stats = ImageCacheStats(
      liveImages: cache.liveImageCount,
      sizeBytes: cache.currentSizeBytes,
    );
    return stats;
  }

  // 메모리 차이를 로그로 출력합니다.
  void _logMemoryDiff(MemoryDiff diff) {
    final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
    final imageCacheDiffMB = diff.imageCacheDiff.sizeBytes ~/ (1024 * 1024);

    if (heapDiffMB > 0 || imageCacheDiffMB > 0) {
      logger.i('메모리 변화 (${diff.beforeLabel} -> ${diff.afterLabel}): '
          '힙: ${heapDiffMB > 0 ? "+$heapDiffMB" : heapDiffMB}MB, '
          '이미지 캐시: ${imageCacheDiffMB > 0 ? "+$imageCacheDiffMB" : imageCacheDiffMB}MB, '
          '시간: ${diff.timeDiff.inMilliseconds}ms');
    }
  }

  // URL에서 민감한 정보를 제거합니다.
  String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (_) {
      return url;
    }
  }

  // 이미지 작업에 대한 고유 ID를 생성합니다.
  String _getImageOperationId(String url) {
    final pathHash = url.hashCode.toString();
    return '${DateTime.now().millisecondsSinceEpoch}_$pathHash';
  }
}

/// 앱 라이프사이클 이벤트를 관찰하는 클래스
class _MemoryProfilerObserver extends WidgetsBindingObserver {
  final MemoryProfiler _profiler;

  _MemoryProfilerObserver(this._profiler);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_profiler.isEnabled) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _profiler.takeSnapshot('app_resumed',
            level: MemoryProfiler.snapshotLevelHigh, includeStackTrace: true);
        break;
      case AppLifecycleState.paused:
        _profiler.takeSnapshot('app_paused',
            level: MemoryProfiler.snapshotLevelHigh, includeStackTrace: true);
        break;
      default:
        // 다른 상태는 처리하지 않음
        break;
    }
  }
}

/// 메모리 스냅샷을 나타내는 클래스
class MemorySnapshot {
  final String label;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final HeapUsage heapUsage;
  final ImageCacheStats imageCacheStats;

  MemorySnapshot({
    required this.label,
    required this.timestamp,
    required this.metadata,
    required this.heapUsage,
    required this.imageCacheStats,
  });
}

/// 힙 사용량 정보를 나타내는 클래스
class HeapUsage {
  final double used; // 현재 사용 중인 메모리 (바이트)
  final double capacity; // 총 할당된 메모리 (바이트)
  final double external; // 외부 메모리 사용량 (바이트)

  HeapUsage({
    required this.used,
    required this.capacity,
    required this.external,
  });
}

/// 이미지 캐시 통계를 나타내는 클래스
class ImageCacheStats {
  final int liveImages; // 현재 캐싱된 이미지 수
  final int sizeBytes; // 캐시 크기 (바이트)

  ImageCacheStats({
    required this.liveImages,
    required this.sizeBytes,
  });
}

/// 두 메모리 스냅샷 간의 차이를 나타내는 클래스
class MemoryDiff {
  final String beforeLabel;
  final String afterLabel;
  final Duration timeDiff;
  final HeapUsage heapDiff;
  final ImageCacheStats imageCacheDiff;

  MemoryDiff({
    required this.beforeLabel,
    required this.afterLabel,
    required this.timeDiff,
    required this.heapDiff,
    required this.imageCacheDiff,
  });
}

/// 메모리 누수 보고서를 나타내는 클래스
class MemoryLeakReport {
  final String source; // 누수 출처 (예: 'ImageCache', 'Widget')
  final int sizeMB; // 누수 크기 (MB)
  final String details; // 상세 정보
  final DateTime timestamp;
  final List<String>? stackTrace; // 스택 트레이스 정보 (선택 사항)

  MemoryLeakReport({
    required this.source,
    required this.sizeMB,
    required this.details,
    required this.timestamp,
    this.stackTrace,
  });
}
