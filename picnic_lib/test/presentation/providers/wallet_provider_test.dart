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

/// Repository whose history responses only resolve when the test says so,
/// so overlapping `loadNext()` calls can be landed out of order.
class _ControlledWalletRepository extends WalletRepository {
  _ControlledWalletRepository({required this.pages})
    : super(_UnusedSupabaseClient());

  final Map<String?, CurrencyHistoryPageModel> pages;
  final List<String?> cursors = [];
  final List<MapEntry<String, Completer<CurrencyHistoryPageModel>>> _pending =
      [];

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) {
    cursors.add(cursor);
    if (cursor == null) return Future.value(pages[null]!);
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

  /// Resolves every request for [cursor] that is still in flight, oldest first.
  void completeRemaining(String cursor) {
    final entries = _pending.where((entry) => entry.key == cursor).toList();
    _pending.removeWhere((entry) => entry.key == cursor);
    for (final entry in entries) {
      entry.value.complete(pages[cursor]!);
    }
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

WalletSummaryModel _summary(int cotton) => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.zero,
  cotton: BigInt.from(cotton),
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 7, 21),
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

  test(
    'a slow loadNext landing late never drops a page nor rewinds the cursor',
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
      final slow = notifier.loadNext();
      final fast = notifier.loadNext();
      await _flush();

      // The response that started last comes back first.
      repository.completeLatest('cursor-2');
      await _flush();

      // The user keeps scrolling and the following page lands as well.
      final third = notifier.loadNext();
      await _flush();
      repository.completeLatest('cursor-3');
      await _flush();

      // Finally the very first, slow response arrives - it must not clobber
      // the newer state it never saw.
      repository.completeRemaining('cursor-2');
      await _flush();
      await Future.wait([slow, fast, third]);

      final page = container.read(provider).value!;
      expect([for (final item in page.items) item.id], ['1', '2', '3']);
      expect(page.nextCursor, isNull);
      expect(page.totalCount, BigInt.from(3));

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
}
