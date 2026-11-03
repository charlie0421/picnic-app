import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/wallet_summary_applier.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeUser extends Fake implements User {
  _FakeUser(this.id);

  @override
  final String id;
}

class _FakeSession extends Fake implements Session {
  _FakeSession(String userId) : user = _FakeUser(userId);

  @override
  final User user;
}

class _AuthGateway implements WalletAuthGateway {
  _AuthGateway(String? owner)
    : _session = owner == null ? null : _FakeSession(owner);

  Session? _session;
  final BehaviorSubject<AuthState> changes = BehaviorSubject<AuthState>();
  int streamReads = 0;

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges {
    streamReads++;
    return changes.stream;
  }

  void change(
    String? owner, {
    AuthChangeEvent event = AuthChangeEvent.signedIn,
  }) {
    _session = owner == null ? null : _FakeSession(owner);
    changes.add(AuthState(event, _session));
  }

  void emitError(Object error) => changes.addError(error, StackTrace.current);
}

class _RecordingRepository extends WalletRepository {
  _RecordingRepository(this.auth, this.responses)
    : super(_UnusedSupabaseClient());

  final _AuthGateway auth;
  final List<Future<WalletSummaryModel> Function()> responses;
  final List<String?> readOwners = <String?>[];

  @override
  Future<WalletSummaryModel> getSummary() {
    readOwners.add(auth.currentSession?.user.id);
    return responses[readOwners.length - 1]();
  }

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

WalletSummaryModel _summary(int cotton, int seconds) => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.zero,
  cotton: BigInt.from(cotton),
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 9, 10, 0, 0, seconds),
);

ProviderContainer _container(
  _AuthGateway auth,
  WalletRepository repository,
) {
  final container = ProviderContainer(
    overrides: [
      walletAuthGatewayProvider.overrideWithValue(auth),
      walletRepositoryProvider.overrideWithValue(repository),
    ],
  );
  container.listen(walletSummaryProvider, (_, _) {});
  return container;
}

Future<void> _turn() => Future<void>.delayed(Duration.zero);

