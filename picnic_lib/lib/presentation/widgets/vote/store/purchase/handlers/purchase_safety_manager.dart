import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';

/// 🎯 심플 구매 안전망 - 3-State 솔루션 (Simple is Better!)
class PurchaseSafetyManager {
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey;
  final VoidCallback _resetPurchaseState;

  static const Duration _safetyTimeout = Duration(seconds: 90);
  static const Duration _purchaseCooldown =
      Duration(seconds: 5); // 🎯 심플한 5초 쿨다운

  Timer? _safetyTimer;
  bool _safetyTimeoutTriggered = false;
  DateTime? _safetyTimeoutTime;
  VoidCallback? onTimeoutUIReset;

  // 🎯 3-State 심플 솔루션 - 이것만으로 모든 문제 해결!
  bool _isPurchaseInProgress = false; // 현재 구매 진행 중?
  String? _lastProcessedTransactionId; // 마지막 처리된 실제 거래 ID
  DateTime? _lastPurchaseTime; // 마지막 구매 시도 시간

  PurchaseSafetyManager({
    required GlobalKey<LoadingOverlayWithIconState> loadingKey,
    required VoidCallback resetPurchaseState,
  })  : _loadingKey = loadingKey,
        _resetPurchaseState = resetPurchaseState;

  /// 안전망 타이머 시작
  void startSafetyTimer() {
    _safetyTimer?.cancel();
    _safetyTimeoutTriggered = false;
    _safetyTimeoutTime = null;

    logger.i('🛡️ 안전망 타이머 시작 (${_safetyTimeout.inSeconds}초)');

    _safetyTimer = Timer(_safetyTimeout, () {
      if (!_safetyTimeoutTriggered) {
        _handleSafetyTimeout();
      }
    });
  }

  /// 안전망 타이머 중지
  void stopSafetyTimer() {
    if (_safetyTimer?.isActive == true) {
      logger.i('🛡️ 안전망 타이머 중지 - 정상 완료');
      _safetyTimer?.cancel();
    }
  }

