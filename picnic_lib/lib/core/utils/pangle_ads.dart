import 'dart:async';
import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/pangle_ads_helper.dart';

class PangleAds {
  static const _channel = MethodChannel('pangle_native_channel');

  // 이벤트 스트림 컨트롤러
  static final _adShownController = StreamController<void>.broadcast();
  static final _adClickedController = StreamController<void>.broadcast();
  static final _adDismissedController = StreamController<void>.broadcast();
  static final _rewardEarnedController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final _rewardFailedController = StreamController<String>.broadcast();
  static final _pollingSignalController = StreamController<void>.broadcast();

  // 이벤트 스트림 제공
  static Stream<void> get onAdShown => _adShownController.stream;
  static Stream<void> get onAdClicked => _adClickedController.stream;
  static Stream<void> get onAdDismissed => _adDismissedController.stream;
  static Stream<Map<String, dynamic>> get onRewardEarned =>
      _rewardEarnedController.stream;
  static Stream<String> get onRewardFailed => _rewardFailedController.stream;
  static Stream<void> get pollingSignals => _pollingSignalController.stream;

  // Pangle SDK 초기화
  static Future<bool> initPangle(
    String appId, {
    String environment = 'prod',
    String? productionAppId,
    String? sandboxPlacementId,
    String? productionPlacementId,
  }) async {
    try {
      if (environment == 'sandbox' &&
          (appId.isEmpty ||
              productionAppId == null ||
              productionAppId.isEmpty ||
              appId == productionAppId ||
              sandboxPlacementId == null ||
              sandboxPlacementId.isEmpty ||
              productionPlacementId == null ||
              productionPlacementId.isEmpty ||
              sandboxPlacementId == productionPlacementId)) {
        logger.e('Pangle sandbox configuration rejected');
        return false;
      }
      logger.i('Initializing Pangle SDK');
      final result = await _channel.invokeMethod<bool>('initPangle', {
        'appId': appId,
        if (environment != 'prod') ...{
          'environment': environment,
          'productionAppId': productionAppId,
          'sandboxPlacementId': sandboxPlacementId,
          'productionPlacementId': productionPlacementId,
        },
      });

      if (result ?? false) {
        logger.i('Pangle SDK initialized successfully');

        // 이벤트 수신 처리 설정
        _setupEventHandlers();
      } else {
        logger.e('Pangle SDK initialization failed');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('Pangle SDK initialization error: ${e.message}');
      return false;
    } catch (e) {
      logger.e('Unexpected error initializing Pangle SDK: $e');
      return false;
    }
  }

  // 이벤트 핸들러 설정
  static void _setupEventHandlers() {
    logger.i('Pangle 이벤트 핸들러 설정 시작');

    _channel.setMethodCallHandler((call) async {
      try {
        final eventType = PangleAdsHelper.classifyEvent(call.method);

        switch (eventType) {
          case PangleAdsHelper.adShownEvent:
            logger.i('광고가 표시됨: ${call.arguments}');
            _adShownController.add(null);
            break;

          case PangleAdsHelper.adClickedEvent:
            logger.i('광고가 클릭됨: ${call.arguments}');
            _adClickedController.add(null);
            break;

          case PangleAdsHelper.adDismissedEvent:
            logger.i('광고가 닫힘 이벤트 수신 [${call.method}]: ${call.arguments}');
            _adDismissedController.add(null);
            _pollingSignalController.add(null);
            break;

          case PangleAdsHelper.rewardEarnedEvent:
            logger.i('리워드 획득: ${call.arguments}');
            try {
              final args = PangleAdsHelper.parseRewardArgs(call.arguments);
              if (args != null) {
                logger.i(
                  '보상 획득 이벤트 처리: ${args['rewardName']}, 수량: ${args['rewardAmount']}',
                );
                _rewardEarnedController.add(args);
                logger.i('보상 획득 이벤트 전파 완료');
              } else {
                logger.e('보상 획득 이벤트 처리 중 오류: invalid arguments');
              }
              _pollingSignalController.add(null);
            } catch (e) {
              logger.e('보상 획득 이벤트 처리 중 오류: $e');
            }
            break;

          case PangleAdsHelper.rewardFailedEvent:
            logger.e('리워드 실패: ${call.arguments}');
            try {
              final String errorMessage = PangleAdsHelper.extractErrorMessage(
                call.arguments,
              );
              logger.e('보상 지급 실패 이벤트 처리: $errorMessage');
              _rewardFailedController.add(errorMessage);
              _pollingSignalController.add(null);
              logger.i('보상 실패 이벤트 전파 완료');
            } catch (e) {
              logger.e('보상 실패 이벤트 처리 중 오류: $e');
            }
            break;

          default:
            logger.w('처리되지 않은 이벤트: ${call.method}');
            break;
        }
      } catch (e, stackTrace) {
        logger.e('이벤트 처리 중 오류 발생: $e', stackTrace: stackTrace);
      }

      return null;
    });

    // 이벤트 핸들러가 설정되었는지 확인
    Future.delayed(Duration(milliseconds: 100), () {
      logger.i(
        '이벤트 Stream 상태 확인: adDismissed=${!_adDismissedController.isClosed}, 구독자=${_adDismissedController.hasListener}',
      );
    });

    logger.i('Pangle 이벤트 핸들러 설정 완료');
  }

  // 리워드 광고 로드
  static Future<bool> loadRewardedAd(
    String placementId,
    String mediaExtra,
  ) async {
    logger.i('Loading rewarded ad with placementId: $placementId');
    // 네이티브 오류는 **삼키지 않는다**.
    //
    // 예전엔 PlatformException 을 잡아 false 를 돌려줬다. 호출부는 false 를
    // "지금 광고가 없다"(no-fill)로 해석해 하드코딩 라벨로 로깅하므로,
    // 사용자에겐 "모든 광고 소진" 이 뜨고 Sentry 보고도 생략됐다. 실제로
    // 아시아픽 #1 이 InvalidMediaExtra("Signed v2 mediaExtra is required")로
    // 100% 실패하는 동안 이 경로 때문에 텔레메트리가 한 건도 남지 않았다
    // (PICNIC-2377).
    //
    // 예외를 올려보내면 `_loadPangleAd` 의 catch 가 실제 에러 텍스트로 분류해
    // Sentry 에 보고하고 일반 오류 문구를 띄운다.
    final result = await _channel.invokeMethod<bool>('loadRewardedAd', {
      'placementId': placementId,
      'mediaExtra': mediaExtra,
    });

    // 네이티브가 **명시적으로 false** 를 준 경우만 진짜 no-fill 이다.
    if (result ?? false) {
      logger.i('Rewarded ad loaded successfully');
      return true;
    }
    logger.w('No rewarded ad available (native returned false)');
    return false;
  }

  // 리워드 광고 표시
  static Future<bool> showRewardedAd() async {
    try {
      logger.i('Showing rewarded ad');
      final result = await _channel.invokeMethod<bool>('showRewardedAd');

      if (result ?? false) {
        logger.i('Rewarded ad shown successfully');
      } else {
        logger.e('Failed to show rewarded ad');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('Error showing rewarded ad: ${e.message}');
      return false;
    } catch (e) {
      logger.e('Unexpected error showing rewarded ad: $e');
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
    _pollingSignalController.close();
  }

  // 광고 닫힘 이벤트 리스너 설정 - 이벤트 테스트 및 확인용
  static StreamSubscription<void> listenToAdDismissed(Function() callback) {
    logger.i('광고 닫힘 이벤트 리스너 설정됨');
    return onAdDismissed.listen((_) {
      logger.i('광고 닫힘 이벤트 감지됨 - 콜백 실행');
      callback();
    });
  }

  // 광고 닫힘 테스트 (디버깅용)
  static Future<void> testAdDismissed() async {
    logger.i('🧪 광고 닫힘 이벤트 테스트 시작');

    try {
      // 테스트 이벤트 발생
      _adDismissedController.add(null);
      logger.i('테스트 이벤트 발생 완료');

      logger.i('🧪 광고 닫힘 이벤트 테스트 성공');
      return Future.value();
    } catch (e) {
      logger.e('🧪 광고 닫힘 이벤트 테스트 실패: $e');
      return Future.error(e);
    }
  }
}
