import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/bullet_point.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/ad_providers.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';

class FreeChargeStation extends ConsumerStatefulWidget {
  const FreeChargeStation({super.key});
  @override
  ConsumerState<FreeChargeStation> createState() => _FreeChargeStationState();
}

class _FreeChargeStationState extends ConsumerState<FreeChargeStation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonScaleAnimation = Tween<double>(begin: .5, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndLoadAds());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkAndLoadAds() {
    final adsState = ref.read(rewardedAdsProvider);
    for (int i = 0; i < adsState.ads.length; i++) {
      if (adsState.ads[i].ad == null &&
          !adsState.ads[i].isLoading &&
          !adsState.ads[i].isShowing) {
        ref.read(rewardedAdsProvider.notifier).loadAd(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(rewardedAdsProvider);
    return _buildContent(adState);
  }

  Widget _buildContent(AdState adState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          SizedBox(height: 36.w),
          StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 100.h),
          SizedBox(height: 36.h),
          _buildStoreListTile(0),
          Divider(height: 32.h, thickness: 1, color: AppColors.Grey200),
          _buildStoreListTile(1),
          Divider(height: 32.h, thickness: 1, color: AppColors.Grey200),
          GestureDetector(
            onTap: () => _showUsagePolicyDialog(context),
            child: Text(S.of(context).candy_usage_policy_guide,
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          ),
        ],
      ),
    );
  }

  void _showUsagePolicyDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(48).r,
            topRight: const Radius.circular(48).r,
          ),
        ),
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    S.of(context).candy_disappear_next_month,
                    style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
                  ),
                  SizedBox(height: 12.h),
                  FutureBuilder(
                      future: ref.read(expireBonusProvider.future),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/icons/store/star_100.png',
                                  width: 48.w, height: 48.w),
                              snapshot.data == null
                                  ? Text(
                                      '0',
                                      style: getTextStyle(
                                          AppTypo.BODY16B, AppColors.Grey900),
                                    )
                                  : Text(
                                      '${snapshot.data}',
                                      style: getTextStyle(
                                          AppTypo.BODY16B, AppColors.Grey900),
                                    ),
                            ],
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      }),
                  SizedBox(height: 48.h),
                  BulletPoint(
                    S.of(context).candy_usage_policy_contents,
                  ),
                  SizedBox(height: 48.h),
                  BulletPoint(
                    S.of(context).candy_usage_policy_contents2,
                  ),
                ]),
              ),
            ));
  }

  Widget _buildStoreListTile(int index) {
    final adState = ref.watch(rewardedAdsProvider);
    final userState = ref.watch(userInfoProvider);
    final adInfo = adState.ads[index];
    bool isLoading = adInfo.isLoading;
    // logger.i('index: $index, isLoading: $isLoading');

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return StoreListTile(
          index: index,
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
          buttonText: isLoading
              ? S.of(context).label_loading_ads
              : S.of(context).label_watch_ads,
          buttonOnPressed: isLoading
              ? null
              : () {
                  if (userState.value == null) {
                    showRequireLoginDialog(context: context);
                  } else {
                    _showRewardedAd(index);
                  }
                },
          isLoading: isLoading,
          buttonScale: _buttonScaleAnimation.value,
        );
      },
    );
  }

  void _showRewardedAd(int index) async {
    // logger.i("Calling showAd for index $index");

    if (!mounted) return;
    final adProvider = ref.read(rewardedAdsProvider.notifier);

    logger.i("Calling showAd for index $index");
    await adProvider.loadAd(index, showWhenLoaded: true, context: context);

    _animateButton();
  }

  void _animateButton() {
    _animationController.forward(from: 0.0);
  }
}
