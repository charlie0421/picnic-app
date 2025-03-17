import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class PangleNative {
  static const MethodChannel _channel = MethodChannel('pangle_native_channel');

  /// Pangle 초기화
  static Future<void> initPangle(String appId) async {
    try {
      logger.i('initPangle appId: $appId');
      final result = await _channel.invokeMethod('initPangle', {
        'appId': appId,
      });
      logger.i('initPangle: $result');
    } on PlatformException catch (e) {
      logger.e('initPangle failed', error: e);
    }
  }

  /// Native 광고 로드
  static Future<bool> loadRewardedAd(String placementId) async {
    try {
      logger.i('loadRewardedAd placementId: $placementId');
      final result = await _channel.invokeMethod('loadRewardedAd', {
        'placementId': placementId,
      });
      logger.i('loadRewardedAd result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('loadRewardedAd failed', error: e);
      return false;
    }
  }

  /// 보상형 광고 표시
  static Future<bool> showRewardedAd() async {
    try {
      logger.i('showRewardedAd called');
      final result = await _channel.invokeMethod('showRewardedAd');
      logger.i('showRewardedAd result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('showRewardedAd failed', error: e);
      return false;
    }
  }
}
