import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/pincruxOfferwallPlugin.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:universal_io/io.dart';

/// Pincrux 미션 플랫폼 구현
class PincruxPlatform extends AdPlatform {
  PincruxPlatform(WidgetRef ref, BuildContext context, String id,
      [AnimationController? animationController])
      : super(ref, context, id, animationController);

  @override
  Future<void> initialize() async {
    // Pincrux는 showAd에서 초기화
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      // 애니메이션 시작
      startButtonAnimation();

      // 최대 30초 후에는 무조건 애니메이션 중지 (안전장치)
      Future.delayed(const Duration(seconds: 30), () {
        if (context.mounted) {
          logger.i('Pincrux 안전장치: 애니메이션 중지');
          stopAllAnimations();
        }
      });

      await _showPincruxOfferwall();
      // 애니메이션 중지
      stopAllAnimations();
    }, isMission: true);
  }

  Future<void> _showPincruxOfferwall() async {
    try {
      logger.i('showPincruxOfferwall');
      // Pincrux SDK 초기화
      String userId = supabase.auth.currentUser!.id;
      String? appKey = Platform.isIOS
          ? Environment.pincruxIosAppKey
          : Environment.pincruxAndroidAppKey;

      if (appKey == null || appKey.isEmpty) {
        throw Exception('Pincrux app key not available');
      }

      PincruxOfferwallPlugin.init(appKey, userId);

      // 오퍼월 타입 설정 (타입 1: 통합형)
      PincruxOfferwallPlugin.setOfferwallType(1);

      // 오퍼월 시작
      PincruxOfferwallPlugin.startPincruxOfferwall();

      // 사용자 프로필 새로고침
      refreshUserProfile();
    } catch (e, s) {
      logger.e('Error in _showPincruxOfferwall', error: e, stackTrace: s);
      throw e;
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('Error in Pincrux mission', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      stopAllAnimations();

      showErrorDialog(S.of(context).label_ads_load_fail, error: error);
    }
  }
}
