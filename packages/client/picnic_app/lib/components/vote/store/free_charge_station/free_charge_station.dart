import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/vote/store/common/store_point_info.dart';
import 'package:picnic_app/components/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_app/components/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_app/config/config_service.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/ad_providers.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
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
  BannerAd? _bannerAd;

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

    // 배너 광고 미리 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBannerAd());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    try {
      final configService = ref.read(configServiceProvider);
      final adUnitId = isIOS()
          ? await configService.getConfig('ADMOB_IOS_FREE_CHARGE_STATION')
          : await configService.getConfig('ADMOB_ANDROID_FREE_CHARGE_STATION');

      if (adUnitId == null) throw Exception('Ad unit ID is null');

      late final BannerAd bannerAd;
      bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() => _bannerAd = bannerAd);
            }
          },
          onAdFailedToLoad: (ad, error) {
            logger.e('Banner ad failed to load: $error');
            ad.dispose();
            if (mounted) {
              setState(() => _bannerAd = null);
            }
          },
        ),
      );

      await bannerAd.load();
    } catch (e, s) {
      logger.e('Error loading banner ad', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(rewardedAdsProvider);
    return _buildContent(adState);
  }

  Widget _buildContent(AdState adState) {
    final configService = ref.read(configServiceProvider);
    Future<String?> placementId = isIOS()
        ? configService.getConfig('UNITY_IOS_BANNER1')
        : configService.getConfig('UNITY_ANDROID_BANNER1');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      child: ListView(
        children: [
          if (supabase.isLogged) ...[
            const SizedBox(height: 36),
            StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 90,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FutureBuilder(
              future: placementId,
              builder: (context, snapshot) {
                if (_bannerAd == null) {
                  return buildLoadingOverlay();
                }
                return Center(child: AdWidget(ad: _bannerAd!));
              },
            ),
          ),
          const SizedBox(height: 18),
          _buildStoreListTileAdmob(0),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildStoreListTileAdmob(1),
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

  Widget _buildStoreListTileAdmob(int index) {
    final userState = ref.watch(userInfoProvider);
    final adState = ref.watch(rewardedAdsProvider);
    final adInfo = adState.ads[index];
    final isLoading = adInfo.isLoading;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return StoreListTile(
          index: index,
          icon: Image.asset(
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
          buttonOnPressed: isLoading
              ? null
              : () async {
                  if (userState.value == null) {
                    showRequireLoginDialog();
                    return;
                  }
                  final loadingFailMessage =
                      S.of(context).label_loading_ads_fail;

                  try {
                    await _showRewardedAdmob(index);
                  } catch (e, s) {
                    logger.e('Error showing rewarded ad',
                        error: e, stackTrace: s);
                    showSimpleDialog(
                      contentWidget: Text(
                        loadingFailMessage,
                        style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                      ),
                    );
                  }
                },
          isLoading: isLoading,
          buttonScale: _buttonScaleAnimation.value,
        );
      },
    );
  }

  Future<void> _showRewardedAdmob(int index) async {
    try {
      OverlayLoadingProgress.start(context);

      final response = await supabase.functions.invoke('check-ads-count');

      if (!mounted) return;
      OverlayLoadingProgress.stop();

      final allowed = response.data['allowed'] as bool?;
      if (allowed != true) {
        final nextAvailableTime =
            DateTime.parse(response.data['nextAvailableTime'] ?? '').toLocal();
        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

        if (!mounted) return;
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
                S.of(context).ads_available_time,
                style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                textAlign: TextAlign.center,
              ),
              Text(
                formatter.format(nextAvailableTime),
                style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
        return;
      }

      // 리워드 광고는 클릭 시에 로딩
      final adProvider = ref.read(rewardedAdsProvider.notifier);
      await adProvider.loadAd(index, showWhenLoaded: true, context: context);
      _animateButton();
    } catch (e, s) {
      logger.e('Error in _showRewardedAdmob', error: e, stackTrace: s);
      rethrow;
    }
  }

  void _animateButton() {
    _animationController.forward(from: 0.0);
  }
}
