import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/analytics/earn_analytics_store.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';

class AdRewardDialogHost extends ConsumerStatefulWidget {
  const AdRewardDialogHost({
    super.key,
    required this.child,
    this.schedulePostFrame,
    this.onAcknowledgeError,
    this.earnAnalyticsStore,
  });

  final Widget child;
  final void Function(VoidCallback callback)? schedulePostFrame;
  final void Function(Object error, StackTrace stackTrace)? onAcknowledgeError;

  /// `earn_virtual_currency` 영속 중복 마커. 미지정이면 앱 공용 저장소를 쓴다.
  final EarnAnalyticsStore? earnAnalyticsStore;

  @override
  ConsumerState<AdRewardDialogHost> createState() => _AdRewardDialogHostState();
}

class _AdRewardDialogHostState extends ConsumerState<AdRewardDialogHost> {
  bool _dialogOpen = false;
  String? _scheduledKey;

  /// `earn_virtual_currency` 중복 방어. 예약(진행 중) · 전송 확인 · 영속 마커를
  /// 모두 [EarnAnalyticsStore] 가 관리한다.
  ///
  /// 위젯 필드로 in-memory Set 을 따로 두지 않는다: 이 Host 는 위젯 재삽입이나
  /// 중첩 네비게이터로 **두 개가 동시에 살아 있을 수 있고**, 그때 인스턴스별
  /// Set 은 서로를 전혀 막지 못한다. 스토어의 예약 상태는 저장소 키 단위
  /// 전역이라 인스턴스 수와 무관하게 하나의 방어선이다.
  late final EarnAnalyticsStore _earnStore =
      widget.earnAnalyticsStore ?? EarnAnalyticsStore();

  String _key(OwnedAdRewardStatus value) =>
      '${value.generation}:${value.ownerUserId}:${value.status.reference.type.wireValue}:${value.status.reference.id}';

  String _earnKey(OwnedAdRewardStatus value) =>
      '${value.status.reference.type.wireValue}:${value.status.reference.id}';

  /// `earn_virtual_currency` (스펙 §2-7) — 광고 리워드가 **서버에서 실제로
  /// 지급 확정된** 시점에만 발송한다.
  ///
  /// 발송 기준을 SDK 콜백이 아니라 여기로 잡은 이유:
  /// Pangle · 내부 숏폼 모두 별사탕/코튼캔디 적립은 서버(SSV·view 콜백)가 하고,
  /// 클라이언트는 `AdRewardRecovery` 폴링으로 확정 상태를 받는다. SDK 의
  /// '보상 획득' 콜백은 적립 성공을 보장하지 않으므로 그 시점에 보내면
  /// 서버 적립이 실패한 건까지 집계된다. 여기서는 `AdRewardState.granted`
  /// (= grant 가 실제로 생성된 상태)에서만 보내므로
  /// DENIED/EXPIRED/ABANDONED 는 절대 발송되지 않는다.
  ///
  /// 중복 차단과 재시도는 [EarnAnalyticsStore]가 위임하는 durable outbox 한
  /// 곳이 맡는다. reference 기반 payload 저장까지만 기다리고 Firebase 전송은
  /// dialog/ACK 수명과 분리하므로, 위젯이 사라지거나 앱이 재시작돼도 pending
  /// 항목은 sink 성공까지 남는다.
  Future<void> _logEarnVirtualCurrency(OwnedAdRewardStatus queued) async {
    final status = queued.status;
    final grant = status.grant;
    if (status.state != AdRewardState.granted ||
        grant == null ||
        grant.amount <= BigInt.zero) {
      return;
    }
    final stored = await _earnStore.enqueueEarn(
      reference: _earnKey(queued),
      virtualCurrencyName: FreeChargeGa4.currencyName(grant.currency),
      rewardAmount: grant.amount.toInt(),
      earnMethod: FreeChargeGa4.earnMethodRewardedAd,
      sectionName: FreeChargeGa4.sectionAds,
      adCategory: FreeChargeGa4.adCategoryForReference(status.reference.type),
    );
    if (!stored) {
      logger.e(
        'earn_virtual_currency outbox 저장 실패 — 적립은 완료됐지만 '
        '내구 재전송 항목을 남기지 못함: ${_earnKey(queued)}',
      );
    }
  }

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

    // 지급 확정(granted) 이 이 시점에 확인됐다. 다이얼로그 표시/ACK 성패와
    // 무관하게 적립 자체는 이미 끝났으므로 여기서 한 번 발송한다.
    // 다이얼로그 표시를 막지 않도록 기다리지 않는다 — in-flight 예약은 이
    // 호출의 첫 동기 구간(`EarnAnalyticsStore.reserve` 진입부)에서 이미 걸린다.
    unawaited(_logEarnVirtualCurrency(queued));

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
