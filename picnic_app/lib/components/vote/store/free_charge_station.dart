import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/components/common/simple_dialog.dart';
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
          CommonListTile(
            title: Text('시청하고 충전하기',
                style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '+보너스 1',
                      style:
                          getTextStyle(AppTypo.CAPTION12B, AppColors.Point900)),
                ],
              ),
            ),
            buttonText: '시청하기',
            buttonOnPressed: () async {
              if (_rewardedAds[0] == null) {
                await _createRewardedAd(0);
              }
              _showRewardedAd(0);
            },
            isLoading: _isLoading[0],
          ),
          Divider(height: 32.w, thickness: 1, color: AppColors.Grey200),
          CommonListTile(
            title: Text('시청하고 충전하기',
                style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '+보너스 1',
                      style:
                          getTextStyle(AppTypo.CAPTION12B, AppColors.Point900)),
                ],
              ),
            ),
            buttonText: '시청하기',
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
                title: '별사탕 사용 정책',
                contentWidget: const Markdown(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  data: """
### 유효기간

- 구매 별사탕 : 없음 (무제한)
- 보너스 별사탕 : 획득한 다음 달 15일에 일괄 소멸

### 별사탕 사용

- 소멸일자가 임박한 별사탕부터 사용됩니다.
- 유효기간이 동일한 경우, 그 중 획득일자가 빠른 순으로 사용됩니다.
                  """,
                ),
              );
            },
            child: Text('보너스는 획득한 다음달에 사라져요! ⓘ',
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
          title: '별사탕이 지급되었어요!!',
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

class CommonListTile extends StatelessWidget {
  const CommonListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.buttonOnPressed,
    required this.isLoading,
  });

  final Text title;
  final Text? subtitle;
  final String buttonText;
  final Function buttonOnPressed;
  final bool isLoading;

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
            child: Image.asset(
              'assets/icons/header/star.png',
              width: 24.w,
              height: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, subtitle ?? Container()],
            ),
          ),
          SizedBox(
            height: 32.w,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => buttonOnPressed(),
              child: isLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        color: AppColors.Primary500,
                      ),
                    )
                  : Text(
                      buttonText,
                      style:
                          getTextStyle(AppTypo.BODY14B, AppColors.Primary500),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
