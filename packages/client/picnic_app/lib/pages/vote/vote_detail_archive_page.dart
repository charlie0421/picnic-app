import 'dart:async';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/common_search_box.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/components/vote/voting/voting_dialog.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
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

class VoteDetailArchivePage extends ConsumerStatefulWidget {
  final int voteId;

  const VoteDetailArchivePage({super.key, required this.voteId});

  @override
  ConsumerState<VoteDetailArchivePage> createState() =>
      _VoteDetailArchivePageState();
}

class _VoteDetailArchivePageState extends ConsumerState<VoteDetailArchivePage> {
  late ScrollController _scrollController;

  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool isEnded = false;
  bool isUpcoming = false;
  bool isArchive = false;
  final _searchSubject = BehaviorSubject<String>();
  Timer? _updateTimer;
  final Map<int, int> _previousVoteCounts = {};
  final Map<int, int> _previousRanks = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
    _setupUpdateTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showBottomNavigation: false,
          pageTitle: S.of(context).page_title_vote_detail);
    });
  }

  void _initializeControllers() {
    _scrollController = ScrollController();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  void _setupListeners() {
    _focusNode.addListener(_onFocusChange);
    _textEditingController.addListener(_onSearchQueryChange);

    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((query) {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = query;
      }
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
    _focusNode.dispose();
    _textEditingController.dispose();
    _searchSubject.close();
    _updateTimer?.cancel();
    super.dispose();
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
      210.cw,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(asyncVoteDetailProvider(voteId: widget.voteId)).when(
          data: (voteModel) {
            if (voteModel == null) return const SizedBox.shrink();
            isEnded = voteModel.isEnded!;
            isUpcoming = voteModel.isUpcoming!;
            isArchive = voteModel.voteCategory == VoteCategory.archive.name;

            return GestureDetector(
              onTap: () => _focusNode.unfocus(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildVoteInfo(context, voteModel),
                  ),
                  SliverToBoxAdapter(child: _buildArchiveItem(context)),
                  SliverToBoxAdapter(child: _buildLevelItem())
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
    return Column(
      children: [
        if (voteModel.mainImage != null && voteModel.mainImage!.isNotEmpty)
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
          padding: EdgeInsets.symmetric(horizontal: 57.cw),
          child: VoteCommonTitle(title: getLocaleTextFromJson(voteModel.title)),
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
  }

  Widget _buildArchiveItem(BuildContext context) {
    return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
          data: (data) {
            return _buildVoteItem(context, data[0]!, 0);
          },
          loading: () => _buildLoadingShimmer(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }

  Widget _buildLevelItem() {
    return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
        data: (data) {
          return Container(
            margin: EdgeInsets.only(top: 20, left: 16.cw, right: 16.cw),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.primary500, width: 1.5.r),
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
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(
                              21,
                              (index) => Row(
                                children: [
                                  if (250000 * index % 1000000 == 0 &&
                                      index != 0)
                                    SizedBox(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: 140,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '리워드${index}',
                                                  style: getTextStyle(
                                                      AppTypo.caption12B,
                                                      AppColors.primary500),
                                                ),
                                                Text(
                                                  getLocaleTextFromJson(snapshot
                                                      .data![0].reward.title!),
                                                  style: getTextStyle(
                                                          AppTypo.caption12B,
                                                          AppColors.primary500)
                                                      .copyWith(
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          decorationColor:
                                                              AppColors
                                                                  .primary500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10.cw,
                                          ),
                                          SizedBox(
                                            width: 50,
                                            child: PicnicCachedNetworkImage(
                                              imageUrl: snapshot
                                                  .data![0].reward.thumbnail!,
                                              width: 50,
                                              height: 50,
                                              memCacheWidth: 50,
                                              memCacheHeight: 50,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    width: 80,
                                    height: 50,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      formatNumberWithComma(
                                          (250000 * index).toString()),
                                      style: getTextStyle(AppTypo.caption12B,
                                          AppColors.primary500),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10.cw,
                                  ),
                                  Container(
                                    width: 20.cw,
                                    height: 2,
                                    color: AppColors.grey700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  SizedBox(
                    width: 8.cw,
                  ),
                  Container(
                    width: 20,
                    height: 50 * 21 + 20,
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    alignment: Alignment.topCenter,
                    child: FAProgressBar(
                      currentValue: data[0]!.voteTotal!.toDouble(),
                      maxValue: 5000000,
                      animatedDuration: const Duration(milliseconds: 200),
                      direction: Axis.vertical,
                      borderRadius: BorderRadiusGeometry.lerp(
                          BorderRadius.circular(10),
                          BorderRadius.circular(10),
                          1),
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
        },
        loading: () => _buildLoadingShimmer(),
        error: (error, stackTrace) => ErrorView(context,
            error: error.toString(), stackTrace: stackTrace));
  }

  Widget _buildVoteItem(BuildContext context, VoteItemModel item, int index) {
    final previousVoteCount = _previousVoteCounts[item.id] ?? item.voteTotal;
    final voteCountDiff = item.voteTotal! - previousVoteCount!;

    final previousRank = _previousRanks[item.id] ?? index + 1;
    final rankChanged = previousRank != index + 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousVoteCounts[item.id] = item.voteTotal!;
      _previousRanks[item.id] = index + 1;
    });

    return AnimatedContainer(
      padding: EdgeInsets.symmetric(horizontal: 34.cw),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleVoteItemTap(context, item),
        child: SizedBox(
          child: Row(
            children: [
              SizedBox(width: 8.cw),
              _buildArtistImage(item, index),
              SizedBox(width: 8.cw),
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
                      _buildVoteCountContainer(item, voteCountDiff),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.cw),
              if (!isEnded)
                Container(
                  alignment: Alignment.bottomCenter,
                  height: 80,
                  padding: const EdgeInsets.only(bottom: 17),
                  child: SvgPicture.asset(
                    key: const ValueKey('assets/icons/star_candy_icon.svg'),
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

  Widget _buildArtistImage(VoteItemModel item, int index) {
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
          key: ValueKey(
              item.artist.id != 0 ? item.artist.image : item.artistGroup.image),
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
            borderRadius: BorderRadius.circular(10.r),
          ),
          // 변화가 있을 때 key를 변경하여 새로운 애니메이션 트리거
          key: ValueKey(hasChanged ? item.voteTotal : 'static'),
        ),
        Container(
          width: double.infinity,
          height: 20,
          padding: EdgeInsets.only(right: 16.cw, bottom: 3),
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
            right: 16.cw,
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
    if (isEnded) {
      showSimpleDialog(content: S.of(context).message_vote_is_ended);
    } else if (isUpcoming) {
      showSimpleDialog(content: S.of(context).message_vote_is_upcoming);
    } else {
      supabase.isLogged
          ? showVotingDialog(
              context: context,
              voteModel: ref
                  .read(asyncVoteDetailProvider(voteId: widget.voteId))
                  .value!,
              voteItemModel: item,
            )
          : showRequireLoginDialog();
    }
  }

  Widget _buildSearchBox() {
    return Positioned(
      top: 0,
      right: 0.cw,
      left: 0.cw,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.cw),
        child: CommonSearchBox(
          focusNode: _focusNode,
          textEditingController: _textEditingController,
          hintText: S.of(context).text_vote_where_is_my_bias,
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
              height: 200,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.cw),
              child: Container(
                height: 24,
                width: 250.cw,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.cw),
              child: Container(
                height: 16,
                width: 200.cw,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.cw),
              child: Container(
                height: 18,
                width: 180.cw,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.cw),
              child: Container(
                height: 16,
                width: 150.cw,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 280.cw,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < 5; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.cw),
                child: Row(
                  children: [
                    Container(
                      width: 45.cw,
                      height: 45,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16.cw),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: 120.cw,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            color: Colors.white,
                          ),
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
