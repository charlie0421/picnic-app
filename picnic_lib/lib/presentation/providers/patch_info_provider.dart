import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

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

      // 먼저 Phoenix.rebirth 시도
      bool restartSuccessful = false;

      try {
        // 최상위 네비게이터 컨텍스트 사용
        final navigatorContext =
            Navigator.of(context, rootNavigator: true).context;

        if (navigatorContext.mounted) {
          logger.i('Phoenix.rebirth를 사용하여 앱 재시작 시도');
          Phoenix.rebirth(navigatorContext);
          restartSuccessful = true;
          logger.i('Phoenix.rebirth 성공적으로 실행됨');
        }
      } catch (e) {
        logger.e('Phoenix.rebirth 실패: $e');
        restartSuccessful = false;
      }

      // Phoenix.rebirth가 실패한 경우 대체 방법 시도
      if (!restartSuccessful && context.mounted) {
        logger.i('Phoenix.rebirth 실패, 대체 방법 시도');

        // 플랫폼별 대체 방법
        if (Platform.isAndroid) {
          await _attemptAndroidRestart(context);
        } else if (Platform.isIOS) {
          await _attemptIOSRestart(context);
        } else {
          await _showManualRestartDialog(context);
        }
      }
    } catch (e) {
      logger.e('수동 재시작 처리 중 오류: $e');
      if (context.mounted) {
        await _showRestartErrorDialog(context);
      }
    }
  }

  /// Android 재시작 대체 방법
  Future<void> _attemptAndroidRestart(BuildContext context) async {
    try {
      logger.i('Android 대체 재시작 방법 시도');

      // 사용자에게 수동 재시작 안내
      final shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('앱 재시작 필요'),
          content: Text(
            '패치 적용을 위해 앱을 다시 시작해야 합니다.\n\n'
            '앱을 종료하고 다시 시작해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('앱 종료'),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        logger.i('사용자가 앱 종료에 동의함');
        // 안드로이드의 경우 시스템 종료 시도
        await SystemNavigator.pop();

        // 만약 SystemNavigator.pop이 작동하지 않으면 exit 시도
        if (Platform.isAndroid) {
          exit(0);
        }
      }
    } catch (e) {
      logger.e('Android 재시작 시도 중 오류: $e');
      if (context.mounted) {
        await _showManualRestartDialog(context);
      }
    }
  }

  /// iOS 재시작 대체 방법
  Future<void> _attemptIOSRestart(BuildContext context) async {
    try {
      logger.i('iOS 대체 재시작 방법 시도');

      // iOS에서는 강제 종료가 제한적이므로 사용자 안내만 제공
      await _showManualRestartDialog(context);
    } catch (e) {
      logger.e('iOS 재시작 시도 중 오류: $e');
      if (context.mounted) {
        await _showManualRestartDialog(context);
      }
    }
  }

  /// 수동 재시작 안내 다이얼로그
  Future<void> _showManualRestartDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('수동 재시작 필요'),
        content: Text(
          '새로운 패치를 적용하려면 앱을 수동으로 재시작해야 합니다.\n\n'
          '다음 단계를 따라주세요:\n'
          '1. 앱을 완전히 종료합니다\n'
          '2. 앱을 다시 실행합니다\n\n'
          '패치가 자동으로 적용됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 재시작 오류 다이얼로그
  Future<void> _showRestartErrorDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('재시작 오류'),
        content: Text(
          '앱 재시작 중 오류가 발생했습니다.\n\n'
          '앱을 수동으로 종료하고 다시 시작해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
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
