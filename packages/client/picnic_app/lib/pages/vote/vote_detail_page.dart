import 'dart:async';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/common_search_box.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_footer.dart';
import 'package:picnic_app/components/vote/voting/voting_dialog.dart';
import 'package:picnic_app/config/config_service.dart';
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
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/vote_share_util.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class VoteDetailPage extends ConsumerStatefulWidget {
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
  bool isEnded = false;
  bool isUpcoming = false;
  final _searchSubject = BehaviorSubject<String>();
  Timer? _updateTimer;
  final Map<int, int> _previousVoteCounts = {};
  final Map<int, int> _previousRanks = {};

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
    _setupUpdateTimer();
    _loadAds();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showBottomNavigation: false,
          pageTitle: S.of(context).page_title_vote_detail);
    });
  }

  void _loadAds() async {
    final configService = ref.read(configServiceProvider);

    String? adUnitId = isIOS()
        ? await configService.getConfig('ADMOB_IOS_VOTE_DETAIL')!
        : await configService.getConfig('ADMOB_ANDROID_VOTE_DETAIL')!;

    _bannerAd = BannerAd(
      adUnitId: adUnitId!,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
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

  List<int> _getFilteredIndices(List<dynamic> args) {
    final List<VoteItemModel?> data = args[0];
    final String query = args[1];
    if (query.isEmpty) {
      return List<int>.generate(data.length, (index) => index);
    }

    return List<int>.generate(data.length, (index) => index).where((index) {
      return data[index]!.artist != 0 &&
              getLocaleTextFromJson(data[index]!.artist.name)
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
          data[index]!.artist != 0 &&
              getLocaleTextFromJson(data[index]!.artistGroup.name)
                  .toLowerCase()
                  .contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        color: AppColors.grey00,
        child: ref.watch(asyncVoteDetailProvider(voteId: widget.voteId)).when(
              data: (voteModel) {
                if (voteModel == null) return const SizedBox.shrink();
                isEnded = voteModel.isEnded!;
                isUpcoming = voteModel.isUpcoming!;

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
            ),
      ),
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
        const SizedBox(height: 8),
        if (_isSaving)
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 24),
            child: Image.asset(
              'assets/images/vote/banner_complete_bottom_${Intl.getCurrentLocale() == "ko" ? 'ko' : 'en'}.jpg',
              fit: BoxFit.contain,
            ),
          )
        else if (_isBannerLoaded && _bannerAd != null)
          Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          )
        else
          SizedBox(height: AdSize.largeBanner.height.toDouble()),
        const SizedBox(height: 8),
        Text(
          S.of(context).text_vote_rank_in_reward,
          style: getTextStyle(AppTypo.body14B, AppColors.primary500),
        ),
        if (voteModel.reward != null)
          Column(
            children: voteModel.reward!
                .map((rewardModel) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showRewardDialog(context, rewardModel),
                      child: Text(
                        getLocaleTextFromJson(rewardModel.title!),
                        style:
                            getTextStyle(AppTypo.caption12R, AppColors.grey900)
                                .copyWith(decoration: TextDecoration.underline),
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(height: 18),
        if (isEnded && !_isSaving)
          Column(
            children: [
              VoteCardInfoFooter(
                saveButtonText: S.of(context).vote_result_save_button,
                shareButtonText: S.of(context).vote_result_share_button,
                onSave: () {
                  if (_isSaving) return;
                  VoteShareUtils.captureAndSaveImage(
                    _globalKey,
                    context,
                    onStart: () => setState(() => _isSaving = true),
                    onComplete: () => setState(() => _isSaving = false),
                  );
                },
                onShare: () {
                  if (_isSaving) return;
                  VoteShareUtils.shareToTwitter(
                    _globalKey,
                    context,
                    title: getLocaleTextFromJson(voteModel.title),
                    onStart: () => setState(() => _isSaving = true),
                    onComplete: () => setState(() => _isSaving = false),
                  );
                },
              ),
              SizedBox(height: 24),
            ],
          ),
      ],
    );
  }

  // VoteDetailPage 클래스 내에서 _buildVoteItemList 메서드를 수정
  Widget _buildVoteItemList(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    return Consumer(
      builder: (context, ref, _) {
        return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
              data: (data) {
                final filteredIndices =
                    _getFilteredIndices([data, searchQuery]);

                // 캡쳐용 레이아웃
                if (_isSaving) {
                  return SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16.cw),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.primary500, width: 1.r),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(70.r),
                          topRight: Radius.circular(70.r),
                          bottomLeft: Radius.circular(40.r),
                          bottomRight: Radius.circular(40.r),
                        ),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          children: [
                            for (int i = 0; i < 3 && i < data.length; i++)
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: i < 2 ? 36 : 16),
                                child: _buildVoteItem(context, data[i]!, i),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // 일반적인 리스트 표시
                return SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        margin:
                            EdgeInsets.only(top: 24, left: 16.cw, right: 16.cw),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primary500, width: 1.r),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(70.r),
                            topRight: Radius.circular(70.r),
                            bottomLeft: Radius.circular(40.r),
                            bottomRight: Radius.circular(40.r),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                                  top: 56, left: 16.cw, right: 16.cw)
                              .r,
                          child: filteredIndices.isEmpty &&
                                  searchQuery.isNotEmpty
                              ? SizedBox(
                                  height: 200,
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
                                      const SizedBox(height: 36),
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
    final previousVoteCount = _previousVoteCounts[item.id] ?? item.voteTotal;
    final voteCountDiff = item.voteTotal! - previousVoteCount!;

    final previousRank = _previousRanks[item.id] ?? index + 1;
    final rankChanged = previousRank != index + 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousVoteCounts[item.id] = item.voteTotal!;
      _previousRanks[item.id] = index + 1;
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: rankChanged
            ? AppColors.primary500.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleVoteItemTap(context, item, index), // index 추가

        child: SizedBox(
          height: 45,
          child: Row(
            children: [
              SizedBox(
                width: 39,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (index < 3)
                      SvgPicture.asset(
                        key:
                            ValueKey('assets/icons/vote/crown${index + 1}.svg'),
                        'assets/icons/vote/crown${index + 1}.svg',
                      ),
                    Text(
                      Intl.message('text_vote_rank', args: [index + 1])
                          .toString(),
                      style:
                          getTextStyle(AppTypo.caption12B, AppColors.point900),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.cw),
              _buildArtistImage(item, index),
              SizedBox(width: 8.cw),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          children: item.artist.id != 0
                              ? [
                                  TextSpan(
                                    text:
                                        getLocaleTextFromJson(item.artist.name),
                                    style: getTextStyle(
                                        AppTypo.body14B, AppColors.grey900),
                                  ),
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: getLocaleTextFromJson(
                                        item.artist.artist_group!.name),
                                    style: getTextStyle(
                                        AppTypo.caption10SB, AppColors.grey600),
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
                    _buildVoteCountContainer(item, voteCountDiff),
                  ],
                ),
              ),
              SizedBox(width: 16.cw),
              if (!isEnded)
                SizedBox(
                  width: 24.cw,
                  height: 24,
                  child: SvgPicture.asset(
                    key: const ValueKey('assets/icons/star_candy_icon.svg'),
                    'assets/icons/star_candy_icon.svg',
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
        gradient: index < 3
            ? [goldGradient, silverGradient, bronzeGradient][index]
            : null,
        color: index >= 3 ? AppColors.grey200 : null,
        borderRadius: BorderRadius.circular(22.5),
      ),
      padding: const EdgeInsets.all(3),
      width: 45,
      height: 45,
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

  void _handleVoteItemTap(BuildContext context, VoteItemModel item, int index) {
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
                height: 48,
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
