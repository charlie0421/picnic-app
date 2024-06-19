import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/simple_dialog.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';

class FreeChargeStation extends ConsumerStatefulWidget {
  const FreeChargeStation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FreeChargeStationState();
}

class _FreeChargeStationState extends ConsumerState<FreeChargeStation> {
  final List<RewardedAd?> _rewardedAds = [null, null];
  final List<bool> _isLoading = [true, true];
  final int maxFailedLoadAttempts = 3;
  final List<int> _numRewardedLoadAttempts = [0, 0];
  final List<String> _adUnitIds = [
    Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-1539304887624918/9821126370',
    Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-1539304887624918/4571289807',
  ];

  static const AdRequest request = AdRequest();

  @override
  void initState() {
    super.initState();
    _createRewardedAd(0);
    _createRewardedAd(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          SizedBox(height: 36.w),
          const CommonPointInfo(),
          SizedBox(height: 36.w),
          StoreListTile(
            title: Text(Intl.message('label_button_watch_and_charge'),
                style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '+${Intl.message('label_bonus')} 1',
                      style:
                          getTextStyle(AppTypo.CAPTION12B, AppColors.Point900)),
                ],
              ),
            ),
            buttonText: Intl.message('label_watch_ads'),
            buttonOnPressed: () async {
              if (_rewardedAds[0] == null) {
                await _createRewardedAd(0);
              }
              _showRewardedAd(0);
            },
            isLoading: _isLoading[0],
          ),
          Divider(height: 32.w, thickness: 1, color: AppColors.Grey200),
          StoreListTile(
            title: Text(Intl.message('label_button_watch_and_charge'),
                style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '+${Intl.message('label_bonus')} 1',
                      style:
                          getTextStyle(AppTypo.CAPTION12B, AppColors.Point900)),
                ],
              ),
            ),
            buttonText: Intl.message('label_watch_ads'),
            buttonOnPressed: () async {
              if (_rewardedAds[1] == null) {
                await _createRewardedAd(1);
              }
              _showRewardedAd(1);
            },
            isLoading: _isLoading[1],
          ),
          Divider(height: 32.w, thickness: 1, color: AppColors.Grey200),
          GestureDetector(
            onTap: () {
              showSimpleDialog(
                context: context,
                title: Intl.message('text_star_candy_usage_policy_title'),
                contentWidget: Markdown(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    data: Intl.message('text_star_candy_usage_policy')),
              );
            },
            child: Text(Intl.message('text_star_candy_usage_policy_guide'),
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          ),
        ],
      ),
    );
  }

  Future<void> _createRewardedAd(int index) async {
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
            _isLoading[index] = true;
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
          title: Intl.message('text_dialog_star_candy_received'),
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
  }
}
