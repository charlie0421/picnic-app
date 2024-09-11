import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/vote/store/free_charge_station/free_charge_station.dart';
import 'package:picnic_app/components/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_app/components/vote/store/purchase/purchase_star_candy_web.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(showPortal: true, showBottomNavigation: true);
    });

    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabBar();
  }

  Widget _buildTabBar() {
    return kIsWeb
        ? PurchaseStarCandyWeb()
        : Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: S.of(context).label_tab_buy_star_candy),
                  if (!kIsWeb)
                    Tab(text: S.of(context).label_tab_free_charge_station),
                ],
              ),
              Expanded(
                  child:
                      TabBarView(controller: _tabController, children: const [
                PurchaseStarCandy(),
                FreeChargeStation(),
              ])),
            ],
          );
  }
}
