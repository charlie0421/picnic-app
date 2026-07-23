import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/shorebird_update_coordinator.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 홈 UI가 준비된 뒤에만 Shorebird를 확인하고 재시작 안내를 표시합니다.
class PatchRestartDialogListener extends ConsumerStatefulWidget {
  const PatchRestartDialogListener({
    super.key,
    required this.child,
    required this.enabled,
  });

  final Widget child;
  final bool enabled;

  @override
  ConsumerState<PatchRestartDialogListener> createState() =>
      _PatchRestartDialogListenerState();
}

class _PatchRestartDialogListenerState
    extends ConsumerState<PatchRestartDialogListener>
    with WidgetsBindingObserver {
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForPatch());
    }
  }

  @override
  void didUpdateWidget(covariant PatchRestartDialogListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForPatch());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.enabled &&
        !_isDialogShowing) {
      unawaited(_checkForPatch());
    }
  }

  Future<void> _checkForPatch() async {
    if (!widget.enabled || !mounted || _isDialogShowing) return;

    final result = await ShorebirdUtils.checkAndRestartOnLaunch();
    if (!mounted) return;

    final patchNumber = result.currentPatchNumber;
    Sentry.configureScope((scope) {
      scope.setTag('shorebird.patch_number', patchNumber?.toString() ?? 'none');
      scope.setTag('shorebird.has_patch', patchNumber == null ? 'no' : 'yes');
    });

    ref.read(patchInfoProvider.notifier).updatePatchInfo({
      'currentPatch': result.currentPatchNumber,
      'newPatch': result.nextPatchNumber,
      'hasUpdate': result.state == ShorebirdRunState.restartRequired,
      'updateDownloaded': result.state == ShorebirdRunState.restartRequired,
      'needsRestart': result.state == ShorebirdRunState.restartRequired,
    });

    if (result.state == ShorebirdRunState.restartRequired) {
      await _showRestartDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _showRestartDialog(BuildContext context) async {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted || !context.mounted) return;

      logger.i('패치 재시작 다이얼로그 표시');
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PatchRestartDialog(),
      );
    } catch (error, stackTrace) {
      logger.e('다이얼로그 표시 실패', error: error, stackTrace: stackTrace);
    } finally {
      _isDialogShowing = false;
    }
  }
}

class PatchRestartDialog extends ConsumerStatefulWidget {
  const PatchRestartDialog({super.key});

  @override
  ConsumerState<PatchRestartDialog> createState() => _PatchRestartDialogState();
}

class _PatchRestartDialogState extends ConsumerState<PatchRestartDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.patch_update_ready_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.patch_update_ios_message_detailed),
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
        ),
        actions: const [],
      ),
    );
  }
}
