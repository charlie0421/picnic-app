import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';

/// 메모리 프로파일링 오버레이 표시 상태 제공자
final memoryProfilerOverlayVisibleProvider =
    StateProvider<bool>((ref) => false);

/// 메모리 프로파일러 설정 상태를 관리하는 프로바이더
final memoryProfilerSettingsProvider =
    StateProvider<MemoryProfilerSettings>((ref) {
  return const MemoryProfilerSettings(
    enableAutoSnapshot: false,
    autoSnapshotIntervalSeconds: 60,
    minimumLeakThresholdMB: 20,
  );
});

/// 메모리 프로파일러 설정 클래스
class MemoryProfilerSettings {
  final bool enableAutoSnapshot;
  final int autoSnapshotIntervalSeconds;
  final int minimumLeakThresholdMB;

  const MemoryProfilerSettings({
    required this.enableAutoSnapshot,
    required this.autoSnapshotIntervalSeconds,
    required this.minimumLeakThresholdMB,
  });

  MemoryProfilerSettings copyWith({
    bool? enableAutoSnapshot,
    int? autoSnapshotIntervalSeconds,
    int? minimumLeakThresholdMB,
  }) {
    return MemoryProfilerSettings(
      enableAutoSnapshot: enableAutoSnapshot ?? this.enableAutoSnapshot,
      autoSnapshotIntervalSeconds:
          autoSnapshotIntervalSeconds ?? this.autoSnapshotIntervalSeconds,
      minimumLeakThresholdMB:
          minimumLeakThresholdMB ?? this.minimumLeakThresholdMB,
    );
  }
}

/// 메모리 누수 보고서 클래스
class MemoryLeakReport {
  final String source;
  final int sizeMB;
  final String details;
  final DateTime timestamp;
  final List<String>? stackTrace;

  MemoryLeakReport({
    required this.source,
    required this.sizeMB,
    required this.details,
    required this.timestamp,
    this.stackTrace,
  });
}

/// 메모리 프로파일러 상태 클래스
class MemoryProfilerState {
  final bool isEnabled;
  final MemoryProfilerSettings settings;
  final bool isDetecting;
  final List<MemoryLeakReport> detectedLeaks;

  MemoryProfilerState({
    required this.isEnabled,
    required this.settings,
    this.isDetecting = false,
    this.detectedLeaks = const [],
  });

  MemoryProfilerState copyWith({
    bool? isEnabled,
    MemoryProfilerSettings? settings,
    bool? isDetecting,
    List<MemoryLeakReport>? detectedLeaks,
  }) {
    return MemoryProfilerState(
      isEnabled: isEnabled ?? this.isEnabled,
      settings: settings ?? this.settings,
      isDetecting: isDetecting ?? this.isDetecting,
      detectedLeaks: detectedLeaks ?? this.detectedLeaks,
    );
  }
}

/// 메모리 프로파일러 노티파이어 클래스
class MemoryProfilerNotifier extends StateNotifier<MemoryProfilerState> {
  Timer? _autoSnapshotTimer;

  MemoryProfilerNotifier(MemoryProfilerSettings settings)
      : super(MemoryProfilerState(
          isEnabled: true,
          settings: settings,
        )) {
    _setupAutoSnapshot();
  }

  @override
  void dispose() {
    _cancelAutoSnapshot();
    super.dispose();
  }

  /// 메모리 프로파일러 초기화
  void initialize() {
    state = state.copyWith(isEnabled: true);
  }

  /// 자동 스냅샷 타이머 설정
  void _setupAutoSnapshot() {
    _cancelAutoSnapshot();

    if (state.settings.enableAutoSnapshot) {
      _autoSnapshotTimer = Timer.periodic(
        Duration(seconds: state.settings.autoSnapshotIntervalSeconds),
        (timer) {
          try {
            takeSnapshot(
              'auto_${DateTime.now().millisecondsSinceEpoch}',
              level: MemoryProfiler.snapshotLevelMedium,
            );
          } catch (e) {
            logger.e('자동 스냅샷 생성 중 오류: $e');
          }
        },
      );
      logger.i('자동 스냅샷 타이머 설정: ${state.settings.autoSnapshotIntervalSeconds}초');
    }
  }

  /// 자동 스냅샷 타이머 취소
  void _cancelAutoSnapshot() {
    _autoSnapshotTimer?.cancel();
    _autoSnapshotTimer = null;
  }

  /// 자동 스냅샷 활성화 설정
  void setAutoSnapshotEnabled(bool enabled) {
    final newSettings = state.settings.copyWith(enableAutoSnapshot: enabled);
    state = state.copyWith(settings: newSettings);
    _setupAutoSnapshot();
  }

  /// 자동 스냅샷 간격 설정
  void setAutoSnapshotInterval(int seconds) {
    final newSettings =
        state.settings.copyWith(autoSnapshotIntervalSeconds: seconds);
    state = state.copyWith(settings: newSettings);
    _setupAutoSnapshot();
  }

