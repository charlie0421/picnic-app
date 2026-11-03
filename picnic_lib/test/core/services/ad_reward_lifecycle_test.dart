import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:picnic_lib/core/services/ad_reward_lifecycle.dart';
import 'package:picnic_lib/core/services/wallet_resume_refresher.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _User extends Fake implements User {
  _User(this.id);
  @override
  final String id;
}

class _Session extends Fake implements Session {
  _Session(String id) : user = _User(id);
  @override
  final User user;
}

class _Auth extends Fake implements WalletAuthGateway {
  Session? session = _Session('owner-a');
  final events = StreamController<AuthState>.broadcast(sync: true);
  @override
  bool get isEnabled => true;
  @override
  Session? get currentSession => session;
  @override
  Stream<AuthState> get authStateChanges => events.stream;
  void emit(String? owner, [AuthChangeEvent event = AuthChangeEvent.signedIn]) {
    session = owner == null ? null : _Session(owner);
    events.add(AuthState(event, session));
  }
}

class _AdApi extends Fake implements AdRewardApi {
  int listCalls = 0;
  int statusCalls = 0;
  AdRewardStatusModel? status;
  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async {
    listCalls++;
    throw StateError('Lifecycle must never list ad rewards');
  }

  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async {
    statusCalls++;
    if (status != null) return status!;
    throw StateError('Lifecycle must never poll past rewards');
  }
}

class _Client extends Fake implements SupabaseClient {}

class _FailingRefresher extends Fake implements WalletResumeRefresher {
  @override
  void reset() {}

  @override
  Future<WalletResumeRefreshOutcome> refreshOnResume() => Future.error(
    const AuthException('fake-secret-resume-token'),
    StackTrace.fromString('fake-secret-resume-stack'),
  );
}

class _OldRewards extends Fake implements PendingAdRewardStore {
  int reads = 0;
  @override
  Future<List<StoredAdRewardReference>> readAll(String userId) async {
    reads++;
    return [
      const StoredAdRewardReference(
        reference: AdRewardReference(
          type: AdRewardReferenceType.internalImpression,
          id: '00000000-0000-4000-8000-000000000001',
        ),
        state: PendingAdRewardLocalState.pendingDisplay,
      ),
    ];
  }
}

WalletSummaryModel _summary(int cotton) => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.zero,
  cotton: BigInt.from(cotton),
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 9, 8, 0, 0, cotton),
);

class _Wallet extends WalletRepository {
  _Wallet() : super(_Client());
  int calls = 0;
  Future<WalletSummaryModel> Function()? next;
  @override
  Future<WalletSummaryModel> getSummary() {
    calls++;
    return next?.call() ?? Future.value(_summary(calls));
  }
}

