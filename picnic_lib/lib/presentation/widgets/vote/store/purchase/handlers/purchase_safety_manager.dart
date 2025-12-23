import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/restore_purchase_handler.dart';

/// 🎯 심플 구매 안전망 - 3-State 솔루션 (Simple is Better!)
class PurchaseSafetyManager implements PurchaseSafetyManagerInterface {
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey;
  final VoidCallback _resetPurchaseState;

  static const Duration _safetyTimeout = Duration(seconds: 90);
  static const Duration _basePurchaseCooldown =
      Duration(seconds: 15); // 🎯 기본 15초 (60초 → 15초로 단축)
  static const Duration _consecutivePurchaseCooldown =
      Duration(seconds: 30); // 🔄 연속 구매 시 30초 (60초 → 30초로 단축)

  // 🔄 연속 구매 추적
  int _consecutivePurchaseCount = 0;
  DateTime? _firstPurchaseInSession;

  Timer? _safetyTimer;
  bool _safetyTimeoutTriggered = false;
  DateTime? _safetyTimeoutTime;
  VoidCallback? onTimeoutUIReset;

  // 🎯 3-State 심플 솔루션 - 이것만으로 모든 문제 해결!
  bool _isPurchaseInProgress = false; // 현재 구매 진행 중?
  String? _lastProcessedTransactionId; // 마지막 처리된 실제 거래 ID
  DateTime? _lastPurchaseTime; // 마지막 구매 시도 시간
  String? _currentProductId; // 현재 진행 중인 상품 ID

  // 🧩 상품별 쿨타임/연속 구매 세션 추적
  final Map<String, DateTime> _lastPurchaseTimeByProduct = {}; // productId -> last attempt time
  final Map<String, int> _consecutivePurchaseCountByProduct = {}; // productId -> count
  final Map<String, DateTime> _firstPurchaseInSessionByProduct = {}; // productId -> first in session
  final Map<String, DateTime> _productCooldownUntil = {}; // productId -> enforced cooldown until

  // 🛡️ 글로벌 트랜잭션 중복 방지 (iOS 연속 결제 문제 해결)
  final Set<String> _globalProcessedTransactions = {};
  static const int _maxGlobalTransactionCache = 50;

  // 🛡️ 성공 다이얼로그 중복 표시 방지
  bool _isSuccessDialogShowing = false;
  DateTime? _lastSuccessDialogTime;
  static const Duration _successDialogCooldown = Duration(seconds: 2);

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

  /// 🎯 심플 구매 가능 체크 + 연속 구매 보호 (적응형 쿨다운)
  @override
  bool canAttemptPurchase() {
    // 전역 쿨다운은 사용하지 않음. 진행 중 여부만 확인
    if (_isPurchaseInProgress) {
      logger.w('🛡️ 구매 진행 중 - 추가 구매 차단');
      return false;
    }
    return true;
  }

  /// 🎯 상품별 구매 가능 체크 (1분 쿨타임을 개별 상품 기준으로 적용)
  bool canAttemptPurchaseForProduct(String productId) {
    if (_isPurchaseInProgress) {
      logger.w('🛡️ 구매 진행 중 - 추가 구매 차단');
      return false;
    }

    // 1) 강제(오버라이드) 쿨타임 우선 적용
    final until = _productCooldownUntil[productId];
    if (until != null) {
      final now = DateTime.now();
      if (now.isBefore(until)) {
        final remaining = until.difference(now);
        logger.w('🛡️ [상품별] 강제 쿨다운 차단: $productId - 남은 ${remaining.inSeconds}s, 종료 예정: ${until.toIso8601String()}');
        return false;
      } else {
        // 만료된 오버라이드는 제거
        _productCooldownUntil.remove(productId);
      }
    }

    final lastForProduct = _lastPurchaseTimeByProduct[productId];
    if (lastForProduct != null) {
      final elapsed = DateTime.now().difference(lastForProduct);
      final requiredCooldown = _getAdaptiveCooldownForProduct(productId);
      if (elapsed < requiredCooldown) {
        final remaining = requiredCooldown - elapsed;
        final endsAt = DateTime.now().add(remaining).toIso8601String();
        logger.w(
            '🛡️ [상품별] 구매 쿨다운 차단: $productId - 남은 ${remaining.inSeconds}s (경과 ${elapsed.inSeconds}s / 필요 ${requiredCooldown.inSeconds}s), 종료 예정: $endsAt');
        return false;
      }
    }

    return true;
  }

