import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/common_banner.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/dialogs/reward_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_list_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/reward_list_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:shimmer/shimmer.dart';

class VoteHomePage extends ConsumerStatefulWidget {
  const VoteHomePage({super.key});

  @override
  ConsumerState<VoteHomePage> createState() => _VoteHomePageState();
}

class _VoteHomePageState extends ConsumerState<VoteHomePage> {
  final PagingController<int, VoteModel> _pagingController =
      PagingController(firstPageKey: 1);
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: true, showBottomNavigation: true);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await ref.read(asyncVoteListProvider(
        pageKey,
        _pageSize,
        'vote.id',
        'DESC',
        status: VoteStatus.activeAndUpcoming,
        category: VoteCategory.all,
      ).future);

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (e, s) {
      _pagingController.error = e;
      logger.e('error', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(S.of(context).label_vote_vote_gather,
                style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
            SvgPicture.asset(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedListView<int, VoteModel>.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<VoteModel>(
            firstPageProgressIndicatorBuilder: (context) =>
                SizedBox(height: 400, child: buildLoadingOverlay()),
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
      ],
    );
  }

  Widget _buildRewardList(BuildContext context) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(left: 16.cw),
          alignment: Alignment.centerLeft,
          child: Text(S.of(context).label_vote_reward_list,
              style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
        ),
        const SizedBox(height: 16),
        asyncRewardListState.when(
          data: (data) => Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16.cw),
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final title = getLocaleTextFromJson(data[index].title!);
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
                            borderRadius: BorderRadius.circular(8).r,
                            child: PicnicCachedNetworkImage(
                              imageUrl: data[index].thumbnail ?? '',
                              width: 120,
                              height: 100,
                              useScreenUtil: false,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: 120,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: const Radius.circular(8).r,
                                  bottomRight: const Radius.circular(8).r,
                                ),
                                color: Colors.black.withOpacity(0.5),
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
                  margin: EdgeInsets.only(
                      left: 16.cw, right: index == 4 ? 16.cw : 0),
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
}
