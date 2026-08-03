import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/currency_history_list_item.dart';

const _historyCurrencies = [
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
    final isAdmin =
        ref.watch(userInfoProvider.select((state) => state.value?.isAdmin)) ??
        false;
    if (!isAdmin) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: _historyCurrencies.length,
      child: Padding(
        key: const Key('currency-history-content'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: l10n.wallet_star_candy),
                Tab(text: l10n.wallet_bonus_star_candy),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _CurrencyHistoryTab(currency: WalletCurrency.starCandy),
                  _CurrencyHistoryTab(currency: WalletCurrency.bonusStarCandy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyHistoryTab extends ConsumerWidget {
  const _CurrencyHistoryTab({required this.currency});

  final WalletCurrency currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(currencyHistoryProvider(currency));
    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text(AppLocalizations.of(context).wallet_load_failed)),
      data: (page) {
        if (page.items.isEmpty) return const NoItemContainer();
        return NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter == 0 &&
                page.nextCursor != null) {
              ref.read(currencyHistoryProvider(currency).notifier).loadNext();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: page.items.length,
            itemBuilder: (context, index) =>
                CurrencyHistoryListItem(item: page.items[index]),
          ),
        );
      },
    );
  }
}
