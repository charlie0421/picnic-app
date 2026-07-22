import 'package:flutter_test/flutter_test.dart';
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
  String? nextCursor,
) => CurrencyHistoryPageModel(
  items: items,
  totalCount: BigInt.from(2),
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
}
