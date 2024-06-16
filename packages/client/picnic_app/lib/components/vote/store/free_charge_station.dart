import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
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
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  static const AdRequest request = AdRequest();

  @override
  void initState() {
    super.initState();
    _createRewardedAd();
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
          CommonListTile(
            title: Text('광고 시청하고 충전하기',
                style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
            // subtitle: Text.rich(
            //   TextSpan(
            //     children: [
            //       TextSpan(
            //           text: '+보너스 50',
            //           style:
            //               getTextStyle(AppTypo.CAPTION12B, AppColors.Point900)),
            //     ],
            //   ),
            // ),
            buttonText: '시청하기',
            buttonOnPressed: () async {
              if (_rewardedAd == null) {
                await _createRewardedAd();
              }

              _showRewardedAd();
            },
          ),
          Divider(height: 32.w, thickness: 1, color: AppColors.Grey200),
        ],
      ),
    );
  }

  Future<void> _createRewardedAd() async {
    await RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/5224354917'
            : 'ca-app-pub-1539304887624918/9821126370',
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        ref.read(userInfoProvider.notifier).getUserProfiles();

        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    logger.i(ref.read(userInfoProvider).value?.id);
    ServerSideVerificationOptions options = ServerSideVerificationOptions(
      userId: ref.watch(userInfoProvider).value?.id.toString(),
      customData: '{"reward_type":"free_charge_station"}',
    );
    _rewardedAd?.setServerSideOptions(options);

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      ref.read(userInfoProvider.notifier).getUserProfiles();
      print('User earned reward of ${reward.amount} ${reward.type}');
    });
    _rewardedAd = null;
  }
}

class CommonListTile extends StatelessWidget {
  const CommonListTile(
      {super.key,
      required this.title,
      this.subtitle,
      required this.buttonText,
      required this.buttonOnPressed});

  final Text title;
  final Text? subtitle;
  final String buttonText;
  final Function buttonOnPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
              width: 48.w,
              height: 48.w,
              child: Image.asset('assets/icons/header/star.png',
                  width: 24.w, height: 24.w)),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, subtitle ?? Container()],
            ),
          ),
          ElevatedButton(
            onPressed: () => buttonOnPressed(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
