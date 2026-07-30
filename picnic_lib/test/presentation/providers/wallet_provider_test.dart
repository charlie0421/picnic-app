import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeWalletRepository extends WalletRepository {
  _FakeWalletRepository({required this.summaries, required this.pages})
    : super(_UnusedSupabaseClient());

  final List<WalletSummaryModel> summaries;
  final Map<String?, CurrencyHistoryPageModel> pages;
  int summaryCalls = 0;
  final List<String?> cursors = [];

  @override
  Future<WalletSummaryModel> getSummary() async => summaries[summaryCalls++];

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async {
    cursors.add(cursor);
    return pages[cursor]!;
  }
}

/// Repository whose cursor-page responses only resolve when the test says so,
/// so a `loadNext()` response can be landed at a chosen moment.
class _ControlledWalletRepository extends WalletRepository {
  _ControlledWalletRepository({required this.pages, this.firstPageOnRebuild})
    : super(_UnusedSupabaseClient());

  final Map<String?, CurrencyHistoryPageModel> pages;

  /// Served instead of `pages[null]` from the second build onwards, so a
  /// rebuild can be seen to replace the list a request was started against.
  final CurrencyHistoryPageModel? firstPageOnRebuild;

  final List<String?> cursors = [];
  int firstPageCalls = 0;
  final List<MapEntry<String, Completer<CurrencyHistoryPageModel>>> _pending =
      [];

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) {
    cursors.add(cursor);
    if (cursor == null) {
      firstPageCalls++;
      return Future.value(
        firstPageCalls > 1
            ? (firstPageOnRebuild ?? pages[null]!)
            : pages[null]!,
      );
    }
    final completer = Completer<CurrencyHistoryPageModel>();
    _pending.add(MapEntry(cursor, completer));
    return completer.future;
  }

  /// Resolves the most recently started request for [cursor].
  void completeLatest(String cursor) {
    final entry = _pending.lastWhere((entry) => entry.key == cursor);
    _pending.remove(entry);
    entry.value.complete(pages[cursor]!);
  }
}

/// Serves a scripted sequence of `getSummary()` outcomes, one per call, so a
/// read that never answers can be followed by one that succeeds.
///
/// Thunks rather than ready-made futures: a `Future.error` built up front would
/// go unhandled until the call that consumes it.
class _ScriptedWalletRepository extends WalletRepository {
  _ScriptedWalletRepository(this.responses) : super(_UnusedSupabaseClient());

  final List<Future<WalletSummaryModel> Function()> responses;
  int summaryCalls = 0;

  @override
  Future<WalletSummaryModel> getSummary() => responses[summaryCalls++]();

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

/// A read that never answers — the shape a stalled `rpc()` takes when the
/// socket is up but the response never arrives.
Future<WalletSummaryModel> Function() _stalled() =>
    () => Completer<WalletSummaryModel>().future;

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

/// Auth whose session is already restored and whose change stream **replays its
/// last event to every new subscriber**.
///
/// That is not a contrivance: `supabase.auth.onAuthStateChange` is a
/// `BehaviorSubject` (gotrue 2.18.0 `gotrue_client.dart:65`), so a listener that
/// attaches after a sign-in immediately receives that `signedIn` again.
class _ReplayingAuthGateway implements WalletAuthGateway {
  _ReplayingAuthGateway({this.session, this.replayed, this.replayLimit = 5});

  final Session? session;
  final AuthState? replayed;

  /// How many subscribers receive [replayed].
  ///
  /// A `BehaviorSubject` replays to *every* subscriber, but an unbounded fake
  /// would make a regression hang the test instead of failing it: the
  /// invalidate loop it reproduces never yields. Bounded, a regression shows up
  /// as too many builds.
  final int replayLimit;
  int subscriptions = 0;

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => session;

  @override
  Stream<AuthState> get authStateChanges {
    subscriptions++;
    final controller = StreamController<AuthState>();
    final replay = replayed;
    if (replay != null && subscriptions <= replayLimit) {
      controller.add(replay);
    }
    // Deliberately left open: gotrue's stream outlives any one subscription,
    // and closing it would turn the session wait into a StateError instead of
    // the timeout the test is about.
    return controller.stream;
  }
}

/// Auth that is wired up but never resolves a session — a real signed-out user,
/// or a session restore that simply does not arrive.
class _SilentAuthGateway implements WalletAuthGateway {
  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges =>
      StreamController<AuthState>().stream;
}

class _FailingHistoryRepository extends WalletRepository {
  _FailingHistoryRepository({required this.firstPage, required this.error})
    : super(_UnusedSupabaseClient());

