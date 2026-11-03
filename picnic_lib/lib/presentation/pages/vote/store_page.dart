import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';

class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage>
    with
        SingleTickerProviderStateMixin<StorePage>,
        RouteAwareStateMixin<StorePage> {
  TabController? _tabController;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavigation();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
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
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final l10n = AppLocalizations.of(context);
            final labels = [
              l10n.label_tab_buy_star_candy,
              l10n.label_tab_free_charge_station,
            ];
            final style = PicnicUi.text(size: 16, weight: FontWeight.w600);
            var tabHeight = 48.0;
            for (final label in labels) {
              final painter = TextPainter(
                text: TextSpan(text: label, style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: math.max(1, constraints.maxWidth / 2 - 32));
              tabHeight = math.max(
                tabHeight,
                painter.height + PicnicUi.vertical(16),
              );
              painter.dispose();
            }
            return TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorColor: PicnicUi.actionColor,
              labelColor: PicnicUi.actionColor,
              unselectedLabelColor: PicnicUi.secondaryText,
              labelStyle: style,
              unselectedLabelStyle: style,
              tabs: [
                for (final label in labels)
                  Tab(
                    height: tabHeight,
                    child: Text(label, textAlign: TextAlign.center),
                  ),
              ],
            );
          },
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

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(
            showPortal: true,
            showTopMenu: false,
            showBottomNavigation: true,
          );
      _setPageTitleForIndex(_tabController?.index ?? 0);
    });
  }
}