  /// 🔄 적응형 쿨다운 시간 계산
  Duration _getAdaptiveCooldown() {
    // 🔄 연속 구매 세션 감지 (10분 내 구매들)
    if (_firstPurchaseInSession != null) {
      final sessionElapsed =
          DateTime.now().difference(_firstPurchaseInSession!);
      if (sessionElapsed.inMinutes > 10) {
        // 세션 리셋
        _consecutivePurchaseCount = 0;
        _firstPurchaseInSession = null;
      }
    }

    // 🔄 연속 구매 횟수에 따른 적응형 쿨다운
    if (_consecutivePurchaseCount >= 2) {
      logger.w('🔄 연속 구매 감지 ($_consecutivePurchaseCount회) - 확장된 쿨다운 적용');
      return _consecutivePurchaseCooldown; // 15초
    }

    return _basePurchaseCooldown; // 8초
  }

  /// 🔄 상품별 적응형 쿨다운 시간 계산
  Duration _getAdaptiveCooldownForProduct(String productId) {
    // 🔄 연속 구매 세션 감지 (10분 내 구매들)
    final firstInSession = _firstPurchaseInSessionByProduct[productId];
    if (firstInSession != null) {
      final sessionElapsed = DateTime.now().difference(firstInSession);
      if (sessionElapsed.inMinutes > 10) {
        // 세션 리셋
        _consecutivePurchaseCountByProduct[productId] = 0;
        _firstPurchaseInSessionByProduct.remove(productId);
      }
    }

    final count = _consecutivePurchaseCountByProduct[productId] ?? 0;
    if (count >= 2) {
      logger.w('🔄 [상품별] 연속 구매 감지 ($count회) - 확장된 쿨다운 적용: $productId');
      return _consecutivePurchaseCooldown;
    }

    return _basePurchaseCooldown;
  }

  /// 🔒 중복 JWS 감지 시 강제로 쿨다운 활성화
  void activateDuplicateCooldown({String? productId, Duration? cooldown}) {
    final now = DateTime.now();
    _lastPurchaseTime = now; // 전역 최근 시도 갱신 (지연 신호 판별 등에 사용)
    _firstPurchaseInSession ??= now;
    _consecutivePurchaseCount++;

    final targetProductId = productId ?? _currentProductId;
    if (targetProductId != null) {
      _lastPurchaseTimeByProduct[targetProductId] = now;
      _firstPurchaseInSessionByProduct[targetProductId] ??= now;
      _consecutivePurchaseCountByProduct[targetProductId] =
          (_consecutivePurchaseCountByProduct[targetProductId] ?? 0) + 1;

      final enforced = cooldown ?? _getAdaptiveCooldownForProduct(targetProductId);
      _productCooldownUntil[targetProductId] = now.add(enforced);
      logger.w('🛡️ [상품별] Duplicate JWS detected - cooldown enforced for '
          '$targetProductId (${enforced.inSeconds}s), until=${_productCooldownUntil[targetProductId]!.toIso8601String()}');
    } else {
      final cooldown = _getAdaptiveCooldown();
      logger.w(
          '🛡️ Duplicate JWS detected - cooldown activated (no productId) (${cooldown.inSeconds}s)');
    }
  }

  /// ⏱️ 남은 쿨다운 시간 반환 (없으면 null)
  Duration? remainingCooldown() {
    if (_lastPurchaseTime == null) return null;
    final required = _getAdaptiveCooldown();
    final elapsed = DateTime.now().difference(_lastPurchaseTime!);
    if (elapsed < required) {
      return required - elapsed;
    }
    return null;
  }

  /// ⏱️ 상품별 남은 쿨다운 시간 반환 (없으면 null)
  Duration? remainingCooldownForProduct(String productId) {
    final lastForProduct = _lastPurchaseTimeByProduct[productId];
    if (lastForProduct == null) return null;
    final required = _getAdaptiveCooldownForProduct(productId);
    final elapsed = DateTime.now().difference(lastForProduct);
    if (elapsed < required) {
      return required - elapsed;
    }
    return null;
  }

  /// 🧹 상품별 쿨타임/세션 상태 초기화 (일반 오류/취소 시 사용)
  void clearProductCooldown(String productId) {
    _lastPurchaseTimeByProduct.remove(productId);
    _consecutivePurchaseCountByProduct.remove(productId);
    _firstPurchaseInSessionByProduct.remove(productId);
    _productCooldownUntil.remove(productId);
    if (_currentProductId == productId) {
      _currentProductId = null;
    }
    logger.i('🧹 [상품별] 쿨타임 초기화: $productId');
  }

