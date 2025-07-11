import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/area_selector.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

class VotePicListPage extends ConsumerStatefulWidget {
  const VotePicListPage({super.key});

  @override
  ConsumerState<VotePicListPage> createState() => _VotePicListPageState();
}

class _VotePicListPageState extends ConsumerState<VotePicListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pageStorageBucket = PageStorageBucket();
  static const String _tabIndexKey = 'vote_pic_list_tab_index';

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

    // Navigation 설정은 부모 페이지(PicChartPage)에서 처리
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(appSettingProvider);
    final area = setting.area;
    return PageStorage(
      bucket: _pageStorageBucket,
      child: Column(
        children: [
          // Area 선택기를 본문 상단에 추가
          Container(
            height: 34,
            width: double.infinity,
            padding: EdgeInsets.only(right: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const AreaSelector(),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              tabs: [
                Tab(
                    text:
                        AppLocalizations.of(context).label_tabbar_vote_active),
                Tab(text: AppLocalizations.of(context).label_tabbar_vote_end),
                Tab(
                    text: AppLocalizations.of(context)
                        .label_tabbar_vote_upcoming),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              key: ValueKey(area),
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 모든 탭에서 image 카테고리만 표시
                VoteList(VoteStatus.active, VoteCategory.image, area),
                VoteList(VoteStatus.end, VoteCategory.image, area),
                VoteList(VoteStatus.upcoming, VoteCategory.image, area),
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
