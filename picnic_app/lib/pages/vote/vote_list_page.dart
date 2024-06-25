import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/vote/list/vote_list.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';

class VoteListPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_gather';

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
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TabBar(controller: _tabController, tabs: [
            Tab(text: S.of(context).label_tabbar_vote_active),
            Tab(text: S.of(context).label_tabbar_vote_end),
          ]),
        ),
        SizedBox(
          height: 36.w,
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: const [
          VoteList(VoteStatus.active, VoteCategory.all),
          VoteList(VoteStatus.end, VoteCategory.all),
        ]))
      ],
    );
  }
}
