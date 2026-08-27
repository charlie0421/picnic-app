// free_charge_station.dart
// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/pangle_ads.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/ad_info.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/pincruxOfferwallPlugin.dart';
import 'package:picnic_lib/presentation/common/ads/banner_ad_widget.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:universal_io/io.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_overlay.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_order.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart';

/// G3: AdMob 구좌를 노출할지 여부.
///
/// AdMob 플랫폼 설정이 실제로 갖춰졌을 때 노출한다.
@visibleForTesting
bool shouldShowDebugAdmobItem({
  required bool isDebugMode,
  required bool isAdmobAvailable,
}) {
  return isAdmobAvailable;
}

// 광고 플랫폼 추상 클래스
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
  late AdService _adService;
  bool _isInitializing = false;

  /// 버튼 연타로 click_mission / ad_request 가 중복 발송되는 것을 막는다.
  /// 광고 호출 자체는 억제하지 않고 로깅만 걸러낸다.
  final Ga4ClickDebounce _ga4ClickDebounce = Ga4ClickDebounce();

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adService = AdService(
      ref: ref,
      context: context,
      animationController: _animationController,
    );

    // 컨텍스트가 유효할 때 광고 플랫폼 초기화
    if (!_isInitializing) {
      _isInitializing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeAdPlatforms();
      });
    }
  }

  // 광고 플랫폼 초기화 메서드
  Future<void> _initializeAdPlatforms() async {
    try {
      await AdLoadingOverlay.start(context);
      // 모든 광고 플랫폼 초기화
      await _adService.initializeAllPlatforms();
    } catch (e, s) {
      logger.e('Error initializing ad platforms', error: e, stackTrace: s);
    } finally {
      if (mounted) {
        AdLoadingOverlay.stop();
      }
    }
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
    _adService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showPincruxOfferwall() async {
    final userState = ref.read(userInfoProvider);
    if (userState.value == null) {
      if (mounted) showRequireLoginDialog();
      return;
    }

    logger.i('showPincruxOfferwall');
    try {
      PincruxOfferwallPlugin.init(
        Platform.isIOS
            ? Environment.pincruxIosAppKey
            : Environment.pincruxAndroidAppKey,
        supabase.auth.currentUser!.id,
      );
      PincruxOfferwallPlugin.setOfferwallType(1);
      PincruxOfferwallPlugin.startPincruxOfferwall();
    } catch (e, s) {
      logger.e('Error in _showPincruxOfferwall', error: e, stackTrace: s);
    }
  }

  /// 미션 버튼 클릭 → `click_mission` (스펙 §2-4).
  ///
  /// 오퍼월 호출 **전** 사용자 의도 시점에 발송한다. analytics 실패가 오퍼월을
  /// 막지 않도록 결과를 기다리지 않는다(레이어가 내부에서 예외를 로깅한다).
  void _onMissionPressed(String platformId, String missionCategory) {
    if (_ga4ClickDebounce.shouldLog('click_mission:$platformId')) {
      unawaited(
        PicnicAnalytics.instance.logClickMission(
          missionCategory: missionCategory,
        ),
      );
    }
    _adService.getPlatform(platformId)?.showAd();
  }

  /// 광고 시청 버튼 클릭 → `ad_request` (스펙 §2-5).
  ///
  /// 같은 시청 건의 `ad_impression` / `ad_click` / `earn_virtual_currency` 가
  /// 동일한 구좌 정보를 쓰도록 [FreeChargeAdGa4Context] 를 플랫폼에 주입한다.
  void _onAdPressed(String platformId, FreeChargeAdGa4Context ga4) {
    if (_ga4ClickDebounce.shouldLog('ad_request:$platformId')) {
      unawaited(
        PicnicAnalytics.instance.logAdRequest(
          sectionName: ga4.sectionName,
          adCategory: ga4.adCategory,
          virtualCurrencyName: ga4.virtualCurrencyName,
          rewardAmount: ga4.rewardAmount,
        ),
      );
    }
    final platform = _adService.getPlatform(platformId);
    platform?.ga4AdContext = ga4;
    platform?.showAd();
  }

  // 미션 아이템 목록 생성
  List<ChargeStationItem> _buildMissionItems(BuildContext context) {
    var globalIndex = 0;
    var koreaIndex = 0;
    final items = <ChargeStationItem>[];

    if (_adService.isPlatformAvailable('tapjoy')) {
      // 클로저가 아니라 값으로 고정한다 — globalIndex 는 아래에서 증가하므로
      // 콜백 안에서 읽으면 클릭 시점의 잘못된 순번이 실린다.
      final missionCategory = FreeChargeGa4.pick(
        FreeChargeGa4.categoryGlobalPick,
        globalIndex + 1,
      );
      items.add(
        ChargeStationItem(
          id: 'tapjoy',
          title:
              '${AppLocalizations.of(context).label_global_recommendation} #${globalIndex + 1}',
          isMission: true,
          platformType: AdPlatformType.tapjoy,
          onPressed: () => _onMissionPressed('tapjoy', missionCategory),
          bonusText: AppLocalizations.of(context).label_unlimited_rewards,
        ),
      );
      globalIndex++;
    }

    if (_adService.isPlatformAvailable('pincrux')) {
      final missionCategory = FreeChargeGa4.pick(
        FreeChargeGa4.categoryKoreaPick,
        koreaIndex + 1,
      );
      items.add(
        ChargeStationItem(
          id: 'pincrux',
          title:
              '${AppLocalizations.of(context).label_korean_recommendation} #${koreaIndex + 1}',
          isMission: true,
          platformType: AdPlatformType.pincrux,
          onPressed: () => _onMissionPressed('pincrux', missionCategory),
          bonusText: AppLocalizations.of(context).label_unlimited_rewards,
        ),
      );
      globalIndex++;
    }

    return items;
  }

  // 광고 아이템 목록 생성
  List<ChargeStationItem> _buildAdItems(BuildContext context) {
    var globalIndex = 0;
    var asiaIndex = 0;
    final items = <ChargeStationItem>[];

    // 광고 구좌의 지급 예정 수량은 UI 에 그대로 노출되는 bonusText 와 같은 값이다.
    const adBonusText = '1';
    final adRewardAmount = int.tryParse(adBonusText) ?? 1;

    final available = <String, bool>{
      'admob': shouldShowDebugAdmobItem(
        isDebugMode: kDebugMode,
        isAdmobAvailable: _adService.isPlatformAvailable('admob'),
      ),
      'internal-shortform': _adService.isPlatformAvailable(
        'internal-shortform',
      ),
      'pangle': _adService.isPlatformAvailable('pangle'),
    };

    for (final platformId in resolveAdOrder(available: available)) {
      switch (platformId) {
        case 'admob':
          final ga4 = FreeChargeAdGa4Context(
            adPlatform: 'AdMob',
            adSource: 'AdMob',
            adUnitName: Platform.isIOS
                ? Environment.admobIosRewardedVideoId
                : Environment.admobAndroidRewardedVideoId,
            adCategory: FreeChargeGa4.pick(
              FreeChargeGa4.categoryGlobalPick,
              globalIndex + 1,
            ),
            virtualCurrencyName: FreeChargeGa4.adRewardCurrencyName,
            rewardAmount: adRewardAmount,
          );
          items.add(
            ChargeStationItem(
              id: 'admob',
              title:
                  '${AppLocalizations.of(context).label_global_recommendation} #${globalIndex + 1}',
              isMission: false,
              platformType: AdPlatformType.admob,
              onPressed: () => _onAdPressed('admob', ga4),
              bonusText: adBonusText,
            ),
          );
          globalIndex++;
        case 'internal-shortform':
          final ga4 = FreeChargeAdGa4Context(
            adPlatform: FreeChargeGa4.platformInternalShortform,
            adSource: FreeChargeGa4.sourceInternalShortform,
            // 자체 숏폼에는 광고 SDK 의 ad unit 개념이 없다. 추정값을 만들지 않고
            // 비워 두면 T2 레이어가 'undefined' 로 대체한다.
            adUnitName: null,
            adCategory: FreeChargeGa4.pick(
              FreeChargeGa4.categoryGlobalPick,
              globalIndex + 1,
            ),
            virtualCurrencyName: FreeChargeGa4.adRewardCurrencyName,
            rewardAmount: adRewardAmount,
          );
          items.add(
            ChargeStationItem(
              id: 'internal-shortform',
              title:
                  '${AppLocalizations.of(context).label_global_recommendation} #${globalIndex + 1}',
              isMission: false,
              platformType: AdPlatformType.custom,
              onPressed: () => _onAdPressed('internal-shortform', ga4),
              bonusText: adBonusText,
            ),
          );
          globalIndex++;
        case 'pangle':
          final ga4 = FreeChargeAdGa4Context(
            adPlatform: FreeChargeGa4.platformPangle,
            adSource: FreeChargeGa4.sourcePangle,
            adUnitName: Platform.isIOS
                ? Environment.pangleIosRewardedVideoId
                : Environment.pangleAndroidRewardedVideoId,
            adCategory: FreeChargeGa4.pick(
              FreeChargeGa4.categoryAsiaPick,
              asiaIndex + 1,
            ),
            virtualCurrencyName: FreeChargeGa4.adRewardCurrencyName,
            rewardAmount: adRewardAmount,
          );
          items.add(
            ChargeStationItem(
              id: 'pangle',
              title:
                  '${AppLocalizations.of(context).label_asia_recommendation} #${asiaIndex + 1}',
              isMission: false,
              platformType: AdPlatformType.pangle,
              onPressed: () => _onAdPressed('pangle', ga4),
              bonusText: adBonusText,
            ),
          );
          asiaIndex++;
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: Colors.white,
      onRefresh: () async {
        _initializeAdPlatforms();
        ref.read(userInfoProvider.notifier).getUserProfiles();
      },
      child: FreeChargeContent(
        buttonScaleAnimation: _buttonScaleAnimation,
        onPolicyTap: () => showUsagePolicyDialog(context),
        missionItemBuilder: _buildMissionItems,
        adItemBuilder: _buildAdItems,
        onPincruxOfferwallPressed: _showPincruxOfferwall,
        rotationController: _rotationController,
      ),
    );
  }
}