void main() {
  test('sign-out between session resolution and RPC sends no anonymous read', () async {
    final auth = _AuthGateway('owner-a');
    final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
      () async => _summary(10, 1),
    ]);
    final container = _container(auth, repository);
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);

    // build() has captured owner-a, but its await continuation has not run yet.
    auth.change(null, event: AuthChangeEvent.signedOut);
    await _turn();

    expect(repository.readOwners, isEmpty);
  });

  test('a startup auth-stream error does not orphan a later initialSession', () async {
    final auth = _AuthGateway(null);
    final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
      () async => _summary(20, 2),
    ]);
    final container = _container(auth, repository);
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);

    auth.emitError(const AuthException('transient restore failure'));
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(repository.readOwners, isEmpty);
    auth.change('owner-a', event: AuthChangeEvent.initialSession);
    await _turn();
    await _turn();

    expect(repository.readOwners, <String?>['owner-a']);
    expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(20));
  });

  test('purchase applier cannot write owner A settlement onto owner B', () async {
    final auth = _AuthGateway('owner-a');
    final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
      () async => _summary(10, 1),
      () async => _summary(20, 2),
    ]);
    final container = _container(auth, repository);
    final purchaseApplier = ContainerWalletSummaryApplier.forContainer(
      container,
    );
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);

    await container.read(walletSummaryProvider.future);
    auth.change('owner-b');
    await _turn();
    expect((await container.read(walletSummaryProvider.future)).cotton, BigInt.from(20));

    // The production purchase adapter is captured before the async settlement
    // and intentionally outlives the route that started it.
    purchaseApplier(_summary(99, 3)); // response initiated by owner A

    expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(20));
  });

  test('rapid A-B-A transition rejects a refresh started in the first A epoch', () async {
    final stale = Completer<WalletSummaryModel>();
    final auth = _AuthGateway('owner-a');
    final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
      () async => _summary(10, 1),
      () => stale.future,
      () async => _summary(30, 3),
    ]);
    final container = _container(auth, repository);
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);

    await container.read(walletSummaryProvider.future);
    final refresh = container.read(walletSummaryProvider.notifier).refresh();
    auth.change('owner-b');
    auth.change('owner-a');
    stale.complete(_summary(11, 2));
    await refresh;

    expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(10));
  });

  test('signed-out refresh before the queued rebuild sends no read', () async {
    final auth = _AuthGateway('owner-a');
    final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
      () async => _summary(10, 1),
    ]);
    final container = _container(auth, repository);
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);

    await container.read(walletSummaryProvider.future);
    auth.change(null, event: AuthChangeEvent.signedOut);
    final refresh = container.read(walletSummaryProvider.notifier).refresh();

    expect(repository.readOwners, <String?>['owner-a']);
    expect(container.read(walletSummaryProvider).value?.cotton, BigInt.zero);
    await refresh;
  });

  test('stale failure from owner A is discarded after switching to B', () async {
    final stale = Completer<WalletSummaryModel>();
    final auth = _AuthGateway('owner-a');
    final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
      () async => _summary(10, 1),
      () => stale.future,
      () async => _summary(20, 2),
    ]);
    final container = _container(auth, repository);
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);

    await container.read(walletSummaryProvider.future);
    final refresh = container.read(walletSummaryProvider.notifier).refresh();
    auth.change('owner-b');
    await _turn();
    expect((await container.read(walletSummaryProvider.future)).cotton, BigInt.from(20));

    stale.completeError(StateError('owner-a read failed'));
    await refresh;
    expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(20));
  });

  test(
    'A-B-A before async auth delivery rejects a refresh response queued first',
    () async {
      final stale = Completer<WalletSummaryModel>();
      final auth = _AuthGateway('owner-a');
      final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
        () async => _summary(10, 1),
        () => stale.future,
        () async => _summary(30, 3),
      ]);
      final container = _container(auth, repository);
      addTearDown(container.dispose);
      addTearDown(auth.changes.close);

      await container.read(walletSummaryProvider.future);
      final observed = <BigInt>[];
      container.listen(walletSummaryProvider, (_, next) {
        final value = next.value;
        if (value != null) observed.add(value.cotton);
      });
      final refresh = container.read(walletSummaryProvider.notifier).refresh();

      // Queue the RPC completion before the BehaviorSubject events, while all
      // state mutations still happen in this synchronous turn.
      stale.complete(_summary(11, 2));
      auth.change('owner-b');
      auth.change('owner-a');
      await refresh;
      await _turn();
      await container.read(walletSummaryProvider.future);

      expect(observed, isNot(contains(BigInt.from(11))));
      expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(30));
    },
  );

  test(
    'A-B-A before async auth delivery rejects an in-flight build success',
    () async {
      final stale = Completer<WalletSummaryModel>();
      final auth = _AuthGateway('owner-a');
      final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
        () => stale.future,
        () async => _summary(30, 3),
      ]);
      final container = _container(auth, repository);
      addTearDown(container.dispose);
      addTearDown(auth.changes.close);
      final observed = <BigInt>[];
      container.listen(walletSummaryProvider, (_, next) {
        final value = next.value;
        if (value != null) observed.add(value.cotton);
      });
      await _turn();

      stale.complete(_summary(11, 2));
      auth.change('owner-b');
      auth.change('owner-a');
      await _turn();
      await container.read(walletSummaryProvider.future);

      expect(observed, isNot(contains(BigInt.from(11))));
      expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(30));
    },
  );

  test(
    'A-B-A before async auth delivery rejects an in-flight build failure',
    () async {
      final stale = Completer<WalletSummaryModel>();
      final auth = _AuthGateway('owner-a');
      final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
        () => stale.future,
        () async => _summary(30, 3),
      ]);
      final container = _container(auth, repository);
      addTearDown(container.dispose);
      addTearDown(auth.changes.close);
      final observedErrors = <Object>[];
      container.listen(walletSummaryProvider, (_, next) {
        final error = next.error;
        if (error != null) observedErrors.add(error);
      });
      await _turn();

      final staleError = StateError('owner-a build failed');
      stale.completeError(staleError, StackTrace.current);
      auth.change('owner-b');
      auth.change('owner-a');
      await _turn();
      await container.read(walletSummaryProvider.future);

      expect(observedErrors, isNot(contains(staleError)));
      expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(30));
    },
  );

  test(
    'sign-out before async auth delivery never exposes an in-flight build',
    () async {
      final stale = Completer<WalletSummaryModel>();
      final auth = _AuthGateway('owner-a');
      final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
        () => stale.future,
      ]);
      final container = _container(auth, repository);
      addTearDown(container.dispose);
      addTearDown(auth.changes.close);
      final observed = <BigInt>[];
      container.listen(walletSummaryProvider, (_, next) {
        final value = next.value;
        if (value != null) observed.add(value.cotton);
      });
      await _turn();

      stale.complete(_summary(11, 2));
      auth.change(null, event: AuthChangeEvent.signedOut);
      await _turn();
      await container.read(walletSummaryProvider.future);

      expect(observed, isNot(contains(BigInt.from(11))));
      expect(container.read(walletSummaryProvider).value?.cotton, BigInt.zero);
    },
  );

  test(
    'A-to-B before async auth delivery never exposes owner A build',
    () async {
      final stale = Completer<WalletSummaryModel>();
      final auth = _AuthGateway('owner-a');
      final repository = _RecordingRepository(auth, <Future<WalletSummaryModel> Function()>[
        () => stale.future,
        () async => _summary(20, 3),
      ]);
      final container = _container(auth, repository);
      addTearDown(container.dispose);
      addTearDown(auth.changes.close);
      final observed = <BigInt>[];
      container.listen(walletSummaryProvider, (_, next) {
        final value = next.value;
        if (value != null) observed.add(value.cotton);
      });
      await _turn();

      stale.complete(_summary(11, 2));
      auth.change('owner-b');
      await _turn();
      await container.read(walletSummaryProvider.future);

      expect(observed, isNot(contains(BigInt.from(11))));
      expect(container.read(walletSummaryProvider).value?.cotton, BigInt.from(20));
    },
  );
}
