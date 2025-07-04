// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

class VoteHomePage extends ConsumerStatefulWidget {
  const VoteHomePage({super.key});

  @override
  ConsumerState<VoteHomePage> createState() => _VoteHomePageState();
}

class _VoteHomePageState extends ConsumerState<VoteHomePage> {
  late final PagingController<int, VoteModel> _pagingController =
      PagingController<int, VoteModel>(
    getNextPageKey: (state) {
      if (state.items == null) return 1;
      final isLastPage = state.items!.length < _pageSize;
      if (isLastPage) return null;
      return (state.keys?.last ?? 0) + 1;
    },
    fetchPage: _fetch,
  );
  static const _pageSize = 20;

  Object? _lastArea = Object();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: true, showBottomNavigation: true);

      // 이미지 캐시 최적화를 먼저 수행
      _optimizeImageCacheForPage();

      // 그 다음 페이징 컨트롤러 초기화
      _pagingController.fetchNextPage();
    });
  }

  /// 페이지별 이미지 캐시 최적화
  void _optimizeImageCacheForPage() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final currentUsage =
          imageCache.currentSizeBytes / imageCache.maximumSizeBytes;

      // 캐시 사용률이 70% 이상이면 부분 정리
      if (currentUsage > 0.7) {
        final targetSize = (imageCache.maximumSizeBytes * 0.5).round();
        final originalMaxSize = imageCache.maximumSizeBytes;
        imageCache.maximumSizeBytes = targetSize;

        // 원래 크기로 복구
        Future.delayed(Duration(milliseconds: 100), () {
          imageCache.maximumSizeBytes = originalMaxSize;
        });

        logger.d('투표 홈페이지 진입 시 이미지 캐시 최적화 수행');
      }
    } catch (e) {
      logger.e('이미지 캐시 최적화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(appSettingProvider);
    final area = setting.area;

    if (_lastArea != area) {
      _lastArea = area;
      _pagingController.refresh();
    }

    return ListView(
      children: [
        const CommonBanner('vote_home', 786 / 400),
        const SizedBox(height: 36),
        _buildRewardList(context),
        const SizedBox(height: 36),
        _buildVoteListTitle(),
        _buildVoteSection(),
      ],
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Widget _buildVoteListTitle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref
          .read(navigationInfoProvider.notifier)
          .setCurrentPage(const VoteListPage(), showTopMenu: false),
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(t('label_vote_vote_gather'),
                style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/arrow_right_style=line.svg',
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(AppColors.grey900, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteSection() {
    return PagingListener(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) =>
          PagedListView<int, VoteModel>.separated(
        state: _pagingController.value,
        fetchNextPage: _pagingController.fetchNextPage,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        builderDelegate: PagedChildBuilderDelegate<VoteModel>(
          firstPageProgressIndicatorBuilder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  VoteCardSkeleton(status: VoteCardStatus.ongoing),
                  VoteCardSkeleton(status: VoteCardStatus.ongoing),
                  VoteCardSkeleton(status: VoteCardStatus.ongoing),
                ],
              ),
            ),
          ),
          newPageProgressIndicatorBuilder: (context) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: VoteCardSkeleton(status: VoteCardStatus.ongoing),
          ),
          firstPageErrorIndicatorBuilder: (context) => buildErrorView(
            context,
            error: _pagingController.error,
            retryFunction: () => _pagingController.refresh(),
            stackTrace: null,
          ),
          newPageErrorIndicatorBuilder: (context) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: VoteCardSkeleton(status: VoteCardStatus.ongoing),
          ),
          noMoreItemsIndicatorBuilder: (context) => const SizedBox.shrink(),
          noItemsFoundIndicatorBuilder: (context) =>
              VoteNoItem(status: VoteStatus.active, context: context),
          itemBuilder: (context, vote, index) {
            final now = DateTime.now().toUtc();
            final status = vote.startAt!.isAfter(now)
                ? VoteStatus.upcoming
                : VoteStatus.active;
            return VoteInfoCard(context: context, vote: vote, status: status);
          },
        ),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.grey300),
      ),
    );
  }

  Widget _buildRewardList(BuildContext context) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(left: 16.w),
          alignment: Alignment.centerLeft,
          child: Text(t('label_vote_reward_list', null),
              style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
        ),
        const SizedBox(height: 16),
        asyncRewardListState.when(
          data: (data) => Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16.w),
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              cacheExtent: 400.0,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
              itemBuilder: (context, index) {
                final title = getLocaleTextFromJson(data[index].title!);
                final isHighPriority = index < 3;

                return GestureDetector(
                  onTap: () => showRewardDialog(context, data[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(8).r),
                    child: SizedBox(
                      width: 120,
                      height: 100,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PicnicCachedNetworkImage(
                              key: ValueKey('reward_${data[index].id}'),
                              imageUrl: data[index].thumbnail ?? '',
                              width: 120,
                              height: 100,
                              fit: BoxFit.fitWidth,
                              priority: isHighPriority
                                  ? ImagePriority.high
                                  : ImagePriority.normal,
                              enableMemoryOptimization: true,
                              enableProgressiveLoading: !isHighPriority,
                              memCacheWidth: 120,
                              memCacheHeight: 100,
                              lazyLoadingStrategy: isHighPriority
                                  ? LazyLoadingStrategy.none
                                  : LazyLoadingStrategy.viewport,
                              timeout: const Duration(seconds: 10),
                              maxRetries: 2,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: 120,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: const Radius.circular(8),
                                  bottomRight: const Radius.circular(8),
                                ),
                                color: AppColors.grey900.withValues(alpha: 0.7),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: Text(
                                title,
                                style: getTextStyle(
                                        AppTypo.body14R, Colors.white)
                                    .copyWith(overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          loading: () => Shimmer.fromColors(
            baseColor: AppColors.grey300,
            highlightColor: AppColors.grey100,
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) => Container(
                  width: 120,
                  height: 100,
                  margin:
                      EdgeInsets.only(left: 16.w, right: index == 4 ? 16.w : 0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: Colors.white),
                ),
              ),
            ),
          ),
          error: (error, stackTrace) => buildErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        ),
      ],
    );
  }

  Future<List<VoteModel>> _fetch(int pageKey) async {
    final setting = ref.watch(appSettingProvider);
    final area = setting.area;
    try {
      final newItems = await ref.watch(asyncVoteListProvider(
        pageKey,
        _pageSize,
        'stop_at',
        'DESC',
        area,
        status: VoteStatus.activeAndUpcoming,
        category: VoteCategory.all,
      ).future);

      logger.d('newItems: $newItems');

      return newItems;
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    }
  }
}
