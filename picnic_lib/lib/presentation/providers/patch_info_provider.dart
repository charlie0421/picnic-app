import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter/material.dart';

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
class PatchInfoNotifier extends StateNotifier<PatchInfo> {
  PatchInfoNotifier() : super(const PatchInfo());

  /// 패치 정보 업데이트
  void updatePatchInfo(Map<String, dynamic>? patchData) {
    if (patchData == null) {
      state = const PatchInfo();
      return;
    }

    final now = DateTime.now();
    state = state.copyWith(
      hasUpdate: patchData['updateAvailable'] == true,
      updateDownloaded: patchData['updateDownloaded'] == true,
      needsRestart: patchData['needsRestart'] == true,
      currentPatch: patchData['currentPatch'],
      newPatch: patchData['newPatch'],
      statusMessage: _generateStatusMessage(patchData),
      lastChecked: now,
    );

    logger.i('패치 정보 업데이트됨: ${state.displayInfo}');
  }

  String _generateStatusMessage(Map<String, dynamic> patchData) {
    if (patchData['needsRestart'] == true) {
      final current = patchData['currentPatch'];
      final newer = patchData['newPatch'];
      if (current != null && newer != null) {
        return 'Update ready: v$current → v$newer';
      }
      return 'Update ready (restart required)';
    } else if (patchData['updateDownloaded'] == true) {
      return 'Update downloaded, will apply when safe';
    } else if (patchData['updateAvailable'] == true) {
      return 'Update available, downloading...';
    } else if (patchData['currentPatch'] != null) {
      return 'Current patch: ${patchData['currentPatch']}';
    } else {
      return 'No patch applied';
    }
  }

  /// 수동 재시작 실행
  Future<void> performManualRestart(BuildContext context) async {
    if (!state.canRestart) {
      logger.w('재시작할 수 있는 업데이트가 없습니다');
      return;
    }

    try {
      logger.i('수동 재시작 시작');
      
      // 현재 컨텍스트 유효성 확인
      if (!context.mounted) {
        logger.e('수동 재시작 시도 시 컨텍스트가 유효하지 않음');
        return;
      }

      // 최상위 네비게이터 컨텍스트 사용
      final navigatorContext = Navigator.of(context, rootNavigator: true).context;

      // 현재 프레임 완료 후 재시작 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorContext.mounted) {
          try {
            Phoenix.rebirth(navigatorContext);
            logger.i('수동 재시작 성공적으로 실행됨');
          } catch (e) {
            logger.e('수동 재시작 실행 중 오류: $e');
          }
        } else {
          logger.w('수동 재시작 시도 시 네비게이터 컨텍스트가 유효하지 않음');
        }
      });

    } catch (e) {
      logger.e('수동 재시작 처리 중 오류: $e');
    }
  }

  /// 상태 초기화
  void reset() {
    state = const PatchInfo();
  }
}

/// 패치 정보 Provider
final patchInfoProvider = StateNotifierProvider<PatchInfoNotifier, PatchInfo>(
  (ref) => PatchInfoNotifier(),
); 