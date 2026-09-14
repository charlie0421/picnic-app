import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/app_save_loading_overlay.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_filter_chip.dart';

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

// 투표 종류 태그(칩). 'ALL'(전체)을 첫 번째로. area='all'은 필터 없이 전체.
const List<_VoteTab> _voteTabs = [
  _VoteTab('ALL', 'all'),
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

class _VoteListContentState extends ConsumerState<VoteListContent> {
  int _selectedTab = 0; // 기본 ALL(전체)
  VoteStatus _status = VoteStatus.active; // 기본 진행중, 미저장

  @override
  Widget build(BuildContext context) {
    final tab = _voteTabs[_selectedTab];

    // 저장/공유 시 공통 아이콘 펄스 오버레이. VoteInfoCard 가
    // LoadingOverlayWithIcon.of(context) 로 이 오버레이를 부른다.
    return AppSaveLoadingOverlay(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // 종류 태그(칩) — 가로 스크롤. 탭 UI 대신 태그 선택 방식.
          _buildTypeChips(context),
          // 상태 필터 드롭다운 (테마 pill)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8, 16.w, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildStatusDropdown(context),
            ),
          ),
          // 선택된 태그의 리스트
          Expanded(
            child: VoteList(
              _status,
              VoteCategory.all,
              tab.area,
              key: ValueKey('votelist_${tab.area}_${_status.name}'),
              portal: VotePortal.vote,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(16)),
      child: Row(
        children: [
          for (var i = 0; i < _voteTabs.length; i++) ...[
            if (i > 0) SizedBox(width: PicnicUi.horizontal(8)),
            PicnicFilterChip(
              label: _voteTabs[i].label,
              selected: _selectedTab == i,
              onSelected: () {
                if (_selectedTab != i) setState(() => _selectedTab = i);
              },
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, VoteStatus status) {
    final l = AppLocalizations.of(context);
    switch (status) {
      case VoteStatus.active:
        return l.label_tabbar_vote_active;
      case VoteStatus.end:
        return l.label_tabbar_vote_end;
      case VoteStatus.upcoming:
        return l.label_tabbar_vote_upcoming;
      case VoteStatus.debug:
        return '(Admin)';
      default:
        return '';
    }
  }

  /// 상태별 컬러 점 색상.
  Color _statusColor(VoteStatus status) {
    switch (status) {
      case VoteStatus.active:
        return AppColors.secondary500; // 진행중 = 민트
      case VoteStatus.end:
        return AppColors.grey400; // 종료됨 = 회색
      case VoteStatus.upcoming:
        return const Color(0xFFFFB020); // 예정됨 = 앰버
      case VoteStatus.debug:
        return AppColors.statusError; // (Admin) = 레드
      default:
        return AppColors.grey400;
    }
  }

  Widget _statusRow(
    BuildContext context,
    VoteStatus status, {
    bool selected = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _statusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            _statusLabel(context, status),
            style: PicnicUi.text(
              weight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    final statuses = <VoteStatus>[
      VoteStatus.active,
      VoteStatus.end,
      VoteStatus.upcoming,
      if (widget.isAdmin) VoteStatus.debug,
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(16)),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<VoteStatus>(
            value: _status,
            isDense: false,
            itemHeight: null,
            style: PicnicUi.text(),
            borderRadius: BorderRadius.circular(16),
            dropdownColor: AppColors.grey00,
            elevation: 4,
            icon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: PicnicUi.secondaryText,
              ),
            ),
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
            selectedItemBuilder: (context) => statuses
                .map(
                  (s) => Center(child: _statusRow(context, s, selected: true)),
                )
                .toList(),
            items: statuses
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: _statusRow(context, s, selected: s == _status),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
