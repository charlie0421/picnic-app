import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/components/vote/common-vote-info.dart';
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

  static final AdRequest request = AdRequest();

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
          SizedBox(height: 36.h),
          CommonPointInfo(point: 100),
          SizedBox(height: 36.h),
          CommonListTile(
            title: Text('광고 시청하고 충전하기',
                style: getTextStyle(AppTypo.BODY16B, AppColors.Gray900)),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '+보너스 50',
                      style:
                          getTextStyle(AppTypo.CAPTION12B, AppColors.Point900)),
                ],
              ),
            ),
            buttonText: '시청하기',
            buttonOnPressed: () async {
              if (_rewardedAd == null) {
                await _createRewardedAd();
              }

              _showRewardedAd();
            },
          ),
          Divider(height: 32.h, thickness: 1, color: AppColors.Gray200),
        ],
      ),
    );
  }

  Future<void> _createRewardedAd() async {
    await RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/5224354917'
            : 'ca-app-pub-3940256099942544/1712485313',
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
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
    });
    _rewardedAd = null;
  }
}

class CommonListTile extends StatelessWidget {
  const CommonListTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.buttonText,
      required this.buttonOnPressed});

  final Text title;
  final Text subtitle;
  final String buttonText;
  final Function buttonOnPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
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
              children: [
                title,
                subtitle,
              ],
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
