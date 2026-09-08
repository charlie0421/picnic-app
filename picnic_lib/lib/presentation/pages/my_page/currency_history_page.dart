import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/currency_history_list_item.dart';

const _historyCurrencies = [
  WalletCurrency.cottonCandy,
  WalletCurrency.starCandy,
  WalletCurrency.bonusStarCandy,
];

class CurrencyHistoryPage extends ConsumerStatefulWidget {
  const CurrencyHistoryPage({super.key});

  @override
  ConsumerState<CurrencyHistoryPage> createState() =>
      _CurrencyHistoryPageState();
}

class _CurrencyHistoryPageState extends ConsumerState<CurrencyHistoryPage> {
  WalletCurrency _selectedCurrency = WalletCurrency.cottonCandy;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(
            pageTitle: AppLocalizations.of(context).wallet_history_title,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      userInfoProvider.select((state) => state.value?.id),
    );
    final session = ref.watch(walletHistorySessionProvider);
    if (userId == null || userId != session.userId) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: _historyCurrencies.length,
      initialIndex: _historyCurrencies.indexOf(_selectedCurrency),
      child: Padding(
        key: const Key('currency-history-content'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              onTap: (index) =>
                  setState(() => _selectedCurrency = _historyCurrencies[index]),
              tabs: [
                Tab(text: l10n.wallet_cotton_candy),
                Tab(text: l10n.wallet_star_candy),
                Tab(text: l10n.wallet_bonus_star_candy),
              ],
            ),
            Expanded(
              child: _CurrencyHistoryTab(
                key: ValueKey((session, _selectedCurrency)),
                currency: _selectedCurrency,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyHistoryTab extends ConsumerStatefulWidget {
  const _CurrencyHistoryTab({super.key, required this.currency});

  final WalletCurrency currency;

  @override
  ConsumerState<_CurrencyHistoryTab> createState() =>
      _CurrencyHistoryTabState();
}

class _CurrencyHistoryTabState extends ConsumerState<_CurrencyHistoryTab> {
  bool _loadingNext = false;
  bool _nextPageFailed = false;
  int _requestGeneration = 0;

  Future<void> _refresh() async {
    setState(() {
      _requestGeneration++;
      _loadingNext = false;
      _nextPageFailed = false;
    });
    try {
      ref.invalidate(currencyHistoryProvider(widget.currency));
      await ref.read(currencyHistoryProvider(widget.currency).future);
    } catch (_) {
      // The provider renders the error and retry control.
    }
  }

  Future<void> _loadNext() async {
    if (_loadingNext) return;
    final generation = _requestGeneration;
    setState(() => _loadingNext = true);
    try {
      final succeeded = await ref
          .read(currencyHistoryProvider(widget.currency).notifier)
          .loadNext();
      if (mounted && generation == _requestGeneration) {
        _nextPageFailed = !succeeded;
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loadingNext = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(currencyHistoryProvider(widget.currency));
    return history.when(
      skipLoadingOnRefresh: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.wallet_load_failed),
            TextButton(
              key: const Key('currency-history-retry'),
              onPressed: () =>
                  ref.invalidate(currencyHistoryProvider(widget.currency)),
              child: Text(l10n.common_retry_label),
            ),
          ],
        ),
      ),
      data: (page) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: page.items.isEmpty
                ? 1
                : page.items.length + (page.nextCursor == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (page.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l10n.wallet_history_empty)),
                );
              }
              if (index < page.items.length) {
                return CurrencyHistoryListItem(item: page.items[index]);
              }
              return Column(
                children: [
                  if (_nextPageFailed)
                    Text(
                      l10n.wallet_load_failed,
                      key: const Key('currency-history-next-error'),
                    ),
                  TextButton(
                    key: const Key('currency-history-next'),
                    onPressed: _loadingNext ? null : _loadNext,
                    child: Text(
                      _loadingNext
                          ? l10n.loading
                          : _nextPageFailed
                          ? l10n.common_retry_label
                          : MaterialLocalizations.of(context).nextPageTooltip,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
