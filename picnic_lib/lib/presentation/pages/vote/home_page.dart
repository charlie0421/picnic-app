import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/latest_media_section.dart';
import 'package:picnic_lib/presentation/widgets/vote/reward_list_section.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';

/// 홈 탭(index 0) 루트 페이지.
///
/// 배너 → "현재 진행중인 투표" 대표 카드 → 리워드 리스트 → 최신 미디어 순으로
/// 조립한다. 대표 투표는 `asyncVoteListProvider`의 active 브랜치(`stop_at ASC`
/// 정렬)를 재사용해 곧 종료되는 투표 1건을 노출한다(신규 provider 없음).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with RouteAwareStateMixin<HomePage> {
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavigation());
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

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: false, // 흰색 스트립(별사탕/area/타이틀) 제거
            showBottomNavigation: true,
            pageTitle: '',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final featured = ref.watch(
      asyncVoteListProvider(
        1,
        1,
        'id',
        'DESC',
        'all',
        status: VoteStatus.active,
        category: VoteCategory.all,
      ),
    );

    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: Colors.white,
      onRefresh: () async {
        ref.invalidate(asyncBannerListProvider(location: 'vote_home'));
        ref.invalidate(asyncRewardListProvider);
        ref.invalidate(asyncLatestMediaProvider);
        ref.invalidate(
          asyncVoteListProvider(
            1,
            1,
            'id',
            'DESC',
            'all',
            status: VoteStatus.active,
            category: VoteCategory.all,
          ),
        );
        setState(() => _bannerKey = UniqueKey());
      },
      child: ListView(
        children: [
          CommonBanner('vote_home', 786 / 400, key: _bannerKey),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.only(left: 16.w, bottom: 8),
            child: Text(
              AppLocalizations.of(context).label_home_current_vote,
              style: getTextStyle(AppTypo.title18B, AppColors.grey900),
            ),
          ),
          featured.when(
            loading: () =>
                const VoteCardSkeleton(status: VoteCardStatus.ongoing),
            error: (e, s) => const SizedBox.shrink(),
            data: (votes) => votes.isEmpty
                ? const SizedBox.shrink()
                : HomeFeaturedVoteCard(vote: votes.first),
          ),
          const SizedBox(height: 36),
          const RewardListSection(),
          const SizedBox(height: 36),
          const LatestMediaSection(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
