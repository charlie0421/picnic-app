import 'dart:async';

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
