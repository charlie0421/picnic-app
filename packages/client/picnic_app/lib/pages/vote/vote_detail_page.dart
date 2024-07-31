import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/reward_dialog.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/components/vote/list/voting_dialog.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class VoteDetailPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_detail';
  final int voteId;

  const VoteDetailPage({super.key, required this.voteId});

  @override
  ConsumerState<VoteDetailPage> createState() => _VoteDetailPageState();
}

class _VoteDetailPageState extends ConsumerState<VoteDetailPage> {
  late ScrollController _scrollController;
  final GlobalKey _searchBoxKey = GlobalKey();

  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  String _searchQuery = '';
  bool is_ended = false;
  bool is_upcoming = false;

  @override
  initState() {
    super.initState();
    _scrollController = ScrollController();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });

      // if (_hasFocus) {
      //   _scrollToTarget(_searchBoxKey);
      // }
    });

    _textEditingController.addListener(() {
      setState(() {
        _searchQuery = _textEditingController.text;
      });

      if (_hasFocus) {
        _scrollToTarget(_searchBoxKey);
      }
    });

    // _setupRealtime();
  }

  // void _handleVoteChanges(PostgresChangePayload payload) {
  //   logger.d('Change received! $payload');
  //   final asyncVoteItemListNotifier =
  //       ref.read(asyncVoteItemListProvider(voteId: widget.voteId).notifier);
  //   asyncVoteItemListNotifier.setVoteItem(
  //       id: payload.newRecord['id'],
  //       voteTotal: payload.newRecord['vote_total']);
  // }

  void _scrollToTarget(GlobalKey targetKey) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(milliseconds: 100), () {
    //     final RenderBox renderBox =
    //         targetKey.currentContext!.findRenderObject() as RenderBox;
    //
    //     _scrollController.animateTo(
    //       210.w,
    //       duration: const Duration(milliseconds: 200),
    //       curve: Curves.easeInOut,
    //     );
    //   });
    // });
  }

  // void _setupRealtime() {
  //   logger.d('Setting up realtime');
  //   supabase
  //       .channel('realtime')
  //       .onPostgresChanges(
  //           event: PostgresChangeEvent.update,
  //           schema: 'public',
  //           table: 'vote_item',
  //           filter: PostgresChangeFilter(
  //               type: PostgresChangeFilterType.eq,
  //               column: 'vote_id',
  //               value: widget.voteId),
  //           callback: _handleVoteChanges)
  //       .subscribe();
  // }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
  }

  List<int> _getFilteredIndices(List<VoteItemModel?> data) {
    if (_searchQuery.isEmpty) {
      return List<int>.generate(data.length, (index) => index);
    }
    return List<int>.generate(data.length, (index) => index)
        .where((index) =>
            getLocaleTextFromJson(data[index]!.artist.name)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            getLocaleTextFromJson(data[index]!.artist.artist_group.name)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  TextSpan _highlightText(String text, String query, TextStyle textStyle) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: textStyle);
    }
    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return TextSpan(text: text, style: textStyle);
    }

    int start = 0;
    final List<TextSpan> spans = [];

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(
            text: text.substring(start, match.start),
            style: getTextStyle(AppTypo.BODY14B, AppColors.Grey900)));
      }

      spans.add(TextSpan(
          text: text.substring(match.start, match.end),
          style: getTextStyle(AppTypo.BODY14B, AppColors.Primary500)));

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
          text: text.substring(start),
          style: getTextStyle(AppTypo.BODY14B, AppColors.Grey900)));
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  _buildVoteInfo(context),
                  _buildVoteItemList(context, constraints),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoteInfo(BuildContext context) {
    final width = getPlatformScreenSize(context).width;
    final height = width * 0.5;
    return ref.watch(asyncVoteDetailProvider(voteId: widget.voteId)).when(
          data: (voteModel) {
            if (voteModel == null) {
              return _buildLoadingShimmer();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                  is_ended = voteModel.is_ended!;
                  is_upcoming = voteModel.is_upcoming!;
                }));
            return Column(
              children: [
                SizedBox(
                  width: width,
                  height: height,
                  child: PicnicCachedNetworkImage(
                    imageUrl: voteModel.main_image,
                    useScreenUtil: true,
                    fit: BoxFit.cover,
                    width: width.toInt(),
                    height: height.toInt(),
                  ),
                ),
                SizedBox(
                  height: 36.h,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 57).r,
                  child: VoteCommonTitle(
                      title: getLocaleTextFromJson(voteModel.title)),
                ),
                SizedBox(
                  height: 12.h,
                ),
                SizedBox(
                  height: 18.h,
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: DateFormat('yyyy.MM.dd HH:mm')
                            .format(voteModel.start_at.toLocal()),
                        style:
                            getTextStyle(AppTypo.CAPTION12R, AppColors.Grey900),
                      ),
                      const TextSpan(text: ' ~ '),
                      TextSpan(
                        text: DateFormat('yyyy.MM.dd HH:mm')
                            .format(voteModel.stop_at.toLocal()),
                        style:
                            getTextStyle(AppTypo.CAPTION12R, AppColors.Grey900),
                      ),
                      TextSpan(
                        text: '(${getShortTimeZoneIdentifier()})',
                        style:
                            getTextStyle(AppTypo.CAPTION12R, AppColors.Grey900),
                      )
                    ]),
                  ),
                ),
                SizedBox(
                  height: 26.h,
                ),
                SizedBox(
                    height: 21.h,
                    child: Text(
                      S.of(context).text_vote_rank_in_reward,
                      style:
                          getTextStyle(AppTypo.BODY14B, AppColors.Primary500),
                    )),
                SizedBox(
                  height: 4.h,
                ),
                voteModel.reward != null
                    ? Column(
                        children: voteModel.reward!
                            .map((rewardModel) => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    logger.d(rewardModel);
                                    showRewardDialog(context, rewardModel);
                                  },
                                  child: Text(rewardModel.getTitle(),
                                      style: getTextStyle(AppTypo.CAPTION12R,
                                              AppColors.Grey900)
                                          .copyWith(
                                        decoration: TextDecoration.underline,
                                      )),
                                ))
                            .toList(),
                      )
                    : const SizedBox.shrink(),
                SizedBox(
                  height: 16.h,
                ),
              ],
            );
          },
          loading: () => _buildLoadingShimmer(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }

  Widget _buildVoteItemList(BuildContext context, BoxConstraints constraints) {
    return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
          data: (data) {
            final filteredIndices = _getFilteredIndices(data);

            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 24, left: 16, right: 16).r,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.Primary500,
                        width: 1.r,
                      ),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(70.r),
                          topRight: Radius.circular(70.r),
                          bottomLeft: Radius.circular(40.r),
                          bottomRight: Radius.circular(40.r))),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 56).w,
                    child: filteredIndices.isEmpty
                        ? SizedBox(
                            height: 200.h,
                            child: Center(
                              child: Text(S.of(context).text_no_search_result),
                            ),
                          )
                        : Column(
                            children: filteredIndices.map((index) {
                              final item = data[index]!;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (is_ended) {
                                      showSimpleDialog(
                                          context: context,
                                          content: S
                                              .of(context)
                                              .message_vote_is_ended);
                                      return;
                                    }

                                    if (is_upcoming) {
                                      showSimpleDialog(
                                          context: context,
                                          content: S
                                              .of(context)
                                              .message_vote_is_upcoming);
                                      return;
                                    }

                                    supabase.isLogged
                                        ? showVotingDialog(
                                            context: context,
                                            voteModel: ref
                                                .watch(asyncVoteDetailProvider(
                                                    voteId: widget.voteId))
                                                .value!,
                                            voteItemModel: item,
                                          )
                                        : showRequireLoginDialog(
                                            context: context,
                                          );
                                  },
                                  child: Container(
                                    key: ValueKey<int>(index),
                                    height: 40.h,
                                    margin: const EdgeInsets.only(
                                            left: 16, right: 16, bottom: 36)
                                        .r,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 35.w,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              if (index < 3)
                                                SvgPicture.asset(
                                                    'assets/icons/vote/crown${index + 1}.svg'),
                                              Text(
                                                Intl.message('text_vote_rank',
                                                        args: [index + 1])
                                                    .toString(),
                                                style: getTextStyle(
                                                    AppTypo.CAPTION12B,
                                                    AppColors.Point900),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 8.w,
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: index + 1 == 1
                                                ? goldGradient
                                                : index + 1 == 2
                                                    ? silverGradient
                                                    : index + 1 == 3
                                                        ? bronzeGradient
                                                        : null,
                                            color: index + 1 > 3
                                                ? AppColors.Grey200
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(27.5),
                                          ),
                                          padding: const EdgeInsets.all(3),
                                          width: 45.w,
                                          height: 45.w,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(39),
                                            child: PicnicCachedNetworkImage(
                                              imageUrl: item.artist.image,
                                              useScreenUtil: true,
                                              width: 55,
                                              height: 55,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 8.w,
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: false,
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          getLocaleTextFromJson(
                                                              item.artist.name),
                                                      style: getTextStyle(
                                                          AppTypo.BODY14B,
                                                          AppColors.Grey900),
                                                    ),
                                                    const TextSpan(
                                                      text: ' ',
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          getLocaleTextFromJson(
                                                              item
                                                                  .artist
                                                                  .artist_group
                                                                  .name),
                                                      style: getTextStyle(
                                                          AppTypo.CAPTION10SB,
                                                          AppColors.Grey500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: double.infinity,
                                                height: 20.w,
                                                padding: const EdgeInsets.only(
                                                        right: 16, bottom: 3)
                                                    .r,
                                                decoration: BoxDecoration(
                                                  gradient: commonGradient,
                                                  color: AppColors.Grey100,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.r),
                                                ),
                                                alignment:
                                                    Alignment.centerRight,
                                                child: AnimatedDigitWidget(
                                                  value: item.vote_total,
                                                  duration: const Duration(
                                                      microseconds: 500),
                                                  curve: Curves.easeInOut,
                                                  enableSeparator: true,
                                                  textStyle: getTextStyle(
                                                      AppTypo.CAPTION10SB,
                                                      AppColors.Grey00),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 16.w,
                                        ),
                                        if (!is_ended)
                                          SizedBox(
                                            width: 24.w,
                                            height: 24.w,
                                            child: SvgPicture.asset(
                                                'assets/icons/star_candy_icon.svg'),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                Positioned(
                  key: _searchBoxKey,
                  top: 0,
                  right: 10.w,
                  left: 10.w,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16).r,
                      width: 280.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.Primary500,
                          width: 1.r,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        color: AppColors.Grey00,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16).w,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/vote/search_icon.svg',
                              width: 20.w,
                              height: 20.w,
                            ),
                            SizedBox(
                              width: 8.w,
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                height: 48.w,
                                child: TextFormField(
                                  cursorHeight: 16.w,
                                  cursorColor: AppColors.Primary500,
                                  focusNode: _focusNode,
                                  controller: _textEditingController,
                                  decoration: InputDecoration(
                                    hintText: S
                                        .of(context)
                                        .text_vote_where_is_my_bias,
                                    hintStyle: getTextStyle(
                                        AppTypo.BODY16R, AppColors.Grey300),
                                    border: InputBorder.none,
                                    focusColor: AppColors.Primary500,
                                    fillColor: AppColors.Grey900,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _textEditingController.clear();
                              },
                              child: SvgPicture.asset(
                                'assets/icons/cancle_style=fill.svg',
                                width: 20.w,
                                height: 20.w,
                                colorFilter: ColorFilter.mode(
                                    _textEditingController.text.isNotEmpty
                                        ? AppColors.Grey700
                                        : AppColors.Grey200,
                                    BlendMode.srcIn),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => _buildLoadingShimmer(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 이미지 영역
            Container(
              height: 200.h,
              color: Colors.white,
            ),
            SizedBox(height: 24.h),

            // 제목 영역
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 24.h,
                width: 250.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),

            // 날짜 영역
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 16.h,
                width: 200.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),

            // 리워드 정보 영역
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 18.h,
                width: 180.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 16.h,
                width: 150.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32.h),

            // 검색 박스 영역
            Center(
              child: Container(
                width: 280.w,
                height: 48.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // 투표 항목 리스트
            for (int i = 0; i < 5; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      width: 45.w,
                      height: 45.w,
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
                            height: 16.h,
                            width: 120.w,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 14.h,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ],
        ),
      ),
    );
  }
}
