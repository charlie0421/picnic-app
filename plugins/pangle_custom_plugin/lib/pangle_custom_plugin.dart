import 'dart:async';

import 'package:flutter/services.dart';

/// Flutter용 Pangle 광고 커스텀 플러그인
class PangleCustomPlugin {
  /// 네이티브 통신을 위한 메소드 채널
  static const MethodChannel _channel = MethodChannel('pangle_native_channel');

  /// Pangle SDK 초기화
  ///
  /// [appId] - Pangle 앱 ID
  static Future<bool> initPangle(String appId) async {
    try {
      print('Pangle SDK 초기화 시작: $appId');
      final bool result =
          await _channel.invokeMethod('initPangle', {'appId': appId});
      print('Pangle SDK 초기화 성공: $result');
      return result;
    } catch (e) {
      print('Pangle SDK 초기화 실패: $e');
      rethrow;
    }
  }

  /// 보상형 광고 로드
  ///
  /// [placementId] - 광고 슬롯 ID
  static Future<bool> loadRewardedAd(String placementId) async {
    try {
      final bool result = await _channel
          .invokeMethod('loadRewardedAd', {'placementId': placementId});
      print('보상형 광고 로드 성공: $result');
      return result;
    } catch (e) {
      print('보상형 광고 로드 실패: $e');
      rethrow;
    }
  }

  /// 보상형 광고 표시
  static Future<bool> showRewardedAd() async {
    try {
      final bool result = await _channel.invokeMethod('showRewardedAd');
      print('보상형 광고 표시 성공: $result');
      return result;
    } catch (e) {
      print('보상형 광고 표시 실패: $e');
      rethrow;
    }
  }
}
