import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/components/vote/store/usage_policy_dialog.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/ad_providers.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView(
        children: [
          if (supabase.isLogged) ...[
            const SizedBox(height: 36),
            StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 70,
            ),
          ],
          const SizedBox(height: 36),
          _buildStoreListTile(0),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildStoreListTile(1),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          GestureDetector(
            onTap: () => showUsagePolicyDialog(context, ref),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: S.of(context).candy_usage_policy_guide,
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: S.of(context).candy_usage_policy_guide_button,
                    style: getTextStyle(AppTypo.caption12B, AppColors.grey600)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            style: getTextStyle(AppTypo.body14B, AppColors.grey900)
                .copyWith(height: 1),
          ),
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '+${S.of(context).label_bonus} 1',
                  style: getTextStyle(AppTypo.caption12B, AppColors.point900),
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
    try {
      // logger.i("Calling showAd for index $index");

      OverlayLoadingProgress.start(context);

      final response =
          await supabase.functions.invoke('check-ads-count', body: {});
      OverlayLoadingProgress.stop();

      logger.i(
          'allowed: ${response.data['allowed']}\n message: ${response.data['message']}\n nextAvailableTime: ${response.data['nextAvailableTime']}\n hourlyCount: ${response.data['hourlyCount']}\n dailyCount: ${response.data['dailyCount']}\n hourlyLimit: ${response.data['hourlyLimit']}\n dailyLimit: ${response.data['dailyLimit']}');
      if (response.data['allowed'] == true) {
        final adProvider = ref.read(rewardedAdsProvider.notifier);

        logger.i("Calling showAd for index $index");
        await adProvider.loadAd(index, showWhenLoaded: true, context: context);

        _animateButton();
      } else {
        final nextAvailableTime =
            DateTime.parse(response.data['nextAvailableTime']).toLocal();
        DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

        showSimpleDialog(
            contentWidget: Column(
          children: [
            Text(
              S.of(context).label_ads_exceeded,
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '다음 광고 시청 가능시간',
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
              textAlign: TextAlign.center,
            ),
            Text(
              formatter.format(nextAvailableTime).toString(),
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
              textAlign: TextAlign.center,
            ),
          ],
        ));
      }
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
    } finally {}
  }

  void _animateButton() {
    _animationController.forward(from: 0.0);
  }
}
