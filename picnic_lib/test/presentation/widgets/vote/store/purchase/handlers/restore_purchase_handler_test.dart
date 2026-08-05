import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/unfinished_purchase_source.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/restore_purchase_handler.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../../helpers/mock_supabase.dart';

/// Store entry used to await [InAppPurchaseService.restorePurchases] and then
/// guess completion by polling a quiet-time heuristic - the plugin call has
/// no completion signal, and doesn't apply to consumables (star candy) at
/// all per store restore semantics, so this cost ~700ms+ on every store
/// visit even with nothing to clean up.
///
/// [PurchaseService.sweepUnfinishedPurchases] already exists, is already
/// exercised by [GlobalPurchaseListener]'s cold-start/resume sweep, and
/// reads the store's transaction queue directly (no restore round trip, a
/// real completion signal). This fixes the store-entry gate to use it.
void main() {
  const userId = 'user-1';

  late _FakeUnfinishedSource source;
  late PurchaseService service;
  late ProviderContainer container;
  late BuildContext capturedContext;
  late RestorePurchaseHandler handler;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth(const {}, userId: userId);
  });

  tearDown(tearDownMockSupabase);

  Future<void> build(WidgetTester tester, _FakeUnfinishedSource src) async {
    source = src;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedContext = context;
            container = ProviderScope.containerOf(context, listen: false);
            return const SizedBox();
          },
        ),
      ),
    );

    final duplicates = DuplicatePreventionService.forContainer(container);
    service = PurchaseService(
      container: container,
      inAppPurchaseService: _FakePlugin(),
      receiptVerificationService: _FakeVerification(),
      analyticsService: AnalyticsService(),
      duplicatePreventionService: duplicates,
      onPurchaseUpdate: (_) {},
      unfinishedPurchaseSource: source,
      // The constructor's own cold-start sweep would otherwise race the
      // handler's manual sweep in these tests and make outcomes flaky.
      sweepOnStart: false,
    );

    handler = RestorePurchaseHandler(
      purchaseService: service,
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      context: capturedContext,
    );
  }

  testWidgets(
      'completes well under the old 700ms quiet-wait floor when the queue is empty',
      (tester) async {
    await build(tester, _FakeUnfinishedSource(const UnfinishedPurchaseScan()));

    await tester.runAsync(() async {
      final stopwatch = Stopwatch()..start();
      await handler.performProactiveCleanup();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(400),
        reason: 'the old implementation floored every store visit at ~700ms '
            'via a quiet-wait heuristic even with nothing to restore; the '
            'direct queue-read sweep has a real completion signal and should '
            'return as soon as the fake scan resolves',
      );
      expect(handler.isProactiveCleanupCompleted, isTrue);
      expect(handler.canPurchase, isTrue);
    });

    handler.dispose();
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets('sweeps the queue directly instead of asking the store to restore',
      (tester) async {
    await build(tester, _FakeUnfinishedSource(const UnfinishedPurchaseScan()));

    await tester.runAsync(() async {
      await handler.performProactiveCleanup();
    });

    expect(source.scans, 1);

    handler.dispose();
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets(
      'retries when the app\'s own cold-start/resume sweep is mid-flight, '
      'instead of declaring the queue clean without checking it',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final duplicates = DuplicatePreventionService.forContainer(
      ProviderScope.containerOf(capturedContext, listen: false),
    );
    final scripted = _ScriptedPurchaseService(
      container: ProviderScope.containerOf(capturedContext, listen: false),
      inAppPurchaseService: _FakePlugin(),
      receiptVerificationService: _FakeVerification(),
      analyticsService: AnalyticsService(),
      duplicatePreventionService: duplicates,
      onPurchaseUpdate: (_) {},
      unfinishedPurchaseSource:
          _FakeUnfinishedSource(const UnfinishedPurchaseScan()),
      sweepOnStart: false,
    );

    final mockedHandler = RestorePurchaseHandler(
      purchaseService: scripted,
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      context: capturedContext,
    );

    await tester.runAsync(() async {
      await mockedHandler.performProactiveCleanup();
    });

    expect(
      scripted.callCount,
      3,
      reason: 'must keep retrying past `concurrent` outcomes rather than '
          'giving up (or declaring success) after the first one',
    );
    expect(
      scripted.waitCallCount,
      2,
      reason: 'must wait for the in-flight sweep to actually finish between '
          'retries, not guess on a fixed delay - a fixed delay can outlast '
          'a sweep that aborts (surface attach) without either side ever '
          'performing a real check',
    );
    expect(mockedHandler.isProactiveCleanupCompleted, isTrue);

    mockedHandler.dispose();
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets(
      'a failed sweep (could not check the queue) does not allow purchase, '
      'and does not finish the loading overlay stuck', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final duplicates = DuplicatePreventionService.forContainer(
      ProviderScope.containerOf(capturedContext, listen: false),
    );
    final scripted = _ScriptedPurchaseService(
      container: ProviderScope.containerOf(capturedContext, listen: false),
      inAppPurchaseService: _FakePlugin(),
      receiptVerificationService: _FakeVerification(),
      analyticsService: AnalyticsService(),
      duplicatePreventionService: duplicates,
      onPurchaseUpdate: (_) {},
      unfinishedPurchaseSource:
          _FakeUnfinishedSource(const UnfinishedPurchaseScan()),
      sweepOnStart: false,
    )..scriptedOutcome = PurchaseSweepOutcome.failed;

    final mockedHandler = RestorePurchaseHandler(
      purchaseService: scripted,
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      context: capturedContext,
    );

    // The overlay-clearing async call must still finish - "could not
    // verify" is not the same as "hung forever".
    await mockedHandler
        .performProactiveCleanup()
        .timeout(const Duration(seconds: 2));

    expect(
      mockedHandler.isProactiveCleanupCompleted,
      isFalse,
      reason: 'a queue that could not be checked must never be treated as '
          '"checked and empty" - that is exactly the gap that let purchases '
          'through without either sweep ever performing a real check',
    );

    mockedHandler.dispose();
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets(
      'a completed sweep that still preserved an unresolved transaction '
      'does not allow purchase either', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final duplicates = DuplicatePreventionService.forContainer(
      ProviderScope.containerOf(capturedContext, listen: false),
    );
    final scripted = _ScriptedPurchaseService(
      container: ProviderScope.containerOf(capturedContext, listen: false),
      inAppPurchaseService: _FakePlugin(),
      receiptVerificationService: _FakeVerification(),
      analyticsService: AnalyticsService(),
      duplicatePreventionService: duplicates,
      onPurchaseUpdate: (_) {},
      unfinishedPurchaseSource:
          _FakeUnfinishedSource(const UnfinishedPurchaseScan()),
      sweepOnStart: false,
    )
      ..scriptedOutcome = PurchaseSweepOutcome.completed
      ..scriptedPreserved = 1;

    final mockedHandler = RestorePurchaseHandler(
      purchaseService: scripted,
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      context: capturedContext,
    );

    await mockedHandler
        .performProactiveCleanup()
        .timeout(const Duration(seconds: 2));

    expect(
      mockedHandler.isProactiveCleanupCompleted,
      isFalse,
      reason: '_reconcileUnfinishedPurchases reports `completed` (not '
          '`aborted`) even when it left a transaction preserved in the '
          'queue because verification failed or a duplicate was '
          'unconfirmed - outcome alone is not enough to call the queue '
          'clean',
    );

    mockedHandler.dispose();
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets(
      'a cleanup that finishes inside the debounce window never shows the '
      'loading overlay - it must not pop back up after the screen already '
      'hid it', (tester) async {
    final overlayKey = GlobalKey<LoadingOverlayWithIconState>();
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          child: LoadingOverlayWithIcon(
            key: overlayKey,
            child: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    final duplicates = DuplicatePreventionService.forContainer(
      ProviderScope.containerOf(capturedContext, listen: false),
    );
    final scripted = _ScriptedPurchaseService(
      container: ProviderScope.containerOf(capturedContext, listen: false),
      inAppPurchaseService: _FakePlugin(),
      receiptVerificationService: _FakeVerification(),
      analyticsService: AnalyticsService(),
      duplicatePreventionService: duplicates,
      onPurchaseUpdate: (_) {},
      unfinishedPurchaseSource:
          _FakeUnfinishedSource(const UnfinishedPurchaseScan()),
      sweepOnStart: false,
    )..scriptedOutcome = PurchaseSweepOutcome.completed;

    final mockedHandler = RestorePurchaseHandler(
      purchaseService: scripted,
      loadingKey: overlayKey,
      context: capturedContext,
    );

    await mockedHandler
        .performProactiveCleanup()
        .timeout(const Duration(seconds: 2));
    // The overlay's own debounce timer fires 100ms after it was scheduled -
    // let it run its course and see whether it still pops the overlay open
    // after cleanup (which finished well under 100ms) already hid it.
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      overlayKey.currentState!.isVisible,
      isFalse,
      reason: 'cleanup finished in the same tick, well inside the 100ms '
          'debounce window meant to skip showing the spinner entirely for '
          'fast operations - the debounce timer must be cancelled, not left '
          'to fire later and pop the overlay back up after the screen '
          'already moved on',
    );

    mockedHandler.dispose();
    await tester.pump(const Duration(milliseconds: 150));
  });
}

class _FakeUnfinishedSource implements UnfinishedPurchaseSource {
  _FakeUnfinishedSource(this._scan);

  final UnfinishedPurchaseScan _scan;

  int scans = 0;

  @override
  String get label => 'fake';

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    scans++;
    return _scan;
  }
}

/// A [PurchaseService] whose [sweepUnfinishedPurchases] answers `concurrent`
/// twice before answering `completed`, simulating GlobalPurchaseListener's
/// own cold-start/resume sweep still occupying the lock when the store
/// screen's manual sweep first asks.
class _ScriptedPurchaseService extends PurchaseService {
  _ScriptedPurchaseService({
    required super.container,
    required super.inAppPurchaseService,
    required super.receiptVerificationService,
    required super.analyticsService,
    required super.duplicatePreventionService,
    required super.onPurchaseUpdate,
    required super.unfinishedPurchaseSource,
    required super.sweepOnStart,
  });

  int callCount = 0;
  int waitCallCount = 0;

  /// When set, every call returns this outcome directly instead of the
  /// default concurrent-twice-then-completed script.
  PurchaseSweepOutcome? scriptedOutcome;

  /// Carried on the scripted report when [scriptedOutcome] is set.
  int scriptedPreserved = 0;

  @override
  Future<PurchaseSweepReport> sweepUnfinishedPurchases({
    required PurchaseSweepTrigger trigger,
    bool Function()? shouldAbort,
  }) async {
    callCount++;
    final outcome = scriptedOutcome ??
        (callCount < 3
            ? PurchaseSweepOutcome.concurrent
            : PurchaseSweepOutcome.completed);
    return PurchaseSweepReport(
      trigger: trigger,
      outcome: outcome,
      preserved: scriptedOutcome == null ? 0 : scriptedPreserved,
    );
  }

  @override
  Future<void> waitForInFlightSweep() async {
    waitCallCount++;
  }
}

class _FakePlugin extends Mock implements InAppPurchaseService {
  @override
  void initialize(Function(List<PurchaseDetails>) onPurchaseUpdate) {}

  @override
  Future<void> clearPendingPurchasesOnStartup() async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {}
}

class _FakeVerification extends ReceiptVerificationService {
  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async =>
      PurchaseSettlementResultModel(
        contractVersion: 'wallet.v1',
        operationId: 'operation',
        replayed: true,
        baseStarAmount: BigInt.zero,
        baseBonusAmount: BigInt.zero,
        promotion: null,
        wallet: WalletSummaryModel(
          contractVersion: 'wallet.v1',
          star: BigInt.zero,
          bonus: BigInt.zero,
          cotton: BigInt.zero,
          cottonExpiringAmount: BigInt.zero,
          cottonNextExpiresAt: null,
          snapshotAt: DateTime.now(),
        ),
      );
}
