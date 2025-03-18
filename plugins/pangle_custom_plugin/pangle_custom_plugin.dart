import 'dart:async';
import 'package:flutter/services.dart';

/// Pangle 네이티브 통합을 위한 플러그인
class PanglePlugin {
  static const MethodChannel _channel = MethodChannel('pangle_native_channel');

  /// Pangle SDK 초기화
  static Future<bool> initPangle(String appId) async {
    try {
      final result = await _channel.invokeMethod<bool>('initPangle', {
        'appId': appId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Pangle SDK 초기화 실패: ${e.message}');
      return false;
    }
  }

  /// 보상형 광고 로드
  static Future<bool> loadRewardedAd(String placementId) async {
    try {
      final result = await _channel.invokeMethod<bool>('loadRewardedAd', {
        'placementId': placementId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('보상형 광고 로드 실패: ${e.message}');
      return false;
    }
  }

  /// 보상형 광고 표시
  static Future<bool> showRewardedAd() async {
    try {
      final result = await _channel.invokeMethod<bool>('showRewardedAd');
      return result ?? false;
    } on PlatformException catch (e) {
      print('보상형 광고 표시 실패: ${e.message}');
      return false;
    }
  }
}
