import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/analytics/store_catalogue_currency_resolver.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
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

/// 화면 없이 도착한 구매 이벤트가 [GlobalPurchaseListener]의 직렬화된
/// `_headlessWork` 체인에서 실제 정산을 기다리는 깊이를 추적한다.
///
/// 정산(네트워크 검증)이 이벤트 도착 속도를 못 따라가면 이 깊이가 계속
/// 자란다. 이벤트를 버려 큐를 자르는 건 안전하지 않다 - "purchased"
/// 이벤트를 잃으면 과금-미적립이 된다. 그래서 자르는 대신 관측 가능하게만
/// 만든다: 임계값에 처음 도달했을 때 한 번 경고하고, 큐가 완전히 빠졌다가
/// 다시 밀리기 시작하면 별개의 지연 사건으로 보고 다시 경고한다.
@visibleForTesting
class HeadlessQueueDepthTracker {
  HeadlessQueueDepthTracker({this.warnThreshold = 10, this.onWarn});

  final int warnThreshold;
  final void Function(int depth)? onWarn;

  int _depth = 0;
  int get depth => _depth;

  int _peak = 0;
  int get peak => _peak;

  /// 이번 밀림 사건에서 이미 경고했는지. 완전히 비워질 때만(0 으로 돌아갈
  /// 때만) 다시 내려간다 - 임계값을 살짝 스치는 정도로는 별개의 사건으로
  /// 치지 않는다(9↔10 을 오가는 정상적인 처리 흐름이 매번 경고를 새로
  /// 울리면 안 된다).
  bool _warned = false;

  void enqueue() {
    _depth++;
    if (_depth > _peak) _peak = _depth;
    if (_depth >= warnThreshold && !_warned) {
      _warned = true;
      onWarn?.call(_depth);
    }
  }

  void dequeue() {
    if (_depth > 0) _depth--;
    if (_depth == 0) _warned = false;
  }
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
    // 이 콜백은 `PurchaseService`가 아니라 여기서 소유한다 - eviction 이
    // 스토어 화면이 떠 있는 동안 일어나면 그 화면의 자체 복원 정리와
    // 경합해서는 안 되는데, `hasSurface` 를 아는 건 이 클래스뿐이다.
    ReceiptQueueService().onItemsEvicted = _onQueueItemsEvicted;
    // 큐 복구가 받은 정산의 매출 이벤트도 여기서 이어받는다. 큐는
    // `PurchaseService` 를 알지 못하므로(역방향 의존 방지) 상위가 연결한다.
    ReceiptQueueService().onSettlementRecovered =
        purchaseService.adoptRecoveredSettlement;
    // 보류된 매출 이벤트가 통화를 되찾을 유일한 경로. 이게 없으면
    // awaiting_currency 는 같은 거래가 다시 전달되지 않는 한 만료될 때까지
    // 그대로 남는다.
    AnalyticsOutbox.configureCurrencyResolver(
      StoreCatalogueCurrencyResolver(container),
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

  /// 화면이 떠 있어 미뤄 둔 eviction 리컨사일이 있는지.
  ///
  /// `_onQueueItemsEvicted`가 화면이 떠 있는 동안 잘림을 통지받으면 이걸
  /// true 로 남기고 아무것도 안 한다. 이후 화면이 닫히면(`_detachSurface`)
  /// 이 플래그를 보고 `manual` 트리거로(재개 스로틀을 무시하고) 즉시
  /// 시도한다 - 일반 `sweepOnResume()`에 맡기면 스로틀이나 다른 진행 중인
  /// 스윕에 막혀 이 특정 eviction 이 아무 재시도 없이 그냥 사라질 수 있다.
  bool _evictionReconcilePending = false;

  /// `_surface`가 바뀔 때마다(붙거나 떨어질 때마다) 증가한다.
  ///
  /// eviction/detach 로 시작한 스윕은 스토어 조회(비동기, 종종 느림) 도중
  /// 새 화면이 붙었다가 다시 떨어져도(빠른 route 전환) 그 사실을 알아야
  /// 한다 - `hasSurface`만 보면 "지금은" 화면이 없어도 그 사이에 화면이
  /// 있었다는 사실을 놓친다.
  int _surfaceGeneration = 0;

  /// 무화면 정산 대기열 깊이. 이벤트를 버리진 않지만, 정산이 밀리기
  /// 시작하면(임계값 도달) 관측할 수 있게 경고 로그를 남긴다.
  final HeadlessQueueDepthTracker _headlessQueueDepth = HeadlessQueueDepthTracker(
    onWarn: (depth) => logger.w(
      '[GlobalPurchaseListener] 무화면 정산 대기열이 $depth건까지 쌓임 - '
      '정산이 이벤트 도착 속도를 못 따라가는 중',
    ),
  );

  /// Whether a store screen currently owns presentation.
  bool get hasSurface => _surface != null;

  /// The headless settlement queue, so a test can await delivery. Production
  /// never waits on it - stream delivery is fire-and-forget by nature.
  @visibleForTesting
  Future<void> get pendingHeadlessWork => _headlessWork;

  /// 테스트가 대기열 깊이/최고치를 확인할 수 있게 노출한다.
  @visibleForTesting
  HeadlessQueueDepthTracker get headlessQueueDepth => _headlessQueueDepth;

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
    _surfaceGeneration++;
    logger.i('[GlobalPurchaseListener] 구매 UI 서피스 연결');
    return registration;
  }

