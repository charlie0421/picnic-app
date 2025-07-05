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

  /// 페이지 진입 시 예방적 복원 정리 실행
  Future<void> performProactiveCleanup() async {
    final platform = Theme.of(_context).platform;
    final startTime = DateTime.now();

    try {
      logger.i('🧹 예방적 복원 구매 정리 시작 (${platform.name})');

      _restoredPurchaseCount = 0;
      _isWaitingForRestoreCompletion = true;
      _showPulseLoading();
      _isProactiveCleanupMode = true;

      await _purchaseService.inAppPurchaseService.restorePurchases();
      await _waitForRestoreCompletion(startTime);

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

  /// 복원 완료까지 스마트 대기
  Future<void> _waitForRestoreCompletion(DateTime startTime) async {
    const maxWaitTime = Duration(seconds: 10);
    int lastProcessedCount = 0;
    DateTime? lastProcessTime = DateTime.now();

    while (DateTime.now().isBefore(startTime.add(maxWaitTime)) &&
        _isWaitingForRestoreCompletion) {
      await Future.delayed(Duration(milliseconds: 300));

      if (_restoredPurchaseCount > lastProcessedCount) {
        lastProcessedCount = _restoredPurchaseCount;
        lastProcessTime = DateTime.now();
        logger.d('🧹 새로운 복원 처리 감지: $_restoredPurchaseCount개');
      }

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds > 2000) {
        final timeSinceLastProcess =
            DateTime.now().difference(lastProcessTime!);
        if (timeSinceLastProcess.inMilliseconds > 1000) {
          logger.i('🧹 복원 처리 완료 감지');
          _isWaitingForRestoreCompletion = false;
        }
      }
    }
  }

  /// 펄스 로딩 표시
  void _showPulseLoading() {
    final platform = Theme.of(_context).platform;
    final platformEmoji = platform == TargetPlatform.iOS ? '📱' : '🤖';

    logger.i('🔄 펄스 로딩 시작: $platformEmoji 복원 구매 정리 중');

    _loadingKey.currentState?.hide();
    Timer(Duration(milliseconds: 100), () {
      _loadingKey.currentState?.show();
    });
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
