import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/global_purchase_provider.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_settlement_step.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/wallet_summary_applier.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_environment.dart';
import 'recording_receipt_dialogs.dart';

const _productId = 'STAR100';
const _userId = 'user-1';

/// Stands in for the store, capturing exactly what `PurchaseStarCandyState`
/// captures in `initState` and in the same place: the Riverpod container the
/// payment path reads through, and the wallet write the settlement uses.
///
/// The real widget cannot be driven through a purchase - it builds its own
/// `InAppPurchaseService`, `ReceiptVerificationService` and
/// `DuplicatePreventionService` in `initState`, none of which are injectable -
/// so the purchase itself is driven against a `PurchaseService` wired the way
/// the widget wires one. That the *real* widget's captures survive its own
/// unmount is pinned separately, at the bottom of this file, by pumping it.
class _StoreStandIn extends ConsumerStatefulWidget {
  const _StoreStandIn({required this.onInit});

  final void Function(_StoreStandInState state) onInit;

  @override
  ConsumerState<_StoreStandIn> createState() => _StoreStandInState();
}

class _StoreStandInState extends ConsumerState<_StoreStandIn> {
  late final ProviderContainer container;
  late final WalletSummaryApplier applier;

  @override
  void initState() {
    super.initState();
    container = ProviderScope.containerOf(context, listen: false);
    applier = ContainerWalletSummaryApplier.of(context);
    widget.onInit(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The store plugin, stubbed out.
///
/// `PurchaseService`'s constructor is the only thing on this path that touches
/// it - `pendingCompletePurchase` is false on the transaction below, so
/// `_completePurchaseIfNeeded` never calls through either.
class _MockInAppPurchaseService extends Mock implements InAppPurchaseService {
  /// 서버 정산이 확정된 뒤 최종 완료(consume/finish)가 호출된 횟수.
  ///
  /// 정산 성공 경로는 정확히 1회여야 한다: 0회면 미소비 잔류(재구매 차단),
  /// 정산 실패에 호출되면 복구 불가능한 선소비다.
  int settledFinalizations = 0;

  @override
  Future<void> clearPendingPurchasesOnStartup() async {}

  @override
  Future<bool> finalizeSettledPurchase(PurchaseDetails purchaseDetails) async {
    settledFinalizations++;
    return true;
  }
}

/// Returns a settled receipt without going near the network.
///
/// A subclass rather than a mock so the real `PurchaseService` calls the real
/// method signatures; only the two calls that leave the device are replaced.
class _SettlingVerification extends ReceiptVerificationService {
  _SettlingVerification(this.result);

  final PurchaseSettlementResultModel result;
  int verifications = 0;

  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async {
    verifications++;
    return result;
  }
}

/// Counts the purchases that actually reached analytics.
///
/// Without this, "the settlement survived" and "the analytics step was skipped
/// and its failure swallowed" look identical from the outside - and the second
/// is how the defect would look if it were papered over instead of fixed.
class _RecordingAnalytics extends AnalyticsService {
  final List<String> logged = [];

  @override
  Future<void> logPurchasePayload({
    required String storeProductId,
    required String? currency,
    required num? value,
    String? transactionId,
    String? idempotencyFallbackKey,
    num? baseAmount,
    num? bonusAmount,
    Duration sendTimeout = AnalyticsService.defaultSendTimeout,
  }) async {
    logged.add(storeProductId);
  }
}

/// Records what the duplicate-prevention service was told about the outcome.
///
/// This is the ledger the defect corrupted: a purchase the server had already
/// settled was reported here as `success: false`.
class _RecordingDuplicatePrevention extends DuplicatePreventionService {
  _RecordingDuplicatePrevention(super.ref);

  final List<bool> outcomes = [];

  @override
  void completePurchase(
    String productId,
    String userId, {
    required bool success,
  }) {
    outcomes.add(success);
    super.completePurchase(productId, userId, success: success);
  }
}

void main() {
  late ProviderContainer container;
  late _StoreStandInState store;
  late PurchaseSafetyManager manager;
  late PurchaseCampaignAttemptRegistry attempts;
  late _RecordingDuplicatePrevention duplicates;
  late _RecordingAnalytics analytics;
  late _SettlingVerification verification;
  late _MockInAppPurchaseService plugin;
  late PurchaseService service;
  late RecordingReceiptDialogs dialogs;
  late List<String> errors;

  setUp(() async {
    initTestColors();
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth({}, userId: _userId);
    errors = [];
  });

  tearDown(tearDownMockSupabase);

  final settled = WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.from(100),
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026, 2),
  );

  final verified = PurchaseSettlementResultModel(
    contractVersion: 'wallet.v1',
    operationId: 'operation',
    replayed: false,
    baseStarAmount: BigInt.from(100),
    baseBonusAmount: BigInt.zero,
    promotion: null,
    wallet: settled,
  );

  final soldProduct = ProductDetails(
    id: _productId,
    title: 'Star Candy 100',
    description: '100 star candies',
    price: '1.99',
    rawPrice: 1.99,
    currencyCode: 'USD',
  );

  final transaction = PurchaseDetails(
    productID: _productId,
    purchaseID: 'txn-$_productId',
    transactionDate: DateTime.utc(2027).millisecondsSinceEpoch.toString(),
    status: PurchaseStatus.purchased,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
  );

  /// Mounts the stand-in store, then walks the user out of it.
  ///
  /// Everything after this point runs against a `State` that is gone - which
  /// is the whole scenario: receipt verification takes as long as the network
  /// takes, and nothing keeps the store alive for it.
  Future<void> openStoreThenLeave(
    WidgetTester tester, {
    required FutureOr<List<ProductDetails>> Function() storeCatalogue,
  }) async {
    container = ProviderContainer(
      overrides: [
        // Never resolves on its own, so the only thing that can put a balance
        // in it is the settlement under test.
        walletSummaryProvider.overrideWithBuild(
          (ref, notifier) => Completer<WalletSummaryModel>().future,
        ),
        storeProductsProvider.overrideWithBuild(
          (ref, notifier) => storeCatalogue(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _StoreStandIn(onInit: (created) => store = created),
      ),
    );

    verification = _SettlingVerification(verified);
    duplicates = _RecordingDuplicatePrevention(store.ref);
    analytics = _RecordingAnalytics();
    plugin = _MockInAppPurchaseService();
    service = PurchaseService(
      container: store.container,
      inAppPurchaseService: plugin,
      receiptVerificationService: verification,
      analyticsService: analytics,
      duplicatePreventionService: duplicates,
      onPurchaseUpdate: (_) {},
    );

    manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () {},
    );
    attempts = PurchaseCampaignAttemptRegistry();
    dialogs = RecordingReceiptDialogs();

    const attempt = PurchaseCampaignAttempt(
      attemptId: 'attempt-1',
      productId: _productId,
      displayedCampaign: null,
    );
    attempts.begin(attempt);
    manager.recordPurchaseAttempt(productId: _productId);
    attempts.applyLaunchResult(_productId, attempt.attemptId, const {
      'success': true,
      'wasCancelled': false,
    });
    expect(attempts.bind(transaction)?.attemptId, attempt.attemptId);

    // The user leaves the store while verification is in flight.
    await tester.pumpWidget(const SizedBox());
    expect(store.mounted, isFalse);
  }

  /// Drives the production entry point, wired the way
  /// `PurchaseStarCandyState._processActivePurchase` wires it.
  Future<void> deliverVerifiedPurchase(WidgetTester tester) async {
    const attempt = PurchaseCampaignAttempt(
      attemptId: 'attempt-1',
      productId: _productId,
      displayedCampaign: null,
    );

    final running = service.handleOptimizedPurchase(
      transaction,
      (result) async {
        await const PurchaseSettlementStep().settle(
          safetyManager: manager,
          attempts: attempts,
          purchaseDetails: transaction,
          result: result,
          attempt: attempt,
          cleanupAllTimersOnSuccess: (_) => manager.cleanupAllTimersOnSuccess(),
          applyWalletSummary: store.applier,
          isMounted: () => store.mounted,
          resetProductPurchaseState: manager.resetProductState,
          hideLoading: () {},
          receiptDialogs: dialogs,
        );
      },
      errors.add,
      isActualPurchase: true,
    );

    // PurchaseSafetyManager.performPostPurchaseCleanup delays before handing
    // control back. Let fake time run it out.
    await tester.pump(const Duration(seconds: 1));
    await running;

    manager.disposeSafetyTimer();
  }

  testWidgets('a receipt verified after the user leaves the store credits the '
      'wallet and releases the attempt', (tester) async {
    await openStoreThenLeave(tester, storeCatalogue: () => [soldProduct]);

    await deliverVerifiedPurchase(tester);

    expect(verification.verifications, 1);
    expect(
      plugin.settledFinalizations,
      1,
      reason: '정산이 확정된 구매는 정확히 1회 최종 완료(consume/finish)되어야 한다',
    );
    expect(
      analytics.logged,
      [_productId],
      reason:
          'the product lookup this needs is a provider read, and it is the '
          'read that used to go through the store\'s WidgetRef and throw; '
          'seeing the event logged is what tells "it worked with the store '
          'gone" apart from "it failed and the failure was swallowed"',
    );
    expect(
      container.read(walletSummaryProvider).value,
      same(settled),
      reason:
          'the candy was granted server-side the moment the receipt verified; '
          'the balance the store reads on the way back in must be the settled '
          'one, not the pre-purchase one',
    );
    expect(
      errors,
      isEmpty,
      reason:
          'nothing failed - an error here is the success path being reported '
          'as a failure because a post-verification read threw',
    );
    expect(
      duplicates.outcomes,
      [true],
      reason:
          'the duplicate-prevention ledger must record the purchase the way '
          'the server settled it; a false here is a settled purchase filed as '
          'a failure',
    );
    expect(
      attempts.contains(_productId),
      isFalse,
      reason:
          'settlement releases the attempt even with nothing to present to, so '
          'the tile is not left mid-purchase for a store that comes back',
    );
    expect(
      dialogs.plainReceipts + dialogs.lateReceipts,
      0,
      reason: 'there is no store on screen to present a receipt to',
    );
  });

  testWidgets('a product the store catalogue does not carry still settles', (
    tester,
  ) async {
    // 카탈로그에 SKU가 없어도 transaction/operation과 정산 수량은 이미 있다.
    // currency/value를 지어내지는 않되 durable payload 자체는 남겨야 한다.
    await openStoreThenLeave(
      tester,
      storeCatalogue: () => [
        ProductDetails(
          id: 'STAR500',
          title: 'Star Candy 500',
          description: '500 star candies',
          price: '9.99',
          rawPrice: 9.99,
          currencyCode: 'USD',
        ),
      ],
    );

    await deliverVerifiedPurchase(tester);

    expect(
      container.read(walletSummaryProvider).value,
      same(settled),
      reason:
          'analytics bookkeeping is downstream of the money; it must not be '
          'able to take the wallet write down with it',
    );
    expect(
      analytics.logged,
      <String>[_productId],
      reason: 'catalogue miss must not erase an already-settled purchase',
    );
    expect(errors, isEmpty);
    expect(duplicates.outcomes, [true]);
    expect(attempts.contains(_productId), isFalse);
  });

  testWidgets('the real store still applies its wallet write after the user '
      'has walked out of it', (tester) async {
    // The eager-capture pin, and the only test that pumps
    // `PurchaseStarCandyState` itself. `_applyWalletSummary` is *assigned* in
    // `initState`; spelling it as a `late final` initializer instead compiles,
    // keeps every other test in the suite green, and defers
    // `ProviderScope.containerOf(context)` to the first read - which happens
    // inside the settlement callback, on a defunct context. Reading the field
    // here for the first time, with the store already gone, is the only place
    // the two spellings differ.
    setupMockSupabase({
      'products': [
        {
          'id': _productId,
          'price': 1.99,
          'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
        },
      ],
    });

    // The app-level scope, which is what the store is mounted inside in
    // production: leaving the store pops a route, it does not tear the
    // container down.
    final app = ProviderContainer(
      overrides: [
        ...defaultProviderOverrides(),
        walletSummaryProvider.overrideWithBuild(
          (ref, notifier) => Completer<WalletSummaryModel>().future,
        ),
      ],
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(_appAround(app, const PurchaseStarCandy()));
    final state = tester.state<PurchaseStarCandyState>(
      find.byType(PurchaseStarCandy),
    );
    await tester.pump(const Duration(seconds: 2));

    // The user leaves the store.
    await tester.pumpWidget(_appAround(app, const SizedBox()));
    await tester.pump(const Duration(seconds: 5));
    expect(state.mounted, isFalse);

    state.walletSummaryApplier(settled);

    expect(
      app.read(walletSummaryProvider).value,
      same(settled),
      reason:
          'the capture has to have happened while the store was mounted; done '
          'lazily it runs here instead, where the context is defunct, and the '
          'settled balance never reaches the provider',
    );
  });

  // =========================================================================
  // 화면이 **한 번도 없었던** 구매.
  //
  // 위 그룹은 "스토어가 있었고 사용자가 나갔다" 를 다룬다. 그 경우조차
  // 예전에는 dispose 된 State 의 콜백이 이벤트를 받아 준 덕분에 살아났다.
  // 살아나지 못한 쪽은 스토어가 **애초에 열린 적이 없는** 경우다:
  // purchaseStream 구독 자체가 스토어 화면 initState 에서만 만들어졌고,
  // broadcast 스트림이라 리스너 없는 이벤트는 그냥 사라졌다. 앱이 결제 중에
  // 죽었다가 재실행된 경우, Face ID 중 백그라운드로 간 경우, **Ask to Buy
  // 승인이 몇 시간 뒤에 도착한 경우**, 다른 기기에서 결제한 경우가 전부
  // 여기에 해당한다. 복구 수단은 "스토어 화면을 열어 보세요" 였다.
  //
  // GlobalPurchaseListener 가 그 구독을 앱 수명으로 옮긴다. 여기서 고정하는
  // 것은 (1) 화면 없이도 정산·적립·완료 처리가 끝나는지, (2) 띄울 화면이
  // 생기면 공용 영수증이 뜨는지, (3) 스토어가 붙어 있으면 무화면 경로가
  // **동시에 돌지 않는지**(= 이중 정산 없음)다.
  // =========================================================================
  group('a purchase that arrives with no store screen', () {
    late _RecordingContainerDuplicatePrevention headlessDuplicates;
    late _RecordingHeadlessPresenter presenter;
    late _RecordingRefresher refresher;

    /// Builds the app-level listener the way the provider builds it, with only
    /// the collaborators that leave the device replaced. No widget is mounted at
    /// any point - that is the scenario.
    GlobalPurchaseListener buildListener({
      required ReceiptVerificationService verificationStub,
      required bool uiSurfaceAvailable,
    }) {
      container = ProviderContainer(
        overrides: [
          walletSummaryProvider.overrideWithBuild(
            (ref, notifier) => Completer<WalletSummaryModel>().future,
          ),
          storeProductsProvider.overrideWithBuild(
            (ref, notifier) => [soldProduct],
          ),
        ],
      );
      addTearDown(container.dispose);

      plugin = _MockInAppPurchaseService();
      analytics = _RecordingAnalytics();
      headlessDuplicates = _RecordingContainerDuplicatePrevention(container);
      presenter = _RecordingHeadlessPresenter(canPresent: uiSurfaceAvailable);
      refresher = _RecordingRefresher();

      return GlobalPurchaseListener(
        container: container,
        presenter: presenter,
        refreshWalletSummary: refresher,
        purchaseServiceFactory: (appContainer, onPurchaseUpdate) =>
            PurchaseService(
              container: appContainer,
              inAppPurchaseService: plugin,
              receiptVerificationService: verificationStub,
              analyticsService: analytics,
              duplicatePreventionService: headlessDuplicates,
              onPurchaseUpdate: onPurchaseUpdate,
            ),
      );
    }

    test('settles, credits the wallet and finishes the transaction with '
        'nothing on screen', () async {
      final listener = buildListener(
        verificationStub: _SettlingVerification(verified),
        uiSurfaceAvailable: false,
      );

      listener.handlePurchaseUpdates([transaction]);
      await listener.pendingHeadlessWork;

      expect(
        container.read(walletSummaryProvider).value,
        same(settled),
        reason:
            '화면이 없어도 지갑은 반영해야 한다 - 이 반영이 무음 정산에서 '
            '사용자에게 도달하는 유일한 통로다',
      );
      expect(
        plugin.settledFinalizations,
        1,
        reason:
            '정산이 확정된 트랜잭션은 정확히 1회 완료(finish/consume)되어야 '
            '한다 - 이걸 빼면 매 실행마다 같은 트랜잭션이 재전달된다',
      );
      expect(headlessDuplicates.outcomes, [
        true,
      ], reason: '서버가 정산한 구매는 중복 방지 원장에도 성공으로 기록된다');
      expect(presenter.settlements, isEmpty, reason: '띄울 화면이 없으면 아무것도 띄우지 않는다');
      expect(
        analytics.logged,
        [_productId],
        reason:
            '카탈로그 조회는 provider read 다 - 예전에는 이 read 가 스토어의 '
            'WidgetRef 를 타서 화면이 없으면 던졌다',
      );
    });

    test('presents the shared receipt when a UI surface exists', () async {
      final listener = buildListener(
        verificationStub: _SettlingVerification(verified),
        uiSurfaceAvailable: true,
      );

      listener.handlePurchaseUpdates([transaction]);
      await listener.pendingHeadlessWork;

      expect(
        presenter.settlements.map((r) => r.operationId),
        ['operation'],
        reason:
            '스토어가 없더라도 네비게이터가 있으면 사용자는 자기가 무엇을 '
            '받았는지 알아야 한다 - AdRewardDialogHost 와 같은 "가능하면 '
            '띄운다" 규칙',
      );
      expect(container.read(walletSummaryProvider).value, same(settled));
      expect(plugin.settledFinalizations, 1);
    });

    test('a grant-confirmed duplicate re-reads the wallet and finishes the '
        'transaction', () async {
      // #116 의 무화면 판본: 응답에 금액이 없으므로 지갑은 다시 읽어야 하고,
      // 지급은 이미 끝났으므로 트랜잭션은 완료해야 한다.
      final listener = buildListener(
        verificationStub: _DuplicateVerification(grantConfirmed: true),
        uiSurfaceAvailable: true,
      );

      listener.handlePurchaseUpdates([transaction]);
      await listener.pendingHeadlessWork;

      expect(refresher.refreshes, 1);
      expect(presenter.acknowledgements, 1);
      expect(presenter.settlements, isEmpty, reason: '보여줄 금액이 없다');
      expect(plugin.settledFinalizations, 1);
      expect(headlessDuplicates.outcomes, [true]);
    });

    test(
      'an unconfirmed outcome preserves the transaction and says nothing',
      () async {
        // #119 의 무화면 판본: 미확정은 실패가 아니다. 무화면 경로에는 "다시 시도
        // 해 주세요" 를 띄울 방법이 아예 없어야 한다 - 소비형 상품에서 그 안내는
        // 되돌릴 수 없는 이중 과금을 만든다.
        final listener = buildListener(
          verificationStub: _FailingVerification(
            FunctionException(status: 503, details: null, reasonPhrase: 'test'),
          ),
          uiSurfaceAvailable: true,
        );

        listener.handlePurchaseUpdates([transaction]);
        await listener.pendingHeadlessWork;

        expect(
          plugin.settledFinalizations,
          0,
          reason: '미확정 트랜잭션을 완료하면 과금된 영수증이 소멸한다',
        );
        expect(presenter.settlements, isEmpty);
        expect(presenter.acknowledgements, 0);
        expect(
          container.read(walletSummaryProvider).value,
          isNull,
          reason: '정산되지 않은 구매로 잔액을 움직여서는 안 된다',
        );
      },
    );

    test('a mounted surface takes delivery and the headless path does not also '
        'run', () async {
      // 이중 전달·이중 정산이 없다는 것을 직접 고정한다. 서피스는 스토어가
      // 쓰는 것과 같은 PurchaseSettlementStep 을 그대로 돌린다.
      final surfaceVerification = _SettlingVerification(verified);
      final listener = buildListener(
        verificationStub: surfaceVerification,
        uiSurfaceAvailable: true,
      );
      final surfaceDialogs = RecordingReceiptDialogs();
      final surfaceManager = PurchaseSafetyManager(
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        resetPurchaseState: () {},
      );
      addTearDown(surfaceManager.disposeSafetyTimer);
      final surfaceAttempts = PurchaseCampaignAttemptRegistry();
      const attempt = PurchaseCampaignAttempt(
        attemptId: 'attempt-1',
        productId: _productId,
        displayedCampaign: null,
      );
      surfaceAttempts.begin(attempt);
      surfaceManager.recordPurchaseAttempt(productId: _productId);

      var surfaceDeliveries = 0;
      Future<void>? surfaceWork;
      final registration = listener.attachSurface((purchases) {
        surfaceDeliveries++;
        surfaceWork = listener.purchaseService.handleOptimizedPurchase(
          purchases.single,
          (result) => const PurchaseSettlementStep().settle(
            safetyManager: surfaceManager,
            attempts: surfaceAttempts,
            purchaseDetails: purchases.single,
            result: result,
            attempt: attempt,
            cleanupAllTimersOnSuccess: (_) =>
                surfaceManager.cleanupAllTimersOnSuccess(),
            applyWalletSummary: ContainerWalletSummaryApplier.forContainer(
              container,
            ),
            isMounted: () => true,
            resetProductPurchaseState: surfaceManager.resetProductState,
            hideLoading: () {},
            receiptDialogs: surfaceDialogs,
          ),
          (_) {},
          isActualPurchase: true,
        );
      });

      expect(listener.hasSurface, isTrue);
      listener.handlePurchaseUpdates([transaction]);
      await surfaceWork;
      // 무화면 경로가 뒤늦게 끼어들지 않는지까지 확인한다.
      await listener.pendingHeadlessWork;

      expect(surfaceDeliveries, 1);
      expect(
        surfaceDialogs.plainReceipts,
        1,
        reason:
            '스토어가 떠 있으면 영수증은 여전히 스토어 경로로 뜬다 - 서피스는 '
            '두 번째 구독자가 아니라 위임 대상이다',
      );
      expect(
        presenter.settlements,
        isEmpty,
        reason:
            '무화면 프리젠터가 같이 돌면 하나의 결제에 영수증이 두 장 뜨고, '
            '정산도 두 번 시도된다',
      );
      expect(
        surfaceVerification.verifications,
        1,
        reason: '전달 경로는 하나다 - 검증도 한 번뿐이어야 한다',
      );
      expect(plugin.settledFinalizations, 1);

      registration.detach();
      expect(listener.hasSurface, isFalse);
    });

    test(
      'detaching the surface hands delivery back to the headless path',
      () async {
        final listener = buildListener(
          verificationStub: _SettlingVerification(verified),
          uiSurfaceAvailable: false,
        );
        var surfaceDeliveries = 0;
        listener.attachSurface((_) => surfaceDeliveries++).detach();

        listener.handlePurchaseUpdates([transaction]);
        await listener.pendingHeadlessWork;

        expect(surfaceDeliveries, 0);
        expect(
          plugin.settledFinalizations,
          1,
          reason:
              '스토어를 닫는 순간부터 무화면 정산이 이어받는다 - 이 인수인계가 '
              '없으면 화면을 닫은 뒤의 이벤트가 다시 유실된다',
        );
      },
    );

    test(
      'an old surface detaching cannot silence a store that just opened',
      () async {
        final listener = buildListener(
          verificationStub: _SettlingVerification(verified),
          uiSurfaceAvailable: false,
        );
        final stale = listener.attachSurface((_) {});
        var freshDeliveries = 0;
        listener.attachSurface((_) => freshDeliveries++);

        // 라우트 전환에서 이전 화면의 dispose 가 새 화면의 initState 뒤에 온다.
        stale.detach();

        listener.handlePurchaseUpdates([transaction]);
        expect(freshDeliveries, 1);
        expect(listener.hasSurface, isTrue);
      },
    );
  });

  testWidgets('opening and closing the store twice leaves exactly one purchase '
      'stream subscription', (tester) async {
    // The invariant, on the real widget. `purchaseStream` is a broadcast
    // stream: a second subscriber receives every event as well, which means two
    // settlements for one charge and two attempts to finish the same
    // transaction. The store used to construct its own `PurchaseService` in
    // `initState`, so the subscription's lifetime was the route's; now it reads
    // the app-level one and only registers itself as a presentation surface.
    setupMockSupabase({
      'products': [
        {
          'id': _productId,
          'price': 1.99,
          'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
        },
      ],
    });

    final app = ProviderContainer(
      overrides: [
        ...defaultProviderOverrides(),
        walletSummaryProvider.overrideWithBuild(
          (ref, notifier) => Completer<WalletSummaryModel>().future,
        ),
      ],
    );
    addTearDown(app.dispose);

    // 앱 시작이 하는 일: 스토어가 열리기 **전에** 리스너를 만든다.
    final listener = app.read(globalPurchaseListenerProvider);
    final storeKit = InAppPurchaseService();
    final registrationsAtLaunch = storeKit.purchaseHandlerRegistrations;
    expect(
      listener.hasSurface,
      isFalse,
      reason:
          '앱만 떠 있는 상태에서는 표시 서피스가 없다 - 이 구간에 도착하는 '
          '이벤트가 예전에 유실됐던 것들이다',
    );

    for (var visit = 0; visit < 2; visit++) {
      await tester.pumpWidget(_appAround(app, const PurchaseStarCandy()));
      await tester.pump(const Duration(seconds: 2));
      expect(listener.hasSurface, isTrue, reason: '방문 $visit: 서피스 연결');

      await tester.pumpWidget(_appAround(app, const SizedBox()));
      await tester.pump(const Duration(seconds: 5));
      expect(listener.hasSurface, isFalse, reason: '방문 $visit: 서피스 반납');
    }

    expect(
      storeKit.purchaseStreamSubscriptions,
      1,
      reason:
          '프로세스 전체에서 구독은 하나다. 스토어를 두 번 열고 닫아도 움직여서는 '
          '안 된다',
    );
    expect(
      storeKit.purchaseHandlerRegistrations,
      registrationsAtLaunch,
      reason: '스토어 화면은 더 이상 전달 경로를 등록하지 않는다 - 서피스로만 붙는다',
    );
  });
}

/// The duplicate-prevention ledger, wired the app-scoped way.
///
/// `_RecordingDuplicatePrevention` above takes a `WidgetRef`, which is exactly
/// what the app-level path must not need.
class _RecordingContainerDuplicatePrevention
    extends DuplicatePreventionService {
  _RecordingContainerDuplicatePrevention(super.container)
    : super.forContainer();

  final List<bool> outcomes = [];

  @override
  void completePurchase(
    String productId,
    String userId, {
    required bool success,
  }) {
    outcomes.add(success);
    super.completePurchase(productId, userId, success: success);
  }
}

/// Records what the headless path tried to show, and whether it believed there
/// was anywhere to show it.
class _RecordingHeadlessPresenter implements HeadlessSettlementPresenter {
  _RecordingHeadlessPresenter({required this.canPresent});

  @override
  final bool canPresent;

  final List<PurchaseSettlementResultModel> settlements = [];
  int acknowledgements = 0;

  @override
  Future<void> presentSettlement(PurchaseSettlementResultModel result) async {
    settlements.add(result);
  }

  @override
  Future<void> acknowledgeSettlement() async {
    acknowledgements++;
  }
}

class _RecordingRefresher implements WalletSummaryRefresher {
  int refreshes = 0;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

/// The server reports the receipt as a duplicate.
class _DuplicateVerification extends ReceiptVerificationService {
  _DuplicateVerification({required this.grantConfirmed});

  final bool grantConfirmed;

  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async => throw ReusedPurchaseException(
    message: 'duplicate',
    grantConfirmed: grantConfirmed,
  );
}

/// Verification fails with the given error.
class _FailingVerification extends ReceiptVerificationService {
  _FailingVerification(this.failure);

  final Object failure;

  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async => throw failure;
}

/// The store, mounted the way the app mounts it: inside a `ProviderScope` that
/// outlives the route.
Widget _appAround(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
