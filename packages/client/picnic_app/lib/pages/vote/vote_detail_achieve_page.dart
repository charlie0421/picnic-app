import 'dart:async';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/components/vote/voting/voting_dialog.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/reward_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/number.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class VoteDetailAchievePage extends ConsumerStatefulWidget {
  final int voteId;

  const VoteDetailAchievePage({super.key, required this.voteId});

  @override
  ConsumerState<VoteDetailAchievePage> createState() =>
      _VoteDetailAchievePageState();
}

class _VoteDetailAchievePageState extends ConsumerState<VoteDetailAchievePage> {
  late ScrollController _scrollController;
  late TextEditingController _textEditingController;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textEditingController = TextEditingController();
    _setupUpdateTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showBottomNavigation: false,
          pageTitle: S.of(context).page_title_vote_detail);
    });
  }

  void _setupUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        ref.refresh(asyncVoteItemListProvider(voteId: widget.voteId));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textEditingController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
        data: (data) {
          if (data.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              _buildVoteInfo(), // 고정될 상단 부분
              _buildAchieveItem(data[0]!),
              Expanded(
                child: SingleChildScrollView(
                  // 스크롤될 하단 부분
                  controller: _scrollController,
                  child: Column(
                    children: [_buildLevelItem(data[0]!)],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _buildLoadingShimmer(),
        error: (error, stackTrace) => ErrorView(context,
            error: error.toString(), stackTrace: stackTrace));
  }

  Widget _buildVoteInfo() {
    final width = MediaQuery.of(context).size.width;
    return ref.watch(asyncVoteDetailProvider(voteId: widget.voteId)).when(
        data: (voteModel) {
          if (voteModel == null) return const SizedBox.shrink();

          return Column(
            children: [
              if (voteModel.mainImage != null &&
                  voteModel.mainImage!.isNotEmpty)
                SizedBox(
                  width: width,
                  child: PicnicCachedNetworkImage(
                    imageUrl: voteModel.mainImage!,
                    width: width.toInt(),
                    memCacheWidth: width.toInt(),
                  ),
                ),
              const SizedBox(height: 36),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 57.w),
                child: VoteCommonTitle(
                    title: getLocaleTextFromJson(voteModel.title)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 18,
                child: Text(
                  '${DateFormat('yyyy.MM.dd HH:mm').format(voteModel.startAt!.toLocal())} ~ '
                  '${DateFormat('yyyy.MM.dd HH:mm').format(voteModel.stopAt!.toLocal())} '
                  '(${getShortTimeZoneIdentifier()})',
                  style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
                ),
              ),
              const SizedBox(height: 36),
            ],
          );
        },
        loading: () => _buildLoadingShimmer(),
        error: (error, stackTrace) => ErrorView(context,
            error: error.toString(), stackTrace: stackTrace));
  }

  Widget _buildAchieveItem(VoteItemModel data) {
    return _buildVoteItem(context, data, 0);
  }

  Widget _buildLevelItem(VoteItemModel data) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary500, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
                future: fetchVoteAchieve(ref, voteId: widget.voteId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  var rewardIndex = 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        21,
                        (index) {
                          final isAchieved = data.voteTotal! >= 250000 * index;
                          return Row(
                            children: [
                              if (250000 * index % 1000000 == 0 && index != 0)
                                _buildRewardInfo(
                                    snapshot.data, rewardIndex++, isAchieved),
                              SizedBox(width: 10.w),
                              Container(
                                width: 80,
                                height: 50,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  formatNumberWithComma(
                                      (250000 * index).toString()),
                                  style: getTextStyle(
                                      250000 * index % 1000000 == 0
                                          ? AppTypo.caption12B
                                          : AppTypo.caption12R,
                                      isAchieved
                                          ? AppColors.primary500
                                          : AppColors.grey400),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Container(
                                width: 20.w,
                                height: 2,
                                color: isAchieved
                                    ? AppColors.primary500
                                    : AppColors.grey400,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
            SizedBox(width: 8.w),
            Container(
              width: 20,
              height: 50 * 21 + 20,
              padding: const EdgeInsets.symmetric(vertical: 25),
              alignment: Alignment.topCenter,
              child: FAProgressBar(
                currentValue: data.voteTotal!.toDouble(),
                maxValue: 5000000,
                animatedDuration: const Duration(milliseconds: 200),
                direction: Axis.vertical,
                borderRadius: BorderRadius.circular(10),
                verticalDirection: VerticalDirection.down,
                backgroundColor: AppColors.grey300,
                progressColor: AppColors.primary500,
                progressGradient: commonGradientVertical,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteItem(BuildContext context, VoteItemModel item, int index) {
    return AnimatedContainer(
      padding: EdgeInsets.symmetric(horizontal: 34.w),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleVoteItemTap(context, item),
        child: SizedBox(
          child: Row(
            children: [
              SizedBox(width: 8.w),
              _buildArtistImage(item),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                            children: item.artist.id != 0
                                ? [
                                    TextSpan(
                                      text: getLocaleTextFromJson(
                                          item.artist.name),
                                      style: getTextStyle(
                                          AppTypo.body14B, AppColors.grey900),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: getLocaleTextFromJson(
                                          item.artist.artist_group.name),
                                      style: getTextStyle(AppTypo.caption10SB,
                                          AppColors.grey600),
                                    ),
                                  ]
                                : [
                                    TextSpan(
                                      text: getLocaleTextFromJson(
                                          item.artistGroup.name),
                                      style: getTextStyle(
                                          AppTypo.body14B, AppColors.grey900),
                                    ),
                                  ]),
                      ),
                      const SizedBox(height: 8),
                      _buildVoteCountContainer(item, item.voteTotal!),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              if (!ref
                  .read(asyncVoteDetailProvider(voteId: widget.voteId))
                  .value!
                  .isEnded!)
                Container(
                  alignment: Alignment.bottomCenter,
                  height: 80,
                  padding: const EdgeInsets.only(bottom: 17),
                  child: SvgPicture.asset(
                    'assets/icons/star_candy_icon.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistImage(VoteItemModel item) {
    return Container(
      decoration: BoxDecoration(
        gradient: goldGradient,
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.all(5),
      width: 80,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: PicnicCachedNetworkImage(
          imageUrl: (item.artist.id != 0
                  ? item.artist.image
                  : item.artistGroup.image) ??
              '',
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          memCacheWidth: 80,
          memCacheHeight: 80,
        ),
      ),
    );
  }

  Widget _buildVoteCountContainer(VoteItemModel item, int voteCountDiff) {
    final hasChanged = voteCountDiff != 0;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          width: double.infinity,
          height: 20,
          decoration: BoxDecoration(
            gradient: commonGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          key: ValueKey(hasChanged ? item.voteTotal : 'static'),
        ),
        Container(
          width: double.infinity,
          height: 20,
          padding: EdgeInsets.only(right: 16.w, bottom: 3),
          alignment: Alignment.centerRight,
          child: hasChanged
              ? AnimatedDigitWidget(
                  value: item.voteTotal,
                  enableSeparator: true,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  textStyle:
                      getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                )
              : Text(
                  NumberFormat('#,###').format(item.voteTotal),
                  style: getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                ),
        ),
        if (voteCountDiff > 0)
          Positioned(
            right: 16.w,
            top: -15,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(0, -10 * value),
                    child: Text(
                      '+$voteCountDiff',
                      style: getTextStyle(
                          AppTypo.caption10SB, AppColors.primary500),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _handleVoteItemTap(BuildContext context, VoteItemModel item) {
    final voteDetail =
        ref.read(asyncVoteDetailProvider(voteId: widget.voteId)).value!;
    if (voteDetail.isEnded!) {
      showSimpleDialog(content: S.of(context).message_vote_is_ended);
    } else if (voteDetail.isUpcoming!) {
      showSimpleDialog(content: S.of(context).message_vote_is_upcoming);
    } else {
      supabase.isLogged
          ? showVotingDialog(
              context: context,
              voteModel: voteDetail,
              voteItemModel: item,
            )
          : showRequireLoginDialog();
    }
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 200, color: Colors.white),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(height: 24, width: 250.w, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(height: 16, width: 200.w, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(height: 18, width: 180.w, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(height: 16, width: 150.w, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 280.w,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < 5; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      width: 45.w,
                      height: 45,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 16, width: 120.w, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  _buildRewardInfo(data, int rewardIndex, bool isAchieved) {
    return GestureDetector(
      onTap: () {
        showRewardDialog(context, data![rewardIndex].reward);
      },
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 120,
              height: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '리워드${rewardIndex + 1}',
                    style: getTextStyle(AppTypo.caption12B,
                        isAchieved ? AppColors.primary500 : AppColors.grey400),
                  ),
                  Text(
                    getLocaleTextFromJson(data![rewardIndex].reward.title!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getTextStyle(
                            AppTypo.caption12B,
                            isAchieved
                                ? AppColors.primary500
                                : AppColors.grey400)
                        .copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: isAchieved
                                ? AppColors.primary500
                                : AppColors.grey400),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Stack(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color:
                          isAchieved ? AppColors.primary500 : AppColors.grey400,
                      width: 1.5,
                    ),
                  ),
                  width: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: PicnicCachedNetworkImage(
                      imageUrl: data![rewardIndex].reward.thumbnail!,
                      width: 50,
                      height: 50,
                      memCacheWidth: 50,
                      memCacheHeight: 50,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color:
                        isAchieved ? null : AppColors.grey400.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
