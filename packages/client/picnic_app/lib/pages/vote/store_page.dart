import 'package:flutter/material.dart';
import 'package:picnic_app/components/vote/store/free_charge_station.dart';
import 'package:picnic_app/components/vote/store/purchase_star_candy.dart';

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
          tabs: const [
            // TODO i18n
            Tab(text: '별사탕 구매'),
            Tab(text: '무료 충전소'),
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