  /// 새로운 스냅샷 생성
  void takeSnapshot(
    String label, {
    int level = MemoryProfiler.snapshotLevelMedium,
    bool includeStackTrace = false,
    Map<String, dynamic>? metadata,
  }) {
    try {
      MemoryProfiler.instance.takeSnapshot(
        label,
        level: level,
        includeStackTrace: includeStackTrace,
        metadata: metadata,
      );
      logger.i('스냅샷 생성 완료: $label');
    } catch (e) {
      logger.e('스냅샷 생성 실패: $e');
    }
  }

  /// 메모리 누수 감지 실행
  Future<void> detectLeaks() async {
    if (state.isDetecting) {
      return;
    }

    state = state.copyWith(isDetecting: true);

    try {
      // 첫번째 스냅샷 생성
      takeSnapshot(
        'leak_detect_start_${DateTime.now().millisecondsSinceEpoch}',
        level: MemoryProfiler.snapshotLevelHigh,
        includeStackTrace: true,
      );

      // UI 업데이트를 위한 지연
      await Future.delayed(const Duration(milliseconds: 100));

      // 가비지 컬렉션 유도를 위한 간단한 지연 (스냅샷 생성 없이)
      await Future.delayed(const Duration(milliseconds: 500));

      // 작업 수행 후 추가 지연
      await Future.delayed(const Duration(milliseconds: 1000));

      // 두번째 스냅샷 생성
      takeSnapshot(
        'leak_detect_end_${DateTime.now().millisecondsSinceEpoch}',
        level: MemoryProfiler.snapshotLevelHigh,
        includeStackTrace: true,
      );

      // 스냅샷 비교 및 누수 감지
      List<MemoryLeakReport> leaks = await _analyzeForLeaks();

      // 결과 업데이트
      state = state.copyWith(
        isDetecting: false,
        detectedLeaks: leaks,
      );

      logger.i('메모리 누수 감지 완료: ${leaks.length}개 발견');
      return;
    } catch (e) {
      logger.e('메모리 누수 감지 중 오류: $e');
      state = state.copyWith(isDetecting: false);
      rethrow;
    }
  }

  /// 두 스냅샷 간의 차이를 계산
  MemoryDiff? calculateDiff(String beforeLabel, String afterLabel) {
    return MemoryProfiler.instance.calculateDiff(beforeLabel, afterLabel);
  }

  /// 이미지 작업에 특화된 프로파일링 메서드
  Future<MemoryDiff?> profileImageOperation(
    String imageUrl,
    Future<void> Function() action, {
    int? imageSize,
    int level = MemoryProfiler.snapshotLevelMedium,
  }) async {
    if (!state.isEnabled) {
      await action();
      return null;
    }

    return MemoryProfiler.instance.profileImageAction(
      imageUrl,
      action,
      imageSize: imageSize,
      level: level,
    );
  }

  /// 메모리 누수 분석
  Future<List<MemoryLeakReport>> _analyzeForLeaks() async {
    final snapshots = MemoryProfiler.instance.getAllSnapshots();
    if (snapshots.length < 2) {
      return [];
    }

    // 최신 2개 스냅샷 가져오기
    final sortedSnapshots = snapshots.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final latestSnapshot = sortedSnapshots[0];
    final previousSnapshot = sortedSnapshots[1];

    final leaks = <MemoryLeakReport>[];
    final threshold =
        state.settings.minimumLeakThresholdMB * 1024 * 1024; // MB를 바이트로 변환

    // 힙 메모리 사용량 비교
    final heapDiff =
        latestSnapshot.heapUsage.used - previousSnapshot.heapUsage.used;
    if (heapDiff > threshold) {
      leaks.add(MemoryLeakReport(
        source: 'Heap',
        sizeMB: (heapDiff / (1024 * 1024)).round(),
        details:
            '힙 메모리 사용량이 ${heapDiff ~/ (1024 * 1024)}MB 증가했습니다. 이전: ${previousSnapshot.heapUsage.used ~/ (1024 * 1024)}MB, 현재: ${latestSnapshot.heapUsage.used ~/ (1024 * 1024)}MB',
        timestamp: DateTime.now(),
        stackTrace: latestSnapshot.metadata['stackTrace'] as List<String>?,
      ));
    }

    // 이미지 캐시 비교
    final imageCacheDiff = latestSnapshot.imageCacheStats.sizeBytes -
        previousSnapshot.imageCacheStats.sizeBytes;
    if (imageCacheDiff > threshold) {
      leaks.add(MemoryLeakReport(
        source: 'ImageCache',
        sizeMB: (imageCacheDiff / (1024 * 1024)).round(),
        details:
            '이미지 캐시 사용량이 ${imageCacheDiff ~/ (1024 * 1024)}MB 증가했습니다. 이전: ${previousSnapshot.imageCacheStats.sizeBytes ~/ (1024 * 1024)}MB, 현재: ${latestSnapshot.imageCacheStats.sizeBytes ~/ (1024 * 1024)}MB, 이미지 수: ${latestSnapshot.imageCacheStats.liveImages}개',
        timestamp: DateTime.now(),
        stackTrace: latestSnapshot.metadata['stackTrace'] as List<String>?,
      ));
    }

    // 이미지 개수 비교
    final imageDiff = latestSnapshot.imageCacheStats.liveImages -
        previousSnapshot.imageCacheStats.liveImages;
    if (imageDiff > 20) {
      // 20개 이상 증가한 경우
      final estimatedSize = imageDiff * 2; // 이미지당 약 2MB로 추정
      if (estimatedSize > state.settings.minimumLeakThresholdMB) {
        leaks.add(MemoryLeakReport(
          source: 'ImageProcessing',
          sizeMB: estimatedSize,
          details:
              '이미지 수가 $imageDiff개 증가했습니다. 이전: ${previousSnapshot.imageCacheStats.liveImages}개, 현재: ${latestSnapshot.imageCacheStats.liveImages}개',
          timestamp: DateTime.now(),
          stackTrace: latestSnapshot.metadata['stackTrace'] as List<String>?,
        ));
      }
    }

    return leaks;
  }
}

