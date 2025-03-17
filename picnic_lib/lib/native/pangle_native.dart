import 'package:flutter/services.dart';

class PangleNative {
  static const MethodChannel _channel = MethodChannel('pangle_native_channel');

  /// Pangle 초기화
  static Future<void> initPangle(String appId) async {
    try {
      await _channel.invokeMethod('initPangle', {
        'appId': appId,
      });
    } on PlatformException catch (e) {
      print('initPangle failed: ${e.message}');
    }
  }

  /// Native 광고 로드
  static Future<void> loadNativeAd(String placementId) async {
    try {
      final result = await _channel.invokeMethod('loadNativeAd', {
        'placementId': placementId,
      });
      print('loadNativeAd result: $result');
    } on PlatformException catch (e) {
      print('loadNativeAd failed: ${e.message}');
    }
  }
}
