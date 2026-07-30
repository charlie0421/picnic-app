import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_processor.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/wallet_summary_applier.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';

/// What a mounted store screen does with a delivered purchase event.
typedef PurchaseUpdateHandler = void Function(List<PurchaseDetails> purchases);

/// Builds the one [PurchaseService] the process owns. Injectable so tests can
/// hand in stubbed collaborators without going near StoreKit/Play.
typedef PurchaseServiceFactory =
    PurchaseService Function(
      ProviderContainer container,
      PurchaseUpdateHandler onPurchaseUpdate,
    );

/// Shows a settled purchase to the user, or reports that there was nowhere to
/// show it.
abstract interface class HeadlessSettlementPresenter {
  /// Whether there is a UI surface to present on at all.
  bool get canPresent;

  /// A settlement that carries amounts.
  Future<void> presentSettlement(PurchaseSettlementResultModel result);

  /// A settlement the server reports as already done, which carries no amounts.
  Future<void> acknowledgeSettlement();
}

/// The production presenter: the app-wide navigator.
///
/// Same surface `PurchaseDialogHandler` presents its receipts on
/// (`navigatorKey.currentContext`), so a purchase that arrives with no store
/// mounted gets the same dialog it would have got with one - and when there is
/// no navigator at all (settled before the first frame, settled from a
/// background isolate) nothing is shown and the wallet write is what carries the
/// balance.
class NavigatorKeySettlementPresenter implements HeadlessSettlementPresenter {
  const NavigatorKeySettlementPresenter();

  @override
  bool get canPresent => navigatorKey.currentContext != null;

  @override
  Future<void> presentSettlement(PurchaseSettlementResultModel result) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    await presentPurchaseSettlement(context, result);
  }

  @override
  Future<void> acknowledgeSettlement() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    acknowledgePurchaseSettlement(context);
  }
}

/// A store screen's claim on purchase delivery, held for as long as it is
/// mounted.
class PurchaseSurfaceRegistration {
  PurchaseSurfaceRegistration._(this._owner, this.handler);

  final GlobalPurchaseListener _owner;
  final PurchaseUpdateHandler handler;

  /// Releases the claim. Safe to call twice, and safe to call after a newer
  /// surface has taken over - it only clears the claim if it is still this one,
  /// so an old store's `dispose` cannot silence a store that just opened.
  void detach() => _owner._detachSurface(this);
}

/// Owns purchase delivery for the whole process.
///
/// ## The gap this closes
///
/// Until this existed, the only subscription to `InAppPurchase.purchaseStream`
/// was created by the store screen
/// (`purchase_star_candy_state.dart`, `initState`). A purchase event that
/// arrived while no store was mounted therefore reached nobody:
///
/// - the app was killed mid-purchase and StoreKit re-delivered on the next
///   launch, straight into the splash screen;
/// - the user navigated away, or backgrounded the app during Face ID;
/// - **an Ask to Buy approval landed hours later**;
/// - a purchase was made on another device.
///
/// `purchaseStream` is a broadcast stream, so an event with no listener is
/// simply dropped. Recovery meant telling the user to open the store screen -
/// which is literally the instruction a tester had to be given. Apple's own
/// guidance in `in_app_purchase`'s API docs is unambiguous: *"You must subscribe
/// to this stream as soon as your app launches, preferably before returning your
/// main App Widget in main()."*
///
/// ## The invariant
///
/// **Exactly one subscription for the process lifetime.** It is enforced
/// structurally, not by convention: this class is the only place that
/// constructs a [PurchaseService] with an `onPurchaseUpdate`, and the store
/// screen now reads [purchaseService] instead of building its own. A second
/// subscriber to a broadcast stream would get every event *as well* - two
/// settlements for one charge, two receipt dialogs, two attempts to finish the
/// same transaction. `InAppPurchaseService.purchaseStreamSubscriptions` counts
/// the subscriptions actually created so a test can prove the number does not
/// move when a store opens and closes.
///
/// A mounted store still gets first refusal on the events, because it has the
/// UI state (attempt registry, per-product cooldowns, the spinner) that the
/// headless path deliberately does not: [attachSurface]. The *delivery* path is
/// single either way - the surface is a delegate, not a second subscriber.
///
/// ## Money safety
///
/// Nothing about settlement changes here. Every event, with a surface or
/// without, still goes through [PurchaseService.handleOptimizedPurchase], which
/// is where the rule lives that an unconfirmed purchase is never finished or
/// consumed. The headless path adds no dialog that could tell a user to pay
/// again: on an unconfirmed outcome it logs and leaves the transaction alone for
/// the next sweep.
class GlobalPurchaseListener {
  GlobalPurchaseListener({
    required this.container,
    PurchaseServiceFactory? purchaseServiceFactory,
    WalletSummaryApplier? applyWalletSummary,
    WalletSummaryRefresher? refreshWalletSummary,
    HeadlessSettlementPresenter presenter =
        const NavigatorKeySettlementPresenter(),
  }) : _presenter = presenter {
    _applyWalletSummary =
        applyWalletSummary ??
        ContainerWalletSummaryApplier.forContainer(container);
    _refreshWalletSummary =
        refreshWalletSummary ??
        ContainerWalletSummaryRefresher.forContainer(container);
    purchaseService = (purchaseServiceFactory ?? _buildPurchaseService)(
      container,
      handlePurchaseUpdates,
    );
  }

