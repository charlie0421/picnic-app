import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';
import 'package:picnic_lib/presentation/providers/home_view_state_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
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
  late final ScrollController _scrollController;
  bool _restoreScheduled = false;
  bool _restoreFinished = false;
  bool _userScrolledBeforeRestore = false;
  bool _waitingForLargerExtent = false;
  bool _suppressOffsetSaves = false;
  int _restoreSuppressionGeneration = 0;
  double? _restoreTarget;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_saveScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavigation());
  }

  void _saveScrollOffset() {
    if (!_restoreFinished ||
        _waitingForLargerExtent ||
        _suppressOffsetSaves ||
        !_scrollController.hasClients) {
      return;
    }
    ref
        .read(homeViewStateProvider.notifier)
        .saveScrollOffset(_scrollController.offset);
  }

  void _scheduleScrollRestore() {
    if (_restoreScheduled || _restoreFinished || _userScrolledBeforeRestore) {
      return;
    }
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScheduled = false;
      if (!mounted || _restoreFinished || _userScrolledBeforeRestore) return;
      if (!_scrollController.hasClients) {
        _scheduleScrollRestore();
        WidgetsBinding.instance.ensureVisualUpdate();
        return;
      }
      final saved = _restoreTarget ??= ref
          .read(homeViewStateProvider)
          .scrollOffset;
      final max = _scrollController.position.maxScrollExtent;
      if (max >= saved) {
        _jumpToRestoreOffset(saved);
        _restoreFinished = true;
        return;
      }
      // Resolve a genuinely shorter mount immediately, while retaining the
      // original target in provider state. Later metric changes finish the
      // restore without relying on self-requeued post-frame callbacks.
      _waitingForLargerExtent = saved > max;
      _jumpToRestoreOffset(saved.clamp(0, max));
      _restoreFinished = true;
    });
  }

  void _jumpToRestoreOffset(double offset) {
    final suppression = ++_restoreSuppressionGeneration;
    _suppressOffsetSaves = true;
    _scrollController.jumpTo(offset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || suppression != _restoreSuppressionGeneration) return;
      _suppressOffsetSaves = false;
    });
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    if (!_waitingForLargerExtent ||
        _userScrolledBeforeRestore ||
        !_scrollController.hasClients) {
      return false;
    }
    final target = _restoreTarget;
    if (target == null) return false;
    final max = notification.metrics.maxScrollExtent;
    if (max <= _scrollController.offset) return false;
    _jumpToRestoreOffset(target.clamp(0, max));
    if (max >= target) _waitingForLargerExtent = false;
    return false;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_saveScrollOffset)
      ..dispose();
    super.dispose();
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
    final featured = ref.watch(asyncActiveFeaturedVotesProvider);
    final latest = ref.watch(asyncLatestMediaProvider);
    final rewards = ref.watch(asyncRewardListProvider);
    if (!featured.isLoading && !latest.isLoading && !rewards.isLoading) {
      _scheduleScrollRestore();
    }
    // 저장/공유 시 공통 펄스 오버레이(앱 아이콘 스케일·페이드)를 홈 전체에
    // 씌운다. 카드가 LoadingOverlayWithIcon.of(context) 로 이 오버레이를 부른다.
    return AppSaveLoadingOverlay(
      child: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(asyncBannerListProvider(location: 'vote_home'));
          // Invalidate both HOME source providers the resolver may read
          // from, not just the resolver itself — otherwise the resolver
          // would recompute against stale cached V1/V2 data instead of
          // triggering a fresh RPC call.
          ref.invalidate(
            activePromotionCampaignV2Provider(PromotionSurfaceV2.home),
          );
          ref.invalidate(
            activePromotionCampaignProvider(PromotionSurface.home),
          );
          ref.invalidate(
            homePromotionCampaignProvider(
              Localizations.localeOf(context).languageCode,
            ),
          );
          ref.invalidate(asyncRewardListProvider);
          ref.invalidate(asyncLatestMediaProvider);
          ref.invalidate(asyncActiveFeaturedVotesProvider);
          setState(() => _bannerKey = UniqueKey());
        },
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _handleScrollMetrics,
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (!_suppressOffsetSaves &&
                  (!_restoreFinished || _waitingForLargerExtent) &&
                  notification.direction != ScrollDirection.idle) {
                _userScrolledBeforeRestore = true;
                _waitingForLargerExtent = false;
                _restoreFinished = true;
              }
              return false;
            },
            child: ListView(
              controller: _scrollController,
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
        ),
      ),
    );
  }
}
