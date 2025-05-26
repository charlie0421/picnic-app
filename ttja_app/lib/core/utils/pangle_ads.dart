import 'dart:async';
import 'package:flutter/services.dart';
import 'package:ttja_app/core/utils/logger.dart';

class PangleAds {
  static const _channel = MethodChannel('pangle_native_channel');

  // 이벤트 스트림 컨트롤러
  static final _adShownController = StreamController<void>.broadcast();
  static final _adClickedController = StreamController<void>.broadcast();
  static final _adDismissedController = StreamController<void>.broadcast();
  static final _rewardEarnedController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final _rewardFailedController = StreamController<String>.broadcast();

  // 프로필 갱신 콜백
  static Function? _onProfileRefreshNeeded;

  // 이벤트 스트림 제공
  static Stream<void> get onAdShown => _adShownController.stream;
  static Stream<void> get onAdClicked => _adClickedController.stream;
  static Stream<void> get onAdDismissed => _adDismissedController.stream;
  static Stream<Map<String, dynamic>> get onRewardEarned =>
      _rewardEarnedController.stream;
  static Stream<String> get onRewardFailed => _rewardFailedController.stream;

  // 광고 닫힘 후 프로필 갱신 콜백 설정
  static void setOnProfileRefreshNeeded(Function callback) {
    _onProfileRefreshNeeded = callback;
    Logger.i('광고 닫힘 후 프로필 갱신 콜백이 설정되었습니다');
  }

  // Pangle SDK 초기화
  static Future<bool> initPangle(String appId) async {
    try {
      Logger.i('Initializing Pangle SDK with appId: $appId');
      final result = await _channel.invokeMethod<bool>(
        'initPangle',
        {'appId': appId},
      );

      if (result ?? false) {
        Logger.i('Pangle SDK initialized successfully');

        // 이벤트 수신 처리 설정
        _setupEventHandlers();
      } else {
        Logger.e('Pangle SDK initialization failed');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      Logger.e('Pangle SDK initialization error: ${e.message}');
      return false;
    } catch (e) {
      Logger.e('Unexpected error initializing Pangle SDK: $e');
      return false;
    }
  }

  // 이벤트 핸들러 설정
  static void _setupEventHandlers() {
    Logger.i('Pangle 이벤트 핸들러 설정 시작');

    _channel.setMethodCallHandler((call) async {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        switch (call.method) {
          case 'onAdShowed':
            Logger.i('광고 표시 이벤트 수신');
            _adShownController.add(null);
            break;

          case 'onAdClicked':
            Logger.i('광고 클릭 이벤트 수신');
            _adClickedController.add(null);
            break;

          case 'onAdClosed':
            Logger.i('광고 닫힘 이벤트 수신');
            _adDismissedController.add(null);
            _performProfileRefresh(timestamp);
            break;

          case 'onUserEarnedReward':
            Logger.i('보상 획득 이벤트 수신: ${call.arguments}');
            try {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              _rewardEarnedController.add(args);
              _performProfileRefresh(timestamp);
              Logger.i('보상 획득 이벤트 전파 완료');
            } catch (e) {
              Logger.e('보상 획득 이벤트 처리 중 오류: $e');
            }
            break;

          case 'onRewardFailed':
            Logger.e('리워드 실패: ${call.arguments}');
            try {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              final String errorMessage = args['errorMessage'] ?? '알 수 없는 오류';
              Logger.e('보상 지급 실패 이벤트 처리: $errorMessage');
              _rewardFailedController.add(errorMessage);
              _performProfileRefresh(timestamp);
              Logger.i('보상 실패 이벤트 전파 완료');
            } catch (e) {
              Logger.e('보상 실패 이벤트 처리 중 오류: $e');
            }
            break;

          default:
            // 알 수 없는 이벤트이지만 'ad'가 포함된 경우 광고 닫힘으로 처리
            if (call.method.toLowerCase().contains('ad')) {
              Logger.w('알 수 없는 광고 이벤트를 광고 닫힘으로 처리: ${call.method}');
              _performProfileRefresh(timestamp);
            } else {
              Logger.w('처리되지 않은 이벤트: ${call.method}');
            }
            break;
        }
      } catch (e, stackTrace) {
        Logger.e('이벤트 처리 중 오류 발생: $e', stackTrace: stackTrace);
      }

      return null;
    });

    // 이벤트 핸들러가 설정되었는지 확인
    Future.delayed(const Duration(milliseconds: 100), () {
      Logger.i(
          '이벤트 Stream 상태 확인: adDismissed=${!_adDismissedController.isClosed}, 구독자=${_adDismissedController.hasListener}');
    });

    Logger.i('Pangle 이벤트 핸들러 설정 완료');
  }

  /// 프로필 새로고침 수행
  static void _performProfileRefresh(dynamic timestamp) {
    try {
      if (_onProfileRefreshNeeded != null) {
        Logger.i('프로필 새로고침 콜백 실행 중...');
        Future.delayed(const Duration(seconds: 1), () {
          _onProfileRefreshNeeded!();
        });
      } else {
        Logger.w('프로필 새로고침 콜백이 등록되지 않았습니다.');
      }
    } catch (e, stackTrace) {
      Logger.e('프로필 새로고침 중 오류 발생: $e', stackTrace: stackTrace);
    }
  }

  // 리워드 광고 로드
  static Future<bool> loadRewardedAd(String placementId, String userId) async {
    try {
      Logger.i(
          'Loading rewarded ad with placementId: $placementId, userId: $userId');
      final result = await _channel.invokeMethod<bool>(
        'loadRewardedAd',
        {'placementId': placementId, 'userId': userId},
      );

      if (result ?? false) {
        Logger.i('Rewarded ad loaded successfully');
      } else {
        Logger.e('Failed to load rewarded ad');
        throw Exception('Pangle 광고 로드 실패');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      Logger.e('Error loading rewarded ad: ${e.message}');
      return false;
    } catch (e) {
      Logger.e('Unexpected error loading rewarded ad: $e');
      return false;
    }
  }

  // 리워드 광고 표시
  static Future<bool> showRewardedAd() async {
    try {
      Logger.i('Showing rewarded ad');
      final result = await _channel.invokeMethod<bool>('showRewardedAd');

      if (result ?? false) {
        Logger.i('Rewarded ad shown successfully');
      } else {
        Logger.e('Failed to show rewarded ad');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      Logger.e('Error showing rewarded ad: ${e.message}');
      return false;
    } catch (e) {
      Logger.e('Unexpected error showing rewarded ad: $e');
      return false;
    }
  }

  // 리소스 해제
  static void dispose() {
    _adShownController.close();
    _adClickedController.close();
    _adDismissedController.close();
    _rewardEarnedController.close();
    _rewardFailedController.close();
    _channel.setMethodCallHandler(null);
  }
}
