// pangle_platform.dart

import 'dart:async';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/pangle_ads.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:universal_io/io.dart';

/// Pangle 광고 플랫폼 구현
class PanglePlatform extends AdPlatform {
  PanglePlatform(super.ref, super.context, super.id,
      [super.animationController]);

  @override
  Future<void> initialize() async {
    try {
      if (Environment.pangleIosAppId == null ||
          Environment.pangleAndroidAppId == null) {
        return;
      }

      final initResult = await PangleAds.initPangle(
        Platform.isIOS
            ? Environment.pangleIosAppId!
            : Environment.pangleAndroidAppId!,
      );

      if (initResult != true) {
        throw Exception('Pangle SDK 초기화 실패');
      }
    } catch (e, s) {
      logger.e('Error in Pangle SDK initialization', error: e, stackTrace: s);
      if (context.mounted) {
        commonUtils.showErrorDialog(S.of(context).label_ads_sdk_init_fail,
            error: e);
      }
      rethrow;
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      // 애니메이션 시작
      startButtonAnimation();

      PangleAds.setOnProfileRefreshNeeded(() {
        commonUtils.refreshUserProfile();
      });

      await initialize();

      // 광고 로드
      bool adLoadSuccess = await _loadPangleAd();
      if (!context.mounted) return;

      // 광고 표시
      if (adLoadSuccess) {
        try {
          await PangleAds.showRewardedAd();
          stopAllAnimations();
        } catch (e) {
          throw Exception('Pangle 광고 표시 실패');
        }
      } else {
        if (context.mounted) {
          commonUtils.showErrorDialog(S.of(context).label_ads_load_fail);
        }
        stopAllAnimations();
      }
    });
  }

  Future<bool> _loadPangleAd() async {
    try {
      if (Environment.pangleIosRewardedVideoId == null ||
          Environment.pangleAndroidRewardedVideoId == null) {
        return false;
      }

      final result = await Future.any([
        PangleAds.loadRewardedAd(
          Platform.isIOS
              ? Environment.pangleIosRewardedVideoId!
              : Environment.pangleAndroidRewardedVideoId!,
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

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('Error in Pangle ads', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      stopAllAnimations();

      commonUtils.showErrorDialog(S.of(context).label_ads_load_fail,
          error: error);
    }
  }
}