  void _detachSurface(PurchaseSurfaceRegistration registration) {
    if (!identical(_surface, registration)) return;
    _surface = null;
    _surfaceGeneration++;
    logger.i('[GlobalPurchaseListener] 구매 UI 서피스 해제 - 이후 이벤트는 무화면 정산');

    if (_evictionReconcilePending) {
      unawaited(_attemptPendingEvictionReconcile());
      return;
    }

    // 스토어 화면이 떠 있는 동안은 재개 스윕이 생략된다(sweepOnResume) -
    // 화면을 벗어나는 이 시점이 그 구간에 놓쳤을 수 있는 리컨사일을 되찾을
    // 첫 기회다. 실제 앱 재개(백그라운드→포그라운드)를 기다리면, 화면만
    // 오래 띄워 둔 채 서버 장애를 겪은 사용자는 화면을 닫은 뒤에도 한참
    // 지나야 재시도된다. 재개 스로틀(최대 5분당 1회)은 그대로 적용되므로
    // 화면을 자주 여닫아도 스팸이 되지 않는다.
    unawaited(sweepOnResume());
  }

  /// 큐(receipt_queue_v1)에서 TTL/상한으로 항목이 잘렸을 때의 콜백.
  ///
  /// 항상 pending 플래그부터 세운다 - 화면이 없어 바로 시도하더라도, 다른
  /// 스윕과 겹쳐(`concurrent`) 이번엔 시도조차 못 할 수 있고, 그러면
  /// 플래그가 다시 서서 다음 detach/재개/콜드스타트 중 먼저 오는 쪽이
  /// 이어받는다.
  void _onQueueItemsEvicted() {
    _evictionReconcilePending = true;
    if (hasSurface) {
      logger.i(
        '[GlobalPurchaseListener] 스토어 화면이 열려 있어 eviction 리컨사일을 '
        '화면 종료 후로 미룸',
      );
      return;
    }
    unawaited(_attemptPendingEvictionReconcile());
  }

  /// 보류 중인 eviction 리컨사일이 있으면 처리를 시도한다.
  ///
  /// `_onQueueItemsEvicted`(화면 없을 때)/`_detachSurface`/`sweepOnResume`/
  /// `sweepOnColdStart` 가 모두 이 하나의 진입점을 공유한다 - 어느 쪽을
  /// 통해서든 pending 이 생기면, 그다음에 실제로 오는 기회(꼭 detach 가
  /// 아니어도)가 이어받아야 "다른 스윕과 겹쳐 계속 놓치는" 시나리오가
  /// 생기지 않는다.
  Future<void> _attemptPendingEvictionReconcile() async {
    if (!_evictionReconcilePending || hasSurface) return;
    _evictionReconcilePending = false;
    // 재개 스로틀에 막혀 조용히 사라지면 안 되므로 manual 트리거로
    // 강행한다(`_sweepAllowed`가 manual 은 항상 허용한다).
    final report = await _guardedSweep(trigger: PurchaseSweepTrigger.manual);
    if (report.outcome == PurchaseSweepOutcome.concurrent) {
      // 다른 스윕과 겹쳐 이번에도 시도조차 못 했다 - 기회를 잃지 않도록
      // 다시 대기시킨다.
      _evictionReconcilePending = true;
    }
  }

