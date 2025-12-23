import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';

// PurchaseSafetyManager 타입 선언 (순환 import 방지)
abstract class PurchaseSafetyManagerInterface {
  bool canAttemptPurchase();
}

/// 🧹 복원 구매 전용 핸들러 - 예방적 정리 및 차단 기능
class RestorePurchaseHandler {
  final PurchaseService _purchaseService;
  // ignore: unused_field - 향후 로딩 표시에 사용될 수 있음
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey;
  final BuildContext _context;

  // 🎯 활성 구매 확인을 위한 안전망 참조
  PurchaseSafetyManagerInterface? _safetyManager;

  bool _isProactiveCleanupMode = false;
  bool _isProactiveCleanupCompleted = false;
  bool _isWaitingForRestoreCompletion = false;
  int _restoredPurchaseCount = 0;
  Timer? _pulseLoadingTimer;

  RestorePurchaseHandler({
    required PurchaseService purchaseService,
    required GlobalKey<LoadingOverlayWithIconState> loadingKey,
    required BuildContext context,
  })  : _purchaseService = purchaseService,
        _loadingKey = loadingKey,
        _context = context;

  /// 🎯 안전망 매니저 설정 (순환 의존성 방지)
  void setSafetyManager(PurchaseSafetyManagerInterface safetyManager) {
    _safetyManager = safetyManager;
  }

  /// 페이지 진입 시 예방적 복원 정리 실행 (최적화: 빠른 초기화 우선)
  Future<void> performProactiveCleanup() async {
    final platform = Theme.of(_context).platform;
    final startTime = DateTime.now();

    try {
      logger.i('🧹 예방적 복원 구매 정리 시작 (${platform.name})');

      _restoredPurchaseCount = 0;
      _isWaitingForRestoreCompletion = true;
      _isProactiveCleanupMode = true;

      // 🚀 로딩 표시 없이 백그라운드에서 정리 시도
      // 사용자가 대기하지 않도록 빠르게 완료
      try {
        // 타임아웃을 3초로 단축 (기존 10초 → 3초)
        await _purchaseService.inAppPurchaseService
            .restorePurchases()
            .timeout(const Duration(seconds: 3));

        // 빠른 대기 (최대 2초)
        await _waitForRestoreCompletion(startTime);
      } catch (e) {
        // 타임아웃 또는 오류 시 즉시 완료 처리
        logger.w('🧹 복원 정리 타임아웃/오류 - 즉시 완료 처리: $e');
      }

      _isProactiveCleanupMode = false;
      _isWaitingForRestoreCompletion = false;
      _isProactiveCleanupCompleted = true;

      final duration = DateTime.now().difference(startTime);
      logger.i(
          '🧹 예방적 복원 정리 완료 - ${duration.inMilliseconds}ms, $_restoredPurchaseCount개');
    } catch (e) {
      logger.e('🧹 예방적 복원 정리 오류: $e');
      _cleanupState();
      _isProactiveCleanupCompleted = true;
    }
  }

  /// 복원 완료까지 스마트 대기 (최적화: 빠른 완료 우선)
  Future<void> _waitForRestoreCompletion(DateTime startTime) async {
    // 🚀 최대 대기 시간을 3초로 단축 (기존 10초 → 3초)
    const maxWaitTime = Duration(seconds: 3);
    int lastProcessedCount = 0;
    DateTime? lastProcessTime = DateTime.now();

    while (DateTime.now().isBefore(startTime.add(maxWaitTime)) &&
        _isWaitingForRestoreCompletion) {
      // 🚀 대기 간격을 200ms로 단축 (기존 300ms)
      await Future.delayed(const Duration(milliseconds: 200));

      if (_restoredPurchaseCount > lastProcessedCount) {
        lastProcessedCount = _restoredPurchaseCount;
        lastProcessTime = DateTime.now();
        logger.d('🧹 새로운 복원 처리 감지: $_restoredPurchaseCount개');
      }

      final elapsed = DateTime.now().difference(startTime);
      // 🚀 1초 후부터 완료 체크 (기존 2초 → 1초)
      if (elapsed.inMilliseconds > 1000) {
        final timeSinceLastProcess =
            DateTime.now().difference(lastProcessTime!);
        // 🚀 500ms 동안 새 처리가 없으면 완료로 간주 (기존 1초 → 500ms)
        if (timeSinceLastProcess.inMilliseconds > 500) {
          logger.i('🧹 복원 처리 완료 감지');
          _isWaitingForRestoreCompletion = false;
        }
      }
    }
  }

  /// 복원 구매 처리 여부 확인 - 🍎 iOS/🤖 Android 플랫폼별 처리
  bool shouldProcessRestored(PurchaseDetails purchaseDetails) {
    final platform = Platform.isIOS ? 'iOS' : 'Android';

    // 📱 iOS와 🤖 Android 완전 분리 처리
    if (Platform.isIOS) {
      return _shouldProcessRestoredIOS(purchaseDetails, platform);
    } else {
      return _shouldProcessRestoredAndroid(purchaseDetails, platform);
    }
  }

