import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';

class AdRewardDialogHost extends ConsumerStatefulWidget {
  const AdRewardDialogHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdRewardDialogHost> createState() => _AdRewardDialogHostState();
}

class _AdRewardDialogHostState extends ConsumerState<AdRewardDialogHost> {
  bool _dialogOpen = false;
  String? _scheduledKey;

  String _key(OwnedAdRewardStatus value) =>
      '${value.ownerUserId}:${value.status.reference.type.wireValue}:${value.status.reference.id}';

  void _scheduleDialog(AdRewardRecoveryState state) {
    if (_dialogOpen || state.dialogQueue.isEmpty) return;
    final queued = state.dialogQueue.first;
    final key = _key(queued);
    if (_scheduledKey == key) return;
    _scheduledKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledKey = null;
      if (!mounted || _dialogOpen) return;
      unawaited(_showRewardDialog(queued));
    });
  }

  Future<void> _showRewardDialog(OwnedAdRewardStatus queued) async {
    if (ref.read(adRewardOwnerReaderProvider)() != queued.ownerUserId) {
      ref.read(adRewardRecoveryProvider.notifier).resetForLogout();
      return;
    }
    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AdRewardDialogBody(
          status: queued.status,
          onFirstFrame: () => ref
              .read(adRewardRecoveryProvider.notifier)
              .acknowledgeAfterRender(queued),
        ),
      );
    } finally {
      _dialogOpen = false;
      if (mounted) {
        _scheduleDialog(ref.read(adRewardRecoveryProvider));
      }
    }
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
  });

  final AdRewardStatusModel status;
  final Future<void> Function() onFirstFrame;

  @override
  State<AdRewardDialogBody> createState() => _AdRewardDialogBodyState();
}

class _AdRewardDialogBodyState extends State<AdRewardDialogBody> {
  bool _didAcknowledge = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAcknowledge) return;
      _didAcknowledge = true;
      unawaited(widget.onFirstFrame());
    });
  }

  @override
  Widget build(BuildContext context) {
    final granted = widget.status.state == AdRewardState.granted;
    return AlertDialog(
      title: Text(
        granted
            ? AppLocalizations.of(context).ad_reward_granted
            : AppLocalizations.of(context).ad_reward_not_granted,
      ),
      content: granted
          ? Text(formatWalletAmount(widget.status.grant!.amount))
          : Text(widget.status.state.name.toUpperCase()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
