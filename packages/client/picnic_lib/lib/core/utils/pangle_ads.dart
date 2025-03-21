import 'dart:async';
import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class PangleAds {
  static const _channel = MethodChannel('pangle_native_channel');
  static String? _appId;

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
    logger.i('광고 닫힘 후 프로필 갱신 콜백이 설정되었습니다');
  }

  // Pangle SDK 초기화
  static Future<bool> initPangle(String appId) async {
    try {
      logger.i('Initializing Pangle SDK with appId: $appId');
      final result = await _channel.invokeMethod<bool>(
        'initPangle',
        {'appId': appId},
      );

      if (result ?? false) {
        _appId = appId;
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
        final DateTime now = DateTime.now();
        final timestamp =
            call.arguments?['timestamp'] ?? (now.millisecondsSinceEpoch / 1000);

        switch (call.method) {
          case 'onAdShown':
            logger.i('광고가 표시됨: ${call.arguments}');
            _adShownController.add(null);
            break;

          case 'onAdClicked':
            logger.i('광고가 클릭됨: ${call.arguments}');
            _adClickedController.add(null);
            break;

          case 'onAdDismissed':
          case 'onAdClosed': // Android에서 전송할 수 있는 대체 이벤트
            logger.i('광고가 닫힘 이벤트 수신 [${call.method}]: ${call.arguments}');
            // 프로필 새로고침 콜백 실행
            _performProfileRefresh(timestamp);
            break;

          case 'onRewardEarned':
            logger.i('리워드 획득: ${call.arguments}');
            try {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              logger.i(
                  '보상 획득 이벤트 처리: ${args['rewardName']}, 수량: ${args['rewardAmount']}');
              _rewardEarnedController.add(args);
              logger.i('보상 획득 이벤트 전파 완료');
            } catch (e) {
              logger.e('보상 획득 이벤트 처리 중 오류: $e');
            }
            break;

          case 'onRewardFailed':
            logger.e('리워드 실패: ${call.arguments}');
            try {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              final String errorMessage = args['errorMessage'] ?? '알 수 없는 오류';
              logger.e('보상 지급 실패 이벤트 처리: $errorMessage');
              _rewardFailedController.add(errorMessage);
              logger.i('보상 실패 이벤트 전파 완료');
            } catch (e) {
              logger.e('보상 실패 이벤트 처리 중 오류: $e');
            }
            break;

          default:
            // 알 수 없는 이벤트이지만 'ad'가 포함된 경우 광고 닫힘으로 처리
            if (call.method.toLowerCase().contains('ad')) {
              logger.w('알 수 없는 광고 이벤트를 광고 닫힘으로 처리: ${call.method}');
              _performProfileRefresh(timestamp);
            } else {
              logger.w('처리되지 않은 이벤트: ${call.method}');
            }
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
          '이벤트 Stream 상태 확인: adDismissed=${!_adDismissedController.isClosed}, 구독자=${_adDismissedController.hasListener}');
    });

    logger.i('Pangle 이벤트 핸들러 설정 완료');
  }

  /// 프로필 새로고침 수행
  static void _performProfileRefresh(dynamic timestamp) {
    try {
      if (_onProfileRefreshNeeded != null) {
        logger.i('프로필 새로고침 콜백 실행 중...');
        _onProfileRefreshNeeded!();
      } else {
        logger.w('프로필 새로고침 콜백이 등록되지 않았습니다.');
      }
    } catch (e, stackTrace) {
      logger.e('프로필 새로고침 중 오류 발생: $e', stackTrace: stackTrace);
    }
  }

  // 리워드 광고 로드
  static Future<bool> loadRewardedAd(String placementId, String userId) async {
    try {
      logger.i(
          'Loading rewarded ad with placementId: $placementId, userId: $userId');
      final result = await _channel.invokeMethod<bool>(
        'loadRewardedAd',
        {'placementId': placementId, 'userId': userId},
      );

      if (result ?? false) {
        logger.i('Rewarded ad loaded successfully');
      } else {
        logger.e('Failed to load rewarded ad');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('Error loading rewarded ad: ${e.message}');
      return false;
    } catch (e) {
      logger.e('Unexpected error loading rewarded ad: $e');
      return false;
    }
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
    _onProfileRefreshNeeded = null;
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

      // 프로필 갱신 콜백이 설정되어 있으면 호출
      if (_onProfileRefreshNeeded != null) {
        logger.i('프로필 갱신 콜백 테스트 호출');
        _onProfileRefreshNeeded!();
      } else {
        logger.i('프로필 갱신 콜백이 설정되지 않았습니다');
      }

      logger.i('🧪 광고 닫힘 이벤트 테스트 성공');
      return Future.value();
    } catch (e) {
      logger.e('🧪 광고 닫힘 이벤트 테스트 실패: $e');
      return Future.error(e);
    }
  }

  // 수동으로 프로필 갱신 호출 (이벤트가 동작하지 않을 경우 대체 방법)
  static void refreshProfileManually() {
    logger.i('수동 프로필 갱신 호출됨');

    try {
      if (_onProfileRefreshNeeded != null) {
        logger.i('수동 프로필 갱신 콜백 실행 중...');
        _onProfileRefreshNeeded!();
        logger.i('수동 프로필 갱신 완료');
      } else {
        logger.e('수동 프로필 갱신 실패: 콜백이 설정되지 않음');
      }
    } catch (e) {
      logger.e('수동 프로필 갱신 중 오류 발생: $e');
    }
  }

  // 광고 청시청 후 반드시 프로필 갱신하는 조합 함수
  static Future<bool> showRewardedAdWithProfileRefresh() async {
    final result = await showRewardedAd();

    // 광고 표시 성공 여부와 관계없이 일정 시간 후 프로필 갱신 시도
    // 이벤트 기반 갱신이 실패할 경우의 백업 방법
    Future.delayed(Duration(seconds: 5), () {
      logger.i('광고 표시 후 5초 지연 - 프로필 갱신 시도 중');
      refreshProfileManually();
    });

    return result;
  }
}

