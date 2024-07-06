import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';

class FreeChargeStation extends ConsumerStatefulWidget {
  const FreeChargeStation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FreeChargeStationState();
}

class _FreeChargeStationState extends ConsumerState<FreeChargeStation>
    with SingleTickerProviderStateMixin {
  final List<RewardedAd?> _rewardedAds = [null, null];
  final List<bool> _isLoading = [true, true];
  final int maxFailedLoadAttempts = 3;
  final List<int> _numRewardedLoadAttempts = [0, 0];
  final List<String> _adUnitIds = [
    Platform.isAndroid
        ? 'ca-app-pub-1539304887624918/3864525446'
        : 'ca-app-pub-1539304887624918/9821126370',
    Platform.isAndroid
        ? 'ca-app-pub-1539304887624918/7505348989'
        : 'ca-app-pub-1539304887624918/4571289807',
  ];

  static const AdRequest request = AdRequest();
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    MobileAds.instance.initialize().then((InitializationStatus status) {
      _createRewardedAd(0);
      _createRewardedAd(1);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          SizedBox(height: 36.w),
          StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 100.w),
          SizedBox(height: 36.w),
          _buildStoreListTile(0),
          Divider(height: 32.w, thickness: 1, color: AppColors.Grey200),
          _buildStoreListTile(1),
          Divider(height: 32.w, thickness: 1, color: AppColors.Grey200),
          GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => LargePopupWidget(
                        width: MediaQuery.of(context).size.width - 32.w,
                        content: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 40.w, vertical: 64.w),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'assets/icons/play_style=fill.svg',
                                    width: 16.w,
                                    height: 16.w,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.Primary500,
                                      BlendMode.srcIn,
                                    )),
                                SizedBox(width: 8.w),
                                Text(
                                  S.of(context).candy_usage_policy_title,
                                  style: getTextStyle(
                                      AppTypo.BODY14B, AppColors.Primary500),
                                ),
                                SizedBox(width: 8.w),
                                Transform.rotate(
                                  angle: 3.14,
                                  child: SvgPicture.asset(
                                      'assets/icons/play_style=fill.svg',
                                      width: 16.w,
                                      height: 16.w,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.Primary500,
                                        BlendMode.srcIn,
                                      )),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.w),
                            Markdown(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              data: S.of(context).candy_usage_policy_contents,
                              styleSheet: commonMarkdownStyleSheet,
                            ),
                            SizedBox(height: 16.w),
                            StorePointInfo(
                                title: S.of(context).label_star_candy_pouch,
                                width: 231.w,
                                titlePadding: 10.w,
                                height: 78.w)
                          ]),
                        ),
                      ));
            },
            child: Text(S.of(context).candy_usage_policy_guide,
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreListTile(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return StoreListTile(
          icon: Image.asset(
            'assets/icons/store/star_100.png',
            width: 48.w,
            height: 48.w,
          ),
          title: Text(
            S.of(context).label_button_watch_and_charge,
            style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
          ),
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '+${S.of(context).label_bonus} 1',
                  style: getTextStyle(AppTypo.CAPTION12B, AppColors.Point900),
                ),
              ],
            ),
          ),
          buttonText: S.of(context).label_watch_ads,
          buttonOnPressed: () async {
            if (_rewardedAds[index] == null) {
              await _createRewardedAd(index);
            }
            _showRewardedAd(index);
          },
          isLoading: _isLoading[index],
          buttonScale: _buttonScaleAnimation.value,
        );
      },
    );
  }

  Future<void> _createRewardedAd(int index) async {
    setState(() {
      _isLoading[index] = true;
    });

    await RewardedAd.load(
      adUnitId: _adUnitIds[index],
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          logger.i('$ad loaded.');
          setState(() {
            _rewardedAds[index] = ad;
            _isLoading[index] = false;
            _numRewardedLoadAttempts[index] = 0;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          logger.i('RewardedAd failed to load: $error');
          setState(() {
            _rewardedAds[index] = null;
            _isLoading[index] = false;
            _numRewardedLoadAttempts[index] += 1;
          });
          if (_numRewardedLoadAttempts[index] < maxFailedLoadAttempts) {
            _createRewardedAd(index);
          }
        },
      ),
    );
  }

  void _showRewardedAd(int index) {
    if (_rewardedAds[index] == null) {
      logger.i('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAds[index]!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          logger.i('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        logger.i('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        ref.read(userInfoProvider.notifier).getUserProfiles();

        showSimpleDialog(
          context: context,
          title: S.of(context).text_dialog_star_candy_received,
          onOk: () {},
        );

        _createRewardedAd(index);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        logger.i('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();

        showSimpleDialog(
          context: context,
          title: '오류 안내',
          content: '오류가 발생했어요.\n다시 한 번 시도해주세요.',
          onOk: () {},
        );

        _createRewardedAd(index);
      },
    );

    ServerSideVerificationOptions options = ServerSideVerificationOptions(
      userId: ref.watch(userInfoProvider).value?.id.toString(),
      customData: '{"reward_type":"free_charge_station"}',
    );
    _rewardedAds[index]?.setServerSideOptions(options);

    _rewardedAds[index]!.setImmersiveMode(true);
    _rewardedAds[index]!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        ref.read(userInfoProvider.notifier).getUserProfiles();
        logger.i('User earned reward of ${reward.amount} ${reward.type}');
      },
    );

    setState(() {
      _rewardedAds[index] = null;
      _isLoading[index] = true;
    });

    _animateButton();
  }

  void _animateButton() {
    _animationController.forward(from: 0.0);
  }
}
