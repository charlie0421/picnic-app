import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/common_banner.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/common/reward_dialog.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_list_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/reward_list_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
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
      _fetch(pageKey, 10).then((newItems) {
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
      CommonBanner('vote_home', 200),
      const SizedBox(height: 36),
      _buildRewardList(context),
      const SizedBox(height: 36),
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
        padding: EdgeInsets.only(left: 16.w),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(S.of(context).label_vote_vote_gather,
                style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900)),
            SvgPicture.asset(
              'assets/icons/arrow_right_style=line.svg',
              width: 24,
              height: 24,
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
            firstPageProgressIndicatorBuilder: (context) => Shimmer.fromColors(
              baseColor: AppColors.Grey300,
              highlightColor: AppColors.Grey100,
              child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 5,
                  itemBuilder: (context, index) => Container(
                        height: 100,
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 200.w,
                              height: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100.w,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(
                        height: 1,
                        color: AppColors.Grey300,
                      )),
            ),
            noItemsFoundIndicatorBuilder: (context) {
              return Container();
            },
          ),
          separatorBuilder: (BuildContext context, int index) => const Divider(
            height: 1,
            color: AppColors.Grey300,
          ),
        ),
      ],
    );
  }

  Future<Map<String, VoteListModel>> _fetch(int page, int limit) async {
    final now = DateTime.now().toUtc();

    final upcomingResponse = await supabase
        .from('vote')
        .select('*, vote_item(*, artist(*, artist_group(*)))')
        .gt('start_at', now)
        .order('start_at', ascending: true)
        .order('order', ascending: true)
        .range((page - 1) * limit, page * limit - 1)
        .limit(limit)
        .count();

    final activeResponse = await supabase
        .from('vote')
        .select('*, vote_item(*, artist(*, artist_group(*)))')
        .lte('start_at', now)
        .gt('stop_at', now)
        .order('stop_at', ascending: true)
        .order('order', ascending: true)
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
        padding: EdgeInsets.only(left: 16.w),
        alignment: Alignment.centerLeft,
        child: Text(S.of(context).label_vote_reward_list,
            style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900)),
      ),
      const SizedBox(height: 16),
      asyncRewardListState.when(
          data: (data) {
            return Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 16.w),
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
                        margin: EdgeInsets.only(right: 16.w),
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
                                  useScreenUtil: true,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 120.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: const Radius.circular(8).r,
                                      bottomRight: const Radius.circular(8).r),
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8.w),
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
          loading: () => Shimmer.fromColors(
                baseColor: AppColors.Grey300,
                highlightColor: AppColors.Grey100,
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (BuildContext context, int index) => Container(
                      width: 120.w,
                      height: 100,
                      margin: EdgeInsets.only(
                          left: 16.w, right: index == 4 ? 16.w : 0),
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
}
