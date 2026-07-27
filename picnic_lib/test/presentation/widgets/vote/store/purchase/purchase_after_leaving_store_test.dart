import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
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
  Future<void> finalizeSettledPurchase(PurchaseDetails purchaseDetails) async {
    settledFinalizations++;
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
  Future<void> logPurchaseEvent(
    ProductDetails product, {
    String? transactionId,
  }) async {
    logged.add(product.id);
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
      reason:
          '정산이 확정된 구매는 정확히 1회 최종 완료(consume/finish)되어야 한다',
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
    // The catalogue lookup exists only to name the product for analytics, and
    // it runs after the receipt has verified - after the candy is granted. It
    // has its own way to fail: the ids the catalogue is built from are
    // prefixed per environment (`ProductProviderHelper.buildProductIds`), so a
    // transaction whose id the catalogue does not carry throws
    // PRODUCT_NOT_FOUND here. That says nothing about whether the user paid.
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
      isEmpty,
      reason: 'there was no product to name, so nothing was logged',
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
