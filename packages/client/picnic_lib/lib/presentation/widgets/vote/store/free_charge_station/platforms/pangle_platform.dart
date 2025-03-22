// pangle_platform.dart

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/pangle_ads.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';

/// Pangle 광고 플랫폼 구현
class PanglePlatform extends AdPlatform {
  PanglePlatform(super.ref, super.context, super.id,
      [super.animationController]);

  @override
  Future<void> initialize() async {
    try {
      final initResult = await PangleAds.initPangle(
        isIOS() ? Environment.pangleIosAppId : Environment.pangleAndroidAppId,
      );

      if (initResult != true) {
        throw Exception('Pangle SDK 초기화 실패');
      }
    } catch (e, s) {
      logger.e('Error in Pangle SDK initialization', error: e, stackTrace: s);
      if (context.mounted) {
        showErrorDialog(S.of(context).label_ads_sdk_init_fail, error: e);
      }
      rethrow;
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      const channel = MethodChannel('pangle_native_channel');

      // 애니메이션 시작
      startButtonAnimation();

      // 최대 30초 후에는 무조건 애니메이션 중지 (안전장치)
      Future.delayed(const Duration(seconds: 30), () {
        if (context.mounted) {
          logger.i('Pangle 안전장치: 애니메이션 중지');
          stopAllAnimations();
        }
      });

      // 이벤트 핸들러 설정
      channel.setMethodCallHandler(_handlePangleEvents);

      PangleAds.setOnProfileRefreshNeeded(() {
        refreshUserProfile();
      });

      await initialize();

      // 광고 로드
      bool adLoadSuccess = await _loadPangleAd();
      if (!context.mounted) return;

      // 광고 표시
      if (adLoadSuccess) {
        try {
          await PangleAds.showRewardedAd();
          // 여기서 애니메이션을 중지하지 않음 - onAdShowed 이벤트에서 처리
        } catch (e, s) {
          throw Exception('Pangle 광고 표시 실패');
        }
      } else {
        if (context.mounted) {
          showErrorDialog(S.of(context).label_ads_load_fail);
        }
        stopAllAnimations();
      }
    });
  }

  Future<bool> _loadPangleAd() async {
    try {
      final result = await Future.any([
        PangleAds.loadRewardedAd(
          isIOS()
              ? Environment.pangleIosRewardedVideoId
              : Environment.pangleAndroidRewardedVideoId,
          supabase.auth.currentUser!.id,
        ),
        Future.delayed(
          const Duration(seconds: 5),
          () => throw TimeoutException('광고 로드 시간이 초과되었습니다.'),
        ),
      ]);

      return result == true;
    } catch (e, s) {
      logger.e('Error in loading Pangle ad', error: e, stackTrace: s);
      if (context.mounted) {
        throw Exception('Pangle 광고 로드 실패');
      }
      return false;
    }
  }

  Future<dynamic> _handlePangleEvents(MethodCall call) async {
    logger.i('Pangle 이벤트 수신: ${call.method}');

    if (!context.mounted) return;

    switch (call.method) {
      case 'onAdShowed':
        logger.i('Pangle 광고가 표시됨');
        // 광고가 실제로 표시될 때 애니메이션 중지
        stopAllAnimations();
        break;
      case 'onAdClicked':
        logger.i('Pangle 광고가 클릭됨');
        break;
      case 'onAdClosed':
        logger.i('Pangle 광고가 닫힘');
        stopAllAnimations();
        refreshUserProfile();
        break;
      case 'onUserEarnedReward':
        final rewardData = call.arguments as Map<String, dynamic>;
        logger.i(
            'Pangle 광고 보상 획득: ${rewardData['amount']} ${rewardData['name']}');
        break;
      case 'onUserEarnedRewardFail':
        final errorData = call.arguments as Map<String, dynamic>;
        final errorDetail =
            'code: ${errorData['code']}, message: ${errorData['message']}';
        logger.e('Pangle 광고 보상 획득 실패', error: errorDetail);
        stopAllAnimations();
        showErrorDialog(S.of(context).label_ads_reward_fail,
            error: errorDetail);
        break;
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('Error in Pangle ads', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      stopAllAnimations();
    }
  }
}
