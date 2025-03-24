// unity_ads_platform.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// Unity Ads 플랫폼 구현
class UnityAdsPlatform extends AdPlatform {
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static String _lastInitError = '';

  UnityAdsPlatform(WidgetRef ref, BuildContext context, String id,
      [AnimationController? animationController])
      : super(ref, context, id, animationController);

  @override
  Future<void> initialize() async {
    // 이미 초기화 중이거나 완료된 경우
    if (_isInitializing || _isInitialized) {
      if (_isInitialized) {
        logger.i('Unity Ads 이미 초기화됨');
      } else {
        logger.i('Unity Ads 초기화 중...');
      }
      return;
    }

    _isInitializing = true;

    // 로그를 통해 사용하는 환경 변수 값 확인
    final gameId =
        isIOS() ? Environment.unityAppleGameId : Environment.unityAndroidGameId;
    final placementId = isIOS()
        ? Environment.unityIosPlacementId
        : Environment.unityAndroidPlacementId;

    logger.i('Unity Ads 초기화 시작');
    logger.i('Unity Ads 게임 ID: $gameId (${isIOS() ? "iOS" : "Android"})');
    logger.i('Unity Ads 배치 ID: $placementId');

    if (gameId.isEmpty) {
      _lastInitError = 'Unity Ads 게임 ID가 비어 있습니다';
      logger.e(_lastInitError);
      _isInitializing = false;
      return;
    }

    try {
      // 테스트 모드로 초기화 (개발 환경에서는 true로 설정)
      final testMode = true;

      await UnityAds.init(
        gameId: gameId,
        testMode: testMode,
        onComplete: () {
          logger.i('Unity Ads 초기화 완료 (testMode: $testMode)');
          _isInitialized = true;
          _isInitializing = false;
          _lastInitError = '';
        },
        onFailed: (error, message) {
          _lastInitError = 'Unity Ads 초기화 실패: $message (오류 코드: $error)';
          logger.e(_lastInitError);
          _isInitializing = false;
        },
      );
    } catch (e, s) {
      _lastInitError = 'Unity Ads 초기화 중 예외 발생: $e';
      logger.e(_lastInitError, error: e, stackTrace: s);
      _isInitializing = false;
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      final placementId = isIOS()
          ? Environment.unityIosPlacementId
          : Environment.unityAndroidPlacementId;

      // Unity Ads 초기화 상태 확인
      if (!_isInitialized) {
        if (_lastInitError.isNotEmpty) {
          logger.e('Unity Ads showAd 실패: 초기화 오류 - $_lastInitError');
          if (context.mounted) {
            showErrorDialog(
              S.of(context).label_ads_sdk_init_fail,
              error: _lastInitError,
            );
            throw Exception(_lastInitError);
          }
          return;
        }

        // 초기화 재시도
        logger.i('Unity Ads 초기화되지 않음 - 초기화 시도');
        await initialize();

        // 초기화가 여전히 실패한 경우
        if (!_isInitialized) {
          logger.e('Unity Ads 초기화 재시도 실패');
          if (context.mounted) {
            showErrorDialog(
              S.of(context).label_ads_sdk_init_fail,
              error: _lastInitError.isEmpty ? '알 수 없는 오류' : _lastInitError,
            );
            throw Exception(_lastInitError);
          }
          return;
        }
      }

      // 배치 ID 확인
      if (placementId!.isEmpty) {
        logger.e('Unity Ads 배치 ID가 비어 있습니다');
        if (context.mounted) {
          showErrorDialog(
            S.of(context).label_ads_load_fail,
            error: 'Unity Ads 배치 ID가 비어 있습니다',
          );
          throw Exception('Unity Ads 배치 ID가 비어 있습니다');
        }
        return;
      }

      // 애니메이션 시작
      startButtonAnimation();

      // 최대 30초 후에는 무조건 애니메이션 중지 (안전장치)
      Future.delayed(const Duration(seconds: 30), () {
        if (context.mounted) {
          logger.i('Unity Ads 안전장치: 애니메이션 중지');
          stopAllAnimations();
        }
      });

      logger.i('Unity Ads 로드 시작: $placementId');
      UnityAds.load(
        placementId: placementId,
        onComplete: (placementId) async {
          logger.i('Unity Ads 로드 완료: $placementId');
          if (!context.mounted) return;

          logger.i('Unity Ads 표시 시작');
          await UnityAds.showVideoAd(
            placementId: placementId,
            onStart: (placementId) {
              logger.i('Unity Ads 비디오 시작됨');
              // 광고가 실제로 시작될 때 애니메이션 중지
              stopAllAnimations();
            },
            onSkipped: (placementId) {
              logger.i('Unity Ads 비디오 건너뜀');
              if (context.mounted) {
                stopAllAnimations();
              }
            },
            onComplete: (placementId) {
              logger.i('Unity Ads 비디오 완료됨 - 보상 지급');
              if (context.mounted) {
                stopAllAnimations();
                refreshUserProfile();
              }
            },
            onFailed: (placementId, error, message) {
              logger.e('Unity Ads 비디오 실패: $message (오류 코드: $error)');
              if (context.mounted) {
                stopAllAnimations();

                showErrorDialog(S.of(context).label_ads_show_fail,
                    error: message);
              }
            },
          );
        },
        onFailed: (placementId, error, message) {
          logger.e('Unity Ads 로드 실패: $message (오류 코드: $error)');
          if (context.mounted) {
            stopAllAnimations();

            showErrorDialog(S.of(context).label_ads_load_fail, error: message);
          }
        },
      );
    });
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('Unity Ads 오류', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      stopAllAnimations();
    }
  }
}
