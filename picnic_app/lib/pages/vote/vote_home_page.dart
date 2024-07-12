import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/custom_pagination.dart';
import 'package:picnic_app/components/common/reward_dialog.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_list_page.dart';
import 'package:picnic_app/providers/banner_list_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/reward_list_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:shimmer/shimmer.dart';

class VoteHomePage extends ConsumerStatefulWidget {
  const VoteHomePage({super.key});

  @override
  ConsumerState<VoteHomePage> createState() => _VoteHomePageState();
}

class _VoteHomePageState extends ConsumerState<VoteHomePage> {
  final PagingController<int, VoteModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetch(pageKey, 10, 'id', "DESC").then((newItems) {
        final isLastPage =
            newItems.meta.currentPage == newItems.meta.totalPages;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems.items);
        } else {
          final nextPageKey = newItems.meta.currentPage + 1;
          _pagingController.appendPage(newItems.items, nextPageKey);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      _buildVoteHomeBanner(context),
      SizedBox(height: 48.w),
      _buildRewardList(context),
      SizedBox(height: 48.w),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref
              .read(navigationInfoProvider.notifier)
              .setCurrentPage(const VoteListPage(), showTopMenu: false);
        },
        child: Container(
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(S.of(context).label_vote_vote_gather,
                  style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900)),
              SvgPicture.asset(
                'assets/icons/arrow_right_style=line.svg',
                width: 8.w,
                height: 15.w,
                colorFilter:
                    const ColorFilter.mode(AppColors.Grey900, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 24.w),
      PagedListView<int, VoteModel>(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        pagingController: _pagingController,
        scrollDirection: Axis.vertical,
        builderDelegate: PagedChildBuilderDelegate<VoteModel>(
            firstPageErrorIndicatorBuilder: (context) {
              return ErrorView(context,
                  error: _pagingController.error.toString(),
                  retryFunction: () => _pagingController.refresh(),
                  stackTrace: _pagingController.error.stackTrace);
            },
            firstPageProgressIndicatorBuilder: (context) {
              return buildLoadingOverlay();
            },
            noItemsFoundIndicatorBuilder: (context) {
              return ErrorView(context,
                  error: 'No Items Found', stackTrace: null);
            },
            itemBuilder: (context, item, index) =>
                VoteInfoCard(context: context, vote: item)),
      ),
    ]);
  }

  _fetch(int page, int limit, String sort, String order) async {
    final response = await supabase
        .from('vote')
        .select('*, vote_item(*, mystar_member(*, mystar_group(*)))')
        .lt('start_at', 'now()')
        .gt('stop_at', 'now()')
        .order('id', ascending: false)
        .order('vote_total', ascending: false, referencedTable: 'vote_item')
        .range((page - 1) * limit, page * limit - 1)
        .limit(limit)
        .count();

    final meta = {
      'totalItems': response.count,
      'currentPage': page,
      'itemCount': response.data.length,
      'itemsPerPage': limit,
      'totalPages': response.count ~/ limit + 1,
    };

    return VoteListModel.fromJson({'items': response.data, 'meta': meta});
  }

  Widget _buildRewardList(BuildContext context) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);
    return Column(children: [
      Container(
        padding: const EdgeInsets.only(left: 16),
        alignment: Alignment.centerLeft,
        child: Text(S.of(context).label_vote_reward_list,
            style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900)),
      ),
      SizedBox(height: 16.w),
      asyncRewardListState.when(
          data: (data) {
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              height: 100.w,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length,
                  itemBuilder: (BuildContext context, int index) {
                    String title = data[index].getTitle();

                    return GestureDetector(
                      onTap: () {
                        showRewardDialog(context, data[index]);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: PicnicCachedNetworkImage(
                                  imageUrl: data[index].thumbnail ?? '',
                                  width: 120,
                                  height: 100,
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
                      ),
                    );
                  }),
            );
          },
          loading: () => Container(
                width: double.infinity,
                height: 100.w,
                margin: const EdgeInsets.only(left: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (BuildContext context, int index) =>
                      Shimmer.fromColors(
                    baseColor: AppColors.Grey300,
                    highlightColor: AppColors.Grey100,
                    child: Container(
                      width: 120.w,
                      height: 120.w,
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

  SizedBox _buildVoteHomeBanner(BuildContext context) {
    final asyncBannerListState =
        ref.watch(asyncBannerListProvider(location: 'vote_home'));
    final width = MediaQuery.of(context).size.width;
    final height = width * 0.5;

    return SizedBox(
      width: width,
      height: height + 25.h,
      child: asyncBannerListState.when(
        data: (data) => Swiper(
          itemBuilder: (BuildContext context, int index) {
            String title = data[index].title[Intl.getCurrentLocale()];
            return Stack(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: width,
                  height: height,
                  child: PicnicCachedNetworkImage(
                      imageUrl: data[index].thumbnail ?? '',
                      width: width.toInt(),
                      height: height.toInt(),
                      fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 25.h,
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
          containerHeight: height,
          itemHeight: height,
          autoplay: true,
          pagination: CustomPaginationBuilder(),
        ),
        loading: () => buildLoadingOverlay(),
        error: (error, stackTrace) =>
            ErrorView(context, error: error.toString(), stackTrace: stackTrace),
      ),
    );
  }
}