  /// 안전망 타이머 정리
  void disposeSafetyTimer() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    logger.i('🛡️ 안전망 타이머 정리 완료');
  }

  /// 안전망 타임아웃 처리
  void _handleSafetyTimeout() {
    _safetyTimeoutTriggered = true;
    _safetyTimeoutTime = DateTime.now();

    logger.w('⏰ 안전망 타임아웃 발동! 90초 경과');

    _loadingKey.currentState?.hide();
    _resetPurchaseState();

    onTimeoutUIReset?.call();
  }

  /// 🎯 심플 구매 가능 체크 (1줄로 해결!)
  bool canAttemptPurchase() {
    if (_isPurchaseInProgress) {
      logger.w('🛡️ 구매 진행 중 - 추가 구매 차단');
      return false;
    }

    if (_lastPurchaseTime != null) {
      final elapsed = DateTime.now().difference(_lastPurchaseTime!);
      if (elapsed < _purchaseCooldown) {
        final remaining = _purchaseCooldown - elapsed;
        logger.w('🛡️ 구매 쿨다운: ${remaining.inMilliseconds}ms 남음');
        return false;
      }
    }

    return true;
  }

  /// 🎯 심플 구매 시작 (3줄로 해결!)
  void recordPurchaseAttempt({String? productId}) {
    _isPurchaseInProgress = true;
    _lastPurchaseTime = DateTime.now();
    logger.i('🎯 구매 시작: $productId');
  }

  /// 🎯 심플 구매 완료 (3줄로 해결!)
  void completePurchaseSession(String productId) {
    final transactionId =
        '${productId}_${DateTime.now().millisecondsSinceEpoch}';
    _isPurchaseInProgress = false;
    _lastProcessedTransactionId = transactionId;
    logger.i('🎯 구매 완료: $transactionId');
  }

  /// 🧹 구매 완료 후 클린 작업 - 시스템 상태 완전 정리
  Future<void> performPostPurchaseCleanup({
    required String productId,
    required String transactionId,
    PurchaseDetails? completedPurchase,
  }) async {
    logger.i('🧹 구매 완료 후 클린 작업 시작: $productId');

    try {
      // 1️⃣ 완료된 구매의 completePurchase 재확인
      if (completedPurchase?.pendingCompletePurchase == true) {
        logger.i('🧹 1️⃣ 완료된 구매 트랜잭션 최종 처리');
        await InAppPurchase.instance.completePurchase(completedPurchase!);
      }

      // 2️⃣ 성공한 구매 정보 확실히 기록
      _lastProcessedTransactionId = transactionId;
      logger.i('🧹 2️⃣ 성공 구매 기록 완료: $transactionId');

      // 3️⃣ 플랫폼별 캐시 정리
      await _performPlatformSpecificCleanup(productId);

      // 4️⃣ 내부 상태 완전 정리
      _cleanupInternalTransactionState();

      // 5️⃣ 다음 구매를 위한 환경 준비
      await _prepareForNextPurchase();

      logger.i('🧹 ✅ 구매 완료 후 클린 작업 성공적으로 완료');
    } catch (e) {
      logger.e('🧹 ❌ 구매 완료 후 클린 작업 중 오류: $e');
      // 클린 작업 실패해도 구매는 이미 성공했으므로 계속 진행
    }
  }

  /// 🧹 플랫폼별 캐시 정리
  Future<void> _performPlatformSpecificCleanup(String productId) async {
    if (Platform.isIOS) {
      await _performIOSCleanup(productId);
    } else if (Platform.isAndroid) {
      await _performAndroidCleanup(productId);
    }
  }

  /// 🍎 iOS 전용 클린 작업
  Future<void> _performIOSCleanup(String productId) async {
    logger.i('🧹 🍎 iOS StoreKit 클린 작업');

    try {
      // StoreKit 트랜잭션 큐 정리를 위한 짧은 대기
      await Future.delayed(Duration(milliseconds: 500));

      // 현재 트랜잭션들 확인 및 완료 처리
      final recentPurchases = await InAppPurchase.instance.purchaseStream
          .take(1)
          .timeout(Duration(seconds: 2))
          .first
          .catchError((e) => <PurchaseDetails>[]);

      for (var purchase in recentPurchases) {
        if (purchase.productID == productId &&
            purchase.pendingCompletePurchase) {
          logger.i('🧹 🍎 iOS 잔여 트랜잭션 완료: ${purchase.productID}');
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }

      logger.i('🧹 🍎 iOS StoreKit 클린 작업 완료');
    } catch (e) {
      logger.w('🧹 🍎 iOS 클린 작업 경고: $e');
    }
  }

  /// 🤖 Android 전용 클린 작업
  Future<void> _performAndroidCleanup(String productId) async {
    logger.i('🧹 🤖 Android Play Billing 클린 작업');

    try {
      // Play Billing 처리 완료를 위한 짧은 대기
      await Future.delayed(Duration(milliseconds: 300));

      // 미완료 트랜잭션들 확인
      final recentPurchases = await InAppPurchase.instance.purchaseStream
          .take(1)
          .timeout(Duration(seconds: 1))
          .first
          .catchError((e) => <PurchaseDetails>[]);

      for (var purchase in recentPurchases) {
        if (purchase.productID == productId &&
            purchase.pendingCompletePurchase) {
          logger.i('🧹 🤖 Android 잔여 트랜잭션 완료: ${purchase.productID}');
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }

      logger.i('🧹 🤖 Android Play Billing 클린 작업 완료');
    } catch (e) {
      logger.w('🧹 🤖 Android 클린 작업 경고: $e');
    }
  }

  /// 🧹 내부 트랜잭션 상태 정리
  void _cleanupInternalTransactionState() {
    // 구매 진행 상태는 이미 false로 설정됨 (completePurchaseSession에서)
    // 여기서는 추가적인 정리 작업만 수행
    logger.i('🧹 내부 트랜잭션 상태 정리 완료');
  }

  /// 🧹 다음 구매를 위한 환경 준비
  Future<void> _prepareForNextPurchase() async {
    // 쿨다운 시간 설정은 유지 (중복 구매 방지)
    // 시스템이 안정화될 시간을 줌
    await Future.delayed(Duration(milliseconds: 200));
    logger.i('🧹 다음 구매 환경 준비 완료');
  }

  /// 🚨 취소/에러 시 내부 상태 완전 리셋 (중요!)
  void resetInternalState({String reason = '상태 리셋'}) {
    _isPurchaseInProgress = false;
    _lastPurchaseTime = null;
    _lastProcessedTransactionId = null;
    logger.i('🔄 내부 상태 완전 리셋: $reason');
  }

  /// 🎯 플랫폼별 구매 판별 - iOS/Android 완전 분리!
  bool isActualPurchase({
    required dynamic purchaseDetails,
    required bool isActivePurchasing,
    required String? pendingProductId,
  }) {
    final productId = purchaseDetails.productID;
    final transactionId = purchaseDetails.purchaseID ?? productId;
    final platform = Platform.isIOS ? 'iOS' : 'Android';

    logger.i(
        '[플랫폼별] 🔍 $platform 구매 판별: $productId (진행중: $_isPurchaseInProgress)');

    // 🚨 공통 중복 차단 (모든 플랫폼)
    if (transactionId == _lastProcessedTransactionId) {
      logger.w('[플랫폼별] 🚨 중복 구매 차단: 이미 처리된 거래');
      return false;
    }

    // 📱 iOS와 🤖 Android 완전 분리 처리
    if (Platform.isIOS) {
      return _isActualPurchaseIOS(purchaseDetails, transactionId, productId);
    } else {
      return _isActualPurchaseAndroid(
          purchaseDetails, transactionId, productId);
    }
  }

  /// 🍎 iOS 전용 구매 판별 - 유연하고 관대한 처리
  bool _isActualPurchaseIOS(
      dynamic purchaseDetails, String transactionId, String productId) {
    // 🍎 1단계: 현재 진행 중인 구매 (확실한 경우)
    if (_isPurchaseInProgress &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      final statusText = purchaseDetails.status == PurchaseStatus.restored
          ? 'restored→정상'
          : 'purchased';
      logger.i('[iOS] ✅ 현재 진행 중인 구매 확인 ($statusText)');
      return true;
    }

    // 🍎 2단계: iOS 특성 - 늦은 신호나 상태 변화 허용
    if (_lastPurchaseTime != null &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      final elapsed = DateTime.now().difference(_lastPurchaseTime!);

      // 🍎 iOS는 30초까지 유연하게 허용 (StoreKit의 복잡성 고려)
      if (elapsed.inSeconds <= 30) {
        final statusText = purchaseDetails.status == PurchaseStatus.restored
            ? 'restored→정상'
            : 'purchased';
        logger.i(
            '[iOS] 🍎 iOS 유연성: 최근 구매 시도와 연관된 $statusText 구매 (${elapsed.inSeconds}초 전)');
        return true;
      }
    }

    // 🍎 3단계: iOS fallback - 예상치 못한 정상 구매 보호
    if ((purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) &&
        _lastPurchaseTime != null) {
      final elapsed = DateTime.now().difference(_lastPurchaseTime!);
      if (elapsed.inMinutes <= 3) {
        final statusText = purchaseDetails.status == PurchaseStatus.restored
            ? 'restored→정상'
            : 'purchased';
        logger.w(
            '[iOS] 🍎 iOS 극한 fallback: 3분 이내 $statusText 구매 (${elapsed.inMinutes}분 전) - 신중히 허용');
        return true;
      }
    }

    final status = purchaseDetails.status.toString();
    logger.w('[iOS] 🍎 iOS 차단: 연관성 없는 구매 ($status)');
    return false;
  }

  /// 🤖 Android 전용 구매 판별 - 엄격하고 직선적인 처리
  bool _isActualPurchaseAndroid(
      dynamic purchaseDetails, String transactionId, String productId) {
    // 🤖 1단계: 현재 진행 중인 구매만 허용 (엄격)
    if (_isPurchaseInProgress &&
        purchaseDetails.status == PurchaseStatus.purchased) {
      logger.i('[Android] ✅ 현재 진행 중인 구매 확인');
      return true;
    }

    // 🤖 2단계: Android 특성 - 짧은 지연만 허용
    if (_lastPurchaseTime != null &&
        purchaseDetails.status == PurchaseStatus.purchased) {
      final elapsed = DateTime.now().difference(_lastPurchaseTime!);

      // 🤖 Android는 10초만 허용 (Google Play Billing은 더 직선적)
      if (elapsed.inSeconds <= 10) {
        logger.i(
            '[Android] 🤖 Android 엄격 허용: 최근 구매 시도 (${elapsed.inSeconds}초 전)');
        return true;
      }
    }

    // 🤖 3단계: 의심스러운 경우 엄격 차단
    if (!_isPurchaseInProgress) {
      logger.w('[Android] 🤖 Android 엄격 차단: 구매 진행 중이 아님');
      return false;
    }

    logger.w('[Android] 🤖 Android 기타 차단');
    return false;
  }

  /// 구매 취소 감지
  bool isPurchaseCanceled(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.canceled) {
      return true;
    }

    if (purchaseDetails.status == PurchaseStatus.error) {
      final errorMessage = purchaseDetails.error?.message.toLowerCase() ?? '';
      final errorCode = purchaseDetails.error?.code ?? '';

      return _checkCancelKeywords(errorMessage) ||
          _checkCancelErrorCodes(errorCode, errorMessage);
    }

    return false;
  }

  bool _checkCancelKeywords(String errorMessage) {
    const cancelKeywords = [
      'cancel',
      'cancelled',
      'canceled',
      'user cancel',
      'abort',
      'dismiss',
      'authentication',
      'touch id',
      'face id',
      'biometric',
      'passcode',
      'unauthorized',
      'permission denied',
      'operation was cancelled',
      'user cancelled',
      'user denied',
      'authentication failed',
      'authentication cancelled',
      'user interaction required',
      'interaction not allowed',
      'declined',
      'rejected',
      'stopped',
      'interrupted',
      'terminated',
      'aborted'
    ];

    for (final keyword in cancelKeywords) {
      if (errorMessage.contains(keyword)) {
        logger.i('🛡️ 취소 키워드 감지: $keyword');
        return true;
      }
    }
    return false;
  }

  bool _checkCancelErrorCodes(String errorCode, String errorMessage) {
    const cancelErrorCodes = [
      'PAYMENT_CANCELED',
      'USER_CANCELED',
      '2',
      'SKErrorPaymentCancelled',
      'BILLING_RESPONSE_USER_CANCELED',
      '-1002',
      '-2',
      'LAErrorUserCancel'
    ];

    for (final code in cancelErrorCodes) {
      if (errorCode.contains(code) || errorMessage.contains(code)) {
        logger.i('🛡️ 취소 에러 코드 감지: $code');
        return true;
      }
    }
    return false;
  }

  /// 늦은 구매인지 판별
  bool isLatePurchase(bool isActivePurchasing) {
    final isLate = !isActivePurchasing &&
        _safetyTimeoutTriggered &&
        _safetyTimeoutTime != null;

    if (isLate) {
      logger.i('🛡️ 늦은 구매 성공 감지');
    }

    return isLate;
  }

  /// 늦은 구매 성공 리셋
  void resetLatePurchaseSuccess() {
    _safetyTimeoutTriggered = false;
    _safetyTimeoutTime = null;
    logger.i('🛡️ 늦은 구매 성공 상태 리셋됨');
  }

  /// 구매 결과 처리
  Future<void> handlePurchaseResult(
    Map<String, dynamic> purchaseResult,
    bool isActivePurchasing,
    Function(String) showErrorDialog,
  ) async {
    final success = purchaseResult['success'] as bool;
    final wasCancelled = purchaseResult['wasCancelled'] as bool;
    final errorMessage = purchaseResult['errorMessage'] as String?;

    if (wasCancelled) {
      logger.i('[심플] 구매 취소 - 조용히 처리');
      resetInternalState(reason: '구매 취소'); // 🚨 내부 상태도 리셋!
      _resetPurchaseState();
      _loadingKey.currentState?.hide();
    } else if (!success) {
      logger.e('[심플] 구매 실패: $errorMessage');
      resetInternalState(reason: '구매 실패'); // 🚨 내부 상태도 리셋!
      _resetPurchaseState();
      _loadingKey.currentState?.hide();
      await showErrorDialog(errorMessage ?? '구매 처리 중 오류가 발생했습니다.');
    } else {
      logger.i('[심플] 구매 시작 성공');
      startSafetyTimer();
    }
  }

  // Getters
  bool get isSafetyTimeoutTriggered => _safetyTimeoutTriggered;
  DateTime? get safetyTimeoutTime => _safetyTimeoutTime;
  DateTime? get lastPurchaseAttempt => _lastPurchaseTime;
}
