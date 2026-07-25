import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';

class AdRewardDialogHost extends ConsumerStatefulWidget {
  const AdRewardDialogHost({
    super.key,
    required this.child,
    this.schedulePostFrame,
    this.onAcknowledgeError,
  });

  final Widget child;
  final void Function(VoidCallback callback)? schedulePostFrame;
  final void Function(Object error, StackTrace stackTrace)? onAcknowledgeError;

  @override
  ConsumerState<AdRewardDialogHost> createState() => _AdRewardDialogHostState();
}

class _AdRewardDialogHostState extends ConsumerState<AdRewardDialogHost> {
  bool _dialogOpen = false;
  String? _scheduledKey;

  String _key(OwnedAdRewardStatus value) =>
      '${value.generation}:${value.ownerUserId}:${value.status.reference.type.wireValue}:${value.status.reference.id}';

  void _scheduleDialog(AdRewardRecoveryState state) {
    if (_dialogOpen || state.dialogQueue.isEmpty) return;
    final queued = state.dialogQueue.first;
    final key = _key(queued);
    if (_scheduledKey == key) return;
    _scheduledKey = key;
    void invoke() {
      if (_scheduledKey == key) _scheduledKey = null;
      if (!mounted || _dialogOpen) return;
      unawaited(_showRewardDialog(queued));
    }

    final scheduler = widget.schedulePostFrame;
    if (scheduler != null) {
      scheduler(invoke);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => invoke());
    }
  }

  Future<void> _showRewardDialog(OwnedAdRewardStatus queued) async {
    final current = ref.read(adRewardRecoveryProvider);
    if (current.activeUserId != queued.ownerUserId ||
        current.dialogQueue.isEmpty ||
        _key(current.dialogQueue.first) != _key(queued) ||
        ref.read(adRewardOwnerReaderProvider)() != queued.ownerUserId) {
      return;
    }
    _dialogOpen = true;
    final report = widget.onAcknowledgeError ?? _logAcknowledgeFailure;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AdRewardDialogBody(
          status: queued.status,
          onFirstFrame: () => ref
              .read(adRewardRecoveryProvider.notifier)
              .acknowledgeAfterRender(queued),
          onAcknowledgeError: (error, stackTrace) {
            // Drop the reward from the in-memory queue so a failed ACK can
            // never re-present the same dialog forever. The durable record is
            // untouched, so an un-acknowledged reward stays recoverable.
            if (mounted) {
              ref.read(adRewardRecoveryProvider.notifier).discardDialog(queued);
            }
            report(error, stackTrace);
          },
        ),
      );
    } finally {
      _dialogOpen = false;
      if (mounted) {
        _scheduleDialog(ref.read(adRewardRecoveryProvider));
      }
    }
  }

  void _logAcknowledgeFailure(Object error, StackTrace stackTrace) {
    logger.e(
      'Ad reward acknowledgement failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adRewardRecoveryProvider);
    _scheduleDialog(state);
    return Stack(
      children: [
        widget.child,
        if (state.checkingReferences.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Semantics(
              liveRegion: true,
              child: Center(
                child: Material(
                  borderRadius: BorderRadius.circular(18),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(AppLocalizations.of(context).ad_reward_pending),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AdRewardDialogBody extends StatefulWidget {
  const AdRewardDialogBody({
    super.key,
    required this.status,
    required this.onFirstFrame,
    this.schedulePostFrame,
    this.onAcknowledgeError,
  });

  final AdRewardStatusModel status;
  final Future<void> Function() onFirstFrame;
  final void Function(VoidCallback callback)? schedulePostFrame;
  final void Function(Object error, StackTrace stackTrace)? onAcknowledgeError;

  @override
  State<AdRewardDialogBody> createState() => _AdRewardDialogBodyState();
}

class _AdRewardDialogBodyState extends State<AdRewardDialogBody> {
  bool _didAcknowledge = false;

  @override
  void initState() {
    super.initState();
    void invoke() {
      if (!mounted || _didAcknowledge) return;
      _didAcknowledge = true;
      final report = widget.onAcknowledgeError;
      unawaited(
        widget.onFirstFrame().catchError((Object error, StackTrace stackTrace) {
          report?.call(error, stackTrace);
        }),
      );
    }

    final scheduler = widget.schedulePostFrame;
    if (scheduler != null) {
      scheduler(invoke);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => invoke());
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = receiptFromAdReward(widget.status);
    if (receipt != null) {
      return CandyRewardReceiptDialog(receipt: receipt);
    }
    return AlertDialog(
      title: Text(AppLocalizations.of(context).ad_reward_not_granted),
      content: Text(widget.status.state.name.toUpperCase()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).confirm),
        ),
      ],
    );
  }
}
