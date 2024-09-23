import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/vote/list/vote_list.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';

class VoteListPage extends ConsumerStatefulWidget {
  const VoteListPage({super.key});

  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends ConsumerState<VoteListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showBottomNavigation: true,
          pageTitle: S.of(context).page_title_vote_gather);
    });

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TabBar(controller: _tabController, indicatorWeight: 3, tabs: [
            Tab(text: S.of(context).label_tabbar_vote_active),
            Tab(text: S.of(context).label_tabbar_vote_end),
            Tab(text: S.of(context).label_tabbar_vote_upcoming),
          ]),
        ),
        Expanded(
            child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
              VoteList(VoteStatus.active, VoteCategory.all),
              VoteList(VoteStatus.end, VoteCategory.all),
              VoteList(VoteStatus.upcoming, VoteCategory.all),
            ]))
      ],
    );
  }
}
