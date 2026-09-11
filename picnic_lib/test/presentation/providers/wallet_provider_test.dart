import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
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

/// Records the session each read actually went out with.
///
/// The requirement is not "fewer reads" but **no read without a session**: a
/// signed-out `rpc('get_wallet_summary')` reaches production as `anon`, whose
/// EXECUTE is revoked by design, so it can only come back as a permission
/// error. Counting calls alone cannot tell a read that raced the session
/// restore from one that waited for it; the owner at call time can.
class _SessionAwareRepository extends WalletRepository {
  _SessionAwareRepository(this.gateway, this.summaries)
    : super(_UnusedSupabaseClient());

  final WalletAuthGateway gateway;
  final List<WalletSummaryModel> summaries;

  /// One entry per read, holding the signed-in user at the moment it was sent.
  final List<String?> readOwners = [];

  @override
  Future<WalletSummaryModel> getSummary() async {
    readOwners.add(gateway.currentSession?.user.id);
    return summaries[readOwners.length - 1];
  }

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

/// Runs [duringSettlement] as [response] settles, either way.
///
/// A wallet response and an auth event are independent futures, so their
/// continuations can interleave inside one microtask drain: the response
/// resolves, the auth event is observed, and only then does the chain reach the
/// code that decides whether to keep the response. This places an event in that
/// window - which is the only window where the rebuild `invalidateSelf()` queues
/// has not run yet, so neither the build counter nor the current user id has
/// moved.
Future<WalletSummaryModel> _settling(
  Future<WalletSummaryModel> response,
  void Function() duringSettlement,
) async {
  try {
    final value = await response;
    duringSettlement();
    return value;
  } catch (_) {
    duringSettlement();
    rethrow;
  }
}

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

class _MutableAuthGateway implements WalletAuthGateway {
  _MutableAuthGateway(String userId) : _session = _FakeSession(userId);

  final _changes = StreamController<AuthState>.broadcast(sync: true);
  Session? _session;

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges => _changes.stream;

  bool get hasListener => _changes.hasListener;

  void emitError(Object error) => _changes.addError(error, StackTrace.current);

  void signIn(String userId) {
    final session = _FakeSession(userId);
    _session = session;
    _changes.add(AuthState(AuthChangeEvent.signedIn, session));
  }

  void signOut() {
    _session = null;
    _changes.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  Future<void> close() => _changes.close();
}

/// Auth shaped like gotrue's, in the two ways that decide whether a wallet read
/// can go out as `anon`.
///
/// 1. `currentSession` is updated the moment the client's state changes, but
///    the matching event is **delivered asynchronously** - gotrue pushes it
///    into a subject that hands it to listeners on a later turn. So the field
///    and the stream disagree for exactly as long as that turn lasts, and a
///    session read out of an event can already be gone.
/// 2. That subject is a `BehaviorSubject`, so its **last emission - an error
///    included** is replayed to every new subscriber. A refresh failure during
///    startup is therefore not a blip: a listener attaching afterwards is
///    handed the error again rather than a clean slate.
class _BehaviorAuthGateway implements WalletAuthGateway {
  Session? _session;

  /// The last emission, replayed to each new subscriber: an [AuthState], or the
  /// error gotrue reported on the same stream.
  Object? _lastEmission;
  final _live = <StreamController<AuthState>>[];

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges {
    final controller = StreamController<AuthState>();
    _live.add(controller);
    controller.onCancel = () => _live.remove(controller);
    switch (_lastEmission) {
      case final AuthState event:
        controller.add(event);
      case final Object error:
        controller.addError(error, StackTrace.empty);
      case null:
        break;
    }
    // Deliberately left open: gotrue's stream outlives any one subscription.
    return controller.stream;
  }

  /// Subscriptions that are still attached. gotrue's own stream outlives the
  /// wallet, so anything left here is a listener the wallet failed to cancel.
  int get liveSubscriptions => _live.length;

  /// A token refresh that failed, reported the way gotrue reports it.
  void failRefresh(Object error) {
    _lastEmission = error;
    for (final controller in [..._live]) {
      controller.addError(error, StackTrace.empty);
    }
  }

  /// The session restore finally completing, announced as `initialSession`.
  void restore(String userId) {
    _session = _FakeSession(userId);
    _emit(AuthState(AuthChangeEvent.initialSession, _session));
  }

  void signOut() {
    _session = null;
    _emit(const AuthState(AuthChangeEvent.signedOut, null));
  }

  void _emit(AuthState event) {
    _lastEmission = event;
    for (final controller in [..._live]) {
      controller.add(event);
    }
  }
}

/// Auth built on the exact primitive gotrue uses: `onAuthStateChange` is a
/// `BehaviorSubject<AuthState>` (gotrue 2.18.0 `gotrue_client.dart:65`), and an
/// rxdart subject defaults to `sync: false`.
///
/// That default is the whole reproduction. `currentSession` is swapped **in the
/// mutating turn** while the matching event is merely queued, so a wallet
/// response queued before it runs its continuation at a moment when
/// `currentSession` already names somebody else and **no listener has been told
/// yet**. Nothing event-driven has moved at that instant - not a rebuild
/// counter, not an epoch the listener increments. The session the read started
/// with is the only thing that has.
class _AsyncAuthGateway implements WalletAuthGateway {
  _AsyncAuthGateway(String? owner)
    : _session = owner == null ? null : _FakeSession(owner);

  Session? _session;
  final _changes = BehaviorSubject<AuthState>();

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges => _changes.stream;

  void change(
    String? owner, {
    AuthChangeEvent event = AuthChangeEvent.signedIn,
  }) {
    _session = owner == null ? null : _FakeSession(owner);
    _changes.add(AuthState(event, _session));
  }

  /// A genuine token refresh: gotrue mints a **new** `Session` for the same
  /// user, swaps it in, and announces `tokenRefreshed`. Same owner, different
  /// instance - which is exactly what a plain replay is not.
  void refreshToken(String owner) =>
      change(owner, event: AuthChangeEvent.tokenRefreshed);

  Future<void> close() => _changes.close();
}

/// Serves scripted responses and records the session each read actually went
/// out with, so a test can show two reads shared a user id and not a session.
class _ScriptedSessionRepository extends WalletRepository {
  _ScriptedSessionRepository(this.gateway, this.responses)
    : super(_UnusedSupabaseClient());

  final WalletAuthGateway gateway;
  final List<Future<WalletSummaryModel> Function()> responses;
  final List<String?> readOwners = [];
  final List<Session?> readSessions = [];

