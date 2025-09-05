// ignore_for_file: unused_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy_web.dart';

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
          .settingNavigation(
            showPortal: true,
            showTopMenu: false,
            showBottomNavigation: true,
          );
      _setPageTitleForIndex(_tabController?.index ?? 0);
    });

    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        _setPageTitleForIndex(_tabController!.index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabBar();
  }

  void _setPageTitleForIndex(int index) {
    final notifier = ref.read(navigationInfoProvider.notifier);
    final loc = AppLocalizations.of(context);
    final title = index == 0
        ? loc.label_tab_buy_star_candy
        : loc.label_tab_free_charge_station;
    notifier.setPageTitle(pageTitle: title);
  }

  Widget _buildTabBar() {
    return kIsWeb
        ? const PurchaseStarCandyWeb()
        : Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    text: AppLocalizations.of(context).label_tab_buy_star_candy,
                  ),
                  if (!kIsWeb)
                    Tab(
                      text: AppLocalizations.of(
                        context,
                      ).label_tab_free_charge_station,
                    ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [PurchaseStarCandy(), FreeChargeStation()],
                ),
              ),
            ],
          );
  }
}
