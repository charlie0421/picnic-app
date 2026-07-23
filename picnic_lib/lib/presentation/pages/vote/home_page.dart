import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/widgets/ui/app_save_loading_overlay.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';
import 'package:picnic_lib/presentation/widgets/vote/latest_media_section.dart';
import 'package:picnic_lib/presentation/widgets/vote/reward_list_section.dart';
import 'package:picnic_lib/ui/style.dart';

/// 홈 탭(index 0) 루트 페이지.
///
/// 배너 → "현재 진행중인 투표" 캐러셀 → 리워드 리스트 → 최신 미디어 순으로 조립한다.
/// 진행중 투표는 [asyncActiveFeaturedVotesProvider]로 여러 건을 가로 스크롤 노출한다.
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
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(
            showPortal: true,
            showTopMenu: false, // 흰색 스트립(별사탕/area/타이틀) 제거
            showBottomNavigation: true,
            pageTitle: '',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 저장/공유 시 공통 펄스 오버레이(앱 아이콘 스케일·페이드)를 홈 전체에
    // 씌운다. 카드가 LoadingOverlayWithIcon.of(context) 로 이 오버레이를 부른다.
    return AppSaveLoadingOverlay(
      child: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(asyncBannerListProvider(location: 'vote_home'));
          ref.invalidate(
            activePromotionCampaignProvider(PromotionSurface.home),
          );
          ref.invalidate(asyncRewardListProvider);
          ref.invalidate(asyncLatestMediaProvider);
          ref.invalidate(asyncActiveFeaturedVotesProvider);
          setState(() => _bannerKey = UniqueKey());
        },
        child: ListView(
          children: [
            CommonBanner('vote_home', 786 / 400, key: _bannerKey),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 16.w, bottom: 10),
              child: Text(
                AppLocalizations.of(context).label_home_current_vote,
                style: getTextStyle(AppTypo.title18B, AppColors.grey900),
              ),
            ),
            const HomeFeaturedVoteCarousel(),
            const SizedBox(height: 28),
            const RewardListSection(),
            const SizedBox(height: 28),
            const LatestMediaSection(),
            // 하단 플로팅 탭바에 마지막 섹션이 가리지 않도록 여백 확보
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}