  @override
  Future<WalletSummaryModel> getSummary() {
    readOwners.add(gateway.currentSession?.user.id);
    readSessions.add(gateway.currentSession);
    return responses[readOwners.length - 1]();
  }

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

/// Every state the pouch published, so a test can assert a value or an error
/// never appeared at all rather than only checking where it came to rest.
class _Observer {
  final values = <BigInt>[];
  final errors = <Object>[];

  void record(
    AsyncValue<WalletSummaryModel>? previous,
    AsyncValue<WalletSummaryModel> next,
  ) {
    final value = next.value;
    if (value != null) values.add(value.cotton);
    final error = next.error;
    if (error != null) errors.add(error);
  }
}

class _MutableHistoryAuth implements WalletAuthGateway {
  _MutableHistoryAuth(String? owner)
    : session = owner == null ? null : _FakeSession(owner);
  Session? session;
  final changes = StreamController<AuthState>.broadcast(sync: true);
  @override
  bool get isEnabled => true;
  @override
  Session? get currentSession => session;
  @override
  Stream<AuthState> get authStateChanges => changes.stream;
  void change(
    String? owner, {
    AuthChangeEvent event = AuthChangeEvent.signedIn,
  }) {
    session = owner == null ? null : _FakeSession(owner);
    changes.add(AuthState(event, session));
  }
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
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(
            _ReplayingAuthGateway(session: _FakeSession('owner-a')),
          ),
        ],
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
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(
            _ReplayingAuthGateway(session: _FakeSession('owner-a')),
          ),
        ],
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
    'a page from before refresh cannot overwrite the new history snapshot',
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
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(
            _ReplayingAuthGateway(session: _FakeSession('owner-a')),
          ),
        ],
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
        ['1', '9'],
        reason:
            'a cursor belongs to its original snapshot and must be discarded after refresh',
      );
      expect(page.nextCursor, 'cursor-2');
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
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(
            _ReplayingAuthGateway(session: _FakeSession('owner-a')),
          ),
        ],
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

  test('history does not call the server without a signed-in owner', () async {
    final repository = _FakeWalletRepository(
      summaries: [],
      pages: {null: _page([], null)},
    );
    final auth = _MutableHistoryAuth(null);
    final container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repository),
        walletAuthGatewayProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);
    await expectLater(
      container.read(
        currencyHistoryProvider(WalletCurrency.cottonCandy).future,
      ),
      throwsStateError,
    );
    expect(repository.cursors, isEmpty);
  });

  test(
    'history account switch discards the previous owner cursor response',
    () async {
      final repository = _ControlledWalletRepository(
        pages: {
          null: _page([_item('owner-a')], 'a-next'),
          'a-next': _page([_item('a-private')], null),
        },
        firstPageOnRebuild: _page([_item('owner-b')], null),
      );
      final auth = _MutableHistoryAuth('owner-a');
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(auth.changes.close);
      final provider = currencyHistoryProvider(WalletCurrency.cottonCandy);
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final pending = container.read(provider.notifier).loadNext();
      auth.change('owner-b');
      await _flush();
      final next = await container.read(provider.future);
      expect(next.items.map((item) => item.id), ['owner-b']);
      repository.completeLatest('a-next');
      await pending;
      expect(container.read(provider).value!.items.map((item) => item.id), [
        'owner-b',
      ]);
      auth.change('owner-b', event: AuthChangeEvent.tokenRefreshed);
      await _flush();
      expect(repository.firstPageCalls, 2);
    },
  );

  test(
    'history A to B to A does not reuse a cursor from the first session',
    () async {
      final repository = _ControlledWalletRepository(
        pages: {
          null: _page([_item('a-before')], 'a-next'),
          'a-next': _page([_item('obsolete')], null),
        },
        firstPageOnRebuild: _page([_item('a-after')], null),
      );
      final auth = _MutableHistoryAuth('owner-a');
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(auth.changes.close);
      final provider = currencyHistoryProvider(WalletCurrency.cottonCandy);
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final pending = container.read(provider.notifier).loadNext();
      auth.change('owner-b');
      auth.change('owner-a');
      await _flush();
      await container.read(provider.future);
      repository.completeLatest('a-next');
      await pending;
      expect(container.read(provider).value!.items.map((item) => item.id), [
        'a-after',
      ]);
      auth.change(null, event: AuthChangeEvent.signedOut);
      await _flush();
      await expectLater(container.read(provider.future), throwsStateError);
      expect(repository.firstPageCalls, 2);
    },
  );

  test(
    'shared auth errors preserve wallet consumers without logging credentials',
    () async {
      final auth = _MutableHistoryAuth('owner-a');
      addTearDown(auth.changes.close);
      final repository = _FakeWalletRepository(
        summaries: [_summary(30), _summary(31)],
        pages: {
          null: _page([_item('settled')], null),
        },
      );
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      final logged = <LogEvent>[];
      void logListener(LogEvent event) => logged.add(event);
      Logger.addLogListener(logListener);
      addTearDown(() => Logger.removeLogListener(logListener));
      final history = currencyHistoryProvider(WalletCurrency.cottonCandy);
      container.listen(authSessionIdentityProvider, (_, _) {});
      container.listen(walletSummaryProvider, (_, _) {});
      container.listen(history, (_, _) {});
      await container.read(walletSummaryProvider.future);
      await container.read(history.future);
      final historySession = container.read(walletHistorySessionProvider);
      logged.clear();

      auth.changes.addError(
        StateError('fake-secret-refresh-token'),
        StackTrace.fromString('fake-secret-auth-stack'),
      );
      await _flush();
      expect(container.read(authSessionIdentityProvider), 'owner-a');
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
      );
      expect(container.read(history).value!.items.single.id, 'settled');
      expect(logged, isNotEmpty, reason: 'the auth failure remains observable');
      expect(logged.map((event) => event.error), everyElement(isNull));
      expect(logged.map((event) => event.stackTrace), everyElement(isNull));
      expect(
        logged.map((event) => event.message.toString()).join(),
        isNot(contains('fake-secret')),
      );

      auth.change('owner-a', event: AuthChangeEvent.initialSession);
      auth.change('owner-a', event: AuthChangeEvent.tokenRefreshed);
      await _flush();
      expect(repository.summaryCalls, 1);
      expect(repository.cursors, [null]);
      expect(
        container.read(walletHistorySessionProvider),
        same(historySession),
      );

      auth.change('owner-b');
      await _flush();
      expect(container.read(authSessionIdentityProvider), 'owner-b');
      expect(
        (await container.read(walletSummaryProvider.future)).cotton,
        BigInt.from(31),
      );
      await container.read(history.future);
      expect(repository.summaryCalls, 2);
      expect(repository.cursors, [null, null]);
      expect(
        container.read(walletHistorySessionProvider),
        isNot(same(historySession)),
      );
      container.dispose();
      expect(auth.changes.hasListener, isFalse);
    },
  );

  test('history auth replay settles without reopening the read loop', () async {
    final auth = _ReplayingAuthGateway(
      session: _FakeSession('owner-a'),
      replayed: AuthState(AuthChangeEvent.signedIn, _FakeSession('owner-a')),
      replayLimit: 5,
    );
    final repository = _FakeWalletRepository(
      summaries: [],
      pages: {
        null: _page([_item('settled')], null),
      },
    );
    final container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repository),
        walletAuthGatewayProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
    final history = currencyHistoryProvider(WalletCurrency.cottonCandy);
    container.listen(history, (_, _) {});
    await container.read(history.future);
    await _flush();
    expect(container.read(history).value!.items.single.id, 'settled');
    expect(repository.cursors, [null]);
    expect(auth.subscriptions, 1);
  });

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
              'give up and answer without one',
        );
        expect(state.hasValue, isTrue);
        expect(
          repository.summaryCalls,
          0,
          reason:
              'there is no session to read with, and the server has revoked '
              'anon EXECUTE on the wallet rpc: the only answer that read can '
              'get is a permission error',
        );
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

    test(
      'an auth stream error keeps the wallet and a later login still re-reads',
      () async {
        final uncaught = <Object>[];
        await runZonedGuarded(() async {
          final repository = _ScriptedWalletRepository([
            () async => _summary(30),
            () async => _summary(31),
          ]);
          final gateway = _MutableAuthGateway('user-1');
          final container = scriptedContainer(repository, gateway: gateway);

          expect(
            (await container.read(walletSummaryProvider.future)).cotton,
            BigInt.from(30),
          );
          expect(gateway.hasListener, isTrue);

          gateway.emitError(StateError('secret-refresh-token'));
          await _flush();
          expect(
            container.read(walletSummaryProvider).value!.cotton,
            BigInt.from(30),
            reason: 'a transient auth error must preserve the settled wallet',
          );

          gateway.signIn('user-2');
          expect(
            (await container.read(walletSummaryProvider.future)).cotton,
            BigInt.from(31),
          );
          expect(repository.summaryCalls, 2);

          container.dispose();
          expect(gateway.hasListener, isFalse);
          await gateway.close();
        }, (error, _) => uncaught.add(error));

        expect(
          uncaught,
          isEmpty,
          reason: 'wallet auth stream errors must not escape to the Zone',
        );
      },
    );
  });

  // `get_wallet_summary` is a `SECURITY DEFINER` read whose EXECUTE is revoked
  // from `anon` on purpose. A read sent without a session therefore cannot
  // return a balance - it returns `42501`, which the repository does not map
  // (it only maps the server's own `WALLET_UNAUTHENTICATED`), so the pouch
  // settles on an error card and every signed-out user leaves a permission
  // denial in the server log. The client already knows there is no session;
  // asking anyway is the defect.
  group('a wallet with no session never reaches the server', () {
    ProviderContainer sessionAwareContainer(
      WalletAuthGateway gateway,
      WalletRepository repository,
    ) {
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      container.listen(walletSummaryProvider, (previous, next) {});
      return container;
    }

    test('a signed-out build answers with an empty wallet, not a read', () {
      fakeAsync((async) {
        final gateway = _SilentAuthGateway();
        final repository = _SessionAwareRepository(gateway, [_summary(30)]);
        final container = sessionAwareContainer(gateway, repository);

        async.elapse(kWalletSessionRestoreTimeout + kWalletSummaryReadTimeout);

        expect(repository.readOwners, isEmpty);
        final wallet = container.read(walletSummaryProvider).value!;
        expect(wallet.star, BigInt.zero);
        expect(wallet.bonus, BigInt.zero);
        expect(wallet.cotton, BigInt.zero);
        expect(wallet.cottonExpiringAmount, BigInt.zero);
        expect(wallet.cottonNextExpiresAt, isNull);
      });
    });

    test('signing out does not send one last read as nobody', () {
      fakeAsync((async) {
        final gateway = _MutableHistoryAuth('owner-a');
        final repository = _SessionAwareRepository(gateway, [
          _summary(30),
          _summary(99),
        ]);
        final container = sessionAwareContainer(gateway, repository);

        async.elapse(const Duration(seconds: 1));
        expect(repository.readOwners, ['owner-a']);

        gateway.change(null, event: AuthChangeEvent.signedOut);
        async.elapse(kWalletSessionRestoreTimeout + kWalletSummaryReadTimeout);

        expect(
          repository.readOwners,
          ['owner-a'],
          reason:
              'the sign-out rebuild has no session to read with; the balance '
              'it shows is the empty wallet, not one the server was asked for',
        );
        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.zero,
        );
      });
    });

    test('the retry affordance is inert while signed out', () {
      fakeAsync((async) {
        final gateway = _SilentAuthGateway();
        final repository = _SessionAwareRepository(gateway, [_summary(30)]);
        final container = sessionAwareContainer(gateway, repository);
        async.elapse(kWalletSessionRestoreTimeout + kWalletSummaryReadTimeout);

        final observed = <AsyncValue<WalletSummaryModel>>[];
        container.listen(
          walletSummaryProvider,
          (previous, next) => observed.add(next),
        );
        container.read(walletSummaryProvider.notifier).refresh();
        async.elapse(kWalletSummaryReadTimeout + const Duration(seconds: 1));

        expect(repository.readOwners, isEmpty);
        expect(
          observed.where((state) => state.isLoading || state.hasError),
          isEmpty,
          reason:
              'a signed-out refresh has nothing to wait for and nothing to '
              'fail at; it must not flash a skeleton or an error card',
        );
      });
    });

    // gotrue announces a session recovered from storage as `initialSession`,
    // not `signedIn`. Once the pouch stops sending a read it cannot wait for,
    // that event is the only thing left that can wake it: a restore slower
    // than `kWalletSessionRestoreTimeout` would otherwise pin the card at zero
    // with no error and no retry affordance for the rest of the session.
    test('a session restored after the wait still gets read', () {
      fakeAsync((async) {
        final gateway = _MutableHistoryAuth(null);
        final repository = _SessionAwareRepository(gateway, [_summary(30)]);
        final container = sessionAwareContainer(gateway, repository);

        async.elapse(kWalletSessionRestoreTimeout + const Duration(seconds: 1));
        expect(repository.readOwners, isEmpty);

        gateway.change('owner-a', event: AuthChangeEvent.initialSession);
        async.elapse(kWalletSummaryReadTimeout + const Duration(seconds: 1));

        expect(
          repository.readOwners,
          ['owner-a'],
          reason: 'the late restore is what the read had to wait for',
        );
        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.from(30),
        );
      });
    });

    // `refresh()` guards its write with `ref.mounted` alone, and a keepAlive
    // notifier stays mounted across `invalidateSelf()`. The read a settled
    // purchase or the retry button starts is therefore still outstanding when
    // an account switch rebuilds the provider, and the balance it carries
    // belongs to the account that is no longer signed in.
    test(
      'a read started for the previous account cannot land on the new one',
      () {
        fakeAsync((async) {
          final gateway = _MutableHistoryAuth('owner-a');
          final stale = Completer<WalletSummaryModel>();
          final repository = _ScriptedWalletRepository([
            () async => _summary(30),
            () => stale.future,
            () async => _summary(99),
          ]);
          final container = sessionAwareContainer(gateway, repository);

          async.elapse(const Duration(seconds: 1));
          expect(
            container.read(walletSummaryProvider).value!.cotton,
            BigInt.from(30),
          );

          // Owner A's balance is being re-read ...
          container.read(walletSummaryProvider.notifier).refresh();
          async.flushMicrotasks();

          // ... and the account switches while that read is outstanding.
          gateway.change('owner-b');
          async.elapse(const Duration(seconds: 1));
          expect(
            container.read(walletSummaryProvider).value!.cotton,
            BigInt.from(99),
          );

          stale.complete(_summary(30));
          async.elapse(const Duration(seconds: 1));

          expect(
            container.read(walletSummaryProvider).value!.cotton,
            BigInt.from(99),
            reason:
                "owner A's balance must not be written onto owner B's screen "
                'just because its read was slower than the switch',
          );
        });
      },
    );

    // The wait ends on a restore *event*, but what the read goes out as is
    // decided by the session that is current when the read is sent. gotrue
    // hands that event over on a later turn than the one that produced it, so a
    // sign-out in between leaves the event holding a session the client has
    // already dropped - and the read it authorises goes out as `anon`.
    test('a sign-out during the session wait sends no read', () {
      fakeAsync((async) {
        final gateway = _BehaviorAuthGateway();
        final repository = _SessionAwareRepository(gateway, [_summary(30)]);
        final container = sessionAwareContainer(gateway, repository);

        // The restore the build was waiting for happens ...
        gateway.restore('owner-a');
        // ... and the user signs out before that event is delivered.
        gateway.signOut();

        async.elapse(kWalletSessionRestoreTimeout + kWalletSummaryReadTimeout);

        expect(
          repository.readOwners,
          isEmpty,
          reason:
              'the session the wait ended on was already gone; the read it '
              'would have authorised can only reach the server as anon',
        );
        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.zero,
        );

        // And nothing is orphaned: the build has to be listening for the
        // account it actually settled as (nobody), not the one the stale event
        // named, or signing back in as that account never wakes the pouch.
        gateway.restore('owner-a');
        async.elapse(kWalletSummaryReadTimeout + const Duration(seconds: 1));

        expect(repository.readOwners, ['owner-a']);
        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.from(30),
        );
      });
    });

    // gotrue reports a failed token refresh as an *error* on the same
    // `onAuthStateChange` the restore arrives on, and that stream replays its
    // last emission to every new subscriber - so a build that lets the error
    // escape fails again on its automatic retry. What goes with it is the
    // durable subscription that build was going to open, and without that
    // subscription the `initialSession` the restore finally produces has
    // nowhere to land: the pouch keeps whatever the failed build settled as for
    // the rest of the session.
    test('an auth failure during the restore wait does not orphan it', () {
      fakeAsync((async) {
        final gateway = _BehaviorAuthGateway();
        final repository = _SessionAwareRepository(gateway, [_summary(30)]);
        final container = sessionAwareContainer(gateway, repository);
        final logged = <LogEvent>[];
        void logListener(LogEvent event) => logged.add(event);
        Logger.addLogListener(logListener);
        addTearDown(() => Logger.removeLogListener(logListener));

        gateway.failRefresh(AuthException('fake-secret-refresh-token'));
        async.elapse(kWalletSessionRestoreTimeout + kWalletSummaryReadTimeout);

        expect(repository.readOwners, isEmpty);
        final whileFaulted = container.read(walletSummaryProvider);

        // The restore finally lands.
        gateway.restore('owner-a');
        async.elapse(kWalletSummaryReadTimeout + const Duration(seconds: 1));

        expect(
          repository.readOwners,
          ['owner-a'],
          reason:
              'the transient auth error must not cost the subscription the '
              'late restore needs',
        );
        expect(
          whileFaulted.isLoading,
          isFalse,
          reason: 'the wait is bounded whether it ends in a session or a fault',
        );
        expect(
          whileFaulted.hasError,
          isFalse,
          reason:
              'no session yet is an empty pouch, not a failure the user could '
              'retry into a balance',
        );
        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.from(30),
        );
        expect(logged, isNotEmpty, reason: 'the auth failure stays observable');
        expect(logged.map((event) => event.error), everyElement(isNull));
        expect(logged.map((event) => event.stackTrace), everyElement(isNull));
        expect(
          logged.map((event) => event.message.toString()).join(),
          isNot(contains('fake-secret')),
        );
      });
    });

    // A → B → A is two transitions that end where they started, and neither
    // guard on the write can see them. The build counter cannot:
    // `invalidateSelf()` only *queues* the rebuild, so it still reads as owner
    // A's first build. The user id cannot either: it reads `owner-a` before the
    // round trip and `owner-a` after it. The read is stale all the same - the
    // account was signed out and back in while it was in flight, and the
    // balance it carries predates both.
    test('a round trip to the same account rejects the read it started', () async {
      final gateway = _MutableHistoryAuth('owner-a');
      addTearDown(gateway.changes.close);
      final stale = Completer<WalletSummaryModel>();
      void roundTrip() {
        gateway.change('owner-b');
        gateway.change('owner-a');
      }

      final repository = _ScriptedWalletRepository([
        () async => _summary(30),
        () => _settling(stale.future, roundTrip),
        () async => _summary(77),
      ]);
      final container = sessionAwareContainer(gateway, repository);
      await container.read(walletSummaryProvider.future);

      final observed = <BigInt>[];
      container.listen(walletSummaryProvider, (previous, next) {
        final value = next.value;
        if (value != null) observed.add(value.cotton);
      });

      unawaited(container.read(walletSummaryProvider.notifier).refresh());
      await _flush();

      // The read owner A's first session started answers, and the round trip is
      // observed while that response is still settling.
      stale.complete(_summary(31));
      await _flush();
      await container.read(walletSummaryProvider.future);

      expect(
        observed,
        isNot(contains(BigInt.from(31))),
        reason:
            'the balance owner A was reading before the round trip is not the '
            'balance of the session that is signed in now',
      );
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(77),
      );
    });

    // The same round trip, with the stale read failing instead of answering.
    // Rejecting it matters just as much: the failure path deliberately restores
    // "the last balance we know of", and after the round trip that balance
    // belongs to a session that is no longer the one on screen.
    test(
      'a round trip to the same account rejects that read\'s failure',
      () async {
        final gateway = _MutableHistoryAuth('owner-a');
        addTearDown(gateway.changes.close);
        final stale = Completer<WalletSummaryModel>();
        final failure = Exception('network went away mid-switch');
        void roundTrip() {
          gateway.change('owner-b');
          gateway.change('owner-a');
        }

        final repository = _ScriptedWalletRepository([
          () async => _summary(30),
          () => _settling(stale.future, roundTrip),
          () async => _summary(77),
        ]);
        final container = sessionAwareContainer(gateway, repository);
        await container.read(walletSummaryProvider.future);

        final logged = <LogEvent>[];
        void logListener(LogEvent event) => logged.add(event);
        Logger.addLogListener(logListener);
        addTearDown(() => Logger.removeLogListener(logListener));

        unawaited(container.read(walletSummaryProvider.notifier).refresh());
        await _flush();

        stale.completeError(failure, StackTrace.current);
        await _flush();
        await container.read(walletSummaryProvider.future);

        expect(
          logged.where((event) => identical(event.error, failure)),
          isEmpty,
          reason:
              'a read the current session did not start must not decide what the '
              'pouch falls back to, successfully or otherwise',
        );
        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.from(77),
        );
      },
    );

    // The session wait is bounded, but it is still up to
    // `kWalletSessionRestoreTimeout` long, and the user can leave the screen
    // inside it. Nothing cancels the wait, so the build resumes afterwards and
    // registers its auth subscription through a `ref` that is already gone -
    // which throws where nobody is waiting, and leaves the subscription it had
    // just opened with no `onDispose` to cancel it.
    test('a dispose during the session wait ends the build quietly', () async {
      final uncaught = <Object>[];
      final gateway = _BehaviorAuthGateway();
      final repository = _SessionAwareRepository(gateway, [_summary(30)]);
      await runZonedGuarded(() async {
        final container = ProviderContainer(
          overrides: [
            walletRepositoryProvider.overrideWithValue(repository),
            walletAuthGatewayProvider.overrideWithValue(gateway),
          ],
        );
        container.listen(walletSummaryProvider, (previous, next) {});
        await _flush();

        // The user leaves the store while the restore is still outstanding ...
        container.dispose();
        // ... and the restore lands afterwards.
        gateway.restore('owner-a');
        await _flush();
      }, (error, _) => uncaught.add(error));

      expect(
        gateway.liveSubscriptions,
        0,
        reason:
            'the subscription is registered a line before the `onDispose` that '
            'cancels it; if that registration throws on a disposed ref, the '
            'listener it just opened stays attached to gotrue for good',
      );
      expect(
        uncaught,
        isEmpty,
        reason: 'a build that outlives its ref must end, not throw',
      );
      expect(repository.readOwners, isEmpty);
    });

    // A settled purchase or a watched ad fires this and drops the future. By
    // the time it runs the user may have left the store, and reaching through
    // `ref` for the gateway is the first thing it does.
    test('a refresh that arrives after dispose reads nothing', () async {
      final gateway = _MutableHistoryAuth('owner-a');
      addTearDown(gateway.changes.close);
      final repository = _SessionAwareRepository(gateway, [_summary(30)]);
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      container.listen(walletSummaryProvider, (previous, next) {});
      await container.read(walletSummaryProvider.future);
      final notifier = container.read(walletSummaryProvider.notifier);

      container.dispose();

      await expectLater(notifier.refresh(), completes);
      expect(repository.readOwners, ['owner-a']);
    });
  });

  // The order below is the whole reproduction, and it is the order a real
  // device produces: the wallet response is queued FIRST, the session is
  // swapped synchronously, and only then is the auth event queued. So the
  // response is judged in a turn where `currentSession` already names somebody
  // else while no listener has heard anything - the rebuild counter and the
  // listener-driven epoch both still read as the session that started the read.
  //
  // What separates the cases is not the user id. A → B → A comes back to
  // `owner-a`, and a token refresh never leaves it. The session **instance** is
  // what moved, and it is the one thing available without waiting for the
  // stream: gotrue swaps `currentSession` before it notifies, and a
  // `BehaviorSubject` replay hands back the very same instance.
  group('a response queued before the auth event it raced', () {
    ProviderContainer observed(
      _AsyncAuthGateway gateway,
      WalletRepository repository,
      _Observer seen,
    ) {
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(gateway.close);
      container.listen(walletSummaryProvider, seen.record);
      return container;
    }

    test('a sign-out discards the build that was already answering', () async {
      final answering = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () => answering.future,
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await _flush();

      answering.complete(_summary(11));
      gateway.change(null, event: AuthChangeEvent.signedOut);
      await _flush();
      await container.read(walletSummaryProvider.future);

      expect(
        seen.values,
        isNot(contains(BigInt.from(11))),
        reason: "owner A's balance must never surface on a signed-out screen",
      );
      expect(container.read(walletSummaryProvider).value!.cotton, BigInt.zero);
      expect(repository.readOwners, ['owner-a']);
    });

    test('an account switch discards the build that was answering', () async {
      final answering = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () => answering.future,
        () async => _summary(20),
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await _flush();

      answering.complete(_summary(11));
      gateway.change('owner-b');
      await _flush();
      await container.read(walletSummaryProvider.future);

      expect(seen.values, isNot(contains(BigInt.from(11))));
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(20),
      );
      expect(repository.readOwners, ['owner-a', 'owner-b']);
    });

    test('a round trip discards the build success it was answering', () async {
      final answering = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () => answering.future,
        () async => _summary(30),
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await _flush();

      answering.complete(_summary(11));
      gateway.change('owner-b');
      gateway.change('owner-a');
      await _flush();
      await container.read(walletSummaryProvider.future);

      expect(seen.values, isNot(contains(BigInt.from(11))));
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
      );
      expect(
        repository.readOwners,
        ['owner-a', 'owner-a'],
        reason: 'both reads carry the same user id - that is the point',
      );
      expect(
        identical(repository.readSessions[0], repository.readSessions[1]),
        isFalse,
        reason:
            'and a different session, which is the only thing that told them '
            'apart without waiting for the stream',
      );
    });

    test('a round trip discards the build failure it was answering', () async {
      final answering = Completer<WalletSummaryModel>();
      final staleError = StateError('owner-a build failed');
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () => answering.future,
        () async => _summary(30),
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await _flush();

      answering.completeError(staleError, StackTrace.current);
      gateway.change('owner-b');
      gateway.change('owner-a');
      await _flush();
      await container.read(walletSummaryProvider.future);

      expect(
        seen.errors,
        isNot(contains(staleError)),
        reason:
            'a failure belongs to the session that asked; showing it to the '
            'next one is an error card nobody can act on',
      );
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
      );
    });

    test('a round trip discards the refresh it queued first', () async {
      final answering = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () async => _summary(10),
        () => answering.future,
        () async => _summary(30),
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      expect(
        (await container.read(walletSummaryProvider.future)).cotton,
        BigInt.from(10),
      );

      unawaited(container.read(walletSummaryProvider.notifier).refresh());
      answering.complete(_summary(11));
      gateway.change('owner-b');
      gateway.change('owner-a');
      await _flush();
      await container.read(walletSummaryProvider.future);

      expect(seen.values, isNot(contains(BigInt.from(11))));
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
        reason: 'the value on screen is replaced by the rebuild, not by 11',
      );
      expect(repository.readOwners, ['owner-a', 'owner-a', 'owner-a']);
    });

    // A token refresh is the case where dropping the response must NOT cost the
    // user anything: same person, same data, only a new token. With a balance
    // already on screen the cheapest correct answer is to keep it and read
    // nothing - the response we dropped was that user's anyway, and the
    // same-owner event will not (and must not) rebuild.
    test('a token refresh keeps the balance and reads nothing more', () async {
      final answering = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () async => _summary(30),
        () => answering.future,
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await container.read(walletSummaryProvider.future);

      final refreshing = container
          .read(walletSummaryProvider.notifier)
          .refresh();
      answering.complete(_summary(31));
      gateway.refreshToken('owner-a');
      await refreshing;
      await _flush();

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
        reason: 'the last balance this user confirmed stays put',
      );
      expect(container.read(walletSummaryProvider).isLoading, isFalse);
      expect(
        repository.readOwners,
        hasLength(2),
        reason:
            'there is something to show, so nothing needs re-reading - and a '
            'same-owner event must never rebuild',
      );
    });

    // With nothing on screen the same drop would strand the pouch in a spinner
    // forever, so this is the one case that earns a fresh read - exactly one,
    // against the session that now holds.
    test('a token refresh with nothing to show re-reads once', () async {
      final answering = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () async => throw Exception('first load failed'),
        () async => throw Exception('and its automatic retry failed'),
        () => answering.future,
        () async => _summary(42),
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(container.read(walletSummaryProvider).value, isNull);

      final refreshing = container
          .read(walletSummaryProvider.notifier)
          .refresh();
      answering.complete(_summary(41));
      gateway.refreshToken('owner-a');
      await refreshing;

      expect(
        repository.readOwners,
        hasLength(4),
        reason:
            'one fresh read for the new session: none would spin forever, more '
            'than one would be a loop',
      );
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(42),
      );
      expect(container.read(walletSummaryProvider).isLoading, isFalse);
      expect(seen.values, isNot(contains(BigInt.from(41))));
    });

    // The re-read budget is one. If the session is replaced *again* while that
    // one re-read is outstanding, abandoning it would leave the spinner this
    // whole branch exists to avoid - and publishing the stale response is still
    // forbidden. So the read is handed back to a rebuild against the session
    // that now holds.
    test('a second token refresh during the re-read still settles', () async {
      final firstTry = Completer<WalletSummaryModel>();
      final secondTry = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () async => throw Exception('first load failed'),
        () async => throw Exception('and its automatic retry failed'),
        () => firstTry.future,
        () => secondTry.future,
        () async => _summary(44),
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(container.read(walletSummaryProvider).value, isNull);

      final refreshing = container
          .read(walletSummaryProvider.notifier)
          .refresh();
      firstTry.complete(_summary(41));
      gateway.refreshToken('owner-a');
      await _flush();

      // The one re-read this branch is allowed is now outstanding, and the
      // session is replaced under it as well.
      secondTry.complete(_summary(43));
      gateway.refreshToken('owner-a');
      await refreshing;
      await _flush();
      await container.read(walletSummaryProvider.future);

      expect(
        container.read(walletSummaryProvider).isLoading,
        isFalse,
        reason: 'exhausting the budget must not strand the pouch in loading',
      );
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(44),
      );
      expect(seen.values, isNot(contains(BigInt.from(41))));
      expect(
        seen.values,
        isNot(contains(BigInt.from(43))),
        reason: 'neither abandoned response may be published on the way out',
      );
      expect(repository.readOwners, hasLength(5));
    });

    // A build whose read finally answers long after a newer build already
    // settled has nothing to fix: the state belongs to that newer build. Asking
    // for another rebuild would re-read a balance that is already correct.
    test('a build the next generation already replaced just stops', () async {
      final abandoned = Completer<WalletSummaryModel>();
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () => abandoned.future,
        () async => _summary(20),
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await _flush();

      // The switch is delivered in full, so owner B's build completes first.
      gateway.change('owner-b');
      await _flush();
      expect(
        (await container.read(walletSummaryProvider.future)).cotton,
        BigInt.from(20),
      );

      // Only now does owner A's read answer.
      abandoned.complete(_summary(11));
      await _flush();
      await _flush();

      expect(
        repository.readOwners,
        ['owner-a', 'owner-b'],
        reason:
            'the settled build is already right; a stale response must not '
            'cost a third read',
      );
      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(20),
      );
      expect(seen.values, isNot(contains(BigInt.from(11))));
    });

    test('a token refresh re-read that fails is shown, not spun', () async {
      final answering = Completer<WalletSummaryModel>();
      final retryFailure = Exception('the new session could not read either');
      final gateway = _AsyncAuthGateway('owner-a');
      final repository = _ScriptedSessionRepository(gateway, [
        () async => throw Exception('first load failed'),
        () async => throw Exception('and its automatic retry failed'),
        () => answering.future,
        () async => throw retryFailure,
      ]);
      final seen = _Observer();
      final container = observed(gateway, repository, seen);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(container.read(walletSummaryProvider).value, isNull);

      final refreshing = container
          .read(walletSummaryProvider.notifier)
          .refresh();
      answering.complete(_summary(41));
      gateway.refreshToken('owner-a');
      await refreshing;

      expect(
        repository.readOwners,
        hasLength(4),
        reason: 'bounded: the re-read is not retried again',
      );
      expect(
        container.read(walletSummaryProvider).isLoading,
        isFalse,
        reason: 'a failure the user can retry beats a spinner they cannot',
      );
      expect(container.read(walletSummaryProvider).error, same(retryFailure));
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

        notifier.setSummary(ad, owner: notifier.captureOwner());
        // The purchase's receipt verification started before the ad and finished
        // after it, so its snapshot predates the reward.
        notifier.setSummary(
          _summary(10, snapshotAt: DateTime.utc(2026, 7, 21, 12, 0, 5)),
          owner: notifier.captureOwner(),
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
        owner: notifier.captureOwner(),
      );
      final purchase = _summary(
        40,
        snapshotAt: DateTime.utc(2026, 7, 21, 12, 0, 10),
      );
      notifier.setSummary(purchase, owner: notifier.captureOwner());

      expect(container.read(walletSummaryProvider).value, same(purchase));
    });

    test(
      'two responses stamped the same instant take the later write',
      () async {
        final stamp = DateTime.utc(2026, 7, 21, 12);
        final container = settledContainer(_summary(0));
        await container.read(walletSummaryProvider.future);
        final notifier = container.read(walletSummaryProvider.notifier);

        notifier.setSummary(
          _summary(30, snapshotAt: stamp),
          owner: notifier.captureOwner(),
        );
        final second = _summary(40, snapshotAt: stamp);
        notifier.setSummary(second, owner: notifier.captureOwner());

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
      final notifier = container.read(walletSummaryProvider.notifier);
      notifier.setSummary(settled, owner: notifier.captureOwner());

      expect(container.read(walletSummaryProvider).value, same(settled));
    });
  });

  group('a settlement carries the account it was started for', () {
    ProviderContainer ownedContainer(
      _ScriptedWalletRepository repository,
      WalletAuthGateway gateway,
    ) {
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      container.listen(walletSummaryProvider, (previous, next) {});
      return container;
    }

    // The purchase adapter is captured while the store is mounted and is
    // *designed* to outlive the route, because the candy is granted the moment
    // the receipt verifies. Nothing about that capture says which account
    // started the purchase, so an account switch does not stop it.
    test('a verified purchase from owner A never lands on owner B', () async {
      final repository = _ScriptedWalletRepository([
        () async => _summary(10),
        () async => _summary(20),
      ]);
      final gateway = _MutableAuthGateway('owner-a');
      final container = ownedContainer(repository, gateway);
      addTearDown(gateway.close);

      // Captured in the store's initState, under owner A.
      final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
      expect(
        (await container.read(walletSummaryProvider.future)).cotton,
        BigInt.from(10),
      );

      gateway.signIn('owner-b');
      expect(
        (await container.read(walletSummaryProvider.future)).cotton,
        BigInt.from(20),
      );

      // A's receipt verification finally answers. Its snapshot is newer, so
      // the snapshotAt ordering rule waves it through.
      applyWallet(_summary(99, snapshotAt: DateTime.utc(2026, 7, 22)));

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(20),
        reason:
            'the response was started by owner A; showing it to owner B puts '
            'another account\'s balance on this screen',
      );
    });

    // The failure mode the guard itself can cause. A settlement takes as long
    // as the network takes, and gotrue swaps in a brand new `Session` object
    // every time it refreshes the token - same account, different instance.
    // Judging ownership by instance identity (the way the *read* path must)
    // would throw away a settlement that is genuinely this user's, and the
    // candy would never appear.
    test('a token refresh mid-settlement still applies', () async {
      final repository = _ScriptedWalletRepository([() async => _summary(10)]);
      final gateway = _MutableAuthGateway('owner-a');
      final container = ownedContainer(repository, gateway);
      addTearDown(gateway.close);

      final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
      await container.read(walletSummaryProvider.future);

      // Same account, new Session instance - a refresh, not a switch.
      gateway.signIn('owner-a');
      await _flush();

      applyWallet(_summary(40, snapshotAt: DateTime.utc(2026, 7, 22)));
      // 세션 인스턴스가 갈린 쓰기는 한 턴 뒤에 판정된다. 그 한 턴이 토큰 갱신과
      // 아직 전달되지 않은 계정 왕복을 가르는 auth 이벤트를 흘려보낸다.
      await _flush();

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(40),
        reason:
            'the purchase belongs to this account; a token refresh in the '
            'middle of it is not an account change',
      );
      expect(
        repository.summaryCalls,
        1,
        reason: 'a same-account refresh must not re-read either',
      );
    });

    // A -> B -> A. The user id at the end is the one the settlement started
    // under, so comparing ids alone waves it through - but B held the screen in
    // between and the balance A came back with is stale for the session that is
    // running now.
    test('a round trip to the same account rejects the settlement', () async {
      final repository = _ScriptedWalletRepository([
        () async => _summary(10),
        () async => _summary(20),
        () async => _summary(30),
      ]);
      final gateway = _MutableAuthGateway('owner-a');
      final container = ownedContainer(repository, gateway);
      addTearDown(gateway.close);

      final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
      await container.read(walletSummaryProvider.future);

      gateway.signIn('owner-b');
      await container.read(walletSummaryProvider.future);
      gateway.signIn('owner-a');
      await container.read(walletSummaryProvider.future);

      applyWallet(_summary(99, snapshotAt: DateTime.utc(2026, 7, 22)));
      // A session-rotated write is decided a turn later, so the queue has to be
      // drained before asking - otherwise the assertion passes simply because
      // nothing has been written yet.
      await _flush();
      await _flush();

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(30),
        reason:
            'the ids match at both ends, so only the count of observed '
            'switches can tell this settlement is from a session that ended',
      );
    });

    // The window the *read* path already guards, applied to a write. gotrue
    // swaps `currentSession` in the mutating turn and only queues the event, so
    // A -> B -> A can complete with no listener having run: the owner id is
    // back to A and the epoch the listener increments has not moved. Nothing
    // event-driven has changed at that instant - only the session instance has.
    test('a round trip completed before its auth events are delivered is '
        'rejected', () async {
      final repository = _ScriptedWalletRepository([
        () async => _summary(10),
        for (var i = 0; i < 6; i++) () async => _summary(20 + i),
      ]);
      final gateway = _AsyncAuthGateway('owner-a');
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(gateway.close);
      container.listen(walletSummaryProvider, (previous, next) {});

      final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
      expect(
        (await container.read(walletSummaryProvider.future)).cotton,
        BigInt.from(10),
      );

      // Both transitions land in the subject; neither listener has run yet.
      gateway.change('owner-b');
      gateway.change('owner-a');

      applyWallet(_summary(99, snapshotAt: DateTime.utc(2099)));

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(10),
        reason:
            'owner B held the session in between; the settlement A started '
            'describes a balance from a session that has ended',
      );

      // Dropping it a turn later is the same bug with a delay, so the queue has
      // to be drained and the balance asked again.
      await _flush();
      await _flush();
      expect(
        container.read(walletSummaryProvider).value?.cotton,
        isNot(BigInt.from(99)),
        reason: 'the stale settlement must not surface on a later turn either',
      );
    });

    // `refresh` is the explicit re-read and deliberately does not go through
    // the snapshot ordering rule - it is the newest thing there is. A deferred
    // settlement must not undo one that finished after it was scheduled.
    test('a re-read that finishes first is not undone by a deferred '
        'settlement', () async {
      final repository = _ScriptedWalletRepository([
        () async => _summary(10),
        () async => _summary(70, snapshotAt: DateTime.utc(2026, 7, 25)),
      ]);
      final gateway = _AsyncAuthGateway('owner-a');
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(gateway.close);
      container.listen(walletSummaryProvider, (previous, next) {});

      final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
      await container.read(walletSummaryProvider.future);

      // Same account, new Session instance, events drained: the settlement is
      // this user's and is allowed - only its application is deferred.
      gateway.refreshToken('owner-a');
      await _flush();

      applyWallet(_summary(99, snapshotAt: DateTime.utc(2099)));
      final reread = container.read(walletSummaryProvider.notifier).refresh();
      await reread;
      await _flush();

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(70),
        reason:
            'the explicit re-read started after the settlement was queued and '
            'answered from the server; a settlement waiting on a later turn '
            'must not roll the balance back over it',
      );
    });

    // A refresh that failed answered nothing. It keeps the balance already on
    // screen, which is the *pre-settlement* one, so treating it as the newer
    // answer throws away candy the server has already granted - and nothing
    // else is coming to put it back.
    // The same undelivered-event window, reached by signing out and back in as
    // the same person. The id matches at both ends just like the round trip,
    // and nothing the listener drives has moved yet.
    test(
      'a sign-out and back in before the events are delivered is rejected',
      () async {
        final repository = _ScriptedWalletRepository([
          () async => _summary(10),
          for (var i = 0; i < 6; i++) () async => _summary(20 + i),
        ]);
        final gateway = _AsyncAuthGateway('owner-a');
        final container = ProviderContainer(
          overrides: [
            walletRepositoryProvider.overrideWithValue(repository),
            walletAuthGatewayProvider.overrideWithValue(gateway),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(gateway.close);
        container.listen(walletSummaryProvider, (previous, next) {});

        final applyWallet = ContainerWalletSummaryApplier.forContainer(
          container,
        );
        expect(
          (await container.read(walletSummaryProvider.future)).cotton,
          BigInt.from(10),
        );

        gateway.change(null, event: AuthChangeEvent.signedOut);
        gateway.change('owner-a');

        applyWallet(_summary(99, snapshotAt: DateTime.utc(2099)));

        expect(
          container.read(walletSummaryProvider).value!.cotton,
          BigInt.from(10),
        );
        await _flush();
        await _flush();
        expect(
          container.read(walletSummaryProvider).value?.cotton,
          isNot(BigInt.from(99)),
          reason:
              'the session that started this settlement ended at sign-out, even '
              'though the same person signed back in',
        );
      },
    );

    test('a failed re-read does not discard the settlement it raced', () async {
      final repository = _ScriptedWalletRepository([
        () async => _summary(10),
        () async => throw Exception('network went away'),
      ]);
      final gateway = _AsyncAuthGateway('owner-a');
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(gateway.close);
      container.listen(walletSummaryProvider, (previous, next) {});

      final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
      await container.read(walletSummaryProvider.future);

      gateway.refreshToken('owner-a');
      await _flush();

      applyWallet(_summary(88, snapshotAt: DateTime.utc(2026, 7, 25)));
      await container.read(walletSummaryProvider.notifier).refresh();
      await _flush();

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.from(88),
        reason:
            'the candy was granted server-side; a re-read that never answered '
            'is not a newer answer, and dropping the settlement behind it '
            'leaves the balance stale with nothing left to correct it',
      );
    });

    test('a settlement that arrives after sign-out never lands', () async {
      final repository = _ScriptedWalletRepository([
        () async => _summary(10),
        () async => _summary(0),
      ]);
      final gateway = _MutableAuthGateway('owner-a');
      final container = ownedContainer(repository, gateway);
      addTearDown(gateway.close);

      final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
      await container.read(walletSummaryProvider.future);

      gateway.signOut();
      await container.read(walletSummaryProvider.future);

      // Stamped past the signed-out snapshot on purpose. The snapshotAt rule
      // must not be what rejects this - otherwise the test would pass with no
      // ownership check at all, which is exactly the bug under repair.
      applyWallet(_summary(99, snapshotAt: DateTime.utc(2099)));

      expect(
        container.read(walletSummaryProvider).value!.cotton,
        BigInt.zero,
        reason:
            'nobody is signed in; a balance from the account that just left '
            'must not be what the pouch shows',
      );
    });
  });
}