  final CurrencyHistoryPageModel firstPage;
  final Object error;

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async {
    if (cursor == null) return firstPage;
    throw error;
  }
}

/// Drains the microtask queue so pending `loadNext()` continuations run.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

WalletSummaryModel _summary(int cotton, {DateTime? snapshotAt}) =>
    WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: BigInt.zero,
      bonus: BigInt.zero,
      cotton: BigInt.from(cotton),
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: snapshotAt ?? DateTime.utc(2026, 7, 21),
    );

CurrencyHistoryItemModel _item(String id) => CurrencyHistoryItemModel(
  id: id,
  currency: WalletCurrency.cottonCandy,
  eventType: 'GRANT',
  origin: 'test',
  delta: BigInt.one,
  balanceEffect: BigInt.one,
  operationId: 'operation-$id',
  createdAt: DateTime.utc(2026, 7, 21),
);

CurrencyHistoryPageModel _page(
  List<CurrencyHistoryItemModel> items,
  String? nextCursor, {
  BigInt? totalCount,
}) => CurrencyHistoryPageModel(
  items: items,
  totalCount: totalCount ?? BigInt.from(2),
  nextCursor: nextCursor,
  snapshotAt: DateTime.utc(2026, 7, 21),
);

void main() {
  test(
    'wallet summary builds once and refresh replaces the snapshot',
    () async {
      final repository = _FakeWalletRepository(
        summaries: [_summary(0), _summary(30)],
        pages: const {},
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(
        (await container.read(walletSummaryProvider.future)).cotton,
        BigInt.zero,
      );
      expect(repository.summaryCalls, 1);

      await container.read(walletSummaryProvider.notifier).refresh();

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
      );
      expect(repository.summaryCalls, 2);
    },
  );

  test(
    'currency history appends the next cursor page without duplicates',
    () async {
      final repository = _FakeWalletRepository(
        summaries: const [],
        pages: {
          null: _page([_item('1')], 'cursor-2'),
          'cursor-2': _page([_item('1'), _item('2')], null),
        },
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(
        currencyHistoryProvider(WalletCurrency.cottonCandy).future,
      );
      await container
          .read(currencyHistoryProvider(WalletCurrency.cottonCandy).notifier)
          .loadNext();

      final page = container
          .read(currencyHistoryProvider(WalletCurrency.cottonCandy))
          .value!;
      expect(page.items.map((item) => item.id), ['1', '2']);
      expect(page.items.map((item) => item.id).toSet(), hasLength(2));
      expect(repository.cursors, [null, 'cursor-2']);
    },
  );

  // `loadNext` sets its in-flight flag synchronously, before its first await,
  // so a second call while a page is outstanding returns without requesting
  // anything. Two `loadNext` responses can therefore never be in flight at once
  // and cannot land out of order - the guard makes that unreachable by
  // construction. What this test pins is the guard itself.
  test(
    'a second scroll-end notification while a page is in flight is dropped',
    () async {
      final repository = _ControlledWalletRepository(
        pages: {
          null: _page([_item('1')], 'cursor-2', totalCount: BigInt.one),
          'cursor-2': _page([_item('2')], 'cursor-3', totalCount: BigInt.two),
          'cursor-3': _page([_item('3')], null, totalCount: BigInt.from(3)),
        },
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final provider = currencyHistoryProvider(WalletCurrency.cottonCandy);
      final observed = <List<String>>[];
      container.listen(provider, (previous, next) {
        final page = next.value;
        if (page != null) {
          observed.add([for (final item in page.items) item.id]);
        }
      }, fireImmediately: true);

      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      // Two scroll-end notifications in a row, before the first response lands.
      final inFlight = notifier.loadNext();
      var duplicateSettled = false;
      final duplicate = notifier.loadNext();
      unawaited(duplicate.then((_) => duplicateSettled = true));
      await _flush();

      expect(
        duplicateSettled,
        isTrue,
        reason:
            'the duplicate notification is dropped, not queued behind the '
            'outstanding request',
      );
      expect(
        repository.cursors,
        [null, 'cursor-2'],
        reason: 'the duplicate notification must not reach the repository',
      );

      repository.completeLatest('cursor-2');
      await _flush();

      // The user keeps scrolling and the following page lands as well.
      final third = notifier.loadNext();
      await _flush();
      repository.completeLatest('cursor-3');
      await _flush();
      await Future.wait([inFlight, duplicate, third]);

      final page = container.read(provider).value!;
      expect([for (final item in page.items) item.id], ['1', '2', '3']);
      expect(page.nextCursor, isNull);
      expect(page.totalCount, BigInt.from(3));
      expect(repository.cursors, [null, 'cursor-2', 'cursor-3']);

      for (var i = 1; i < observed.length; i++) {
        expect(
          observed[i].take(observed[i - 1].length),
          observed[i - 1],
          reason:
              'loaded items must only grow, but went from '
              '${observed[i - 1]} to ${observed[i]}',
        );
      }
    },
  );

  // The in-flight guard rules out two overlapping `loadNext` calls, but not a
  // rebuild: `build` re-runs on the same notifier when a dependency is
  // invalidated, so the list a request was started against can be replaced
  // while that request is still outstanding. This is the case the merge in
  // `loadNext` reads `state.value` for instead of its pre-await snapshot.
  test(
    'a page landing after a rebuild extends the rebuilt list, not the snapshot',
    () async {
      final repository = _ControlledWalletRepository(
        pages: {
          null: _page([_item('1')], 'cursor-2', totalCount: BigInt.one),
          'cursor-2': _page([_item('2')], null, totalCount: BigInt.from(3)),
        },
        firstPageOnRebuild: _page(
          [_item('1'), _item('9')],
          'cursor-2',
          totalCount: BigInt.two,
        ),
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final provider = currencyHistoryProvider(WalletCurrency.cottonCandy);
      container.listen(provider, (previous, next) {});
      await container.read(provider.future);

      // The next page is requested against ['1'] ...
      final inFlight = container.read(provider.notifier).loadNext();
      await _flush();

      // ... and while it is outstanding the provider rebuilds, so the list the
      // request was started against no longer exists.
      container.invalidate(provider);
      await container.read(provider.future);
      expect(
        [for (final item in container.read(provider).value!.items) item.id],
        ['1', '9'],
      );

      repository.completeLatest('cursor-2');
      await _flush();
      await inFlight;

      final page = container.read(provider).value!;
      expect(
        [for (final item in page.items) item.id],
        ['1', '9', '2'],
        reason:
            'the late page must extend the list it actually landed in; merging '
            'into the pre-await snapshot would drop the refreshed item',
      );
      expect(page.nextCursor, isNull);
    },
  );

  test(
    'a failed loadNext keeps the loaded page and reports the failure',
    () async {
      final failure = Exception('history unavailable');
      final repository = _FailingHistoryRepository(
        firstPage: _page([_item('1')], 'cursor-2', totalCount: BigInt.one),
        error: failure,
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final logged = <LogEvent>[];
      void logListener(LogEvent event) => logged.add(event);
      Logger.addLogListener(logListener);
      addTearDown(() => Logger.removeLogListener(logListener));

      final provider = currencyHistoryProvider(WalletCurrency.cottonCandy);
      container.listen(provider, (previous, next) {});
      await container.read(provider.future);

      // The page fires this and drops the future, so it must not escape.
      await expectLater(
        container.read(provider.notifier).loadNext(),
        completes,
      );

      final page = container.read(provider).value;
      expect(page, isNotNull);
      expect([for (final item in page!.items) item.id], ['1']);
      expect(page.nextCursor, 'cursor-2');
      expect(
        logged.where(
          (event) =>
              event.level == Level.error && identical(event.error, failure),
        ),
        isNotEmpty,
        reason: 'the pagination failure must be reported, not swallowed',
      );
    },
  );

  // The pouch showed an infinite loading state on Android (1.3.0+130000 patch
  // 9) that a force-stop cleared. Every await in the summary path is bounded
  // now, and every terminal state is one the user can act on.
  group('the pouch is never left waiting forever', () {
    ProviderContainer scriptedContainer(
      _ScriptedWalletRepository repository, {
      WalletAuthGateway? gateway,
    }) {
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          if (gateway != null)
            walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      // Keep the provider alive and mark its errors handled, the way the panel
      // watching it does.
      container.listen(walletSummaryProvider, (previous, next) {});
      return container;
    }

    // riverpod 3 retries a failed build on its own (here: once, per
    // `walletSummaryRetry`), so a permanently stalled read takes two attempts
    // before the error is the settled state.
    const readsUntilSettled = 2;
    final settleBudget =
        kWalletSummaryReadTimeout * readsUntilSettled +
        const Duration(seconds: 2);

    test('a read that never answers ends in an error, not a spinner', () {
      fakeAsync((async) {
        final repository = _ScriptedWalletRepository([_stalled(), _stalled()]);
        final container = scriptedContainer(repository);

        async.elapse(kWalletSummaryReadTimeout - const Duration(seconds: 1));
        expect(
          container.read(walletSummaryProvider).isLoading,
          isTrue,
          reason: 'still within the read budget',
        );

        async.elapse(settleBudget);

        final state = container.read(walletSummaryProvider);
        expect(
          state.isLoading,
          isFalse,
          reason:
              'postgrest has no default timeout, so a stalled rpc() future '
              'never completes; without a bound the card spins until the app '
              'is force-stopped',
        );
        expect(state.error, isA<TimeoutException>());
        expect(
          repository.summaryCalls,
          readsUntilSettled,
          reason:
              'the automatic retry must be short and finite - riverpod\'s '
              'default (10 tries, up to 6.4s apart) hides the failure behind '
              'more than a minute of skeleton',
        );
      });
    });

    test('retry after a failed read renders the balance', () {
      fakeAsync((async) {
        final repository = _ScriptedWalletRepository([
          _stalled(),
          _stalled(),
          () async => _summary(30),
        ]);
        final container = scriptedContainer(repository);

        async.elapse(settleBudget);
        expect(container.read(walletSummaryProvider).hasError, isTrue);

        // What the card's retry affordance calls.
        container.read(walletSummaryProvider.notifier).refresh();
        async.elapse(const Duration(seconds: 1));

        final state = container.read(walletSummaryProvider);
        expect(state.hasError, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.value!.cotton, BigInt.from(30));
        expect(repository.summaryCalls, readsUntilSettled + 1);
      });
    });

    test(
      'a failed refresh keeps the last known balance instead of clobbering it',
      () async {
        final repository = _ScriptedWalletRepository([
          () async => _summary(30),
          () async => throw Exception('network went away'),
        ]);
        final container = scriptedContainer(repository);

        await container.read(walletSummaryProvider.future);

        final observed = <AsyncValue<WalletSummaryModel>>[];
        container.listen(
          walletSummaryProvider,
          (previous, next) => observed.add(next),
        );

        // The background re-read a settled purchase or watched ad fires.
        await container.read(walletSummaryProvider.notifier).refresh();

        final state = container.read(walletSummaryProvider);
        expect(state.hasError, isFalse);
        expect(state.isLoading, isFalse);
        expect(
          state.value!.cotton,
          BigInt.from(30),
          reason:
              'the balance on screen was correct; a failed background refresh '
              'must not replace it with a skeleton or an error',
        );
        expect(
          observed.where((state) => state.isLoading || state.hasError),
          isEmpty,
          reason:
              'no intermediate loading/error state may reach the card while a '
              'good value is displayed',
        );
      },
    );

    test('a session that never restores still reaches a terminal state', () {
      fakeAsync((async) {
        final repository = _ScriptedWalletRepository([() async => _summary(0)]);
        final container = scriptedContainer(
          repository,
          gateway: _SilentAuthGateway(),
        );

        async.elapse(
          kWalletSessionRestoreTimeout - const Duration(milliseconds: 100),
        );
        expect(
          container.read(walletSummaryProvider).isLoading,
          isTrue,
          reason: 'still waiting for the session, on purpose',
        );

        async.elapse(kWalletSessionRestoreTimeout + kWalletSummaryReadTimeout);

        final state = container.read(walletSummaryProvider);
        expect(
          state.isLoading,
          isFalse,
          reason:
              'a signed-out user never gets a session event; the wait has to '
              'give up and let the server answer',
        );
        expect(state.hasValue, isTrue);
        expect(repository.summaryCalls, 1);
      });
    });

    // The reported Android symptom, reproduced. `onAuthStateChange` is a
    // `BehaviorSubject`, so the subscription `build()` opens is handed the last
    // event immediately. Once a sign-in has happened in the process, that event
    // is `signedIn` - and a listener keyed on the event type alone answers it
    // with `invalidateSelf()`, which re-runs `build()`, which subscribes again,
    // which is replayed again. `build()` never gets to finish, so the card
    // never leaves loading, and only a relaunch clears it (right after launch
    // the last event is `initialSession`, which is why a fresh start looked
    // fine). The condition is a change of *user*, not the event type.
    test('a replayed signedIn for the same user does not re-enter loading', () {
      fakeAsync((async) {
        final session = _FakeSession('user-1');
        final repository = _ScriptedWalletRepository([
          for (var i = 0; i < 8; i++) () async => _summary(30 + i),
        ]);
        final gateway = _ReplayingAuthGateway(
          session: session,
          replayed: AuthState(AuthChangeEvent.signedIn, session),
        );
        final container = scriptedContainer(repository, gateway: gateway);

        async.elapse(const Duration(seconds: 1));

        final state = container.read(walletSummaryProvider);
        expect(
          state.isLoading,
          isFalse,
          reason: 'the replayed signedIn must not invalidate the build',
        );
        expect(state.value!.cotton, BigInt.from(30));
        expect(
          repository.summaryCalls,
          1,
          reason: 'one build, one read - not an invalidate storm',
        );
      });
    });

    test('a signedIn for a different user does re-read', () {
      fakeAsync((async) {
        final repository = _ScriptedWalletRepository([
          () async => _summary(30),
          () async => _summary(31),
        ]);
        final gateway = _ReplayingAuthGateway(
          session: _FakeSession('user-1'),
          replayed: AuthState(AuthChangeEvent.signedIn, _FakeSession('user-2')),
          // A real event, delivered once - not a replay to every subscriber.
          replayLimit: 1,
        );
        final container = scriptedContainer(repository, gateway: gateway);

        async.elapse(const Duration(seconds: 1));

        expect(
          repository.summaryCalls,
          2,
          reason: 'an account switch must still force a re-read',
        );
        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.from(31),
        );
      });
    });
  });

  // Every settled operation answers with the wallet as of its own response, and
  // the three that write one - a vote, a rewarded ad, a verified purchase - are
  // independent round trips. Receipt verification is the slow one: an ad
  // watched while a purchase is being verified settles first, and the purchase
  // response that lands afterwards still describes the balance from before the
  // ad. `snapshotAt` is what tells them apart.
  group('setSummary orders settlements by the server\'s own stamp', () {
    ProviderContainer settledContainer(WalletSummaryModel first) {
      final repository = _FakeWalletRepository(
        summaries: [first],
        pages: const {},
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'a settlement stamped before the balance on screen is dropped',
      () async {
        final ad = _summary(
          30,
          snapshotAt: DateTime.utc(2026, 7, 21, 12, 0, 10),
        );
        final container = settledContainer(_summary(0));
        await container.read(walletSummaryProvider.future);
        final notifier = container.read(walletSummaryProvider.notifier);

        notifier.setSummary(ad);
        // The purchase's receipt verification started before the ad and finished
        // after it, so its snapshot predates the reward.
        notifier.setSummary(
          _summary(10, snapshotAt: DateTime.utc(2026, 7, 21, 12, 0, 5)),
        );

        expect(
          container.read(walletSummaryProvider).value,
          same(ad),
          reason:
              'the later-arriving purchase response describes a balance from '
              'before the ad; applying it rolls the displayed cotton back until '
              'the next refresh',
        );
      },
    );

    test('a settlement stamped after it replaces the balance', () async {
      final container = settledContainer(_summary(0));
      await container.read(walletSummaryProvider.future);
      final notifier = container.read(walletSummaryProvider.notifier);

      notifier.setSummary(
        _summary(30, snapshotAt: DateTime.utc(2026, 7, 21, 12, 0, 5)),
      );
      final purchase = _summary(
        40,
        snapshotAt: DateTime.utc(2026, 7, 21, 12, 0, 10),
      );
      notifier.setSummary(purchase);

      expect(container.read(walletSummaryProvider).value, same(purchase));
    });

    test(
      'two responses stamped the same instant take the later write',
      () async {
        final stamp = DateTime.utc(2026, 7, 21, 12);
        final container = settledContainer(_summary(0));
        await container.read(walletSummaryProvider.future);
        final notifier = container.read(walletSummaryProvider.notifier);

        notifier.setSummary(_summary(30, snapshotAt: stamp));
        final second = _summary(40, snapshotAt: stamp);
        notifier.setSummary(second);

        expect(
          container.read(walletSummaryProvider).value,
          same(second),
          reason:
              'equal stamps are not evidence of staleness, and dropping the '
              'second one would strand a settlement the server did apply',
        );
      },
    );

    test('a settlement lands while the first read is still in flight', () {
      // Nothing to compare against yet: the store can be left before
      // walletSummaryProvider has ever resolved.
      final container = ProviderContainer(
        overrides: [
          walletSummaryProvider.overrideWithBuild(
            (ref, notifier) => Completer<WalletSummaryModel>().future,
          ),
        ],
      );
      addTearDown(container.dispose);

      final settled = _summary(10, snapshotAt: DateTime.utc(2020));
      container.read(walletSummaryProvider.notifier).setSummary(settled);

      expect(container.read(walletSummaryProvider).value, same(settled));
    });
  });
}