/// 메모리 프로파일러 프로바이더
final memoryProfilerProvider =
    StateNotifierProvider<MemoryProfilerNotifier, MemoryProfilerState>((ref) {
  final settings = ref.watch(memoryProfilerSettingsProvider);
  return MemoryProfilerNotifier(settings);
});

/// 메모리 프로파일러 위젯 래퍼
class MemoryProfilerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final bool enableInDebug;
  final bool enableAutoSnapshot;
  final int autoSnapshotIntervalSeconds;

  const MemoryProfilerWrapper({
    super.key,
    required this.child,
    this.enableInDebug = true,
    this.enableAutoSnapshot = false,
    this.autoSnapshotIntervalSeconds = 60,
  });

  @override
  ConsumerState<MemoryProfilerWrapper> createState() =>
      _MemoryProfilerWrapperState();
}

class _MemoryProfilerWrapperState extends ConsumerState<MemoryProfilerWrapper> {
  @override
  void initState() {
    super.initState();
    // 위젯 생명주기 메서드에서 상태 업데이트하는 것을 방지하기 위해
    // 마이크로태스크로 래핑하여 다음 프레임으로 지연
    Future.microtask(() => _initializeProfiler());
  }

  void _initializeProfiler() {
    if (!mounted) return; // 위젯이 이미 해제되었다면 초기화 중단

    try {
      final enableInDebug = widget.enableInDebug;
      final enableAutoSnapshot = widget.enableAutoSnapshot;
      final autoSnapshotIntervalSeconds = widget.autoSnapshotIntervalSeconds;

      // 디버그 모드에서만 활성화 (디버그 모드가 아니면 빈 작업)
      if (kDebugMode && enableInDebug) {
        // 설정 업데이트
        final settingsNotifier =
            ref.read(memoryProfilerSettingsProvider.notifier);
        settingsNotifier.state = MemoryProfilerSettings(
          enableAutoSnapshot: enableAutoSnapshot,
          autoSnapshotIntervalSeconds: autoSnapshotIntervalSeconds,
          minimumLeakThresholdMB: 20, // 기본값 설정
        );

        // 프로파일러 초기화
        ref.read(memoryProfilerProvider.notifier).initialize();

        // 자동 스냅샷 설정
        if (enableAutoSnapshot) {
          ref
              .read(memoryProfilerProvider.notifier)
              .setAutoSnapshotEnabled(true);
          ref
              .read(memoryProfilerProvider.notifier)
              .setAutoSnapshotInterval(autoSnapshotIntervalSeconds);
        }

        logger.i('메모리 프로파일러 초기화 완료');
      }
    } catch (e) {
      logger.e('메모리 프로파일러 초기화 오류: $e');
    }
  }

  @override
  void didUpdateWidget(MemoryProfilerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 설정이 변경되었는지 확인
    if (oldWidget.enableAutoSnapshot != widget.enableAutoSnapshot ||
        oldWidget.autoSnapshotIntervalSeconds !=
            widget.autoSnapshotIntervalSeconds) {
      // 설정 업데이트
      final notifier = ref.read(memoryProfilerProvider.notifier);

      // 자동 스냅샷 설정 변경
      final currentState = ref.read(memoryProfilerProvider);
      if (currentState.isEnabled) {
        if (oldWidget.autoSnapshotIntervalSeconds !=
            widget.autoSnapshotIntervalSeconds) {
          notifier.setAutoSnapshotInterval(widget.autoSnapshotIntervalSeconds);
        }

        if (oldWidget.enableAutoSnapshot != widget.enableAutoSnapshot) {
          notifier.setAutoSnapshotEnabled(widget.enableAutoSnapshot);
        }

        logger.i(
            '메모리 프로파일러 설정 변경 (자동 스냅샷: ${widget.enableAutoSnapshot}, 간격: ${widget.autoSnapshotIntervalSeconds}초)');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
