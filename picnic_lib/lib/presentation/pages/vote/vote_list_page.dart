import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/area_selector.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

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
          showMyPoint: false,
          showBottomNavigation: true,
          pageTitle: AppLocalizations.of(context).page_title_vote_list);
    });
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
                _buildTabContent(VoteStatus.active, area, 0),
                _buildTabContent(VoteStatus.end, area, 1),
                _buildTabContent(VoteStatus.upcoming, area, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 탭별 컨텐츠를 lazy loading으로 빌드
  Widget _buildTabContent(VoteStatus status, String area, int tabIndex) {
    // 현재 선택된 탭만 로딩
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        // 현재 탭이거나 인접한 탭만 빌드 (성능 최적화)
        final currentIndex = _tabController.index;
        final shouldBuild = (currentIndex - tabIndex).abs() <= 1;

        if (!shouldBuild) {
          return const SizedBox.shrink();
        }

        return VoteList(status, VoteCategory.all, area);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
