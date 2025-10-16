// free_charge_station.dart
// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
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
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart';

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
      OverlayLoadingProgress.start(context);
      // 모든 광고 플랫폼 초기화
      await _adService.initializeAllPlatforms();
    } catch (e, s) {
      logger.e('Error initializing ad platforms', error: e, stackTrace: s);
    } finally {
      if (mounted) {
        OverlayLoadingProgress.stop();
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

  // 미션 아이템 목록 생성
  List<ChargeStationItem> _buildMissionItems(BuildContext context) {
    var globalIndex = 0;
    var koreaIndex = 0;
    final items = <ChargeStationItem>[];

    if (_adService.isPlatformAvailable('tapjoy')) {
      items.add(
        ChargeStationItem(
          id: 'tapjoy',
          title:
              '${AppLocalizations.of(context).label_global_recommendation} #${globalIndex + 1}',
          isMission: true,
          platformType: AdPlatformType.tapjoy,
          onPressed: () => _adService.getPlatform('tapjoy')?.showAd(),
          bonusText: AppLocalizations.of(context).label_unlimited_rewards,
        ),
      );
      globalIndex++;
    }

    if (_adService.isPlatformAvailable('pincrux')) {
      items.add(
        ChargeStationItem(
          id: 'pincrux',
          title:
              '${AppLocalizations.of(context).label_korean_recommendation} #${koreaIndex + 1}',
          isMission: true,
          platformType: AdPlatformType.pincrux,
          onPressed: () => _adService.getPlatform('pincrux')?.showAd(),
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

    // 글로벌 픽 #2에 내부 숏폼 광고 버튼 배치
    if (_adService.isPlatformAvailable('internal-shortform')) {
      // 글로벌 픽 #1 자리는 기존 순서를 유지하고, #2 자리를 내부광고로
      final internalItem = ChargeStationItem(
        id: 'internal-shortform',
        title:
            '${AppLocalizations.of(context).label_global_recommendation} #${globalIndex + 2}',
        isMission: false,
        platformType: AdPlatformType.custom,
        onPressed: () => _adService.getPlatform('internal-shortform')?.showAd(),
        bonusText: '1',
      );
      // 임시로 뒤에서 추가 후 재정렬: 먼저 기존 글로벌 #1을 채운 다음 삽입
      // 실제 순서 보장은 아래 기존 플랫폼 추가 로직 이후에 배열 재배치로 처리
      // (간단히 마지막에 위치를 정리)
      items.add(internalItem);
    }

    if (_adService.isPlatformAvailable('admob')) {
      items.add(
        ChargeStationItem(
          id: 'admob',
          title:
              '${AppLocalizations.of(context).label_global_recommendation} #${globalIndex + 1}',
          isMission: false,
          platformType: AdPlatformType.admob,
          index: 0,
          onPressed: () => _adService.getPlatform('admob')?.showAd(),
          bonusText: '1',
        ),
      );
      globalIndex++;
    }

    if (_adService.isPlatformAvailable('unity')) {
      items.add(
        ChargeStationItem(
          id: 'unity',
          title:
              '${AppLocalizations.of(context).label_global_recommendation} #${globalIndex + 1}',
          isMission: false,
          platformType: AdPlatformType.unity,
          onPressed: () => _adService.getPlatform('unity')?.showAd(),
          bonusText: '1',
        ),
      );
      globalIndex++;
    }

    if (_adService.isPlatformAvailable('pangle')) {
      items.add(
        ChargeStationItem(
          id: 'pangle',
          title:
              '${AppLocalizations.of(context).label_asia_recommendation} #${asiaIndex + 1}',
          isMission: false,
          platformType: AdPlatformType.pangle,
          onPressed: () => _adService.getPlatform('pangle')?.showAd(),
          bonusText: '1',
        ),
      );
      asiaIndex++;
    }

    // 재정렬: 내부 숏폼을 글로벌 #2로, 기존 글로벌 #2(있다면) → #3로 숨김 처리
    // 간단 구현: 글로벌 추천들만 추출해 내부 숏폼을 2번째 위치로 이동하고, 3번째 항목은 제거
    final globalItems = <int>[]; // 인덱스 목록
    for (var i = 0; i < items.length; i++) {
      final t = items[i].title;
      if (t.contains(
        AppLocalizations.of(context).label_global_recommendation,
      )) {
        globalItems.add(i);
      }
    }
    // 내부 숏폼 찾기
    final internalIdx = items.indexWhere((x) => x.id == 'internal-shortform');
    if (internalIdx != -1) {
      // 글로벌 #2 목표 위치 계산
      int targetPos = -1;
      if (globalItems.isNotEmpty) {
        // #1 다음 위치를 찾음
        final firstGlobal = globalItems.first;
        targetPos = (firstGlobal + 1 <= items.length)
            ? firstGlobal + 1
            : items.length;
      } else {
        targetPos = 0;
      }
      final internalItem = items.removeAt(internalIdx);
      items.insert(targetPos, internalItem);
      // 기존 글로벌 #2(새 위치 기준 #2 다음)의 항목이 있다면 한 개 제거(보이지 않게)
      // targetPos+1이 유효하고 글로벌 추천이면 제거
      if (targetPos + 1 < items.length) {
        final nextItem = items[targetPos + 1];
        if (nextItem.title.contains(
          AppLocalizations.of(context).label_global_recommendation,
        )) {
          items.removeAt(targetPos + 1);
        }
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