  /// 🎯 심플 구매 시작 + 연속 구매 추적 (3줄로 해결!)
  void recordPurchaseAttempt({String? productId}) {
    _isPurchaseInProgress = true;
    _lastPurchaseTime = DateTime.now();
    if (productId != null) {
      // 성공 시에만 상품별 쿨타임을 적용하므로 여기서는 상품 ID만 저장
      _currentProductId = productId;
    }

    // 🔄 연속 구매 세션 추적
    _firstPurchaseInSession ??= _lastPurchaseTime;
    _consecutivePurchaseCount++;

    logger.i('🎯 구매 시작: $productId (연속 $_consecutivePurchaseCount회째)');
  }

  /// 🎯 심플 구매 완료 + 타이머 정리 (3줄로 해결!)
  void completePurchaseSession(String productId) {
    final transactionId =
        '${productId}_${DateTime.now().millisecondsSinceEpoch}';
    _isPurchaseInProgress = false;
    _lastProcessedTransactionId = transactionId;
    // ✅ 성공 직후에도 연속 구매를 막기 위해 최근 시도 시간을 현재로 갱신
    _lastPurchaseTime = DateTime.now();
    _currentProductId = productId;
    _lastPurchaseTimeByProduct[productId] = _lastPurchaseTime!;
    _firstPurchaseInSessionByProduct[productId] ??= _lastPurchaseTime!;
    _consecutivePurchaseCountByProduct[productId] =
        (_consecutivePurchaseCountByProduct[productId] ?? 0) + 1;

    // 🛡️ 정상 구매 완료 시 안전망 타이머 정리
    stopSafetyTimer();

    logger.i('🎯 구매 완료: $transactionId (타이머 정리됨)');
  }

  /// 🧹 모든 타이머 완전 정리 (정상 구매 완료 시)
  void cleanupAllTimersOnSuccess() {
    // 1️⃣ 안전망 타이머 정리
    stopSafetyTimer();

    // 2️⃣ 안전망 상태 완전 리셋 (단, 구매 세션 정보는 유지)
    _safetyTimeoutTriggered = false;
    _safetyTimeoutTime = null;

    logger.i('🧹 ✅ 모든 타이머 정리 완료 (정상 구매 성공 시)');
  }

