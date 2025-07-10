import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/ui/style.dart';

class FreeChargeContent extends ConsumerWidget {
  final Animation<double> buttonScaleAnimation;
  final VoidCallback onPolicyTap;
  final Function(BuildContext) missionItemBuilder;
  final Function(BuildContext) adItemBuilder;
  final VoidCallback onPincruxOfferwallPressed;
  final VoidCallback? onRetryBannerAd;
  final AnimationController rotationController;

  const FreeChargeContent({
    super.key,
    required this.buttonScaleAnimation,
    required this.onPolicyTap,
    required this.missionItemBuilder,
    required this.adItemBuilder,
    required this.onPincruxOfferwallPressed,
    required this.rotationController,
    this.onRetryBannerAd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(adLoadingStateProvider);
    final userInfo = ref.watch(userInfoProvider);
    final isLogged = userInfo.value != null;

    // 미션과 광고 아이템 목록 생성
    final missions = missionItemBuilder(context);
    final ads = adItemBuilder(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView(
        children: [
          if (isLogged) ...[
            const SizedBox(height: 16),
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
                    width: 24,
                    height: 24,
                    colorFilter:
                        ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            StorePointInfo(
              title: AppLocalizations.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 80,
            ),
          ],
          const SizedBox(height: 12),

          // 미션 섹션
          _buildSectionHeader(context,
              AppLocalizations.of(context).label_mission_get_star_candy),
          const SizedBox(height: 4),
          _buildItemsList(missions, context, loadingState),

          const SizedBox(height: 16),

          // 광고 섹션
          _buildSectionHeader(
              context, AppLocalizations.of(context).label_ads_get_star_candy),
          const SizedBox(height: 4),
          _buildItemsList(ads, context, loadingState),

          const SizedBox(height: 12),
          const Divider(height: 12, thickness: 1, color: AppColors.grey200),
          _buildPolicyGuide(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: getTextStyle(AppTypo.body14B, AppColors.grey900),
        ),
        const SizedBox(height: 2),
        const Divider(height: 1, thickness: 1, color: AppColors.grey200),
      ],
    );
  }

  Widget _buildItemsList(
    List<ChargeStationItem> items,
    BuildContext context,
    Map<String, bool> loadingState,
  ) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Column(
          children: [
            if (index > 0)
              const Divider(height: 12, thickness: 1, color: AppColors.grey200),
            _buildStationItem(item, context, loadingState),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStationItem(
    ChargeStationItem item,
    BuildContext context,
    Map<String, bool> loadingState,
  ) {
    // 광고 로딩 상태 확인
    bool isLoading = loadingState[item.id] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
      child: StoreListTile(
        index: item.isMission ? null : item.index,
        title: Text(
          item.title,
          style: getTextStyle(AppTypo.caption12B, AppColors.grey900)
              .copyWith(height: 1),
        ),
        buttonText: _getButtonText(item, isLoading, context),
        buttonOnPressed: isLoading ? null : item.onPressed,
        isLoading: isLoading,
        icon: Image.asset(
          package: 'picnic_lib',
          'assets/icons/store/star_100.png',
          width: 40.w,
          height: 40.w,
        ),
        subtitle: item.bonusText.isNotEmpty
            ? Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '+${AppLocalizations.of(context).label_bonus} ${item.bonusText}',
                      style:
                          getTextStyle(AppTypo.caption12B, AppColors.point900),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  String _getButtonText(
      ChargeStationItem item, bool isLoading, BuildContext context) {
    if (isLoading) {
      return AppLocalizations.of(context).label_loading_ads;
    }

    if (item.isMission) {
      return AppLocalizations.of(context).label_mission_short;
    }

    return AppLocalizations.of(context).label_watch_ads_short;
  }

  Widget _buildPolicyGuide(BuildContext context) {
    return GestureDetector(
      onTap: onPolicyTap,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: AppLocalizations.of(context).candy_usage_policy_guide,
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text:
                  AppLocalizations.of(context).candy_usage_policy_guide_button,
              style: getTextStyle(AppTypo.caption12B, AppColors.grey600)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
}
