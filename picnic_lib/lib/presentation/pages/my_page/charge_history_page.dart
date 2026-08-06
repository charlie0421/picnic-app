import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/admin/payment_breakdown.dart';
import 'package:picnic_lib/presentation/providers/admin_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

class ChargeHistoryPage extends ConsumerStatefulWidget {
  const ChargeHistoryPage({super.key});

  @override
  ConsumerState<ChargeHistoryPage> createState() => _ChargeHistoryPageState();
}

class _ChargeHistoryPageState extends ConsumerState<ChargeHistoryPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: '충전 내역');
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAdminAccess =
        ref.watch(
          userInfoProvider.select((state) => state.value?.hasAdminAccess),
        ) ??
        false;
    if (!hasAdminAccess) {
      return const Center(child: Text('접근 권한이 없습니다.'));
    }

    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: '플랫폼별'),
              Tab(text: '상품별'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PaymentBreakdownTab(
                  dimension: PaymentBreakdownDimension.platform,
                ),
                _PaymentBreakdownTab(
                  dimension: PaymentBreakdownDimension.product,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBreakdownTab extends ConsumerWidget {
  const _PaymentBreakdownTab({required this.dimension});

  final PaymentBreakdownDimension dimension;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = switch (dimension) {
      PaymentBreakdownDimension.platform => ref.watch(
        platformPaymentBreakdownProvider,
      ),
      PaymentBreakdownDimension.product => ref.watch(
        productPaymentBreakdownProvider,
      ),
    };
    return breakdown.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('충전 내역을 불러오지 못했습니다.')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('충전 내역이 없습니다.'));
        }
        return ListView.separated(
          key: const Key('charge-history-list'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) => _PaymentBreakdownRow(item: items[index]),
        );
      },
    );
  }
}

class _PaymentBreakdownRow extends StatelessWidget {
  const _PaymentBreakdownRow({required this.item});

  final PaymentBreakdownItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.key),
      subtitle: Text('결제 ${item.payCount}건 · \$${item.revenueUsd}'),
    );
  }
}