/* 사용 예시:

// 광고 닫힘 후 프로필 갱신 콜백 설정하기
void initializeAds() {
  PangleAds.initPangle("YOUR_APP_ID");
  
  // 방법 1: 프로필 갱신 콜백 설정 (권장)
  PangleAds.setOnProfileRefreshNeeded(() {
    // 여기서 프로필 갱신 API 호출
    refreshUserProfile();
  });
  
  // 방법 2: 이벤트 스트림 구독 (대안)
  final subscription = PangleAds.onAdDismissed.listen((_) {
    // 여기서 프로필 갱신 API 호출
    refreshUserProfile();
  });
  
  // 구독 해제 (위젯 dispose 시)
  // subscription.cancel();
}

// 예시: 프로필 갱신 메서드
void refreshUserProfile() async {
  try {
    // 프로필 갱신 API 호출
    // await UserRepository.refreshProfile();
    print('프로필이 성공적으로 갱신되었습니다');
  } catch (e) {
    print('프로필 갱신 중 오류 발생: $e');
  }
}

// 디버깅: 이벤트 전달 테스트 방법
void testAdEvents() {
  // 1. 우선 콜백 설정
  PangleAds.setOnProfileRefreshNeeded(() {
    print('프로필 갱신 테스트 성공!');
  });
  
  // 2. 이벤트 스트림 구독 확인
  final subscription = PangleAds.onAdDismissed.listen((_) {
    print('광고 닫힘 이벤트 수신 성공!');
  });
  
  // 3. 테스트 함수 호출로 이벤트 강제 발생
  PangleAds.testAdDismissed().then((_) {
    print('이벤트 테스트 완료');
  });
  
  // 테스트 후 구독 해제 필요 시
  // subscription.cancel();
}

// 문제 해결: 광고 닫힘 이벤트가 동작하지 않을 경우
// 1. 로그 확인: iOS와 Flutter 모두 로그 확인
// 2. 테스트 함수로 이벤트 전달 확인: PangleAds.testAdDismissed()
// 3. 광고 종료 후 수동 호출 임시 방편:
//    광고가 닫히지 않을 경우 수동으로 PangleAds.refreshProfileManually()를 호출
// 4. 대안: 이벤트 대신 타이머 기반 갱신 사용
//    PangleAds.showRewardedAdWithProfileRefresh() 호출

*/
