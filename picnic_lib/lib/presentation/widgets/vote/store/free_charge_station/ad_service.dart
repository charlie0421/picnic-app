import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/tapjoy_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/unity_ads_platform.dart';

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
      'unity_ads':
          UnityAdsPlatform(ref, context, 'unity_ads', animationController),
      'pangle': PanglePlatform(ref, context, 'pangle', animationController),
      'tapjoy': TapjoyPlatform(ref, context, 'tapjoy', animationController),
    };
  }

  // 모든 광고 플랫폼 초기화 메서드 추가
  Future<void> initializeAllPlatforms() async {
    if (_initialized) return;

    // 모든 플랫폼 초기화 시작
    final futures = _platforms.entries.map((entry) async {
      try {
        await entry.value.initialize();
        logger.i('${entry.key} platform initialized');
      } catch (e) {
        logger.e('Error initializing ${entry.key}', error: e);
      }
    });

    // 병렬로 모든 초기화 진행
    await Future.wait(futures);
    logger.i('All ad platforms initialized');
    _initialized = true;
  }

  AdPlatform? getPlatform(String id) {
    return _platforms[id];
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
