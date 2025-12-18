import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
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
  Widget build(BuildContext context) {
    ref.listen<PatchStatusInfo>(
      patchStatusProvider,
      (previous, next) {
        if (next.shouldShowDialog && !_isDialogShowing) {
          _showRestartDialog(context);
        }
      },
    );

    return widget.child;
  }

  Future<void> _showRestartDialog(BuildContext context) async {
    if (_isDialogShowing) return;

    _isDialogShowing = true;
    ref.read(patchStatusProvider.notifier).markDialogShown();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PatchRestartDialog(),
    );

    _isDialogShowing = false;
  }
}

/// 재시작 다이얼로그
class PatchRestartDialog extends ConsumerWidget {
  const PatchRestartDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: L10N 적용 필요
    final isIOS = Platform.isIOS;

    return AlertDialog(
      title: const Text('Update Ready'),
      content: Text(
        isIOS
            ? 'A new update has been downloaded. Please close and reopen the app to apply the update.'
            : 'A new update has been downloaded. Restart the app now to apply the update?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        if (!isIOS)
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ShorebirdUtils.restartAppForPatch();
            },
            child: const Text('Restart'),
          ),
        if (isIOS)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
      ],
    );
  }
}
