import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/custom_pagination.dart';
import 'package:picnic_app/components/common/reward_dialog.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_list_page.dart';
import 'package:picnic_app/providers/banner_list_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/reward_list_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoteHomePage extends ConsumerStatefulWidget {
  const VoteHomePage({super.key});

  @override
  ConsumerState<VoteHomePage> createState() => _VoteHomePageState();
}

class _VoteHomePageState extends ConsumerState<VoteHomePage> {
  final PagingController<int, VoteModel> _upcomingPagingController =
      PagingController(firstPageKey: 1);
  final PagingController<int, VoteModel> _activePagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _initPagingController(_upcomingPagingController, 'upcoming');
    _initPagingController(_activePagingController, 'active');
  }

  void _initPagingController(
      PagingController<int, VoteModel> controller, String type) {
    controller.addPageRequestListener((pageKey) {
      _fetch(pageKey, 10, 'id', "DESC").then((newItems) {
        final typeItems = newItems[type]!;
        final isLastPage =
            typeItems.meta.currentPage == typeItems.meta.totalPages;
        if (isLastPage) {
          controller.appendLastPage(typeItems.items);
        } else {
          final nextPageKey = typeItems.meta.currentPage + 1;
          controller.appendPage(typeItems.items, nextPageKey);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      _buildVoteHomeBanner(context),
      SizedBox(height: 36.h),
      _buildRewardList(context),
      SizedBox(height: 36.h),
      _buildVoteListTitle(),

      //TODO 구분을 enum 으로 변경
      _buildVoteSection(context, "Upcoming Votes", _upcomingPagingController),
      _buildVoteSection(context, "Active Votes", _activePagingController),
    ]);
  }

  Widget _buildVoteListTitle() {
    return GestureDetector(
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
              width: 8,
              height: 15,
              colorFilter:
                  const ColorFilter.mode(AppColors.Grey900, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteSection(BuildContext context, String title,
      PagingController<int, VoteModel> controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedListView<int, VoteModel>.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          pagingController: controller,
          builderDelegate: PagedChildBuilderDelegate<VoteModel>(
            itemBuilder: (context, item, index) => VoteInfoCard(
              context: context,
              vote: item,
              status: title == "Upcoming Votes"
                  ? VoteStatus.upcoming
                  : VoteStatus.active,
            ),
            firstPageErrorIndicatorBuilder: (context) {
              return ErrorView(context,
                  error: controller.error.toString(),
                  retryFunction: () => controller.refresh(),
                  stackTrace: controller.error.stackTrace);
            },
            firstPageProgressIndicatorBuilder: (context) {
              return buildLoadingOverlay();
            },
            noItemsFoundIndicatorBuilder: (context) {
              return ErrorView(context,
                  error: 'No Items Found', stackTrace: null);
            },
          ),
          separatorBuilder: (BuildContext context, int index) => Divider(
            height: 1.h,
            color: AppColors.Grey300,
          ),
        ),
        Divider(
          color: AppColors.Grey300,
          thickness: 1.h,
          height: 1.h,
        ),
      ],
    );
  }

  Future<Map<String, VoteListModel>> _fetch(
      int page, int limit, String sort, String order) async {
    final now = DateTime.now().toIso8601String();

    final upcomingResponse = await supabase
        .from('vote')
        .select('*, vote_item(*, artist(*, artist_group(*)))')
        .gt('start_at', now)
        .order('start_at', ascending: true)
        .range((page - 1) * limit, page * limit - 1)
        .limit(limit)
        .count();

    final activeResponse = await supabase
        .from('vote')
        .select('*, vote_item(*, artist(*, artist_group(*)))')
        .lte('start_at', now)
        .gt('stop_at', now)
        .order('stop_at', ascending: true)
        .range((page - 1) * limit, page * limit - 1)
        .limit(limit)
        .count();

    final upcomingMeta = _createMeta(upcomingResponse, page, limit);
    final activeMeta = _createMeta(activeResponse, page, limit);

    return {
      'upcoming': VoteListModel.fromJson(
          {'items': upcomingResponse.data, 'meta': upcomingMeta}),
      'active': VoteListModel.fromJson(
          {'items': activeResponse.data, 'meta': activeMeta}),
    };
  }

  Map<String, dynamic> _createMeta(
      PostgrestResponse response, int page, int limit) {
    return {
      'totalItems': response.count,
      'currentPage': page,
      'itemCount': response.data.length,
      'itemsPerPage': limit,
      'totalPages': response.count ~/ limit + 1,
    };
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
              height: 100,
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
                          borderRadius: BorderRadius.circular(8).r,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8).r,
                              child: PicnicCachedNetworkImage(
                                  imageUrl: data[index].thumbnail ?? '',
                                  width: 120,
                                  height: 100,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: const Radius.circular(8).r,
                                      bottomRight: const Radius.circular(8).r),
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
                height: 100.h,
                margin: const EdgeInsets.only(left: 16).r,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (BuildContext context, int index) =>
                      Shimmer.fromColors(
                    baseColor: AppColors.Grey300,
                    highlightColor: AppColors.Grey100,
                    child: Container(
                      height: 100.h,
                      margin: const EdgeInsets.only(right: 16).r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8).r,
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
    final width =
        kIsWeb ? webDesignSize.width : MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      height: width / 2,
      child: asyncBannerListState.when(
        data: (data) => Swiper(
          itemBuilder: (BuildContext context, int index) {
            String title = getLocaleTextFromJson(data[index].title);
            return Stack(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: width.w,
                  child: PicnicCachedNetworkImage(
                      imageUrl: data[index].thumbnail ?? '',
                      width: width.toInt(),
                      height: (width / 2).toInt(),
                      fit: BoxFit.fitWidth),
                ),
                if (title.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: width,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        title,
                        style: getTextStyle(AppTypo.BODY14R, Colors.white)
                            .copyWith(overflow: TextOverflow.ellipsis),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            );
          },
          itemCount: data.length,
          autoplay: data.length > 1,
          pagination: data.length > 1 ? CustomPaginationBuilder() : null,
        ),
        loading: () => buildLoadingOverlay(),
        error: (error, stackTrace) =>
            ErrorView(context, error: error.toString(), stackTrace: stackTrace),
      ),
    );
  }
}
