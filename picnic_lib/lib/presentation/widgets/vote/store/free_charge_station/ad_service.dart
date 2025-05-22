import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/pincrux_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/tapjoy_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/unity_ads_platform.dart';
import 'package:picnic_lib/core/config/environment.dart';

/// 통합 광고 서비스
class AdService {
  final WidgetRef ref;
  final BuildContext context;
  final AnimationController animationController;

  late final Map<String, AdPlatform> _platforms;
  bool _initialized = false;

  AdService({
    required this.ref,
    required this.context,
    required this.animationController,
  }) {
    _initPlatforms();
  }

  void _initPlatforms() {
    _platforms = {
      'admob': AdmobPlatform(ref, context, 'admob', animationController),
      'unity': UnityAdsPlatform(ref, context, 'unity', animationController),
      'pangle': PanglePlatform(ref, context, 'pangle', animationController),
      'tapjoy': TapjoyPlatform(ref, context, 'tapjoy', animationController),
      'pincrux': PincruxPlatform(ref, context, 'pincrux', animationController),
    };
  }

  // 모든 광고 플랫폼 초기화 메서드 추가
  Future<void> initializeAllPlatforms() async {
    if (_initialized) return;

    // 사용 가능한 플랫폼만 필터링
    final availablePlatforms = _platforms.entries
        .where((entry) => isPlatformAvailable(entry.key))
        .toList();

    if (availablePlatforms.isEmpty) {
      logger.i('No available ad platforms to initialize');
      _initialized = true;
      return;
    }

    // 사용 가능한 플랫폼만 초기화 시작
    final futures = availablePlatforms.map((entry) async {
      try {
        await entry.value.initialize();
        logger.i('${entry.key} platform initialized');
      } catch (e) {
        logger.e('Error initializing ${entry.key}', error: e);
      }
    });

    // 병렬로 모든 초기화 진행
    await Future.wait(futures);
    logger
        .i('Available ad platforms initialized: ${availablePlatforms.length}');
    _initialized = true;
  }

  AdPlatform? getPlatform(String id) {
    return _platforms[id];
  }

  /// 설정 파일을 기반으로 특정 광고 플랫폼이 사용 가능한지 확인
  bool isPlatformAvailable(String platformId) {
    switch (platformId) {
      case 'admob':
        return Environment.admobIosRewardedVideoId != null &&
            Environment.admobIosRewardedVideoId!.isNotEmpty &&
            Environment.admobAndroidRewardedVideoId != null &&
            Environment.admobAndroidRewardedVideoId!.isNotEmpty;
      case 'unity':
        return Environment.unityAppleGameId != null &&
            Environment.unityAppleGameId!.isNotEmpty &&
            Environment.unityAndroidGameId != null &&
            Environment.unityAndroidGameId!.isNotEmpty;
      case 'pangle':
        return Environment.pangleIosAppId != null &&
            Environment.pangleIosAppId!.isNotEmpty &&
            Environment.pangleAndroidAppId != null &&
            Environment.pangleAndroidAppId!.isNotEmpty;
      case 'tapjoy':
        return Environment.tapjoyIosSdkKey != null &&
            Environment.tapjoyIosSdkKey!.isNotEmpty &&
            Environment.tapjoyAndroidSdkKey != null &&
            Environment.tapjoyAndroidSdkKey!.isNotEmpty;
      case 'pincrux':
        return Environment.pincruxIosAppKey != null &&
            Environment.pincruxIosAppKey!.isNotEmpty &&
            Environment.pincruxAndroidAppKey != null &&
            Environment.pincruxAndroidAppKey!.isNotEmpty;
      default:
        return false;
    }
  }

  /// 사용 가능한 모든 광고 플랫폼 ID 목록 반환
  List<String> getAvailablePlatforms() {
    return _platforms.keys
        .where((platformId) => isPlatformAvailable(platformId))
        .toList();
  }

  bool isAdLoading(String id) {
    return ref.read(adLoadingStateProvider.notifier).isLoading(id);
  }

  // 리소스 해제
  void dispose() {
    // 클린업 로직
    _platforms.clear();
  }
}