  /// [purchaseService.sweepUnfinishedPurchases]를, 시작 시점 이후로 화면이
  /// 붙었는지(또는 붙었다 떨어졌는지)를 계속 확인하는 `shouldAbort`와 함께
  /// 부른다.
  ///
  /// 시작 전에 한 번만 `hasSurface`를 확인하는 것으로는 부족하다 - 스토어
  /// 조회는 비동기라 그 도중에 화면이 붙을 수 있고, 그러면 그 화면의 자체
  /// 복원 로직과 검증/완료 처리가 경합한다.
  Future<PurchaseSweepReport> _guardedSweep({
    required PurchaseSweepTrigger trigger,
  }) {
    final generationAtStart = _surfaceGeneration;
    return purchaseService.sweepUnfinishedPurchases(
      trigger: trigger,
      shouldAbort: () =>
          hasSurface || _surfaceGeneration != generationAtStart,
    );
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
    _headlessQueueDepth.enqueue();
    // 직렬화한다: 같은 상품의 이벤트가 연달아 오면 동시 정산이 서버에 중복
    // 검증을 던지고, 그중 하나는 중복 판정으로 되돌아온다.
    _headlessWork = _headlessWork.then(
      (_) => _settleQueuedWithoutSurface(purchases),
      onError: (Object e, StackTrace s) {
        logger.e('[GlobalPurchaseListener] 이전 무화면 정산 실패', error: e, stackTrace: s);
        return _settleQueuedWithoutSurface(purchases);
      },
    );
  }

  Future<void> _settleQueuedWithoutSurface(
    List<PurchaseDetails> purchases,
  ) async {
    try {
      await _settleWithoutSurface(purchases);
    } finally {
      _headlessQueueDepth.dequeue();
    }
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
  Future<PurchaseSweepReport> sweepOnColdStart() async {
    // detach 로 이어받지 못한(다른 스윕과 겹쳐 concurrent 로 재무장된)
    // 보류 중인 eviction 리컨사일이 있으면, 콜드 스타트가 먼저 이어받는다.
    await _attemptPendingEvictionReconcile();
    return _guardedSweep(trigger: PurchaseSweepTrigger.coldStart);
  }

  /// The resume half.
  ///
  /// Skipped while a store screen is mounted: the store runs its own proactive
  /// restore cleanup on entry and may have a purchase in flight, and a sweep
  /// racing that would push the same transaction through verification twice.
  /// Guarded for the rest of its run too - a screen can attach *during* the
  /// (async, often slow) store scan, after this entry check already passed.
  Future<PurchaseSweepReport> sweepOnResume() async {
    if (hasSurface) {
      logger.i('[GlobalPurchaseListener] 스토어 화면이 열려 있어 resume 스윕 생략');
      return const PurchaseSweepReport(
        trigger: PurchaseSweepTrigger.resume,
        outcome: PurchaseSweepOutcome.concurrent,
      );
    }
    // detach 로 이어받지 못한 보류 중인 eviction 리컨사일이 있으면 재개가
    // 먼저 이어받는다 - 이게 소진되면 방금 갱신된 _lastSweepAt 때문에
    // 아래의 일반 resume 스윕은 대개 스로틀에 걸려 자연히 생략된다(중복
    // 왕복 없음).
    await _attemptPendingEvictionReconcile();
    return _guardedSweep(trigger: PurchaseSweepTrigger.resume);
  }

  void dispose() {
    _surface = null;
    // `ReceiptQueueService` 는 싱글턴이다 - 이 콜백을 무조건 지우면, 이
    // listener 가 dispose 된 뒤 새 listener 가 만들어지기 전에 eviction 이
    // 나면 아무도 못 듣고, 반대로 이미 새 listener 가 자기 콜백을 등록한
    // 뒤에 옛 listener 를 dispose 하면 새 콜백을 지워버릴 수 있다. 지금도
    // 내가 등록한 콜백일 때만 지운다.
    // 같은 인스턴스에서 같은 메서드를 다시 tear-off 하면 `identical()`이
    // 항상 참을 보장하지는 않으므로(구현에 따라 다름) `==`를 쓴다 - Dart는
    // 메서드 tear-off의 동등성(`==`)은 "같은 리시버 + 같은 메서드"면 항상
    // 참이라고 보장한다.
    AnalyticsOutbox.configureCurrencyResolver(null);
    if (ReceiptQueueService().onSettlementRecovered ==
        purchaseService.adoptRecoveredSettlement) {
      ReceiptQueueService().onSettlementRecovered = null;
    }
    if (ReceiptQueueService().onItemsEvicted == _onQueueItemsEvicted) {
      ReceiptQueueService().onItemsEvicted = null;
    }
    purchaseService.dispose();
  }
}
