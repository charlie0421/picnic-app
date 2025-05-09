import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/area_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';

class VoteListPage extends ConsumerStatefulWidget {
  const VoteListPage({super.key});

  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends ConsumerState<VoteListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pageStorageBucket = PageStorageBucket();
  static const String _tabIndexKey = 'vote_list_tab_index';

  @override
  void initState() {
    super.initState();

    final savedIndex = PageStorage.of(context).readState(
          context,
          identifier: _tabIndexKey,
        ) as int? ??
        0;

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: savedIndex,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        PageStorage.of(context).writeState(
          context,
          _tabController.index,
          identifier: _tabIndexKey,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showBottomNavigation: true,
          pageTitle: t('page_title_vote_gather'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final area = ref.watch(areaProvider);
    return PageStorage(
      bucket: _pageStorageBucket,
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              tabs: [
                Tab(text: t('label_tabbar_vote_active')),
                Tab(text: t('label_tabbar_vote_end')),
                Tab(text: t('label_tabbar_vote_upcoming')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              key: ValueKey(area),
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                VoteList(VoteStatus.active, VoteCategory.all, area),
                VoteList(VoteStatus.end, VoteCategory.all, area),
                VoteList(VoteStatus.upcoming, VoteCategory.all, area),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
