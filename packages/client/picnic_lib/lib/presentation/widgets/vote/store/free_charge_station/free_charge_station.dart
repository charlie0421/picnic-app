// free_charge_station.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/common/ads/banner_ad_widget.dart';
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
    _setupAnimation();
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

  @override
  Widget build(BuildContext context) {
    return FreeChargeContent(
      buttonScaleAnimation: _buttonScaleAnimation,
      onPolicyTap: () => showUsagePolicyDialog(context, ref),
      onAdButtonPressed: _showRewardedAdmob,
    );
  }
}

class FreeChargeContent extends ConsumerWidget {
  final Animation<double> buttonScaleAnimation;
  final VoidCallback onPolicyTap;
  final Function(int) onAdButtonPressed;
  final VoidCallback? onRetryBannerAd;

  const FreeChargeContent({
    super.key,
    required this.buttonScaleAnimation,
    required this.onPolicyTap,
    required this.onAdButtonPressed,
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
            const SizedBox(height: 36),
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
          _buildMissionSection(context),
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

  Widget _buildMissionSection(BuildContext context) {
    return StoreListTile(
      title: Text(
        S.of(context).label_button_mission_and_charge,
        style: getTextStyle(AppTypo.body14B, AppColors.grey900)
            .copyWith(height: 1),
      ),
      buttonOnPressed: () async {
        Tapjoy.setUserID(
            userId: supabase.auth.currentUser!.id,
            onSetUserIDSuccess: () => logger
                .i('setUserID onSuccess: ${supabase.auth.currentUser!.id}'),
            onSetUserIDFailure: (error) =>
                logger.e('setUserID onFailure', error: error));

        TJPlacement placement = await TJPlacement.getPlacement(
          placementName: 'mission',
          onRequestSuccess: (placement) async {
            logger.i('onRequestSuccess');
          },
          onRequestFailure: (placement, error) =>
              logger.e('onRequestFailure', error: error),
          onContentReady: (placement) {
            logger.i('onContentReady');
            placement.showContent();
          },
          onContentShow: (placement) => logger.i('onContentShow'),
          onContentDismiss: (placement) => logger.i('onContentDismiss'),
        );
        placement.setEntryPoint(TJEntryPoint.entryPointStore);

        await placement.requestContent();
      },
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
