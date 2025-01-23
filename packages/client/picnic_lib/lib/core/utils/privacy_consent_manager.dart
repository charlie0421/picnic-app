import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class PrivacyConsentManager {
  static Future<void> initialize() async {
    if (!isMobile()) return;

    try {
      // iOS에서만 ATT 동의를 먼저 얻습니다
      if (Platform.isIOS) {
        final attGranted = await _requestATTConsent();
        if (!attGranted) {
          // ATT 동의를 얻지 못한 경우 비개인화 광고로 초기화
          await _initializeNonPersonalizedAds();
          return;
        }
      }

      // UMP 초기화 및 동의 얻기
      await _initializeUMP();

      // Android에서는 UMP 이후에 ATT 동의를 얻습니다
      if (Platform.isAndroid) {
        final attGranted = await _requestATTConsent();
        if (!attGranted) {
          // ATT 동의를 얻지 못한 경우 비개인화 광고로 초기화
          await _initializeNonPersonalizedAds();
          return;
        }
      }

      // AdMob 초기화
      await _initializeAdMob();

      logger.i('Privacy consent and ads initialization completed');
    } catch (e, s) {
      logger.e('Privacy consent initialization error', error: e, stackTrace: s);
      // 에러가 발생해도 광고는 비개인화로 초기화
      await _initializeNonPersonalizedAds();
    }
  }

  static Future<void> _initializeUMP() async {
    final completer = Completer<void>();

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: ['TEST-DEVICE-HASHED-ID'],
            )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _showConsentForm();
          }
          completer.complete();
        } catch (e, s) {
          logger.e('Error showing consent form', error: e, stackTrace: s);
          completer.completeError(e);
        }
      },
      (FormError error) {
        completer.completeError(error);
      },
    );

    return completer.future;
  }

  static Future<void> _showConsentForm() {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired(
      (FormError? error) {
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete();
        }
      },
    );

    return completer.future;
  }

  static Future<bool> _requestATTConsent() async {
    try {
      // ATT 상태 확인 전에 잠시 대기 (iOS 14+ 권장사항)
      await Future.delayed(const Duration(milliseconds: 500));

      // 현재 상태 확인
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      logger.i('Initial ATT status: $status');

      if (status == TrackingStatus.notDetermined) {
        // ATT 동의 요청 전에 약간의 지연 추가 (권장사항)
        await Future.delayed(const Duration(seconds: 1));

        // ATT 동의 요청
        final requestedStatus =
            await AppTrackingTransparency.requestTrackingAuthorization();
        logger.i('ATT status after request: $requestedStatus');

        return requestedStatus == TrackingStatus.authorized;
      }

      return status == TrackingStatus.authorized;
    } catch (e) {
      logger.e('Error requesting ATT consent: $e');
      return false;
    }
  }

  static Future<void> _initializeAdMob() async {
    final attStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
    final umpStatus = await ConsentInformation.instance.getConsentStatus();

    logger.i('Initializing AdMob with ATT: $attStatus, UMP: $umpStatus');

    // ATT가 거부되었거나 UMP 동의가 없는 경우 비개인화 광고만 표시
    if (attStatus != TrackingStatus.authorized ||
        (umpStatus != ConsentStatus.obtained &&
            umpStatus != ConsentStatus.notRequired)) {
      await _initializeNonPersonalizedAds();
      return;
    }

    // 모든 권한이 허용된 경우에만 개인화 광고 초기화
    await MobileAds.instance.initialize();
  }

  static Future<void> _initializeNonPersonalizedAds() async {
    final config = RequestConfiguration(
      tagForChildDirectedTreatment: TagForUnderAgeOfConsent.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
      maxAdContentRating: MaxAdContentRating.g,
      // 추적 거부 시 테스트 디바이스 ID도 제거
      testDeviceIds: [],
    );

    await MobileAds.instance.updateRequestConfiguration(config);
    await MobileAds.instance.initialize();
  }

  static Future<bool> canShowPersonalizedAds() async {
    if (!isMobile()) return false;

    try {
      final attStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      final umpStatus = await ConsentInformation.instance.getConsentStatus();

      return attStatus == TrackingStatus.authorized &&
          (umpStatus == ConsentStatus.obtained ||
              umpStatus == ConsentStatus.notRequired);
    } catch (e, s) {
      logger.e('Error checking ads personalization status',
          error: e, stackTrace: s);
      return false;
    }
  }
}