void main() {
  late _Auth auth;
  late _AdApi ads;
  late _Wallet wallet;
  late _OldRewards oldRewards;
  late ProviderContainer container;

  setUp(() {
    auth = _Auth();
    ads = _AdApi();
    wallet = _Wallet();
    oldRewards = _OldRewards();
    container = ProviderContainer(
      overrides: [
        walletAuthGatewayProvider.overrideWithValue(auth),
        walletRepositoryProvider.overrideWithValue(wallet),
        adRewardRepositoryProvider.overrideWithValue(ads),
        pendingAdRewardStoreProvider.overrideWithValue(oldRewards),
        adRewardOwnerReaderProvider.overrideWithValue(
          () => auth.session?.user.id,
        ),
        // Stable loaded state when a test explicitly opens the wallet. The
        // resume service still reads the real repository override above.
        walletSummaryProvider.overrideWithBuild(
          (ref, notifier) async => _summary(1),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await auth.events.close();
  });

  void resume(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  testWidgets('A to B to A clears queued receipts from the previous session', (
    tester,
  ) async {
    container.read(adRewardLifecycleProvider).start();
    const reference = AdRewardReference(
      type: AdRewardReferenceType.internalImpression,
      id: '00000000-0000-4000-8000-000000000001',
    );
    ads.status = AdRewardStatusModel(
      reference: reference,
      state: AdRewardState.denied,
      grant: null,
      wallet: _summary(1),
      snapshotAt: DateTime.utc(2026, 9, 8),
    );
    await container
        .read(adRewardRecoveryProvider.notifier)
        .poll(ownerUserId: 'owner-a', reference: reference);
    expect(container.read(adRewardRecoveryProvider).dialogQueue, hasLength(1));
    auth.emit('owner-b');
    expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
    expect(container.read(adRewardRecoveryProvider).references, isEmpty);
    auth.emit('owner-a');
    expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
    expect(container.read(adRewardRecoveryProvider).references, isEmpty);
    expect(ads.statusCalls, 1);
    expect(ads.listCalls, 0);
  });

  testWidgets(
    'auth errors preserve queued receipts without logging credentials',
    (tester) async {
      final lifecycle = container.read(adRewardLifecycleProvider)..start();
      const reference = AdRewardReference(
        type: AdRewardReferenceType.internalImpression,
        id: '00000000-0000-4000-8000-000000000001',
      );
      ads.status = AdRewardStatusModel(
        reference: reference,
        state: AdRewardState.denied,
        grant: null,
        wallet: _summary(1),
        snapshotAt: DateTime.utc(2026, 9, 8),
      );
      await container
          .read(adRewardRecoveryProvider.notifier)
          .poll(ownerUserId: 'owner-a', reference: reference);
      final queued = container.read(adRewardRecoveryProvider);
      expect(queued.dialogQueue, hasLength(1));
      final logged = <LogEvent>[];
      void logListener(LogEvent event) => logged.add(event);
      Logger.addLogListener(logListener);
      addTearDown(() => Logger.removeLogListener(logListener));

      auth.events.addError(
        const AuthException('fake-secret-access-token'),
        StackTrace.fromString('fake-secret-auth-stack'),
      );
      await tester.pump();

      expect(logged, isNotEmpty);
      for (final event in logged) {
        expect(event.error, isNull);
        expect(event.stackTrace, isNull);
        expect(event.message.toString(), isNot(contains('fake-secret')));
      }
      expect(container.read(adRewardRecoveryProvider), same(queued));
      expect(auth.currentSession?.user.id, 'owner-a');
      expect(ads.statusCalls, 1);
      expect(ads.listCalls, 0);
      expect(oldRewards.reads, 0);
      expect(wallet.calls, 0);

      // A stream error must not stop subsequent owner-change isolation.
      auth.emit('owner-b');
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
      expect(container.read(adRewardRecoveryProvider).references, isEmpty);
      expect(ads.statusCalls, 1);
      expect(ads.listCalls, 0);
      expect(oldRewards.reads, 0);
      expect(wallet.calls, 0);
      lifecycle.dispose();
      expect(auth.events.hasListener, isFalse);
    },
  );

  testWidgets(
    'resume auth errors preserve the balance without logging credentials',
    (tester) async {
      container.read(adRewardLifecycleProvider).start();
      await container.read(walletSummaryProvider.future);
      final before = container.read(walletSummaryProvider).value;
      wallet.next = () => Future.error(
        const AuthException('fake-secret-resume-token'),
        StackTrace.fromString('fake-secret-resume-stack'),
      );
      final logged = <LogEvent>[];
      void logListener(LogEvent event) => logged.add(event);
      Logger.addLogListener(logListener);
      addTearDown(() => Logger.removeLogListener(logListener));

      resume(tester);
      await tester.pump();

      expect(logged, isNotEmpty);
      for (final event in logged) {
        expect(event.error, isNull);
        expect(event.stackTrace, isNull);
        expect(event.message.toString(), isNot(contains('fake-secret')));
      }
      expect(container.read(walletSummaryProvider).value, same(before));
      expect(wallet.calls, 1);
      expect(ads.listCalls, 0);
      expect(ads.statusCalls, 0);
      expect(oldRewards.reads, 0);

      wallet.next = () async => _summary(20);
      resume(tester);
      await tester.pump();
      expect(wallet.calls, 2);
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(20),
      );
    },
  );

  testWidgets('resume fallback omits auth exception and stack credentials', (
    tester,
  ) async {
    final lifecycle = AdRewardLifecycle(
      auth: auth,
      wallet: _FailingRefresher(),
      resetRewards: () {},
    )..start();
    addTearDown(lifecycle.dispose);
    final logged = <LogEvent>[];
    void logListener(LogEvent event) => logged.add(event);
    Logger.addLogListener(logListener);
    addTearDown(() => Logger.removeLogListener(logListener));

    resume(tester);
    await tester.pump();

    expect(logged, isNotEmpty);
    for (final event in logged) {
      expect(event.error, isNull);
      expect(event.stackTrace, isNull);
      expect(event.message.toString(), isNot(contains('fake-secret')));
    }
    expect(ads.listCalls, 0);
    expect(ads.statusCalls, 0);
    expect(wallet.calls, 0);
  });

  testWidgets(
    'startup, auth replay and unloaded resume issue no reward or wallet reads',
    (tester) async {
      final lifecycle = container.read(adRewardLifecycleProvider);
      lifecycle.start();
      lifecycle.start();
      auth.emit('owner-a');
      auth.emit('owner-a', AuthChangeEvent.tokenRefreshed);
      resume(tester);
      await tester.pump();
      expect(ads.listCalls, 0);
      expect(ads.statusCalls, 0);
      expect(oldRewards.reads, 0);
      expect(wallet.calls, 0);
      expect(container.exists(walletSummaryProvider), isFalse);
    },
  );

  testWidgets(
    'real binding resume refreshes a loaded wallet once and coalesces repeats',
    (tester) async {
      final lifecycle = container.read(adRewardLifecycleProvider)..start();
      await container.read(walletSummaryProvider.future);
      final pending = Completer<WalletSummaryModel>();
      wallet.next = () => pending.future;
      resume(tester);
      resume(tester);
      expect(wallet.calls, 1);
      pending.complete(_summary(20));
      await tester.pump();
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(20),
      );
      auth.emit('owner-a', AuthChangeEvent.tokenRefreshed);
      resume(tester);
      await tester.pump();
      expect(wallet.calls, 1);
      expect(ads.listCalls, 0);
      expect(ads.statusCalls, 0);
      lifecycle.dispose();
    },
  );

  testWidgets(
    'A to logout to A discards a pending resume response and releases cooldown',
    (tester) async {
      container.read(adRewardLifecycleProvider).start();
      await container.read(walletSummaryProvider.future);
      final pending = Completer<WalletSummaryModel>();
      wallet.next = () => pending.future;
      resume(tester);
      auth.emit(null, AuthChangeEvent.signedOut);
      auth.emit('owner-a');
      pending.complete(_summary(99));
      await tester.pump();
      expect(container.read(walletSummaryProvider).value!.cotton, BigInt.one);
      wallet.next = () async => _summary(30);
      resume(tester);
      await tester.pump();
      expect(wallet.calls, 2);
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
      );
      expect(ads.listCalls, 0);
      expect(ads.statusCalls, 0);
    },
  );

  testWidgets(
    'disposal cancels auth and resume work and invalidates in-flight reads',
    (tester) async {
      final lifecycle = container.read(adRewardLifecycleProvider)..start();
      await container.read(walletSummaryProvider.future);
      final pending = Completer<WalletSummaryModel>();
      wallet.next = () => pending.future;
      resume(tester);
      lifecycle.dispose();
      auth.emit('owner-b');
      resume(tester);
      pending.complete(_summary(99));
      await tester.pump();
      expect(wallet.calls, 1);
      expect(container.read(walletSummaryProvider).value!.cotton, BigInt.one);
      expect(ads.listCalls, 0);
      expect(ads.statusCalls, 0);
    },
  );
}
