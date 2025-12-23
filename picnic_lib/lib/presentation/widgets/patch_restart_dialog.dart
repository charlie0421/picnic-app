import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/patch_status_provider.dart';

/// 패치 다운로드 완료 후 재시작을 유도하는 다이얼로그 리스너
///
/// 앱의 상위 위젯 (예: MaterialApp 바로 아래)에 배치하여
/// 패치 상태 변경 시 자동으로 다이얼로그를 표시합니다.
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

  @override
  void initState() {
    super.initState();
    // 위젯이 마운트된 후 현재 상태 확인 (이미 restartRequired 상태일 수 있음)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentPatchStatus();
    });
  }

  /// 현재 패치 상태 확인 - 이미 restartRequired 상태이면 다이얼로그 표시
  void _checkCurrentPatchStatus() {
    if (!mounted) return;

    final currentStatus = ref.read(patchStatusProvider);
    logger.i('🔍 PatchRestartDialogListener 마운트 시 상태 확인: ${currentStatus.status}, shouldShowDialog: ${currentStatus.shouldShowDialog}');

    if (currentStatus.shouldShowDialog && !_isDialogShowing) {
      logger.i('📢 마운트 시 재시작 다이얼로그 표시 필요 - 다이얼로그 표시');
      _showRestartDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 상태를 watch하여 리빌드 시에도 상태 확인
    final currentStatus = ref.watch(patchStatusProvider);

    ref.listen<PatchStatusInfo>(
      patchStatusProvider,
      (previous, next) {
        logger.i('🔔 PatchStatusProvider 상태 변경: ${previous?.status} -> ${next.status}, shouldShowDialog: ${next.shouldShowDialog}');
        if (next.shouldShowDialog && !_isDialogShowing) {
          _showRestartDialog(context);
        }
      },
    );

    // 리빌드 시 현재 상태 확인 (initState 이후 상태가 변경된 경우 대응)
    // WidgetsBinding을 사용하여 빌드 완료 후 다이얼로그 표시
    if (currentStatus.shouldShowDialog && !_isDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDialogShowing) {
          final status = ref.read(patchStatusProvider);
          if (status.shouldShowDialog) {
            logger.i('📢 빌드 시 재시작 다이얼로그 표시 필요 - 다이얼로그 표시');
            _showRestartDialog(context);
          }
        }
      });
    }

    return widget.child;
  }

  Future<void> _showRestartDialog(BuildContext context) async {
    if (_isDialogShowing) {
      logger.i('⚠️ 다이얼로그가 이미 표시 중 - 중복 표시 방지');
      return;
    }

    logger.i('🚀 패치 재시작 다이얼로그 표시 시작');
    _isDialogShowing = true;
    ref.read(patchStatusProvider.notifier).markDialogShown();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PatchRestartDialog(),
    );

    logger.i('✅ 패치 재시작 다이얼로그 닫힘');
    _isDialogShowing = false;
  }
}

/// 재시작 다이얼로그
///
/// Android: 3초 카운트다운 후 자동 재시작 (회피 불가)
/// iOS: 앱 종료 방법 안내와 함께 확인 버튼
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

    logger.i('🔄 패치 적용을 위한 앱 재시작 실행');

    try {
      await ShorebirdUtils.restartAppForPatch();
    } catch (e) {
      logger.e('❌ 앱 재시작 실패: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _closeDialog() {
    Navigator.of(context).pop();
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

    // Android: 백 버튼으로 다이얼로그 닫기 방지
    return PopScope(
      canPop: isIOS,
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
        actions: [
          // Android: 버튼 없음 - 자동 재시작만
          // iOS: 확인 버튼 (앱 수동 종료 필요)
          if (isIOS)
            FilledButton(
              onPressed: _closeDialog,
              child: Text(l10n.patch_button_understood),
            ),
        ],
      ),
    );
  }
}