  /// The app-level Riverpod container.
  ///
  /// The same capture `ContainerWalletSummaryApplier` exists for, for the same
  /// reason - every read on this path happens on the far side of receipt
  /// verification, where no widget is guaranteed to be alive. Here it is not
  /// even a capture: this object *is* app-scoped, so there was never a `ref` to
  /// go stale.
  final ProviderContainer container;

  /// The single purchase service for the process.
  late final PurchaseService purchaseService;

  late final WalletSummaryApplier _applyWalletSummary;
  late final WalletSummaryRefresher _refreshWalletSummary;
  final HeadlessSettlementPresenter _presenter;

  PurchaseSurfaceRegistration? _surface;
  Future<void> _headlessWork = Future<void>.value();

  /// Whether a store screen currently owns presentation.
  bool get hasSurface => _surface != null;

  /// The headless settlement queue, so a test can await delivery. Production
  /// never waits on it - stream delivery is fire-and-forget by nature.
  @visibleForTesting
  Future<void> get pendingHeadlessWork => _headlessWork;

  static PurchaseService _buildPurchaseService(
    ProviderContainer container,
    PurchaseUpdateHandler onPurchaseUpdate,
  ) => PurchaseService(
    container: container,
    inAppPurchaseService: InAppPurchaseService(),
    receiptVerificationService: ReceiptVerificationService(),
    analyticsService: AnalyticsService(),
    // 앱 수명 컨테이너로 만든다 - 이전에는 스토어 화면의 WidgetRef 였고,
    // 그래서 이 서비스의 수명이 화면 수명에 묶여 있었다.
    duplicatePreventionService: DuplicatePreventionService.forContainer(
      container,
    ),
    onPurchaseUpdate: onPurchaseUpdate,
    // 구독은 지금(앱 첫 프레임) 세우되 리컨사일은 미룬다. 이 시점에는
    // Supabase 초기화가 runApp 이후 Phase 2 에서 아직 진행 중일 수 있고,
    // 세션 복원 전에 훑으면 정산할 계정이 없다. [sweepOnColdStart] 를 앱이
    // SDK 준비 후에 부른다.
    sweepOnStart: false,
  );

  /// Registers the mounted store as the presentation surface.
  ///
  /// Only one surface can be active. If a second registers (a route transition
  /// that briefly overlaps two store screens) the newest wins and the older
  /// registration becomes inert, which is why [PurchaseSurfaceRegistration
  /// .detach] is identity-checked.
  PurchaseSurfaceRegistration attachSurface(PurchaseUpdateHandler handler) {
    if (_surface != null) {
      logger.w('[GlobalPurchaseListener] 이전 구매 UI 서피스를 새 서피스로 교체');
    }
    final registration = PurchaseSurfaceRegistration._(this, handler);
    _surface = registration;
    logger.i('[GlobalPurchaseListener] 구매 UI 서피스 연결');
    return registration;
  }

  void _detachSurface(PurchaseSurfaceRegistration registration) {
    if (!identical(_surface, registration)) return;
    _surface = null;
    logger.i('[GlobalPurchaseListener] 구매 UI 서피스 해제 - 이후 이벤트는 무화면 정산');
  }

  /// The one entry point for every purchase event in the process.
  void handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    final surface = _surface;
    if (surface != null) {
      surface.handler(purchases);
      return;
    }