  /// 🧹 구매 완료 후 클린 작업 - 연속 구매 최적화
  Future<void> performPostPurchaseCleanup({
    required String productId,
    required String transactionId,
    PurchaseDetails? completedPurchase,
  }) async {
    final isConsecutivePurchase = _consecutivePurchaseCount >= 2;
    final cleanupType = isConsecutivePurchase ? '간소화' : '전체';

    logger.i('🧹 구매 완료 후 클린 작업 시작: $productId ($cleanupType)');

    try {
      // 1️⃣ 완료된 구매의 completePurchase 재확인
      if (completedPurchase?.pendingCompletePurchase == true) {
        logger.i('🧹 1️⃣ 완료된 구매 트랜잭션 최종 처리');
        await InAppPurchase.instance.completePurchase(completedPurchase!);
      }

      // 2️⃣ 성공한 구매 정보 확실히 기록
      _lastProcessedTransactionId = transactionId;
      logger.i('🧹 2️⃣ 성공 구매 기록 완료: $transactionId');

      // 3️⃣ 플랫폼별 캐시 정리 (연속 구매 시 간소화)
      if (isConsecutivePurchase) {
        await _performLightweightCleanup(productId);
      } else {
        await _performPlatformSpecificCleanup(productId);
      }

      // 4️⃣ 내부 상태 완전 정리
      _cleanupInternalTransactionState();

      // 5️⃣ 다음 구매를 위한 환경 준비 (연속 구매 시 단축)
      await _prepareForNextPurchase(isConsecutivePurchase);

      logger.i('🧹 ✅ 구매 완료 후 클린 작업 성공적으로 완료 ($cleanupType)');
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

  /// 🚀 간소화된 클린 작업 (연속 구매 시)
  Future<void> _performLightweightCleanup(String productId) async {
    logger.i('🚀 간소화된 클린 작업 시작 (연속 구매 최적화)');

    try {
      if (Platform.isIOS) {
        // iOS: 최소한의 대기만 (StoreKit 안정화)
        await Future.delayed(Duration(milliseconds: 100));
        logger.i('🚀 🍎 iOS 간소화 클린 완료');
      } else if (Platform.isAndroid) {
        // Android: 매우 짧은 대기
        await Future.delayed(Duration(milliseconds: 50));
        logger.i('🚀 🤖 Android 간소화 클린 완료');
      }
    } catch (e) {
      logger.w('🚀 간소화 클린 작업 경고: $e');
    }
  }

  /// 🍎 iOS 전용 클린 작업 (강화된 버전)
  Future<void> _performIOSCleanup(String productId) async {
    logger.i('🧹 🍎 iOS StoreKit 클린 작업 (강화된 버전)');

    try {
      // StoreKit 트랜잭션 큐 정리를 위한 짧은 대기
      await Future.delayed(Duration(milliseconds: 300));

      // 🛡️ 1차: 현재 트랜잭션들 확인 및 완료 처리
      final recentPurchases = await InAppPurchase.instance.purchaseStream
          .take(1)
          .timeout(Duration(seconds: 1))
          .first
          .catchError((e) => <PurchaseDetails>[]);

      int completedCount = 0;
      for (var purchase in recentPurchases) {
        if (purchase.pendingCompletePurchase) {
          try {
            await InAppPurchase.instance.completePurchase(purchase);
            completedCount++;
            logger.i('🧹 🍎 iOS 잔여 트랜잭션 완료: ${purchase.productID}');
          } catch (e) {
            logger.w('🧹 🍎 iOS 트랜잭션 완료 실패: ${purchase.productID} - $e');
          }
        }
      }

      // 🛡️ 2차: 추가 정리 (같은 상품에 대한 중복 트랜잭션 정리)
      if (completedCount > 0) {
        await Future.delayed(Duration(milliseconds: 200));

        final additionalPurchases = await InAppPurchase.instance.purchaseStream
            .take(1)
            .timeout(Duration(milliseconds: 500))
            .first
            .catchError((e) => <PurchaseDetails>[]);

        for (var purchase in additionalPurchases) {
          if (purchase.productID == productId && purchase.pendingCompletePurchase) {
            try {
              await InAppPurchase.instance.completePurchase(purchase);
              logger.i('🧹 🍎 iOS 추가 잔여 트랜잭션 완료: ${purchase.productID}');
            } catch (e) {
              logger.w('🧹 🍎 iOS 추가 트랜잭션 완료 실패: $e');
            }
          }
        }
      }

      logger.i('🧹 🍎 iOS StoreKit 클린 작업 완료 (정리: $completedCount개)');
    } catch (e) {
      logger.w('🧹 🍎 iOS 클린 작업 경고: $e');
    }
  }

  /// 🤖 Android 전용 클린 작업 (최적화)
  Future<void> _performAndroidCleanup(String productId) async {
    logger.i('🧹 🤖 Android Play Billing 클린 작업');

    try {
      // Play Billing 처리 완료를 위한 짧은 대기 (최적화: 300ms → 200ms)
      await Future.delayed(Duration(milliseconds: 200));

      // 미완료 트랜잭션들 확인 (최적화: 1초 → 500ms)
      final recentPurchases = await InAppPurchase.instance.purchaseStream
          .take(1)
          .timeout(Duration(milliseconds: 500))
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
  Future<void> _prepareForNextPurchase(bool isConsecutivePurchase) async {
    // 쿨다운 시간 설정은 유지 (중복 구매 방지)
    // 시스템이 안정화될 시간을 줌
    final waitTime = isConsecutivePurchase ? 100 : 200; // 연속 구매 시 더 짧게
    await Future.delayed(Duration(milliseconds: waitTime));
    logger.i('🧹 다음 구매 환경 준비 완료 (${waitTime}ms)');
  }

  /// 🚨 취소/에러 시 내부 상태 완전 리셋 (중요!)
  void resetInternalState({String reason = '상태 리셋'}) {
    _isPurchaseInProgress = false;
    _lastProcessedTransactionId = null;

    // 🔄 연속 구매 세션도 리셋 (에러/취소 시)
    if (reason.contains('취소') || reason.contains('실패')) {
      _consecutivePurchaseCount = 0;
      _firstPurchaseInSession = null;
      logger.i('🔄 연속 구매 세션 리셋: $reason');
    }

    logger.i('🔄 내부 상태 완전 리셋: $reason');
  }

  /// UI만 리셋하고 쿨다운 시각은 유지
  void resetUIOnly({String reason = 'UI 상태 리셋'}) {
    _isPurchaseInProgress = false;
    // _lastPurchaseTime 유지 → 연속 구매 차단 지속
    // _lastProcessedTransactionId 유지 가능 (로직 영향 없음)
    logger.i('🔄 UI 상태 리셋(쿨다운 유지): $reason');
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

  // 🛡️ ===== iOS 전용: 성공 다이얼로그 중복 방지 메서드들 =====

  /// 🛡️ iOS 전용: 성공 다이얼로그 표시 가능 여부 확인
  bool canShowSuccessDialog() {
    // 🍎 iOS에서만 적용
    if (!Platform.isIOS) return true;

    // 이미 다이얼로그가 표시 중이면 차단
    if (_isSuccessDialogShowing) {
      logger.w('🍎 iOS: 성공 다이얼로그 이미 표시 중 - 중복 표시 차단');
      return false;
    }

    // 최근에 다이얼로그를 표시했으면 차단
    if (_lastSuccessDialogTime != null) {
      final elapsed = DateTime.now().difference(_lastSuccessDialogTime!);
      if (elapsed < _successDialogCooldown) {
        logger.w('🍎 iOS: 성공 다이얼로그 쿨다운 중 (${elapsed.inMilliseconds}ms) - 중복 표시 차단');
        return false;
      }
    }

    return true;
  }

  /// 🛡️ iOS 전용: 성공 다이얼로그 표시 시작 기록
  void onSuccessDialogShown() {
    // 🍎 iOS에서만 적용
    if (!Platform.isIOS) return;

    _isSuccessDialogShowing = true;
    _lastSuccessDialogTime = DateTime.now();
    logger.i('🍎 iOS: 성공 다이얼로그 표시 시작 기록');
  }

  /// 🛡️ iOS 전용: 성공 다이얼로그 표시 완료 기록
  void onSuccessDialogDismissed() {
    // 🍎 iOS에서만 적용
    if (!Platform.isIOS) return;

    _isSuccessDialogShowing = false;
    logger.i('🍎 iOS: 성공 다이얼로그 표시 완료 기록');
  }

  // 🛡️ ===== iOS 전용: 글로벌 트랜잭션 중복 방지 메서드들 =====

  /// 🛡️ iOS 전용: 트랜잭션이 이미 처리되었는지 확인
  bool isTransactionAlreadyProcessed(String transactionKey) {
    // 🍎 iOS에서만 적용
    if (!Platform.isIOS) return false;

    return _globalProcessedTransactions.contains(transactionKey);
  }

  /// 🛡️ iOS 전용: 트랜잭션을 처리 완료로 마킹
  void markTransactionAsProcessed(String transactionKey) {
    // 🍎 iOS에서만 적용
    if (!Platform.isIOS) return;

    _globalProcessedTransactions.add(transactionKey);

    // 캐시 크기 관리
    if (_globalProcessedTransactions.length > _maxGlobalTransactionCache) {
      final toRemove = _globalProcessedTransactions.take(10).toList();
      _globalProcessedTransactions.removeAll(toRemove);
      logger.d('🍎 iOS: 오래된 글로벌 트랜잭션 캐시 정리: ${toRemove.length}개');
    }

    logger.i('🍎 iOS: 글로벌 트랜잭션 처리 완료 마킹: $transactionKey');
  }

  /// 🛡️ iOS 전용: 트랜잭션 고유 키 생성
  String generateTransactionKey(dynamic purchaseDetails) {
    final productId = purchaseDetails.productID ?? '';
    final purchaseId = purchaseDetails.purchaseID ?? '';
    final transactionDate = purchaseDetails.transactionDate ?? '';

    // iOS: transactionDate + productID + purchaseID 조합
    return '${productId}_${transactionDate}_$purchaseId';
  }

  /// 🛡️ iOS 전용: 현재 처리 중인 구매인지 확인 (중복 콜백 방지)
  bool shouldProcessPurchase(dynamic purchaseDetails) {
    // 🍎 iOS에서만 적용
    if (!Platform.isIOS) return true;

    final transactionKey = generateTransactionKey(purchaseDetails);

    // 이미 처리된 트랜잭션은 스킵
    if (isTransactionAlreadyProcessed(transactionKey)) {
      logger.w('🍎 iOS: 이미 처리된 트랜잭션 - 스킵: $transactionKey');
      return false;
    }

    return true;
  }
}
