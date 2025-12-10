import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 패치 정보 상태 모델
class PatchInfo {
  final bool hasUpdate;
  final bool updateDownloaded;
  final bool needsRestart;
  final int? currentPatch;
  final int? newPatch;
  final String statusMessage;
  final DateTime? lastChecked;

  const PatchInfo({
    this.hasUpdate = false,
    this.updateDownloaded = false,
    this.needsRestart = false,
    this.currentPatch,
    this.newPatch,
    this.statusMessage = 'No updates available',
    this.lastChecked,
  });

  PatchInfo copyWith({
    bool? hasUpdate,
    bool? updateDownloaded,
    bool? needsRestart,
    int? currentPatch,
    int? newPatch,
    String? statusMessage,
    DateTime? lastChecked,
  }) {
    return PatchInfo(
      hasUpdate: hasUpdate ?? this.hasUpdate,
      updateDownloaded: updateDownloaded ?? this.updateDownloaded,
      needsRestart: needsRestart ?? this.needsRestart,
      currentPatch: currentPatch ?? this.currentPatch,
      newPatch: newPatch ?? this.newPatch,
      statusMessage: statusMessage ?? this.statusMessage,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  /// 사용자에게 표시할 패치 정보 문자열
  String get displayInfo {
    if (needsRestart) {
      return 'Update ready (restart required)';
    } else if (updateDownloaded) {
      return 'Update downloaded';
    } else if (hasUpdate) {
      return 'Update available';
    } else if (currentPatch != null) {
      return 'Current patch: $currentPatch';
    } else {
      return 'No patch applied';
    }
  }

  /// 재시작 가능 여부
  bool get canRestart => needsRestart;
}

/// 패치 정보 상태 관리 Provider
class PatchInfoNotifier extends Notifier<PatchInfo> {
  @override
  PatchInfo build() => const PatchInfo();

  /// 패치 정보 업데이트 메소드
  void updatePatchInfo(Map<String, dynamic> info) {
    try {
      state = state.copyWith(
        hasUpdate: info['hasUpdate'] ?? state.hasUpdate,
        updateDownloaded: info['updateDownloaded'] ?? state.updateDownloaded,
        needsRestart: info['needsRestart'] ?? state.needsRestart,
        currentPatch: info['currentPatch'] ?? state.currentPatch,
        newPatch: info['newPatch'] ?? state.newPatch,
        statusMessage: info['statusMessage'] ?? state.statusMessage,
        lastChecked: DateTime.now(),
      );

      logger.i('📊 PatchInfo 업데이트 완료: ${state.statusMessage}');
    } catch (e) {
      logger.e('❌ PatchInfo 업데이트 실패: $e');
    }
  }

  /// 패치 정보 초기화
  void reset() {
    state = const PatchInfo();
    logger.i('🔄 PatchInfo 초기화 완료');
  }
}

/// 패치 정보 Provider
final patchInfoProvider = NotifierProvider<PatchInfoNotifier, PatchInfo>(
  PatchInfoNotifier.new,
);
