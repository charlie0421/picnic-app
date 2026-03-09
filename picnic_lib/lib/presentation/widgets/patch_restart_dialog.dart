import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_status_provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

/// 패치 자동 체크 + 강제 재시작 다이얼로그 리스너
///
/// 앱의 상위 위젯 (MaterialApp 바로 아래)에 배치.
/// 마운트 시 직접 Shorebird 패치를 체크하고, 패치가 있으면
/// 다운로드 후 닫을 수 없는 재시작 다이얼로그를 표시합니다.
class PatchRestartDialogListener extends ConsumerStatefulWidget {
  final Widget child;

  const PatchRestartDialogListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<PatchRestartDialogListener> createState() =>
      _PatchRestartDialogListenerState();
}

class _PatchRestartDialogListenerState
    extends ConsumerState<PatchRestartDialogListener> {
  bool _isDialogShowing = false;
  bool _patchCheckDone = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndDownloadPatch();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// 앱 시작 시 패치 체크 → 다이얼로그 표시
  ///
  /// auto_update: true 환경에서는 Shorebird 엔진이 cold start 시
  /// 백그라운드에서 패치를 다운로드합니다.
  /// Flutter 코드가 실행되는 시점에는 아직 다운로드가 완료되지 않았을 수 있으므로,
  /// 즉시 체크 + 폴링(3초 간격, 최대 30초)으로 다운로드 완료를 감지합니다.
  Future<void> _checkAndDownloadPatch() async {
    if (_patchCheckDone || !mounted) return;
    _patchCheckDone = true;

    if (!await ShorebirdUtils.isPatchingAvailable()) {
      logger.i('패치 사용 불가');
      return;
    }

    try {
      final updater = shorebird.ShorebirdUpdater();

      if (!updater.isAvailable) {
        logger.i('Shorebird 사용 불가 (디버그 빌드)');
        return;
      }

      // 현재 패치 정보
      final currentPatch = await updater.readCurrentPatch();
      final currentNumber = currentPatch?.number;
      logger.i('현재 패치: ${currentNumber ?? "없음"}');

      // patchInfoProvider 업데이트 (설정 페이지 표시용)
      ref.read(patchInfoProvider.notifier).updatePatchInfo({
        'currentPatch': currentNumber,
      });

      // 즉시 체크: 이미 다운로드된 패치가 있는지
      if (await _checkForPendingPatch(updater, currentNumber)) return;

      // 서버에 새 패치가 있는지 확인
      final status = await updater.checkForUpdate().timeout(
        const Duration(seconds: 10),
        onTimeout: () => shorebird.UpdateStatus.upToDate,
      );
      logger.i('서버 패치 상태: $status');

      if (status == shorebird.UpdateStatus.outdated) {
        // auto_update가 백그라운드에서 다운로드 중일 수 있음
        // 직접 다운로드도 시도하고, 폴링도 시작
        logger.i('새 패치 존재 - 다운로드 시도 + 폴링 시작');
        _startPolling(updater, currentNumber);
        try {
          await updater.update();
          logger.i('수동 패치 다운로드 완료');
          _pollTimer?.cancel();
          if (mounted) _showRestartDialog(context);
        } catch (e) {
          logger.i('수동 다운로드 실패 (auto_update가 처리 중일 수 있음): $e');
          // 폴링이 계속 돌고 있으므로 auto_update 완료를 기다림
        }
      } else if (status == shorebird.UpdateStatus.restartRequired) {
        logger.i('재시작 필요 상태 - 다이얼로그 표시');
        if (mounted) _showRestartDialog(context);
      } else {
        // upToDate지만 auto_update가 아직 다운로드 중일 수 있음
        // 폴링으로 확인 (최대 30초)
        logger.i('현재 upToDate - auto_update 완료 대기 폴링 시작');
        _startPolling(updater, currentNumber);
      }
    } catch (e, s) {
      logger.e('패치 체크 실패 (앱 계속 실행): $e', stackTrace: s);
    }
  }

  /// readNextPatch()로 대기 중인 패치 확인
  Future<bool> _checkForPendingPatch(
    shorebird.ShorebirdUpdater updater,
    int? currentNumber,
  ) async {
    final nextPatch = await updater.readNextPatch();
    logger.i('대기 패치: ${nextPatch?.number ?? "없음"}');

    if (nextPatch != null && nextPatch.number != currentNumber) {
      logger.i('대기 패치 발견 (현재: $currentNumber, 다음: ${nextPatch.number})');
      _pollTimer?.cancel();
      if (mounted) _showRestartDialog(context);
      return true;
    }
    return false;
  }

  /// 3초 간격으로 readNextPatch() 폴링 (최대 30초)
  void _startPolling(shorebird.ShorebirdUpdater updater, int? currentNumber) {
    int attempts = 0;
    const maxAttempts = 10; // 3초 × 10 = 30초

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (!mounted || attempts > maxAttempts) {
        timer.cancel();
        logger.i('패치 폴링 종료 (시도: $attempts)');
        return;
      }

      try {
        if (await _checkForPendingPatch(updater, currentNumber)) {
          timer.cancel();
        }
      } catch (e) {
        logger.e('폴링 중 에러: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _showRestartDialog(BuildContext context) async {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    try {
      // Navigator 준비 대기
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || !context.mounted) {
        _isDialogShowing = false;
        return;
      }

      logger.i('패치 재시작 다이얼로그 표시');

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PatchRestartDialog(),
      );
    } catch (e) {
      logger.e('다이얼로그 표시 실패: $e');
    } finally {
      _isDialogShowing = false;
    }
  }
}

/// 재시작 다이얼로그
///
/// Android: 3초 카운트다운 후 자동 재시작 (닫기 불가)
/// iOS: 앱 종료 안내 (닫기 불가 - 사용자가 직접 앱 종료해야 함)
class PatchRestartDialog extends ConsumerStatefulWidget {
  const PatchRestartDialog({super.key});

  @override
  ConsumerState<PatchRestartDialog> createState() => _PatchRestartDialogState();
}

class _PatchRestartDialogState extends ConsumerState<PatchRestartDialog> {
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _isRestarting = false;

  @override
  void initState() {
    super.initState();
    // Android에서만 카운트다운 시작
    if (Platform.isAndroid) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _performRestart();
      }
    });
  }

  Future<void> _performRestart() async {
    if (_isRestarting) return;

    setState(() {
      _isRestarting = true;
    });

    logger.i('패치 적용을 위한 앱 재시작 실행');

    try {
      await ShorebirdUtils.restartAppForPatch();
    } catch (e) {
      logger.e('앱 재시작 실패: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIOS = Platform.isIOS;

    if (_isRestarting) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.patch_update_ready_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.message_setting_patch_restarting),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.patch_update_ready_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIOS
                  ? l10n.patch_update_ios_message_detailed
                  : l10n.patch_update_android_message,
            ),
            if (!isIOS) ...[
              const SizedBox(height: 16),
              Text(
                l10n.patch_auto_restart_countdown(_countdown),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (isIOS) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.patch_ios_how_to_close_title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.patch_ios_how_to_close_step1),
                    Text(l10n.patch_ios_how_to_close_step2),
                    Text(l10n.patch_ios_how_to_close_step3),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: const [],
      ),
    );
  }
}
