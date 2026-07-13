import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteListPage extends ConsumerStatefulWidget {
  const VoteListPage({super.key});

  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends ConsumerState<VoteListPage>
    with RouteAwareStateMixin<VoteListPage> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _updateNavigation();
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
      key: ValueKey('vote_list_$_isAdmin'),
      isAdmin: _isAdmin,
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
            showMyPoint: false,
            showBottomNavigation: true,
            pageTitle: AppLocalizations.of(context).label_vote_screen_title,
          );
    });
  }
}

class _VoteTab {
  final String label;
  final String area;
  const _VoteTab(this.label, this.area);
}

const List<_VoteTab> _voteTabs = [
  _VoteTab('PICNIC', 'kpop'),
  _VoteTab('PIC CHART', 'pic-chart'),
  _VoteTab('MUSICAL', 'musical'),
  _VoteTab('SPOTLIGHT', 'spotlight'),
];

class VoteListContent extends ConsumerStatefulWidget {
  final bool isAdmin;

  const VoteListContent({super.key, required this.isAdmin});

  @override
  ConsumerState<VoteListContent> createState() => _VoteListContentState();
}

class _VoteListContentState extends ConsumerState<VoteListContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  VoteStatus _status = VoteStatus.active; // 기본 진행중, 미저장

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _voteTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 페이지 타이틀 (흰색 스트립 제거로 본문에서)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            AppLocalizations.of(context).label_vote_screen_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
        ),
        // 종류 탭 (가로 스크롤 + 스와이프)
        SizedBox(
          height: 48,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorWeight: 3,
            tabs: _voteTabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),
        // 상태 필터 드롭다운
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<VoteStatus>(
              value: _status,
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
              items: [
                DropdownMenuItem(
                  value: VoteStatus.active,
                  child:
                      Text(AppLocalizations.of(context).label_tabbar_vote_active),
                ),
                DropdownMenuItem(
                  value: VoteStatus.end,
                  child:
                      Text(AppLocalizations.of(context).label_tabbar_vote_end),
                ),
                DropdownMenuItem(
                  value: VoteStatus.upcoming,
                  child: Text(
                      AppLocalizations.of(context).label_tabbar_vote_upcoming),
                ),
                if (widget.isAdmin)
                  const DropdownMenuItem(
                    value: VoteStatus.debug,
                    child: Text('(Admin)'),
                  ),
              ],
            ),
          ),
        ),
        // 리스트 (종류별 스와이프)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _voteTabs
                .map((t) => VoteList(
                      _status,
                      VoteCategory.all,
                      t.area,
                      key: ValueKey('votelist_${t.area}_${_status.name}'),
                      portal: VotePortal.vote,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
