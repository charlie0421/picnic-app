import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_section_header.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_surface.dart';

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
            StorePointInfo(
              title: AppLocalizations.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 120,
              refreshController: rotationController,
              onRefresh: () {
                rotationController.forward(from: 0);
                ref.read(userInfoProvider.notifier).getUserProfiles();
                ref.read(walletSummaryProvider.notifier).refresh();
              },
            ),
            const SizedBox(height: 16),
          ],
          if (!isLogged) const SizedBox(height: 8),

          // 미션 섹션
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).label_mission_get_bonus_star_candy,
          ),
          const SizedBox(height: 4),
          _buildItemsList(missions, context, loadingState),

          const SizedBox(height: 16),

          // 광고 섹션
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).label_ads_get_cotton_candy,
          ),
          const SizedBox(height: 4),
          _buildItemsList(ads, context, loadingState),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return PicnicSectionHeader(title: title);
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

    return PicnicSurface(
      key: ValueKey('free-charge-${item.id}'),
      radius: 8,
      color: AppColors.grey100,
      padding: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(12),
        vertical: PicnicUi.vertical(8),
      ),
      child: StoreListTile(
        flexibleHeight: true,
        index: item.isMission ? null : item.index,
        title: Text(
          item.title,
          style: PicnicUi.text(size: 14, weight: FontWeight.w600),
        ),
        buttonText: _getButtonText(item, isLoading, context),
        buttonOnPressed: isLoading ? null : item.onPressed,
        isLoading: isLoading,
        icon: Image.asset(
          package: 'picnic_lib',
          item.isMission
              ? 'assets/icons/store/currency_bonus_star_candy.png'
              : 'assets/icons/store/currency_cotton_candy.png',
          width: 40.w,
          height: 40.w,
        ),
        subtitle: item.bonusText.isNotEmpty
            ? Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: item.isMission
                          ? AppLocalizations.of(
                              context,
                            ).free_charge_mission_reward(item.bonusText)
                          : AppLocalizations.of(
                              context,
                            ).free_charge_ads_reward(item.bonusText),
                      style: PicnicUi.text(
                        size: 12,
                        weight: FontWeight.w600,
                        color: PicnicUi.secondaryText,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  String _getButtonText(
    ChargeStationItem item,
    bool isLoading,
    BuildContext context,
  ) {
    if (isLoading) {
      return AppLocalizations.of(context).label_loading_ads;
    }

    if (item.isMission) {
      return AppLocalizations.of(context).label_mission_short;
    }

    return AppLocalizations.of(context).label_watch_ads_short;
  }
}
