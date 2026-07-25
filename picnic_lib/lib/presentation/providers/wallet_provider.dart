import 'package:picnic_lib/core/utils/logger.dart';
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

  bool _loadingNext = false;

  Future<void> loadNext() async {
    // 스크롤 끝 알림이 연달아 들어와도 페이지 요청은 한 번만 (PICNIC-APP-4R8)
    if (_loadingNext) return;
    final current = state.value;
    if (current == null || current.nextCursor == null) return;

    _loadingNext = true;
    try {
      final next = await ref
          .read(walletRepositoryProvider)
          .getHistory(currency: currency, cursor: current.nextCursor);
      // async gap 중 provider 가 dispose 되었으면 state 접근 금지
      if (!ref.mounted) return;
      // 응답이 도착한 시점의 state 기준으로 병합 (await 이전 스냅샷 사용 금지)
      final latest = state.value ?? current;
      final seen = latest.items.map((item) => item.id).toSet();
      state = AsyncData(
        latest.copyWith(
          items: [
            ...latest.items,
            ...next.items.where((item) => seen.add(item.id)),
          ],
          nextCursor: next.nextCursor,
          totalCount: next.totalCount,
        ),
      );
    } catch (e, s) {
      // 이미 불러온 페이지는 유지하고 실패만 보고한다.
      logger.e(
        'Failed to load next currency history page',
        error: e,
        stackTrace: s,
      );
    } finally {
      _loadingNext = false;
    }
  }
}
