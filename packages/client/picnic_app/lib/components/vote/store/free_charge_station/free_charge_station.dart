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
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class FreeChargeStation extends ConsumerStatefulWidget {
  const FreeChargeStation({super.key});
  @override
  ConsumerState<FreeChargeStation> createState() => _FreeChargeStationState();
}

class _FreeChargeStationState extends ConsumerState<FreeChargeStation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;
  final Map<String, BannerAd?> _bannerAds = {};

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
    _loadBannerAds();
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

  Future<void> _loadBannerAds() async {
    final configService = ref.read(configServiceProvider);
    final adUnitId = isIOS()
        ? await configService.getConfig('ADMOB_IOS_FREE_CHARGE_STATION')
        : await configService.getConfig('ADMOB_ANDROID_FREE_CHARGE_STATION');

    _loadBannerAd('free_charge_station', adUnitId!, AdSize.banner);
  }

  void _loadBannerAd(String position, String adUnitId, AdSize size) {
    _bannerAds[position] = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAds[position] = null;
        },
      ),
    )..load();
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading banner'));
                  }
                  return Center(
                    child: _bannerAds['free_charge_station'] != null
                        ? AdWidget(ad: _bannerAds['free_charge_station']!)
                        : UnityBannerAd(
                            placementId: snapshot.data as String,
                            onLoad: (placementId) =>
                                print('Banner loaded: $placementId'),
                            onClick: (placementId) =>
                                print('Banner clicked: $placementId'),
                            onShown: (placementId) =>
                                print('Banner shown: $placementId'),
                            onFailed: (placementId, error, message) => print(
                                'Banner Ad $placementId failed: $error $message'),
                          ),
                  );
                }),
          ),
          const SizedBox(height: 18),
          _buildStoreListTileAdmob(0),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildStoreListTileAdmob(1),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildStoreListTileUnity(2),
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
              : () {
                  if (userState.value == null) {
                    showRequireLoginDialog(context: context);
                  } else {
                    switch (index) {
                      case 0:
                      case 1:
                        _showRewardedAdmob(index);
                        break;
                      case 2:
                        _showRewaredUnity(index);
                        break;
                      default:
                        break;
                    }
                  }
                },
          isLoading: isLoading,
          buttonScale: _buttonScaleAnimation.value,
        );
      },
    );
  }

  Widget _buildStoreListTileUnity(int index) {
    final userState = ref.watch(userInfoProvider);
    bool isLoading = false;
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
              : () {
                  if (userState.value == null) {
                    showRequireLoginDialog(context: context);
                  } else {
                    switch (index) {
                      case 0:
                      case 1:
                        _showRewardedAdmob(index);
                        break;
                      case 2:
                        _showRewaredUnity(index);
                        break;
                      default:
                        break;
                    }
                  }
                },
          isLoading: isLoading,
          buttonScale: _buttonScaleAnimation.value,
        );
      },
    );
  }

  void _showRewardedAdmob(int index) async {
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
      rethrow;
    } finally {}
  }

  void _showRewaredUnity(int index) async {
    OverlayLoadingProgress.start(context);
    final configService = ref.read(configServiceProvider);

    String? placementId = isIOS()
        ? await configService.getConfig('UNITY_IOS_PLACEMENT1')
        : await configService.getConfig('UNITY_ANDROID_PLACEMENT1');

    try {
      placementId = placementId ?? '';
      UnityAds.load(
        placementId: placementId,
        onComplete: (placementId) {
          logger.i('Load Complete $placementId');
          UnityAds.showVideoAd(
            placementId: placementId,
            serverId: supabase.auth.currentUser?.id,
            onStart: (placementId) {
              logger.i('Video Ad $placementId started');
            },
            onClick: (placementId) {
              logger.i('Video Ad $placementId click');
              OverlayLoadingProgress.stop();
            },
            onSkipped: (placementId) {
              logger.i('Video Ad $placementId skipped');
              OverlayLoadingProgress.stop();
            },
            onComplete: (placementId) async {
              logger.i('Video Ad $placementId completed');
              await supabase.functions.invoke(
                'reward-unity',
              );
              ref.read(userInfoProvider.notifier).getUserProfiles();
              OverlayLoadingProgress.stop();
              showSimpleDialog(
                content: S.of(context).text_dialog_star_candy_received,
                onOk: () {
                  Navigator.of(context).pop();
                },
              );
            },
            onFailed: (placementId, error, message) {
              logger.i('Video Ad $placementId failed: $error $message');
              OverlayLoadingProgress.stop();
              showSimpleDialog(
                content: S.of(context).text_dialog_ad_failed_to_show,
                onOk: () {
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
        onFailed: (placementId, error, message) {
          logger.i('Load Failed $placementId: $error $message');
          OverlayLoadingProgress.stop();
          showSimpleDialog(
            content: S.of(context).text_dialog_ad_failed_to_show,
            onOk: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      rethrow;
    }
  }

  void _animateButton() {
    _animationController.forward(from: 0.0);
  }
}