    logger.i(
      '[GlobalPurchaseListener] 화면 없이 도착한 구매 이벤트 '
      '${purchases.length}건 - 무화면 정산 실행',
    );
    // 직렬화한다: 같은 상품의 이벤트가 연달아 오면 동시 정산이 서버에 중복
    // 검증을 던지고, 그중 하나는 중복 판정으로 되돌아온다.
    _headlessWork = _headlessWork.then(
      (_) => _settleWithoutSurface(purchases),
      onError: (Object e, StackTrace s) {
        logger.e('[GlobalPurchaseListener] 이전 무화면 정산 실패', error: e, stackTrace: s);
        return _settleWithoutSurface(purchases);
      },
    );
  }

  Future<void> _settleWithoutSurface(List<PurchaseDetails> purchases) async {
    for (final details in purchases) {
      try {
        await _settleOneWithoutSurface(details);
      } catch (e, s) {
        logger.e(
          '[GlobalPurchaseListener] 무화면 정산 실패: ${details.productID}',
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  Future<void> _settleOneWithoutSurface(PurchaseDetails details) async {
    switch (details.status) {
      case PurchaseStatus.purchased:
        await settleHeadless(details);
      case PurchaseStatus.error:
      case PurchaseStatus.canceled:
        // 결제가 성립하지 않은 트랜잭션은 남겨 두면 매 실행마다 재전달되며
        // 큐를 막는다. 스토어 화면의 _processErrorAndCancel 과 같은 처리다.
        logger.w(
          '[GlobalPurchaseListener] 실패/취소 트랜잭션 정리: '
          '${details.productID} (${details.status})',
        );
        await PurchaseProcessor.completeFailedTransaction(
          purchaseDetails: details,
          inAppPurchaseService: purchaseService.inAppPurchaseService,
        );
      case PurchaseStatus.pending:
      case PurchaseStatus.restored:
        // pending 은 아직 돈이 아니고, restored 는 소비형에서 나오지 않는다.
        // 어느 쪽도 무화면에서 손댈 이유가 없다 (스토어 화면과 동일).
        logger.i(
          '[GlobalPurchaseListener] 무화면에서 무시: '
          '${details.productID} (${details.status})',
        );
    }
  }

  /// Settles one paid transaction with no widget alive anywhere.
  ///
  /// The shape mirrors the store's `_settleOrphanPurchase`, minus everything
  /// that needs a `State`: verification → server grant → wallet → receipt if
  /// there is somewhere to show it → finish, and *only* on a confirmed
  /// settlement (that gate lives in [PurchaseService.handleOptimizedPurchase]
  /// and is untouched).
  ///
  /// Returns whether the server confirmed the settlement.
  Future<bool> settleHeadless(PurchaseDetails details) async {
    var confirmed = false;
    logger.i(
      '[GlobalPurchaseListener] 무화면 정산 시작: ${details.productID} '
      '(${details.purchaseID})',
    );

    await purchaseService.handleOptimizedPurchase(
      details,
      (result) async {
        confirmed = true;
        // 지갑은 화면 유무와 무관하게 반영한다 - 영수증이 검증된 순간 지급은
        // 서버에서 끝났고, 여기서 건너뛰면 잔액이 결제 전 값에 머문다.
        _applyWalletSummary(result.wallet);
        if (_presenter.canPresent) {
          await _presenter.presentSettlement(result);
        } else {
          logger.i(
            '[GlobalPurchaseListener] 표시할 화면이 없어 무음 정산 - '
            '잔액은 지갑 반영으로 전달됨: ${details.productID}',
          );
        }
      },
      (error) {
        // 무화면 경로는 사용자에게 아무 안내도 하지 않는다. 특히 "다시
        // 시도해 주세요" 류를 띄울 수 없다는 점이 중요하다 - 소비형 상품에서
        // 그 안내는 되돌릴 수 없는 이중 과금을 유도한다. 미확정 결과는
        // 트랜잭션을 보존하고 다음 스윕이 재시도한다.
        logger.w(
          '[GlobalPurchaseListener] 무화면 정산 미확정(트랜잭션 보존): '
          '${details.productID} ($error)',
        );
      },
      isActualPurchase: true,
      onAlreadySettled: () async {
        // 서버가 지급까지 확정한 중복은 성공이다. 금액이 없으니 지갑은 다시
        // 읽는다 (스토어의 settleServerConfirmed 와 같은 이유).
        confirmed = true;
        try {
          await _refreshWalletSummary.refresh();
        } catch (e, s) {
          logger.w(
            '[GlobalPurchaseListener] 기정산 중복 후 지갑 재조회 실패: $e',
            stackTrace: s,
          );
        }
        if (_presenter.canPresent) {
          await _presenter.acknowledgeSettlement();
        }
      },
    );

    return confirmed;
  }

  /// The once-per-process sweep, called by the app once its SDKs are up.
  ///
  /// Deliberately not in the constructor: the subscription has to exist on the
  /// first frame (StoreKit re-delivers unfinished transactions as soon as the
  /// queue observer is installed), but the reconcile needs a signed-in account,
  /// and Supabase is initialised after `runApp`. A sweep that runs before
  /// session restore reports `notSignedIn` and does not consume the run, so this
  /// is belt-and-braces rather than the only guard.
  Future<PurchaseSweepReport> sweepOnColdStart() =>
      purchaseService.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );

  /// The resume half.
  ///
  /// Skipped while a store screen is mounted: the store runs its own proactive
  /// restore cleanup on entry and may have a purchase in flight, and a sweep
  /// racing that would push the same transaction through verification twice.
  Future<PurchaseSweepReport> sweepOnResume() {
    if (hasSurface) {
      logger.i('[GlobalPurchaseListener] 스토어 화면이 열려 있어 resume 스윕 생략');
      return Future.value(
        const PurchaseSweepReport(
          trigger: PurchaseSweepTrigger.resume,
          outcome: PurchaseSweepOutcome.concurrent,
        ),
      );
    }
    return purchaseService.sweepUnfinishedPurchases(
      trigger: PurchaseSweepTrigger.resume,
    );
  }

  void dispose() {
    _surface = null;
    purchaseService.dispose();
  }
}