  /// 🍎 iOS 전용 복원 처리 판별 - 정상 구매 보호
  bool _shouldProcessRestoredIOS(
      PurchaseDetails purchaseDetails, String platform) {
    // 🎯 연속 구매 보호: 현재 구매 진행 중이면 복원 신호도 정상 구매 가능성!
    final isActivePurchasing = _safetyManager?.canAttemptPurchase() ==
        false; // canAttemptPurchase() == false는 구매 진행 중을 의미

    // 🍎 1단계: 정리 완료 후 순수 복원 신호는 차단 (단, 활성 구매 중이면 허용!)
    if (_isProactiveCleanupCompleted &&
        purchaseDetails.status == PurchaseStatus.restored) {
      // 🎯 활성 구매 진행 중이면 복원 신호라도 정상 구매로 처리!
      if (isActivePurchasing) {
        logger.i('[iOS] 🎯 연속 구매 보호: 활성 구매 중인 restored 신호 → 정상 구매로 처리');
        return false; // false = 복원 처리 안함, 활성 구매 검증으로 넘어감
      }

      // 활성 구매가 아닌 순수 복원 신호는 차단
      logger.w('[iOS] 🛡️ 정리 완료 후 순수 복원 신호 무시: ${purchaseDetails.productID}');
      return false;
    }

    // 🍎 2단계: iOS 특성 - restored 상태도 정상 구매일 수 있음!
    if (purchaseDetails.status == PurchaseStatus.restored) {
      // 🍎 iOS는 restored도 정상 구매 가능성 있으므로 다음 단계로 넘김
      // shouldProcessActivePurchase에서 실제 구매 여부 검증하도록 함
      logger.i('[iOS] 🍎 iOS 특성: restored 상태지만 정상 구매 가능성 - 다음 단계로 위임');
      return false; // false = 복원 처리 안함, 다음 단계(활성 구매 검증)로 넘어감
    }

    return false;
  }

  /// 🤖 Android 전용 복원 처리 판별 - 엄격한 차단
  bool _shouldProcessRestoredAndroid(
      PurchaseDetails purchaseDetails, String platform) {
    // 🤖 1단계: 정리 완료 후 복원 신호는 무조건 차단
    if (_isProactiveCleanupCompleted &&
        purchaseDetails.status == PurchaseStatus.restored) {
      logger.w('[Android] 🛡️ 정리 완료 후 복원 신호 무시: ${purchaseDetails.productID}');
      return false;
    }

    // 🤖 2단계: Android는 restored 상태를 엄격하게 차단
    if (purchaseDetails.status == PurchaseStatus.restored) {
      logger.w('[Android] 🚫 복원 구매 엄격 차단: ${purchaseDetails.productID}');
      return false; // Android는 restored를 정상 구매로 보지 않음
    }

    return false;
  }

  /// 복원 구매 조용히 처리 (시스템 무결성만 유지)
  Future<void> processRestoredPurchase(PurchaseDetails purchaseDetails) async {
    final platform = Theme.of(_context).platform;

    if (_isProactiveCleanupMode) {
      _restoredPurchaseCount++;
      logger.i('🧹 예방적 정리: 복원 구매 조용히 완료 처리 [$_restoredPurchaseCount개째]');

      if (purchaseDetails.pendingCompletePurchase) {
        await _purchaseService.inAppPurchaseService
            .completePurchase(purchaseDetails);
      }
      return;
    }

    logger.w('🚫 복원 구매 처리 차단 (${platform.name}): ${purchaseDetails.productID}');

    if (purchaseDetails.pendingCompletePurchase) {
      await _purchaseService.inAppPurchaseService
          .completePurchase(purchaseDetails);
    }
  }

  /// 정리 작업
  void _cleanupState() {
    _isProactiveCleanupMode = false;
    _isWaitingForRestoreCompletion = false;
  }

  /// 🧹 모든 타이머 정리 (정상 구매 완료 시)
  void cleanupTimersOnPurchaseSuccess() {
    // 1️⃣ 펄스 로딩 타이머 정리
    _pulseLoadingTimer?.cancel();
    _pulseLoadingTimer = null;

    // 2️⃣ 대기 상태 정리
    _isWaitingForRestoreCompletion = false;

    logger.i('🧹 ✅ RestoreHandler 타이머 정리 완료 (정상 구매 성공 시)');
  }

  void dispose() {
    _pulseLoadingTimer?.cancel();
    _cleanupState();
    _restoredPurchaseCount = 0;
  }

  // Getters
  bool get isProactiveCleanupMode => _isProactiveCleanupMode;
  bool get isProactiveCleanupCompleted => _isProactiveCleanupCompleted;
  bool get canPurchase => _isProactiveCleanupCompleted;
}
