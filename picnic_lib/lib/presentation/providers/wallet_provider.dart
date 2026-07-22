import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/wallet_provider.g.dart';

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) => WalletRepository(supabase);

@Riverpod(keepAlive: true)
class WalletSummary extends _$WalletSummary {
  @override
  Future<WalletSummaryModel> build() {
    return ref.watch(walletRepositoryProvider).getSummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(walletRepositoryProvider).getSummary,
    );
  }

  void setSummary(WalletSummaryModel summary) {
    state = AsyncData(summary);
  }
}

@riverpod
class CurrencyHistory extends _$CurrencyHistory {
  @override
  Future<CurrencyHistoryPageModel> build(WalletCurrency currency) {
    return ref.watch(walletRepositoryProvider).getHistory(currency: currency);
  }

  Future<void> loadNext() async {
    final current = state.value;
    if (current == null || current.nextCursor == null) return;

    final next = await ref
        .read(walletRepositoryProvider)
        .getHistory(currency: currency, cursor: current.nextCursor);
    final seen = current.items.map((item) => item.id).toSet();
    state = AsyncData(
      current.copyWith(
        items: [
          ...current.items,
          ...next.items.where((item) => seen.add(item.id)),
        ],
        nextCursor: next.nextCursor,
        totalCount: next.totalCount,
      ),
    );
  }
}
