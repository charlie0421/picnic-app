import 'package:flutter/material.dart';
import 'package:picnic_app/components/vote/store/free_charge_station.dart';
import 'package:picnic_app/components/vote/store/purchase_star_candy.dart';
import 'package:picnic_app/generated/l10n.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabBar();
  }

  Widget _buildTabBar() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          tabs: [
            Tab(text: S.of(context).label_tab_buy_star_candy),
            Tab(text: S.of(context).label_tab_free_charge_station),
          ],
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: const [
          PurchaseStarCandy(),
          FreeChargeStation(),
        ])),
      ],
    );
  }
}
