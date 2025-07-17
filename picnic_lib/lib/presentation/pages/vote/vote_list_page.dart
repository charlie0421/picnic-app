import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/area_selector.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

class VoteListPage extends ConsumerStatefulWidget {
  const VoteListPage({super.key});

  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends ConsumerState<VoteListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const String _tabIndexKey = 'vote_list_tab_index';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeTabController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showMyPoint: false,
          showBottomNavigation: true,
          pageTitle: AppLocalizations.of(context).label_vote_screen_title);
    });
  }

  void _initializeTabController() {
    final savedIndex = PageStorage.of(context).readState(
          context,
          identifier: _tabIndexKey,
        ) as int? ??
        0;

    final tabLength = _isAdmin ? 4 : 3;
    _tabController = TabController(
      length: tabLength,
      vsync: this,
      initialIndex: savedIndex < tabLength ? savedIndex : 0,
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
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(appSettingProvider);
    final area = setting.area;

    // 사용자 정보를 확인하여 관리자인지 체크
    final userInfo = ref.watch(userInfoProvider);
    userInfo.whenData((user) {
      final newIsAdmin = user?.isAdmin == true;
      if (newIsAdmin != _isAdmin) {
        // 관리자 상태가 변경되면 페이지를 다시 빌드하기 위해 Key 변경
        _isAdmin = newIsAdmin;
      }
    });

    // 관리자 상태에 따라 고유한 Key 생성하여 위젯 재생성
    return VoteListContent(
      key: ValueKey('vote_list_${area}_$_isAdmin'),
      isAdmin: _isAdmin,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class VoteListContent extends ConsumerStatefulWidget {
  final bool isAdmin;

  const VoteListContent({
    super.key,
    required this.isAdmin,
  });

  @override
  ConsumerState<VoteListContent> createState() => _VoteListContentState();
}

class _VoteListContentState extends ConsumerState<VoteListContent>
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

    final tabLength = widget.isAdmin ? 4 : 3;
    _tabController = TabController(
      length: tabLength,
      vsync: this,
      initialIndex: savedIndex < tabLength ? savedIndex : 0,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        logger.d('🔄 탭 변경됨: ${_tabController.index} (관리자: ${widget.isAdmin})');
        if (widget.isAdmin && _tabController.index == 3) {
          logger.d('🚨🚨🚨 디버그 탭(3번)으로 변경됨!');
        }
        PageStorage.of(context).writeState(
          context,
          _tabController.index,
          identifier: _tabIndexKey,
        );
      }
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
                if (widget.isAdmin) const Tab(text: '(Admin)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTabContent(VoteStatus.active, area, 0),
                _buildTabContent(VoteStatus.end, area, 1),
                _buildTabContent(VoteStatus.upcoming, area, 2),
                if (widget.isAdmin) _buildTabContent(VoteStatus.debug, area, 3),
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
        // 디버그 탭은 항상 빌드되도록 예외 처리
        final currentIndex = _tabController.index;
        final shouldBuild =
            (currentIndex - tabIndex).abs() <= 1 || status == VoteStatus.debug;

        // 디버그 탭 선택 시 로그 추가
        if (status == VoteStatus.debug && currentIndex == tabIndex) {
          logger.d(
              '🚨🚨🚨 디버그 탭 선택됨! currentIndex: $currentIndex, tabIndex: $tabIndex');
        }

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
