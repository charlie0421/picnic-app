import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// UMP(User Messaging Platform) 동의 관리 서비스
/// GDPR 및 기타 개인정보 보호 규정에 따른 사용자 동의를 관리합니다.
class ConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  bool _isInitialized = false;
  Completer<bool>? _initCompleter;

  /// 동의 서비스 초기화
  /// 앱 시작 시 MobileAds.instance.initialize() 전에 호출해야 합니다.
  Future<bool> initialize() async {
    if (_isInitialized && _initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<bool>();

    try {
      logger.i('[ConsentService] 동의 정보 확인 시작');

      final params = ConsentRequestParameters();

      // 동의 정보 업데이트 요청
      await _requestConsentInfoUpdate(params);

      _isInitialized = true;
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete(true);
      }
      return true;
    } catch (e, s) {
      logger.e('[ConsentService] 초기화 실패', error: e, stackTrace: s);
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete(false);
      }
      return false;
    }
  }

  /// 동의 정보 업데이트 요청
  Future<void> _requestConsentInfoUpdate(ConsentRequestParameters params) async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        logger.i('[ConsentService] 동의 정보 업데이트 완료');

        final status = await ConsentInformation.instance.getConsentStatus();
        logger.i('[ConsentService] 현재 동의 상태: $status');

        // 동의 폼이 필요하고 사용 가능한 경우 표시
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          if (status == ConsentStatus.required) {
            logger.i('[ConsentService] 동의 폼 표시 필요');
            await _loadAndShowConsentForm();
          }
        }

        completer.complete();
      },
      (FormError error) {
        logger.e('[ConsentService] 동의 정보 업데이트 실패: ${error.message}');
        completer.completeError(error);
      },
    );

    return completer.future;
  }

  /// 동의 폼 로드 및 표시
  Future<void> _loadAndShowConsentForm() async {
    final completer = Completer<void>();

    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        logger.i('[ConsentService] 동의 폼 로드 완료');

        consentForm.show((FormError? error) {
          if (error != null) {
            logger.e('[ConsentService] 동의 폼 표시 오류: ${error.message}');
          } else {
            logger.i('[ConsentService] 동의 폼 닫힘');
          }
          completer.complete();
        });
      },
      (FormError error) {
        logger.e('[ConsentService] 동의 폼 로드 실패: ${error.message}');
        completer.complete(); // 실패해도 앱은 계속 진행
      },
    );

    return completer.future;
  }

  /// 광고 요청 가능 여부 확인
  Future<bool> canRequestAds() async {
    return await ConsentInformation.instance.canRequestAds();
  }

  /// 현재 동의 상태 조회
  Future<ConsentStatus> getConsentStatus() async {
    return await ConsentInformation.instance.getConsentStatus();
  }

  /// GDPR 적용 여부 확인
  Future<bool> isGdprApplicable() async {
    final status = await getConsentStatus();
    // required 또는 obtained 상태면 GDPR 적용 지역
    return status == ConsentStatus.required ||
           status == ConsentStatus.obtained;
  }

  /// 동의 상태 초기화 (테스트용)
  void reset() {
    ConsentInformation.instance.reset();
    _isInitialized = false;
    _initCompleter = null;
    logger.i('[ConsentService] 동의 상태 초기화됨');
  }

  /// 동의 상태 초기화 후 재초기화
  Future<bool> resetAndReinitialize() async {
    logger.i('[ConsentService] 동의 상태 초기화 및 재초기화 시작');

    // UMP 동의 상태 초기화
    ConsentInformation.instance.reset();
    _isInitialized = false;
    _initCompleter = null;

    // 잠시 대기 후 재초기화
    await Future.delayed(const Duration(milliseconds: 500));

    // 재초기화
    return await initialize();
  }

  /// 개인정보 보호 옵션 폼 표시 (설정에서 다시 동의 변경 시)
  Future<void> showPrivacyOptionsForm() async {
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();

    if (status == PrivacyOptionsRequirementStatus.required) {
      await _loadAndShowConsentForm();
    } else {
      logger.i('[ConsentService] 개인정보 옵션 폼 표시 불필요');
    }
  }

  /// 현재 설정 상태 로깅 (디버그용)
  Future<void> logCurrentState() async {
    final status = await getConsentStatus();
    final canRequest = await canRequestAds();

    logger.i('[ConsentService] === 현재 상태 ===');
    logger.i('[ConsentService] 동의 상태: $status');
    logger.i('[ConsentService] 광고 요청 가능: $canRequest');
    logger.i('[ConsentService] 초기화 완료: $_isInitialized');
    logger.i('[ConsentService] ==================');
  }
}
