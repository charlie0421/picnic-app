// free_charge_station.dart
// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/pincruxOfferwallPlugin.dart';
import 'package:picnic_lib/presentation/common/ads/banner_ad_widget.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/data/models/ad_info.dart';
import 'package:picnic_lib/presentation/providers/ad_providers.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:universal_io/io.dart';

class FreeChargeStation extends ConsumerStatefulWidget {
  const FreeChargeStation({super.key});

  @override
  ConsumerState<FreeChargeStation> createState() => _FreeChargeStationState();
}

class _FreeChargeStationState extends ConsumerState<FreeChargeStation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonScaleAnimation = Tween<double>(begin: .5, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showSimpleDialog(
      contentWidget: Text(message,
          style: getTextStyle(AppTypo.body14M, AppColors.grey900)),
    );
  }

  Future<void> _showRewardedAdmob(int index) async {
    final userState = ref.read(userInfoProvider);
    if (userState.value == null) {
      if (mounted) showRequireLoginDialog();
      return;
    }

    try {
      if (mounted) OverlayLoadingProgress.start(context);

      final response = await supabase.functions.invoke('check-ads-count');
      if (!mounted) return;
      OverlayLoadingProgress.stop();

      final allowed = response.data['allowed'] as bool?;
      if (allowed != true) {
        _handleExceededAdsLimit(response.data['nextAvailableTime']);
        return;
      }

      if (!mounted) return;
      ref
          .read(rewardedAdsProvider.notifier)
          .loadAd(index, showWhenLoaded: true, context: context);
      _animateButton();
    } catch (e, s) {
      logger.e('Error in _showRewardedAdmob', error: e, stackTrace: s);
      if (mounted) _showErrorDialog(Intl.message('label_loading_ads_fail'));
    } finally {
      if (mounted) OverlayLoadingProgress.stop();
    }
  }

  void _handleExceededAdsLimit(String? nextAvailableTimeStr) {
    if (nextAvailableTimeStr == null) return;

    final nextAvailableTime = DateTime.parse(nextAvailableTimeStr).toLocal();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    showSimpleDialog(
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context).label_ads_exceeded,
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(S.of(context).ads_available_time,
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
              textAlign: TextAlign.center),
          Text(formatter.format(nextAvailableTime),
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _animateButton() {
    _animationController.forward(from: 0.0);
  }

  Future<void> _showTapjoyMission() async {
    final userState = ref.read(userInfoProvider);
    if (userState.value == null) {
      if (mounted) showRequireLoginDialog();
      return;
    }

    try {
      if (mounted) OverlayLoadingProgress.start(context);

      Tapjoy.setUserID(
          userId: supabase.auth.currentUser!.id,
          onSetUserIDSuccess: () =>
              logger.i('setUserID onSuccess: ${supabase.auth.currentUser!.id}'),
          onSetUserIDFailure: (error) =>
              logger.e('setUserID onFailure', error: error));

      TJPlacement placement = await TJPlacement.getPlacement(
        placementName: 'mission',
        onRequestSuccess: (placement) async {
          logger.i('onRequestSuccess');
        },
        onRequestFailure: (placement, error) {
          logger.e('onRequestFailure', error: error);
          if (mounted) OverlayLoadingProgress.stop();
        },
        onContentReady: (placement) {
          logger.i('onContentReady');
          placement.showContent();
        },
        onContentShow: (placement) {
          logger.i('onContentShow');
        },
        onContentDismiss: (placement) {
          logger.i('onContentDismiss');
          if (mounted) OverlayLoadingProgress.stop();
        },
      );
      placement.setEntryPoint(TJEntryPoint.entryPointStore);

      await placement.requestContent();
    } catch (e, s) {
      logger.e('Error in _showTapjoyMission', error: e, stackTrace: s);
      if (mounted) _showErrorDialog(Intl.message('label_loading_mission_fail'));
    } finally {}
  }

  Future<void> _showPincruxOfferwall() async {
    logger.i('showPincruxOfferwall');
    try {
      PincruxOfferwallPlugin.init(
          Platform.isIOS
              ? Environment.pincruxIosAppKey
              : Environment.pincruxAndroidAppKey,
          supabase.auth.currentUser!.id);
      PincruxOfferwallPlugin.setOfferwallType(1);
      PincruxOfferwallPlugin.startPincruxOfferwall();
    } catch (e, s) {
      logger.e('Error in _showPincruxOfferwall', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FreeChargeContent(
      buttonScaleAnimation: _buttonScaleAnimation,
      onPolicyTap: () => showUsagePolicyDialog(context, ref),
      onAdButtonPressed: _showRewardedAdmob,
      onTajoyPressed: _showTapjoyMission,
      onPincruxOfferwallPressed: _showPincruxOfferwall,
      rotationController: _rotationController,
    );
  }
}

class FreeChargeContent extends ConsumerWidget {
  final Animation<double> buttonScaleAnimation;
  final VoidCallback onPolicyTap;
  final Function(int) onAdButtonPressed;
  final VoidCallback onTajoyPressed;
  final VoidCallback onPincruxOfferwallPressed;
  final VoidCallback? onRetryBannerAd;
  final AnimationController rotationController;

  const FreeChargeContent({
    super.key,
    required this.buttonScaleAnimation,
    required this.onPolicyTap,
    required this.onAdButtonPressed,
    required this.onTajoyPressed,
    required this.onPincruxOfferwallPressed,
    required this.rotationController,
    this.onRetryBannerAd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(rewardedAdsProvider);
    final isLogged = supabase.isLogged;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      child: ListView(
        children: [
          if (isLogged) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  rotationController.forward(from: 0);
                  ref.read(userInfoProvider.notifier).getUserProfiles();
                },
                child: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: rotationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: SvgPicture.asset(
                    package: 'picnic_lib',
                    'assets/icons/reset_style=line.svg',
                    width: 30,
                    height: 30,
                    colorFilter:
                        ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 90,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: BannerAdWidget(
              configKey: 'FREE_CHARGE_STATION',
              adSize: AdSize.fullBanner,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildMissionTapjoy(ref, context),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildMissionPincrux(ref, context),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildStoreListTileAdmob(context, 0, adState),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildStoreListTileAdmob(context, 1, adState),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildPolicyGuide(),
        ],
      ),
    );
  }

  Widget _buildMissionTapjoy(ref, BuildContext context) {
    return StoreListTile(
      title: Text(
        '${S.of(context).label_button_mission_and_charge} #1',
        style: getTextStyle(AppTypo.body14B, AppColors.grey900)
            .copyWith(height: 1),
      ),
      buttonOnPressed: onTajoyPressed,
      icon: Image.asset(
        package: 'picnic_lib',
        'assets/icons/store/star_100.png',
        width: 48.cw,
        height: 48.cw,
      ),
      buttonText: S.of(context).label_mission,
    );
  }

  Widget _buildMissionPincrux(ref, BuildContext context) {
    return StoreListTile(
      title: Text(
        '${S.of(context).label_button_mission_and_charge} #2',
        style: getTextStyle(AppTypo.body14B, AppColors.grey900)
            .copyWith(height: 1),
      ),
      buttonOnPressed: onPincruxOfferwallPressed,
      icon: Image.asset(
        package: 'picnic_lib',
        'assets/icons/store/star_100.png',
        width: 48.cw,
        height: 48.cw,
      ),
      buttonText: S.of(context).label_mission,
    );
  }

  Widget _buildStoreListTileAdmob(
      BuildContext context, int index, AdState adState) {
    final adInfo = adState.ads[index];
    final isLoading = adInfo.isLoading;

    return StoreListTile(
      index: index,
      icon: Image.asset(
        package: 'picnic_lib',
        'assets/icons/store/star_100.png',
        width: 48.cw,
        height: 48.cw,
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
      buttonOnPressed: isLoading ? null : () => onAdButtonPressed(index),
      isLoading: isLoading,
      buttonScale: buttonScaleAnimation.value,
    );
  }

  Widget _buildPolicyGuide() {
    return GestureDetector(
      onTap: onPolicyTap,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: Intl.message('candy_usage_policy_guide'),
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: Intl.message('candy_usage_policy_guide_button'),
              style: getTextStyle(AppTypo.caption12B, AppColors.grey600)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
}
