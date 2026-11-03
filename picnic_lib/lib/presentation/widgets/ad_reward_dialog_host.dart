import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';

/// 확정된 광고 보상의 영수증을 앱 어디에서든 한 번 띄우는 호스트.
///
/// **통계는 이 위젯의 책임이 아니다.** `earn_virtual_currency` 는 예전에 이
/// 호스트가 다이얼로그를 열기 직전에 보냈고, 그래서 호스트가 마운트되지
/// 않았거나 사용자가 광고 화면을 먼저 떠난 확정 적립은 통계에서 빠졌다. 지금은
/// 적립을 확인한 `AdRewardRecovery` 가 그 시점에 durable outbox 에 넣는다.
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
    final report = widget.onAcknowledgeError ?? _logAcknowledgeFailure;

    // 지급되지 않은 종결 상태(ABANDONED/DENIED/EXPIRED)는 화면에 띄우지 않는다.
    // 사용자에게 줄 새 정보가 없고, 상태 이름을 그대로 보여 주는 모달이 실행
    // 직후 여러 장 쌓인다(실측: 지갑 엔진 이전 광고 시청분이 ABANDONED 로
    // 채워지면서 일부 테스터에게 6장). 확인(acknowledge)은 그대로 수행해야
    // 큐에서 빠지고 다음 실행에 다시 폴링되지 않는다.
    if (queued.status.state != AdRewardState.granted) {
      _dialogOpen = true;
      try {
        await ref
            .read(adRewardRecoveryProvider.notifier)
            .acknowledgeAfterRender(queued);
      } catch (error, stackTrace) {
        if (mounted) {
          ref.read(adRewardRecoveryProvider.notifier).discardDialog(queued);
        }
        report(error, stackTrace);
      } finally {
        _dialogOpen = false;
        if (mounted) {
          _scheduleDialog(ref.read(adRewardRecoveryProvider));
        }
      }
      return;
    }

    // 적립 영수증과 별사탕 파우치가 같은 서버 확정 스냅샷을 보여 주도록,
    // 팝업을 띄우기 전에 공통 지갑 상태에 즉시 반영한다. 별도 재조회보다
    // 정확하고, AdMob/Pangle/내부 숏폼의 복구 팝업 경로를 한 번에 다룬다.
    //
    // 이 쓰기의 소유권은 위 이른 반환이 이미 정했다(PICNIC-2664). 구매·숏폼은
    // 응답에 소유자가 없어서 시작 시점의 토큰을 따로 들고 다녀야 하지만, 여기
    // 보상은 `queued.ownerUserId` 로 **자기 주인을 스스로 들고 온다**. 그래서
    // 그 값을 지금 로그인한 계정과 맞춰 보는 위 검사가 토큰보다 강하다.
    //
    // 그 검사와 이 줄 사이에 await 가 없다는 것이 이 가드의 전제다. 사이에
    // await 를 넣으면 그때 계정이 갈릴 수 있고, 이 쓰기는 다시 무방비가 된다.
    if (ref.exists(walletSummaryProvider)) {
      final notifier = ref.read(walletSummaryProvider.notifier);
      notifier.setSummary(queued.status.wallet, owner: notifier.captureOwner());
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
