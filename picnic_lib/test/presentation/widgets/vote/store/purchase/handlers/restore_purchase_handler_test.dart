import 'dart:async';

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

  // 재구매 시도 시 남아있는 시도를 정리해도 되는지 확인할 때 쓰는 공개
  // 메서드. performProactiveCleanup과 같은 신호(_sweepUntilResolved)를
  // 재사용하므로, "큐를 실제로 확인했고 비어 있었다"만 true를 반환해야
  // 한다.
  testWidgets(
      'verifyStoreQueueClean returns true when the store queue is actually '
      'empty', (tester) async {
    await build(tester, _FakeUnfinishedSource(const UnfinishedPurchaseScan()));

    late bool clean;
    await tester.runAsync(() async {
      clean = await handler.verifyStoreQueueClean();
    });

    expect(clean, isTrue);

    handler.dispose();
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets(
      'verifyStoreQueueClean returns false when the scan itself fails - a '
      'failure to check is not the same as "checked, nothing there"',
      (tester) async {
    await build(
      tester,
      _FakeUnfinishedSource(
        UnfinishedPurchaseScan(error: Exception('billing client down')),
      ),
    );

    late bool clean;
    await tester.runAsync(() async {
      clean = await handler.verifyStoreQueueClean();
    });

    expect(clean, isFalse);

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

  /// 실기기 재현 (2026-08-07): 앱 설치 후 **처음** 구매를 눌렀는데
  /// "초기화 중입니다. 잠시 후 다시 시도해주세요"가 뜬다.
  ///
  /// 구매 버튼은 `_isInitializing` 동안 아예 비활성이므로 이 문구가 실제로
  /// 나오는 곳은 `_processPurchase` 의 `isProactiveCleanupCompleted` 가드뿐인데,
  /// 그 플래그는 화면 진입 시 스윕 **한 번**의 결과를 그대로 래치한다. 그때
  /// 검증에 실패하는 정상적인 이유가 여럿 있다 - 스토어 화면은 비로그인으로도
  /// 열리므로 진입 스윕이 notSignedIn 으로 끝나고(로그인은 구매 버튼을 눌러야
  /// 뜬다), 부팅 직후 조회 실패(failed), 콜드스타트 스윕과의 경합
  /// (concurrent 3회 포기)도 있다. 래치되면 안내문이 약속하는 "잠시 후 다시
  /// 시도"가 실제로는 아무 일도 하지 않아, 사용자는 화면을 나갔다 다시
  /// 들어오기 전까지 영구히 구매가 막힌다.
  group('purchase gate re-verification', () {
    Future<_ScriptedPurchaseService> buildScripted(WidgetTester tester) async {
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
      return _ScriptedPurchaseService(
        container: ProviderScope.containerOf(capturedContext, listen: false),
        inAppPurchaseService: _FakePlugin(),
        receiptVerificationService: _FakeVerification(),
        analyticsService: AnalyticsService(),
        duplicatePreventionService: DuplicatePreventionService.forContainer(
          ProviderScope.containerOf(capturedContext, listen: false),
        ),
        onPurchaseUpdate: (_) {},
        unfinishedPurchaseSource:
            _FakeUnfinishedSource(const UnfinishedPurchaseScan()),
        sweepOnStart: false,
      );
    }

    testWidgets(
        'a store entered before sign-in re-opens the gate on the next '
        'purchase attempt instead of blocking it forever', (tester) async {
      final scripted = await buildScripted(tester);
      scripted
        ..scriptedOutcome = PurchaseSweepOutcome.notSignedIn
        ..scriptedFound = 1
        ..scriptedPreserved = 1;

      final handler = RestorePurchaseHandler(
        purchaseService: scripted,
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        context: capturedContext,
      );

      await handler
          .performProactiveCleanup()
          .timeout(const Duration(seconds: 2));
      expect(
        handler.isProactiveCleanupCompleted,
        isFalse,
        reason: 'entering the store signed out cannot verify the queue',
      );

      // 사용자가 구매를 눌러 로그인 다이얼로그를 거쳐 로그인했고, 이제 큐를
      // 실제로 확인할 수 있다.
      scripted
        ..scriptedOutcome = PurchaseSweepOutcome.completed
        ..scriptedFound = 0
        ..scriptedPreserved = 0;

      late bool verified;
      await tester.runAsync(() async {
        verified = await handler.ensureProactiveCleanupCompleted();
      });

      expect(verified, isTrue);
      expect(
        handler.isProactiveCleanupCompleted,
        isTrue,
        reason: 'the gate must be re-checkable, not a write-once latch - '
            'otherwise "please try again in a moment" is a lie and the user '
            'has to leave and re-enter the store to buy anything',
      );

      handler.dispose();
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets(
        'a re-check that still cannot verify the queue keeps the gate shut',
        (tester) async {
      final scripted = await buildScripted(tester);
      scripted.scriptedOutcome = PurchaseSweepOutcome.failed;

      final handler = RestorePurchaseHandler(
        purchaseService: scripted,
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        context: capturedContext,
      );

      await handler
          .performProactiveCleanup()
          .timeout(const Duration(seconds: 2));

      late bool verified;
      await tester.runAsync(() async {
        verified = await handler.ensureProactiveCleanupCompleted();
      });

      expect(verified, isFalse);
      expect(
        handler.isProactiveCleanupCompleted,
        isFalse,
        reason: '"could not check" is still not "checked and safe" - the '
            're-check must not become a way around the double-charge guard',
      );

      handler.dispose();
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets('an already-open gate costs no extra store round trip',
        (tester) async {
      final scripted = await buildScripted(tester);
      scripted.scriptedOutcome = PurchaseSweepOutcome.completed;

      final handler = RestorePurchaseHandler(
        purchaseService: scripted,
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        context: capturedContext,
      );

      await handler
          .performProactiveCleanup()
          .timeout(const Duration(seconds: 2));
      expect(handler.isProactiveCleanupCompleted, isTrue);
      final sweepsAfterEntry = scripted.callCount;

      late bool verified;
      await tester.runAsync(() async {
        verified = await handler.ensureProactiveCleanupCompleted();
      });

      expect(verified, isTrue);
      expect(scripted.callCount, sweepsAfterEntry);

      handler.dispose();
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets('concurrent re-checks share one sweep', (tester) async {
      final scripted = await buildScripted(tester);
      scripted.scriptedOutcome = PurchaseSweepOutcome.failed;

      final handler = RestorePurchaseHandler(
        purchaseService: scripted,
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        context: capturedContext,
      );

      await handler
          .performProactiveCleanup()
          .timeout(const Duration(seconds: 2));
      final sweepsAfterEntry = scripted.callCount;

      await tester.runAsync(() async {
        scripted
          ..scriptedOutcome = PurchaseSweepOutcome.completed
          ..gate = Completer<void>();

        final first = handler.ensureProactiveCleanupCompleted();
        final second = handler.ensureProactiveCleanupCompleted();
        scripted.gate!.complete();

        expect(await first, isTrue);
        expect(await second, isTrue);
      });

      expect(
        scripted.callCount - sweepsAfterEntry,
        1,
        reason: 'the store button and any other caller must not each fire '
            'their own queue scan',
      );

      handler.dispose();
      await tester.pump(const Duration(milliseconds: 150));
    });
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
  int scriptedFound = 0;

  /// Lets a test hold a sweep open, to prove concurrent callers share one.
  Completer<void>? gate;

  @override
  Future<PurchaseSweepReport> sweepUnfinishedPurchases({
    required PurchaseSweepTrigger trigger,
    bool Function()? shouldAbort,
  }) async {
    callCount++;
    await gate?.future;
    final outcome = scriptedOutcome ??
        (callCount < 3
            ? PurchaseSweepOutcome.concurrent
            : PurchaseSweepOutcome.completed);
    return PurchaseSweepReport(
      trigger: trigger,
      outcome: outcome,
      found: scriptedOutcome == null ? 0 : scriptedFound,
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
