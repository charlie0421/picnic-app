import 'dart:async';
import 'dart:math';

import 'package:animated_digit/animated_digit.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
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
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/number.dart';
import 'package:picnic_app/util/ui.dart';
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
  Timer? _updateTimer;
  bool _isDisposed = false;
  late ConfettiController _confettiController;
  List<VoteAchieve>? _achievements;
  OverlayEntry? _overlayEntry;
  final List<int> _achievedMilestones = [];

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _setupTimer();
    _loadAds();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showBottomNavigation: false,
          pageTitle: S.of(context).page_title_vote_detail);
    });
  }

  void _setupTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isDisposed && mounted) {
        ref.refresh(asyncVoteItemListProvider(voteId: widget.voteId));

        final voteItemData =
            ref.read(asyncVoteItemListProvider(voteId: widget.voteId)).value;
        if (voteItemData == null || voteItemData.isEmpty) return;

        _achievements ??= await fetchVoteAchieve(ref, voteId: widget.voteId);
        if (_achievements == null || _achievements!.isEmpty) return;

        final currentVotes = voteItemData[0]!.voteTotal!;
        _checkMilestoneAchievement(currentVotes, _achievements!);
      }
    });
  }

  void _loadAds() async {
    final configService = ref.read(configServiceProvider);

    String? adUnitId = isIOS()
        ? await configService.getConfig('ADMOB_IOS_VOTE_COMPLETE')!
        : await configService.getConfig('ADMOB_ANDROID_VOTE_COMPLETE')!;

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

  void _checkMilestoneAchievement(
      int currentVotes, List<VoteAchieve> achievements) {
    final sortedAchievements = List<VoteAchieve>.from(achievements)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    List<VoteAchieve> newlyAchieved = [];
    List<VoteAchieve> allAchieved = [];

    for (var achievement in sortedAchievements) {
      if (currentVotes >= achievement.amount) {
        allAchieved.add(achievement);
        if (!_achievedMilestones.contains(achievement.amount)) {
          newlyAchieved.add(achievement);
          _achievedMilestones.add(achievement.amount);
        }
      }
    }

    if (newlyAchieved.isNotEmpty) {
      _showMilestoneAnimation(allAchieved);
    }
  }

  void _showMilestoneAnimation(List<VoteAchieve> achievements) {
    if (!mounted || _isDisposed) return;

    _confettiController.play();

    OverlayState? overlayState = Overlay.of(context);

    _overlayEntry?.remove();

    Timer? autoCloseTimer;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.7),
        child: Stack(
          children: [
            // Confetti effects
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 8,
                minBlastForce: 4,
                emissionFrequency: 0.08,
                numberOfParticles: 80,
                gravity: 0.15,
                shouldLoop: false,
                colors: const [
                  Colors.amber,
                  Colors.amberAccent,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                ],
                createParticlePath: (size) {
                  final path = Path();
                  if (Random().nextBool()) {
                    path.addOval(
                        Rect.fromCircle(center: Offset.zero, radius: 6.0));
                  } else {
                    final star = Path();
                    for (var i = 0; i < 5; i++) {
                      final angle = -pi / 2 + (i * 4 * pi / 5);
                      final point = Offset(cos(angle) * 6, sin(angle) * 6);
                      if (i == 0) {
                        star.moveTo(point.dx, point.dy);
                      } else {
                        star.lineTo(point.dx, point.dy);
                      }
                    }
                    path.addPath(star, Offset.zero);
                  }
                  return path;
                },
              ),
            ),
            // Achievement popup
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                onEnd: () {
                  autoCloseTimer = Timer(const Duration(seconds: 3), () {
                    if (_overlayEntry?.mounted ?? false) {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    }
                  });
                },
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: commonGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              Intl.message('text_achievement',
                                  args: [achievements.length]),
                              style: getTextStyle(
                                  AppTypo.title18B, AppColors.grey00),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: achievements.asMap().entries.map((entry) {
                              final index = entry.key;
                              final achievement = entry.value;
                              final isNewlyAchieved = !_achievedMilestones
                                  .contains(achievement.amount);
                              final isEven = index.isEven;

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutBack,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 150,
                                      margin: EdgeInsets.only(
                                        top: isEven ? 0 : 20,
                                        bottom: isEven ? 20 : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isNewlyAchieved
                                              ? AppColors.primary500
                                              : AppColors.grey00
                                                  .withOpacity(0.3),
                                          width: isNewlyAchieved ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (achievement.reward.thumbnail !=
                                              null)
                                            Container(
                                              width: 80,
                                              height: 80,
                                              margin: const EdgeInsets.only(
                                                top: 16,
                                                bottom: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.grey00,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.grey00
                                                        .withOpacity(0.2),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                                child: PicnicCachedNetworkImage(
                                                  imageUrl: achievement
                                                      .reward.thumbnail!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            formatNumberWithComma(
                                                achievement.amount.toString()),
                                            style: getTextStyle(
                                              AppTypo.body16B,
                                              AppColors.grey00,
                                            ),
                                          ),
                                          if (achievement.reward.title != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              child: Text(
                                                getLocaleTextFromJson(
                                                    achievement.reward.title!),
                                                style: getTextStyle(
                                                  AppTypo.caption12R,
                                                  AppColors.grey00,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    autoCloseTimer?.cancel();
    overlayState.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
        data: (data) {
          if (data.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              _buildVoteInfo(),
              _buildAchieveItem(data[0]!),
              Expanded(
                child: SingleChildScrollView(
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
              const SizedBox(height: 8),
              (_isBannerLoaded && _bannerAd != null)
                  ? Container(
                      alignment: Alignment.center,
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    )
                  : SizedBox(height: AdSize.largeBanner.height.toDouble()),
              const SizedBox(height: 18),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<List<VoteAchieve>?>(
                future: fetchVoteAchieve(ref, voteId: widget.voteId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container();
                  }

                  final achievements = snapshot.data!;
                  _achievements = achievements; // 캐시를 위해 저장

                  final mainMilestones =
                      _generateMilestonesFromAchievements(achievements);

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_isDisposed) {
                      _checkMilestoneAchievement(data.voteTotal!, achievements);
                    }
                  });

                  final levels = _generateLevels(mainMilestones);
                  var rewardIndex = 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        levels.length,
                        (index) {
                          final currentLevel = levels[index];
                          final isAchieved = data.voteTotal! >= currentLevel;
                          final isMainMilestone =
                              mainMilestones.contains(currentLevel);

                          return Row(
                            children: [
                              if (isMainMilestone && currentLevel > 0)
                                _buildRewardInfo(
                                    achievements, rewardIndex++, isAchieved)
                              else
                                const SizedBox(width: 180),
                              SizedBox(width: 5.w),
                              Container(
                                width: 80,
                                height: 50,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  currentLevel == 0
                                      ? '0'
                                      : formatNumberWithComma(
                                          currentLevel.toString()),
                                  style: getTextStyle(
                                      isMainMilestone
                                          ? AppTypo.caption12B
                                          : AppTypo.caption12R,
                                      isAchieved
                                          ? AppColors.primary500
                                          : AppColors.grey400),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Container(
                                width: 10.w,
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
            FutureBuilder<List<VoteAchieve>?>(
                future: fetchVoteAchieve(ref, voteId: widget.voteId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }

                  final achievements = snapshot.data!;
                  final mainMilestones =
                      _generateMilestonesFromAchievements(achievements);

                  final progressHeight =
                      50 * _calculateTotalSteps(mainMilestones).toDouble() - 50;
                  return Container(
                    width: 20,
                    height: progressHeight,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    alignment: Alignment.center,
                    child: LayoutBuilder(builder: (context, constraints) {
                      final allLevels = _generateLevels(mainMilestones);
                      final voteTotal = data.voteTotal ?? 0;

                      // 개선된 진행률 계산 로직
                      double exactProgress =
                          _calculateExactProgress(voteTotal, allLevels);

                      return FAProgressBar(
                        key: ValueKey(voteTotal),
                        currentValue: exactProgress,
                        maxValue: 100,
                        animatedDuration: const Duration(milliseconds: 300),
                        direction: Axis.vertical,
                        verticalDirection: VerticalDirection.down,
                        borderRadius: BorderRadius.circular(5),
                        backgroundColor: AppColors.grey300,
                        progressGradient: commonGradientVertical,
                        displayText: null, // 텍스트 표시 제거
                      );
                    }),
                  );
                }),
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

  Widget _buildRewardInfo(achievements, int rewardIndex, bool isAchieved) {
    return GestureDetector(
      onTap: () {
        showRewardDialog(context, achievements[rewardIndex].reward);
      },
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 130,
              height: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${S.of(context).reward}${rewardIndex + 1}',
                    style: getTextStyle(AppTypo.caption12B,
                        isAchieved ? AppColors.primary500 : AppColors.grey400),
                  ),
                  Text(
                    getLocaleTextFromJson(
                        achievements[rewardIndex].reward.title!),
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
                      imageUrl: achievements[rewardIndex].reward.thumbnail!,
                      width: 50,
                      memCacheWidth: 50,
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

  List<int> _generateMilestonesFromAchievements(
      List<VoteAchieve> achievements) {
    List<int> milestones = [0];
    milestones.addAll(achievements.map((achieve) => achieve.amount));
    return milestones;
  }

  double _calculateExactProgress(int voteTotal, List<int> levels) {
    if (voteTotal >= levels.last) {
      return 100.0;
    }
    if (voteTotal <= levels.first) {
      return 0.0;
    }

    // 현재 단계 찾기
    int currentLevelIndex = 0;
    for (int i = 0; i < levels.length - 1; i++) {
      if (voteTotal >= levels[i] && voteTotal < levels[i + 1]) {
        currentLevelIndex = i;
        break;
      }
    }

    // 각 단계의 크기를 동일하게 설정
    final totalSteps = levels.length - 1;
    final stepSize = 100.0 / totalSteps; // 각 단계는 동일한 크기를 가짐

    // 현재 단계 내에서의 진행률 계산
    final currentLevel = levels[currentLevelIndex];
    final nextLevel = levels[currentLevelIndex + 1];
    final levelDiff = nextLevel - currentLevel;
    final currentDiff = voteTotal - currentLevel;

    // 현재 단계에서의 진행률을 0-1 사이의 값으로 계산
    final progressInCurrentStep = levelDiff > 0 ? currentDiff / levelDiff : 0.0;

    // 전체 진행률 계산
    // 이전 단계들의 진행률 + 현재 단계에서의 진행률
    final baseProgress = currentLevelIndex * stepSize;
    final additionalProgress = progressInCurrentStep * stepSize;

    return (baseProgress + additionalProgress).clamp(0.0, 100.0);
  }

  List<int> _generateLevels(List<int> mainMilestones) {
    List<int> allLevels = [];
    allLevels.add(0);

    for (int i = 1; i < mainMilestones.length; i++) {
      final start = mainMilestones[i - 1];
      final end = mainMilestones[i];

      // 각 구간을 5개의 동일한 간격으로 나눔
      final stepSize = (end - start) ~/ 5;

      if (start != 0) {
        for (int j = 1; j <= 4; j++) {
          allLevels.add(start + (stepSize * j));
        }
      } else {
        for (int j = 1; j <= 4; j++) {
          allLevels.add(stepSize * j);
        }
      }
      allLevels.add(end);
    }

    return allLevels;
  }

  int _calculateTotalSteps(List<int> mainMilestones) {
    return _generateLevels(mainMilestones).length;
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

  @override
  void dispose() {
    _overlayEntry?.remove();
    _isDisposed = true;
    _updateTimer?.cancel();
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
}
