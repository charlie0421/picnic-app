import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_artists.dart';
import 'package:picnic_app/components/vote/list/vote_image.dart';
import 'package:picnic_app/components/vote/list/vote_title.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_detail_page.dart';
import 'package:picnic_app/providers/banner_list_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/reward_list_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:shimmer/shimmer.dart';

class VoteHomePage extends ConsumerStatefulWidget {
  const VoteHomePage({super.key});

  @override
  ConsumerState<VoteHomePage> createState() => _VoteHomePageState();
}

class _VoteHomePageState extends ConsumerState<VoteHomePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      _buildVoteBanner(context),
      SizedBox(height: 44.h),
      _buildReward(context),
      SizedBox(height: 44.h),
      ref.watch(asyncVoteListProvider(category: 'all')).when(
            data: (pagingController) => Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: PagedListView<int, VoteModel>(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  pagingController: pagingController,
                  scrollDirection: Axis.vertical,
                  builderDelegate: PagedChildBuilderDelegate<VoteModel>(
                      firstPageErrorIndicatorBuilder: (context) {
                        return ErrorView(context,
                            error: pagingController.error.toString(),
                            retryFunction: () => pagingController.refresh(),
                            stackTrace: pagingController.error.stackTrace);
                      },
                      firstPageProgressIndicatorBuilder: (context) {
                        return buildLoadingOverlay();
                      },
                      noItemsFoundIndicatorBuilder: (context) {
                        return ErrorView(context,
                            error: 'No Items Found', stackTrace: null);
                      },
                      itemBuilder: (context, item, index) =>
                          _buildVote(context, ref, item)),
                )),
            loading: () => buildLoadingOverlay(),
            error: (error, stackTrace) => ErrorView(context,
                error: error.toString(), stackTrace: stackTrace),
          ),
    ]);
  }

  Widget _buildReward(BuildContext context) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);
    return Column(children: [
      Container(
        padding: const EdgeInsets.only(left: 16),
        alignment: Alignment.centerLeft,
        child: Text(Intl.message('label_vote_reward_list'),
            style: getTextStyle(AppTypo.TITLE18B, AppColors.Gray900)),
      ),
      SizedBox(height: 16.h),
      asyncRewardListState.when(
          data: (data) => Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                height: 100.h,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      String title = '';
                      if (Intl.getCurrentLocale() == 'ko')
                        title = data[index].title_ko;
                      else if (Intl.getCurrentLocale() == 'en')
                        title = data[index].title_en;
                      else if (Intl.getCurrentLocale() == 'ja')
                        title = data[index].title_ja;
                      else if (Intl.getCurrentLocale() == 'zh')
                        title = data[index].title_zh;

                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: CachedNetworkImage(
                                  imageUrl: '${data[index].thumbnail}' ?? '',
                                  width: 120.w,
                                  height: 100.h,
                                  placeholder: (context, url) =>
                                      buildPlaceholderImage(),
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 120.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8.r),
                                      bottomRight: Radius.circular(8.r)),
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Text(
                                  title,
                                  style: getTextStyle(
                                          AppTypo.BODY14R, Colors.white)
                                      .copyWith(
                                          overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
              ),
          loading: () => Container(
                width: double.infinity,
                height: 100.h,
                margin: const EdgeInsets.only(left: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (BuildContext context, int index) =>
                      Shimmer.fromColors(
                    baseColor: AppColors.Gray300,
                    highlightColor: AppColors.Gray100,
                    child: Container(
                      width: 120.w,
                      height: 120.h,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace)),
    ]);
  }

  SizedBox _buildVoteBanner(BuildContext context) {
    final asyncBannerListState =
        ref.watch(asyncBannerListProvider(location: 'vote_home'));

    return SizedBox(
      height: 230.h,
      child: asyncBannerListState.when(
        data: (data) => Swiper(
          itemBuilder: (BuildContext context, int index) {
            String title = '';
            if (Intl.getCurrentLocale() == 'ko')
              title = data[index].title_ko;
            else if (Intl.getCurrentLocale() == 'en')
              title = data[index].title_en;
            else if (Intl.getCurrentLocale() == 'ja')
              title = data[index].title_ja;
            else if (Intl.getCurrentLocale() == 'zh')
              title = data[index].title_zh;
            return Stack(
              children: [
                Container(
                  alignment: Alignment.center,
                  height: 200.h,
                  child: CachedNetworkImage(
                      imageUrl: '${data[index].thumbnail}' ?? '',
                      height: 200.h,
                      placeholder: (context, url) => buildPlaceholderImage(),
                      fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 30,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: Colors.black.withOpacity(0.5),
                    child: Text(
                      title,
                      style: getTextStyle(AppTypo.BODY14R, Colors.white)
                          .copyWith(overflow: TextOverflow.ellipsis),
                    ),
                  ),
                )
              ],
            );
          },
          itemCount: data.length,
          containerHeight: 230.h,
          itemHeight: 200.0.h,
          autoplay: true,
          pagination: const SwiperPagination(
              builder: DotSwiperPaginationBuilder(
                  size: 8,
                  color: AppColors.Gray200,
                  activeColor: AppColors.Gray500)),
          layout: SwiperLayout.DEFAULT,
        ),
        loading: () => buildLoadingOverlay(),
        error: (error, stackTrace) =>
            ErrorView(context, error: error.toString(), stackTrace: stackTrace),
      ),
    );
  }

  Widget _buildVote(BuildContext context, WidgetRef ref, VoteModel vote) {
    return GestureDetector(
      onTap: () {
        final navigationInfoNotifier =
            ref.read(navigationInfoProvider.notifier);
        navigationInfoNotifier.setCurrentPage(VoteDetailPage(voteId: vote.id));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16).r,
        child: Column(
          children: [
            VoteTitle(vote: vote),
            SizedBox(
              height: 10.h,
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.withOpacity(1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VoteImage(vote: vote),
                  VoteArtists(vote: vote),
                  // VoteContent(vote: vote),
                  // VoteBestComment(
                  //     vote: vote, showComments: _showComments),
                  // VoteCommentInfo(
                  //     vote: vote, showComments: _showComments)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
