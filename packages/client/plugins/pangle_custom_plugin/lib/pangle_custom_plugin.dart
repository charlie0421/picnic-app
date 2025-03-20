import 'dart:async';

import 'package:flutter/services.dart';

/// Flutter용 Pangle 광고 커스텀 플러그인
class PangleCustomPlugin {
  /// 네이티브 통신을 위한 메소드 채널
  static const MethodChannel _channel = MethodChannel('pangle_native_channel');

  /// 광고 이벤트 콜백 함수들
  static void Function()? onAdShowed;
  static void Function()? onAdClicked;
  static void Function()? onAdClosed;
  static void Function(int amount, String name)? onUserEarnedReward;
  static void Function(int code, String message)? onUserEarnedRewardFail;

  static void _initEventHandler() {
    _channel.setMethodCallHandler((call) async {
      print('Pangle 이벤트 수신: ${call.method}');

      switch (call.method) {
        case 'onAdShowed':
          print('광고가 표시됨');
          onAdShowed?.call();
          break;

        case 'onAdClicked':
          print('광고가 클릭됨');
          onAdClicked?.call();
          break;

        case 'onAdClosed':
          print('광고가 닫힘');
          onAdClosed?.call();
          break;

        case 'onUserEarnedReward':
          final Map<String, dynamic> rewardData = call.arguments;
          final amount = rewardData['amount'] as int;
          final name = rewardData['name'] as String;
          print('사용자가 보상을 받음: $amount $name');
          onUserEarnedReward?.call(amount, name);
          break;

        case 'onUserEarnedRewardFail':
          final Map<String, dynamic> errorData = call.arguments;
          final code = errorData['code'] as int;
          final message = errorData['message'] as String;
          print('보상 획득 실패: ($code) $message');
          onUserEarnedRewardFail?.call(code, message);
          break;
      }
    });
  }

  /// Pangle SDK 초기화
  ///
  /// [appId] - Pangle 앱 ID
  static Future<bool> initPangle(String appId, String userId) async {
    try {
      _initEventHandler(); // 이벤트 핸들러 초기화
      print('Pangle SDK 초기화 시작: $appId');
      final bool result = await _channel.invokeMethod('initPangle', {
        'appId': appId,
        'userId': userId,
      });
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
  static Future<bool> loadRewardedAd(
    String appId,
    String placementId,
    String userId,
  ) async {
    try {
      await initPangle(appId, userId);

      final bool result = await _channel.invokeMethod('loadRewardedAd', {
        'placementId': placementId,
      });
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
