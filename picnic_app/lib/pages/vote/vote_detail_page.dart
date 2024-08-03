import 'dart:async';

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
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class VoteDetailPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_detail';
  final int voteId;

  const VoteDetailPage({super.key, required this.voteId});

  @override
  ConsumerState<VoteDetailPage> createState() => _VoteDetailPageState();
}

class _VoteDetailPageState extends ConsumerState<VoteDetailPage> {
  late ScrollController _scrollController;

  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  String _searchQuery = '';
  bool isEnded = false;
  bool isUpcoming = false;
  final _searchSubject = BehaviorSubject<String>();
  Timer? _updateTimer;
  Map<int, int> _previousVoteCounts = {};
  Map<int, int> _previousRanks = {};

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(_onFocusChange);
    _textEditingController.addListener(_onSearchQueryChange);

    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((query) {
      ref.read(searchQueryProvider.notifier).state = query;
    });

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.refresh(asyncVoteItemListProvider(voteId: widget.voteId));
    });
  }

  void _onFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
      if (_hasFocus) {
        _scrollToSearchBox();
      }
    }
  }

  void _onSearchQueryChange() {
    _searchSubject.add(_textEditingController.text);
    if (_hasFocus) {
      _scrollToSearchBox();
    }
  }

  void _scrollToSearchBox() {
    _scrollController.animateTo(
      210.w,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  List<int> _getFilteredIndices(List<dynamic> args) {
    final List<VoteItemModel?> data = args[0];
    final String query = args[1];
    if (query.isEmpty) {
      return List<int>.generate(data.length, (index) => index);
    }
    return List<int>.generate(data.length, (index) => index)
        .where((index) =>
            getLocaleTextFromJson(data[index]!.artist.name)
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            getLocaleTextFromJson(data[index]!.artist.artist_group.name)
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(asyncVoteDetailProvider(voteId: widget.voteId)).when(
          data: (voteModel) {
            if (voteModel == null) return const SizedBox.shrink();
            isEnded = voteModel.is_ended!;
            isUpcoming = voteModel.is_upcoming!;

            return GestureDetector(
              onTap: () => _focusNode.unfocus(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildVoteInfo(context, voteModel),
                  ),
                  _buildVoteItemList(context),
                ],
              ),
            );
          },
          loading: () => _buildLoadingShimmer(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }

  Widget _buildVoteInfo(BuildContext context, VoteModel voteModel) {
    final width = getPlatformScreenSize(context).width;
    final height = width * 0.5;

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
            memCacheWidth: width.toInt(),
            memCacheHeight: height.toInt(),
          ),
        ),
        SizedBox(height: 36.h),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 57).r,
          child: VoteCommonTitle(title: getLocaleTextFromJson(voteModel.title)),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 18.h,
          child: Text(
            '${DateFormat('yyyy.MM.dd HH:mm').format(voteModel.start_at.toLocal())} ~ '
            '${DateFormat('yyyy.MM.dd HH:mm').format(voteModel.stop_at.toLocal())} '
            '(${getShortTimeZoneIdentifier()})',
            style: getTextStyle(AppTypo.CAPTION12R, AppColors.Grey900),
          ),
        ),
        SizedBox(height: 26.h),
        Text(
          S.of(context).text_vote_rank_in_reward,
          style: getTextStyle(AppTypo.BODY14B, AppColors.Primary500),
        ),
        SizedBox(height: 4.h),
        if (voteModel.reward != null)
          Column(
            children: voteModel.reward!
                .map((rewardModel) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showRewardDialog(context, rewardModel),
                      child: Text(
                        rewardModel.getTitle(),
                        style:
                            getTextStyle(AppTypo.CAPTION12R, AppColors.Grey900)
                                .copyWith(decoration: TextDecoration.underline),
                      ),
                    ))
                .toList(),
          ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildVoteItemList(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    return Consumer(
      builder: (context, ref, _) {
        return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
              data: (data) {
                final filteredIndices =
                    _getFilteredIndices([data, searchQuery]);
                return SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        margin:
                            const EdgeInsets.only(top: 24, left: 16, right: 16)
                                .r,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.Primary500, width: 1.r),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(70.r),
                            topRight: Radius.circular(70.r),
                            bottomLeft: Radius.circular(40.r),
                            bottomRight: Radius.circular(40.r),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                                  top: 56, left: 16, right: 16)
                              .r,
                          child: filteredIndices.isEmpty &&
                                  searchQuery.isNotEmpty
                              ? SizedBox(
                                  height: 200.h,
                                  child: Center(
                                    child: Text(
                                        S.of(context).text_no_search_result),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredIndices.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: 36.h),
                                  itemBuilder: (context, index) {
                                    final itemIndex = filteredIndices[index];
                                    final item = data[itemIndex]!;
                                    return _buildVoteItem(
                                        context, item, itemIndex);
                                  },
                                ),
                        ),
                      ),
                      _buildSearchBox(),
                    ],
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(child: _buildLoadingShimmer()),
              error: (error, stackTrace) => SliverToBoxAdapter(
                child: ErrorView(context,
                    error: error.toString(), stackTrace: stackTrace),
              ),
            );
      },
    );
  }

  Widget _buildVoteItem(BuildContext context, VoteItemModel item, int index) {
    final previousVoteCount = _previousVoteCounts[item.id] ?? item.vote_total;
    final voteCountDiff = item.vote_total - previousVoteCount;

    final previousRank = _previousRanks[item.id] ?? index + 1;
    final rankChanged = previousRank != index + 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousVoteCounts[item.id] = item.vote_total;
      _previousRanks[item.id] = index + 1;
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: rankChanged
            ? AppColors.Primary500.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleVoteItemTap(context, item),
        child: SizedBox(
          height: 40.h,
          child: Row(
            children: [
              SizedBox(
                width: 35.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (index < 3)
                      SvgPicture.asset(
                          'assets/icons/vote/crown${index + 1}.svg'),
                    Text(
                      Intl.message('text_vote_rank', args: [index + 1])
                          .toString(),
                      style:
                          getTextStyle(AppTypo.CAPTION12B, AppColors.Point900),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _buildArtistImage(item, index),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${getLocaleTextFromJson(item.artist.name)} ${getLocaleTextFromJson(item.artist.artist_group.name)}',
                      style: getTextStyle(AppTypo.BODY14B, AppColors.Grey900),
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildVoteCountContainer(item, voteCountDiff),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              if (!isEnded)
                SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: SvgPicture.asset('assets/icons/star_candy_icon.svg'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistImage(VoteItemModel item, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: index < 3
            ? [goldGradient, silverGradient, bronzeGradient][index]
            : null,
        color: index >= 3 ? AppColors.Grey200 : null,
        borderRadius: BorderRadius.circular(27.5),
      ),
      padding: const EdgeInsets.all(3),
      width: 45.w,
      height: 45.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: PicnicCachedNetworkImage(
          imageUrl: item.artist.image,
          useScreenUtil: true,
          width: 55,
          height: 55,
          memCacheWidth: 55,
          memCacheHeight: 55,
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
          height: 20.w,
          decoration: BoxDecoration(
            gradient: commonGradient,
            borderRadius: BorderRadius.circular(10.r),
          ),
          // 변화가 있을 때 key를 변경하여 새로운 애니메이션 트리거
          key: ValueKey(hasChanged ? item.vote_total : 'static'),
        ),
        Container(
          width: double.infinity,
          height: 20.w,
          padding: const EdgeInsets.only(right: 16, bottom: 3).r,
          alignment: Alignment.centerRight,
          child: hasChanged
              ? AnimatedDigitWidget(
                  value: item.vote_total,
                  enableSeparator: true,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  textStyle:
                      getTextStyle(AppTypo.CAPTION10SB, AppColors.Grey00),
                )
              : Text(
                  NumberFormat('#,###').format(item.vote_total),
                  style: getTextStyle(AppTypo.CAPTION10SB, AppColors.Grey00),
                ),
        ),
        if (voteCountDiff > 0)
          Positioned(
            right: 16.w,
            top: -15.h,
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
                          AppTypo.CAPTION10SB, AppColors.Primary500),
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
    if (isEnded) {
      showSimpleDialog(
          context: context, content: S.of(context).message_vote_is_ended);
    } else if (isUpcoming) {
      showSimpleDialog(
          context: context, content: S.of(context).message_vote_is_upcoming);
    } else {
      supabase.isLogged
          ? showVotingDialog(
              context: context,
              voteModel: ref
                  .read(asyncVoteDetailProvider(voteId: widget.voteId))
                  .value!,
              voteItemModel: item,
            )
          : showRequireLoginDialog(context: context);
    }
  }

  Widget _buildSearchBox() {
    return Positioned(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8).w,
                child: SvgPicture.asset(
                  'assets/icons/vote/search_icon.svg',
                  width: 20.w,
                  height: 20.w,
                ),
              ),
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    hintText: S.of(context).text_vote_where_is_my_bias,
                    hintStyle: getTextStyle(AppTypo.BODY16R, AppColors.Grey300),
                    border: InputBorder.none,
                    focusColor: AppColors.Primary500,
                    fillColor: AppColors.Grey900,
                  ),
                  style: getTextStyle(AppTypo.BODY16R, AppColors.Grey900),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _textEditingController.clear(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 16).w,
                  child: SvgPicture.asset(
                    'assets/icons/cancle_style=fill.svg',
                    width: 20.w,
                    height: 20.w,
                    colorFilter: ColorFilter.mode(
                      _textEditingController.text.isNotEmpty
                          ? AppColors.Grey700
                          : AppColors.Grey200,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            Container(
              height: 200.h,
              color: Colors.white,
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 24.h,
                width: 250.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 16.h,
                width: 200.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
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

class GradientProgressPainter extends CustomPainter {
  final double progress;
  final Gradient gradient;

  GradientProgressPainter({required this.progress, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * progress, size.height),
        Radius.circular(10.r),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(GradientProgressPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
