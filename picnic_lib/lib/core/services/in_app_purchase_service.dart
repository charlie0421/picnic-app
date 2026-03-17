import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

part 'in_app_purchase_service_sandbox.dart';
part 'in_app_purchase_cache_manager.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  StreamController<List<PurchaseDetails>>? _purchaseController;
  late Function(List<PurchaseDetails>) _onPurchaseUpdate;

  bool _streamInitialized = false;
  Timer? _purchaseTimeoutTimer;

  // 🧹 백그라운드 정리용 타이머 (필요 시 사용)
  Timer? _backgroundCleanupTimer;

  // 🔍 마지막 구매 시도의 취소 여부 추적
  bool _lastPurchaseWasCancelled = false;

  // 🔍 Pending 구매 정리 상태 추적
  int _totalPendingFoundCount = 0;
  int _totalPendingClearedCount = 0;
  DateTime? _lastCleanupTime;

  final List<ProductDetails> _products = [];
  final bool _isAvailable = false;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  /// 마지막 구매 시도가 취소되었는지 확인
  bool get lastPurchaseWasCancelled => _lastPurchaseWasCancelled;

  // 성능 최적화 상수
  static const Duration _fastCacheTimeout = Duration(milliseconds: 500);
  static const Duration _backgroundCleanupDelay = Duration(seconds: 5);
  static const Duration _pendingProcessTimeout = Duration(seconds: 2);

  // 🚨 타임아웃 콜백 추가
  void Function(String productId)? onPurchaseTimeout;

  // 현재 진행 중인 구매 추적 (타임아웃 시 정리용)
  String? _currentPurchasingProductId;

  // 🧪 디버그 모드 설정
  bool debugMode = false;
  String debugTimeoutMode =
      'normal'; // 'normal', 'debug', 'ultrafast', 'instant'
  bool simulateSlowPurchase = false; // 구매 요청 지연 시뮬레이션
  bool forceTimeoutSimulation = false; // 🎯 무조건 타임아웃 시뮬레이션 (실제 구매 요청 안함)
  Duration _slowPurchaseDelay = const Duration(seconds: 1); // 디버그 지연 기본 1초

  /// 🧪 디버그 모드 설정 (타임아웃 시간 단축)
  void setDebugMode(bool enabled) {
    debugMode = enabled;
    debugTimeoutMode = enabled ? 'debug' : 'normal';
    logger.i(
        '🧪 디버그 모드 ${enabled ? "활성화" : "비활성화"}: 타임아웃 시간 ${getTimeoutDescription()}');
  }

  /// 🧪 타임아웃 모드 설정 (더 세밀한 제어)
  void setTimeoutMode(String mode) {
    debugTimeoutMode = mode;
    debugMode = mode != 'normal';
    logger.i('🧪 타임아웃 모드 변경: $mode (${getTimeoutDescription()})');
  }

  /// 🧪 구매 지연 시뮬레이션 설정
  void setSlowPurchaseSimulation(bool enabled, {Duration? delay}) {
    simulateSlowPurchase = enabled;
    if (delay != null) {
      _slowPurchaseDelay = delay;
    }
    final delayText = _slowPurchaseDelay.inMilliseconds < 1000
        ? '${_slowPurchaseDelay.inMilliseconds}ms'
        : '${_slowPurchaseDelay.inSeconds}초';
    logger.i('🧪 구매 지연 시뮬레이션 ${enabled ? "활성화" : "비활성화"}: ${enabled ? delayText : "즉시 실행"}');
  }

  /// 🎯 무조건 타임아웃 시뮬레이션 설정 (실제 구매 요청 안함)
  void setForceTimeoutSimulation(bool enabled) {
    forceTimeoutSimulation = enabled;

    if (enabled) {
      logger.i('🎯 강제 타임아웃 시뮬레이션 활성화 - 실제 구매 요청 없이 3초 후 무조건 타임아웃');
    } else {
      logger.i('🎯 강제 타임아웃 시뮬레이션 비활성화 - 정상 구매 진행');
    }
  }

  /// 현재 타임아웃 설정 가져오기
  @visibleForTesting
  Duration getCurrentTimeout() {
    // 🎯 강제 타임아웃 모드일 때는 무조건 빠른 타임아웃 사용
    if (forceTimeoutSimulation) {
      return PurchaseConstants.debugPurchaseTimeout; // 3초 고정
    }

    switch (debugTimeoutMode) {
      case 'instant':
        return PurchaseConstants.instantTimeout;
      case 'ultrafast':
        return PurchaseConstants.ultraFastTimeout;
      case 'debug':
        return PurchaseConstants.debugPurchaseTimeout;
      default:
        return PurchaseConstants.purchaseTimeout;
    }
  }

  /// 타임아웃 설명 가져오기
  @visibleForTesting
  String getTimeoutDescription() {
    final timeout = getCurrentTimeout();
    if (timeout.inMilliseconds < 1000) {
      return '${timeout.inMilliseconds}ms';
    } else {
      return '${timeout.inSeconds}초';
    }
  }

  /// 🧪 수동 타임아웃 트리거 (테스트용)
  void triggerManualTimeout({String? productId}) {
    final targetProductId = productId ?? _currentPurchasingProductId;
    if (targetProductId != null) {
      logger.w('🧪 수동 타임아웃 트리거: $targetProductId');
      if (onPurchaseTimeout != null) {
        onPurchaseTimeout!(targetProductId);
        _currentPurchasingProductId = null;
      }
    } else {
      logger.w('🧪 수동 타임아웃 트리거 실패: 진행 중인 구매가 없음');
    }
  }

  void initialize(Function(List<PurchaseDetails>) onPurchaseUpdate) {
    _onPurchaseUpdate = onPurchaseUpdate;
    _initializePurchaseStream();
  }

  /// 앱 시작 시 처리되지 않은 구매를 정리합니다.
  Future<void> clearPendingPurchasesOnStartup() async {
    logger.i('✨ 앱 시작: 처리되지 않은 구매 정리 시작');
    // StoreKit/BillingClient 초기화를 위해 약간의 지연 시간을 줍니다.
    await Future.delayed(const Duration(seconds: 1));

    // iOS에서는 SKPaymentQueue를 직접 정리하여 안정성을 높입니다.
    if (Platform.isIOS) {
      await _clearIosPendingTransactions();
    }

    // 모든 플랫폼에서 플러그인을 통한 정리를 한 번 더 수행합니다.
    await this.processPendingTransactions();
    logger.i('✨ 앱 시작: 처리되지 않은 구매 정리 완료');
  }

  /// iOS의 SKPaymentQueue에 남아있는 트랜잭션을 직접 정리합니다.
  Future<void> _clearIosPendingTransactions() async {
    if (!Platform.isIOS) {
      return;
    }
    logger.i('iOS: SKPaymentQueue의 pending 트랜잭션 직접 정리 시작');
    try {
      final transactions = await SKPaymentQueueWrapper().transactions();
      if (transactions.isEmpty) {
        logger.i('iOS: SKPaymentQueue에 정리할 pending 트랜잭션 없음');
        return;
      }
      logger.w('iOS: ${transactions.length}개의 pending 트랜잭션 발견. 강제 정리 시작.');
      for (final transaction in transactions) {
        try {
          await SKPaymentQueueWrapper().finishTransaction(transaction);
          logger.i('iOS: 트랜잭션 강제 완료: ${transaction.transactionIdentifier}');
        } catch (e) {
          logger.e('iOS: 트랜잭션 강제 완료 실패: ${transaction.transactionIdentifier}, error: $e');
        }
      }
    } catch (e) {
      logger.e('iOS: SKPaymentQueue 트랜잭션 조회 실패: $e');
    }
  }

  void _initializePurchaseStream() {
    logger.d('Initializing purchase stream...');

    if (_streamInitialized) {
      logger.d('Purchase stream already initialized');
      return;
    }

    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        logger.d(
            'Purchase stream event: ${purchaseDetailsList.length} purchases');

        // 🚨 구매 완료 시 현재 구매 ID 정리
        for (final purchase in purchaseDetailsList) {
          if (purchase.productID == _currentPurchasingProductId &&
              (purchase.status == PurchaseStatus.purchased ||
                  purchase.status == PurchaseStatus.restored ||
                  purchase.status == PurchaseStatus.error ||
                  purchase.status == PurchaseStatus.canceled)) {
            logger.i('🧹 구매 완료로 인한 현재 구매 ID 정리: ${purchase.productID}');
            _currentPurchasingProductId = null;
          }
        }

        _onPurchaseUpdate(purchaseDetailsList);
      },
      onError: (error) {
        logger.e('Purchase stream error: $error');
        // 🚨 에러 시에도 현재 구매 ID 정리
        if (_currentPurchasingProductId != null) {
          logger
              .w('🧹 구매 스트림 오류로 인한 현재 구매 ID 정리: $_currentPurchasingProductId');
          _currentPurchasingProductId = null;
        }
        _onPurchaseUpdate([]);
      },
    );

    _streamInitialized = true;
    logger.d('Purchase stream initialized successfully');
  }

  void _resetPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();

    // 🧪 디버그 모드일 때 짧은 타임아웃 사용
    final timeout = getCurrentTimeout();

    _purchaseTimeoutTimer = Timer(timeout, () {
      logger.w(
          '⏰ Purchase timeout - no updates for ${timeout.inSeconds}s ${debugMode ? "(디버그 모드)" : ""}');

      // 🛡️ 타임아웃 발생을 로깅하고 상태 마킹 (안전망은 UI에서 처리)
      logger.w('🚨 InAppPurchaseService 타임아웃 발생 - UI 안전망에서 처리 예정');
      logger.w('   → UI 안전망 타이머가 ${(45).toString()}초 후 무한 로딩 해제');

      // 추가적인 디버그 정보 제공
      logger.w('   → 현재 상태: InAppPurchaseService 단계에서 응답 없음');
      logger.w('   → 예상 원인: StoreKit 응답 지연 또는 네트워크 문제');
      logger.w('   → 해결 방법: UI 안전망이 자동으로 처리할 예정');

      // 🚨 타임아웃 콜백 호출 (구매 상태 정리)
      if (_currentPurchasingProductId != null && onPurchaseTimeout != null) {
        logger.w('🧹 타임아웃 콜백 호출: $_currentPurchasingProductId');
        onPurchaseTimeout!(_currentPurchasingProductId!);
        _currentPurchasingProductId = null; // 정리
      }
    });
  }

  Future<bool> makePurchase(
    ProductDetails productDetails, {
    bool isConsumable = true,
  }) async {
    logger.i('🚀 즉시 구매 시작: ${productDetails.id} (${productDetails.price})');

    // 🔍 구매 시도 시작 시 취소 상태 초기화
    _lastPurchaseWasCancelled = false;

    // 🚨 현재 구매 중인 제품 ID 설정 (타임아웃 추적용)
    _currentPurchasingProductId = productDetails.id;

    try {
      // 🛡️ StoreKit 레벨 중복 방지: 현재 pending 구매 확인
      final currentPendingPurchases =
          await _getPendingPurchasesForProduct(productDetails.id);
      if (currentPendingPurchases.isNotEmpty) {
        logger.w('🚫 StoreKit에서 이미 진행 중인 구매 감지: ${productDetails.id}');
        logger.w('   → 진행 중인 구매: ${currentPendingPurchases.length}개');

        // 기존 pending 구매들 정리
        for (final pendingPurchase in currentPendingPurchases) {
          logger.i('📋 기존 pending 구매 완료 처리: ${pendingPurchase.productID}');
          await completePurchase(pendingPurchase).catchError((e) {
            logger.w('기존 pending 구매 완료 실패: $e');
          });
        }

        // 짧은 대기 후 재시도
        await Future.delayed(Duration(milliseconds: 500));

        // 중복 구매로 판단하고 실패 반환
        logger.w('🚫 중복 구매 방지: ${productDetails.id}');
        _currentPurchasingProductId = null; // 🚨 정리
        return false;
      }

      // ⚡ 구매 전 대기 시간 완전 제거 - 즉시 구매 진행!
      logger.i('⚡ 구매 전 처리 건너뛰기 - 즉시 구매 진행');

      // 🧪 구매 지연 시뮬레이션 (디버그용)
      if (simulateSlowPurchase) {
        final delayText = _slowPurchaseDelay.inMilliseconds < 1000
            ? '${_slowPurchaseDelay.inMilliseconds}ms'
            : '${_slowPurchaseDelay.inSeconds}초';
        logger.w('🧪 구매 지연 시뮬레이션 - $delayText 대기 중...');
        await Future.delayed(_slowPurchaseDelay);
        logger.w('🧪 구매 지연 시뮬레이션 완료 - 구매 요청 시작');
      }

      // 🎯 강제 타임아웃 시뮬레이션 (실제 구매 요청 안함)
      if (forceTimeoutSimulation) {
        logger.w('🎯 강제 타임아웃 시뮬레이션 - 실제 구매 요청 없이 타임아웃만 발생');

        // 타임아웃 타이머 시작
        _resetPurchaseTimeout();

        // 실제 구매 요청은 하지 않고 바로 return
        // 타이머가 만료되면 자동으로 타임아웃 처리됨
        logger.w('🎯 강제 타임아웃 대기 중 - ${getTimeoutDescription()} 후 타임아웃 발생 예정');
        return true; // 성공적으로 "구매 요청"했다고 반환 (실제로는 타임아웃만 대기)
      }

      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );

      final result = isConsumable
          ? await InAppPurchase.instance.buyConsumable(
              purchaseParam: purchaseParam,
              autoConsume: true,
            )
          : await InAppPurchase.instance.buyNonConsumable(
              purchaseParam: purchaseParam,
            );

      if (result) {
        logger.i('✅ 구매 요청 성공 - 백그라운드 정리 예약');
        _resetPurchaseTimeout();

        // 🧹 구매 성공 후 백그라운드에서 조용히 정리 (사용자 대기 없음)
        this.scheduleBackgroundCleanup();
      } else {
        logger.w('❌ 구매 요청 실패');
        _currentPurchasingProductId = null; // 🚨 정리
      }

      return result;
    } catch (e) {
      // 🔍 취소 감지: 예외가 취소인지 실제 에러인지 구분
      if (isPurchaseCancelledException(e)) {
        logger.i('🚫 구매 취소 감지: ${e.toString()}');
        _lastPurchaseWasCancelled = true; // ← 취소 상태 설정
        _currentPurchasingProductId = null; // 🚨 정리
        return false; // 취소는 정상적인 false 반환
      } else {
        logger.e('💥 구매 오류: $e');
        _currentPurchasingProductId = null; // 🚨 정리
        return false; // 실제 에러도 false 반환 (기존 동작 유지)
      }
    }
  }

  /// 예외가 취소 관련인지 확인
  @visibleForTesting
  bool isPurchaseCancelledException(dynamic exception) {
    final exceptionString = exception.toString().toLowerCase();

    // StoreKit 2 취소 관련 에러 코드들
    final cancelErrorCodes = [
      'storekit2_purchase_cancelled',
      'storekit2_user_cancelled',
      'storekit2_cancelled',
      'purchase_cancelled',
      'transaction_cancelled',
      'user_cancelled_purchase',
      'cancelled_by_user',
      // StoreKit 1 취소 관련
      'payment_canceled',
      'user_canceled',
      'skeerrorpaymentcancelled',
      'billing_response_user_canceled',
      // 일반적인 취소 키워드
      'cancel',
      'cancelled',
      'canceled',
      'user cancel',
      'abort',
      'dismiss',
      // iOS 인증 관련 취소 키워드
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
      // StoreKit 2 취소 메시지들
      'transaction has been cancelled',
      'cancelled by the user',
      'purchase was cancelled',
      'user has cancelled',
      'transaction cancelled',
      'purchase cancelled',
      'payment cancelled',
      'cancelled transaction',
      'user cancellation',
      'cancelled by user'
    ];

    // 키워드 검사
    for (final keyword in cancelErrorCodes) {
      if (exceptionString.contains(keyword)) {
        logger.i('🔍 InAppPurchaseService 취소 키워드 감지: $keyword');
        return true;
      }
    }

    return false;
  }

  /// 특정 제품의 pending 구매들 조회
  Future<List<PurchaseDetails>> _getPendingPurchasesForProduct(
      String productId) async {
    try {
      final purchaseDetailsList =
          await this.getPurchaseUpdates(Duration(milliseconds: 300));
      return purchaseDetailsList
          .where((p) =>
              p.productID == productId && p.status == PurchaseStatus.pending)
          .toList();
    } catch (e) {
      logger.w('pending 구매 조회 실패: $e');
      return [];
    }
  }

  Future<List<ProductDetails>> getProducts(Set<String> productIds) async {
    logger.i('Fetching ${productIds.length} products');

    final response =
        await InAppPurchase.instance.queryProductDetails(productIds);

    if (response.error != null) {
      logger.e('Product query error: ${response.error}');
      throw Exception('Failed to fetch products: ${response.error}');
    }

    logger
        .i('Products fetched successfully: ${response.productDetails.length}');
    return response.productDetails;
  }

  Future<void> restorePurchases() async {
    logger.i('🔄 즉시 복원 시작...');
    try {
      await InAppPurchase.instance.restorePurchases();
      logger.i('✅ 복원 요청 성공 - 백그라운드 정리 예약');

      // 🧹 복원 성공 후 백그라운드에서 조용히 정리 (사용자 대기 없음)
      this.scheduleBackgroundCleanup();
    } catch (e) {
      logger.e('❌ 복원 실패: $e');
      rethrow;
    }
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    logger.i('Completing purchase: ${purchaseDetails.productID}');
    try {
      await InAppPurchase.instance.completePurchase(purchaseDetails);
      logger.i('Purchase completed successfully');
    } catch (e) {
      logger.e('Complete purchase failed: $e');
      rethrow;
    }
  }

  Future<void> clearTransactions({bool includePendingPurchases = false}) async {
    logger
        .i('Clearing transactions (includePending: $includePendingPurchases)');

    try {
      if (includePendingPurchases) {
        // 🧹 실제 pending 구매 처리 후 캐시 정리 (구매 시에만)
        await this.comprehensiveClear();
      } else {
        // ⚡ 빠른 캐시 클리어만 (초기화 시)
        await this.fastCacheClear();
      }

      // 🧹 iOS 캐시 클리어 (기존 로직 유지)
      if (Platform.isIOS) {
        try {
          await this.iosCacheClear();
          logger.i('iOS cache cleared successfully');
        } catch (e) {
          logger.w('iOS cache cleanup failed: $e');
        }
      }
    } catch (e) {
      logger.e('Transaction clearing failed: $e');
      rethrow;
    }
  }

  // Cache/transaction clearing methods are in in_app_purchase_cache_manager.dart (part file)
  // Sandbox/diagnostic methods are in in_app_purchase_service_sandbox.dart (part file)

  /// 🧹 정상 구매 완료 시 타이머 정리
  void cleanupTimersOnPurchaseSuccess(String productId) {
    logger.i('🧹 ✅ InAppPurchaseService 타이머 정리 시작: $productId (정상 구매 성공 시)');

    // 🧹 통합 타이머 정리 메서드 호출
    this.cleanupPurchaseTimersOnSuccess();

    logger.i('🧹 ✅ InAppPurchaseService 타이머 정리 완료: $productId (정상 구매 성공 시)');
  }

  void dispose() {
    logger.i('Disposing InAppPurchaseService');

    _purchaseTimeoutTimer?.cancel();
    _backgroundCleanupTimer?.cancel(); // 🧹 백그라운드 정리 타이머도 정리
    _subscription?.cancel();
    _purchaseController?.close();
    _streamInitialized = false;
  }
}
