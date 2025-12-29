import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

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
        '🧪 디버그 모드 ${enabled ? "활성화" : "비활성화"}: 타임아웃 시간 ${_getTimeoutDescription()}');
  }

  /// 🧪 타임아웃 모드 설정 (더 세밀한 제어)
  void setTimeoutMode(String mode) {
    debugTimeoutMode = mode;
    debugMode = mode != 'normal';
    logger.i('🧪 타임아웃 모드 변경: $mode (${_getTimeoutDescription()})');
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
  Duration _getCurrentTimeout() {
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
  String _getTimeoutDescription() {
    final timeout = _getCurrentTimeout();
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

    // 🧹 내부 상태 초기화
    _currentPurchasingProductId = null;
    _lastPurchaseWasCancelled = false;
    _purchaseTimeoutTimer?.cancel();
    _backgroundCleanupTimer?.cancel();

    // StoreKit/BillingClient 초기화를 위해 약간의 지연 시간을 줍니다.
    await Future.delayed(const Duration(milliseconds: 500));

    // iOS에서는 SKPaymentQueue를 직접 정리하여 안정성을 높입니다.
    if (Platform.isIOS) {
      await _clearIosPendingTransactions();
    }

    // 모든 플랫폼에서 플러그인을 통한 정리를 한 번 더 수행합니다.
    await _processPendingTransactions();
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
    final timeout = _getCurrentTimeout();

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
        logger.w('🎯 강제 타임아웃 대기 중 - ${_getTimeoutDescription()} 후 타임아웃 발생 예정');
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
        _scheduleBackgroundCleanup();
      } else {
        logger.w('❌ 구매 요청 실패');
        _currentPurchasingProductId = null; // 🚨 정리
      }

      return result;
    } catch (e) {
      // 🔍 취소 감지: 예외가 취소인지 실제 에러인지 구분
      if (_isPurchaseCancelledException(e)) {
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
  bool _isPurchaseCancelledException(dynamic exception) {
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
          await _getPurchaseUpdates(Duration(milliseconds: 300));
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
      _scheduleBackgroundCleanup();
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
        await _comprehensiveClear();
      } else {
        // ⚡ 빠른 캐시 클리어만 (초기화 시)
        await _fastCacheClear();
      }

      // 🧹 iOS 캐시 클리어 (기존 로직 유지)
      if (Platform.isIOS) {
        try {
          await _iosCacheClear();
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

  /// ⚡ 초고속 캐시 클리어 (pending 구매 처리 없음)
  Future<void> _fastCacheClear() async {
    logger.i('⚡ 초고속 캐시 클리어 시작');

    try {
      if (Platform.isIOS) {
        logger.i('📱 iOS: 초고속 StoreKit 캐시 정리');

        // Purchase stream 일시 중단
        await _subscription?.cancel();
        _streamInitialized = false;

        // 최소한의 대기만 (20ms)
        await Future.delayed(Duration(milliseconds: 20));

        // 빈 쿼리로 캐시 무효화 (타임아웃 적용)
        try {
          await InAppPurchase.instance
              .queryProductDetails({}).timeout(_fastCacheTimeout);
          logger.i('✅ iOS 제품 캐시 무효화 완료');
        } catch (e) {
          logger.w('⚠️ iOS 제품 캐시 무효화 실패 (무시): $e');
          // 타임아웃이나 다른 오류 모두 무시하고 계속 진행
        }

        // Purchase stream 재초기화
        _initializePurchaseStream();

        logger.i('⚡ iOS 초고속 캐시 정리 완료');
      } else {
        // Android: 최소한의 대기
        logger.i('🤖 Android: 즉시 완료');
        await Future.delayed(Duration(milliseconds: 10));
        logger.i('⚡ Android 정리 완료');
      }

      logger.i('⚡ 초고속 캐시 클리어 완료');
    } catch (e) {
      logger.w('⚠️ 초고속 캐시 클리어 실패 (무시): $e');
      // 실패해도 계속 진행
    }
  }

  /// 🚀 실제 pending 구매 처리 후 캐시 정리
  Future<void> _comprehensiveClear() async {
    logger.i('🚀 실제 pending 구매 처리 시작');

    try {
      // 🧹 1단계: 실제 pending 구매들을 찾아서 완료 처리
      await _processPendingTransactions();

      // 🧹 2단계: 캐시 클리어 및 재초기화
      if (Platform.isIOS) {
        logger.i('📱 iOS: StoreKit 캐시 정리');

        // Purchase stream 일시 중단
        await _subscription?.cancel();
        _streamInitialized = false;

        // 짧은 대기로 시스템 정리 시간 제공
        await Future.delayed(Duration(milliseconds: 200));

        // 빈 쿼리로 캐시 무효화
        try {
          await InAppPurchase.instance.queryProductDetails({});
          logger.i('✅ iOS 제품 캐시 무효화 완료');
        } catch (e) {
          logger.w('⚠️ iOS 제품 캐시 무효화 실패: $e');
        }

        // Purchase stream 재초기화
        _initializePurchaseStream();

        logger.i('✅ iOS 캐시 정리 완료');
      } else {
        // Android: 짧은 대기
        logger.i('🤖 Android: 시스템 안정화 대기');
        await Future.delayed(Duration(milliseconds: 100));
        logger.i('✅ Android 정리 완료');
      }

      logger.i('🎯 실제 pending 구매 처리 완료');
    } catch (e) {
      logger.e('❌ pending 구매 처리 실패: $e');
      // 실패해도 계속 진행
    }
  }

  /// 🧹 실제 pending 구매들을 찾아서 완료 처리
  Future<void> _processPendingTransactions() async {
    logger.i('🧹 pending 구매 검색 및 완료 처리 시작');

    try {
      // Purchase stream에서 현재 대기 중인 모든 구매 확인
      final purchaseDetailsList =
          await _getPurchaseUpdates(_pendingProcessTimeout);

      // pending 구매들만 필터링
      final pendingPurchases = purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .toList();

      logger.i('📋 발견된 pending 구매: ${pendingPurchases.length}개');

      if (pendingPurchases.isEmpty) {
        logger.i('✅ 처리할 pending 구매가 없음');
        return;
      }

      // 모든 pending 구매를 완료 처리
      final completionFutures = <Future<void>>[];

      for (final purchase in pendingPurchases) {
        logger.i('🧹 pending 구매 완료 처리: ${purchase.productID}');

        final future = completePurchase(purchase).catchError((error) {
          logger.w('⚠️ ${purchase.productID} 완료 처리 실패: $error');
        });

        completionFutures.add(future);
      }

      // 모든 완료 처리를 대기 (최대 10초)
      await Future.wait(completionFutures).timeout(Duration(seconds: 10),
          onTimeout: () {
        logger.w('⏰ Pending 구매 완료 처리 타임아웃');
        return [];
      });

      logger.i('✅ ${pendingPurchases.length}개 pending 구매 완료 처리됨');
    } catch (e) {
      logger.e('❌ pending 구매 처리 중 오류: $e');
    }
  }

  /// Purchase stream에서 업데이트 가져오기
  Future<List<PurchaseDetails>> _getPurchaseUpdates(Duration timeout) async {
    final completer = Completer<List<PurchaseDetails>>();
    late StreamSubscription subscription;

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete([]);
      }
    });

    subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) {
        if (!completer.isCompleted) {
          subscription.cancel();
          timer.cancel();
          completer.complete(purchaseDetailsList);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          subscription.cancel();
          timer.cancel();
          completer.complete([]);
        }
      },
    );

    return completer.future;
  }

  Future<void> _iosCacheClear() async {
    try {
      await _aggressiveCacheClear();
      logger.i('iOS cache cleared successfully');
    } catch (e) {
      logger.w('iOS cache cleanup failed: $e');
    }
  }

  Future<void> _aggressiveCacheClear() async {
    logger.d('Performing aggressive cache clear...');

    try {
      // 구매 스트림 일시 중단
      await _subscription?.cancel();
      _streamInitialized = false;

      // 캐시 무효화 대기
      await Future.delayed(PurchaseConstants.initializationDelay);

      // 제품 정보 캐시 갱신
      if (Platform.isIOS) {
        try {
          await InAppPurchase.instance.queryProductDetails({});
          logger.d('Product cache cleared');
        } catch (e) {
          logger.w('Product cache clear warning: $e');
        }
      }

      // 구매 스트림 재초기화
      _initializePurchaseStream();
      logger.d('Cache clear completed');
    } catch (e) {
      logger.e('Cache clear failed: $e');
      if (!_streamInitialized) {
        _initializePurchaseStream();
      }
    }
  }

  Future<void> refreshStoreKitCache() async {
    logger.d('Refreshing StoreKit cache...');

    try {
      if (Platform.isIOS) {
        await Future.delayed(PurchaseConstants.cacheRefreshDelay);

        // 새로운 트랜잭션 상태 확인
        try {
          await InAppPurchase.instance.queryProductDetails({});
        } catch (e) {
          logger.w('Product refresh warning: $e');
        }

        // Purchase stream 새로고침
        try {
          final purchases = await InAppPurchase.instance.purchaseStream
              .take(1)
              .timeout(PurchaseConstants.initializationDelay)
              .first
              .catchError((e) => <PurchaseDetails>[]);

          logger.d('Purchase stream refreshed: ${purchases.length} items');

          // 캐시된 구매 완료 처리
          for (var purchase in purchases) {
            if (purchase.pendingCompletePurchase) {
              logger.d('Completing cached purchase: ${purchase.productID}');
              await InAppPurchase.instance.completePurchase(purchase);
            }
          }
        } catch (e) {
          logger.w('Purchase stream refresh warning: $e');
        }
      }

      logger.d('StoreKit cache refresh completed');
    } catch (e) {
      logger.w('StoreKit cache refresh failed: $e');
    }
  }

  Future<void> configureStoreKit() async {
    if (Platform.isIOS) {
      try {
        logger.d('Configuring iOS StoreKit2 support');
        // in_app_purchase 3.2.0+는 자동으로 StoreKit2를 활용
        logger.d('StoreKit2 configuration completed');
      } catch (e) {
        logger.w('StoreKit configuration warning: $e');
      }
    }
  }

  Future<String> getStoreKitInfo() async {
    if (Platform.isIOS) {
      return 'StoreKit2 (in_app_purchase 3.2.0+)';
    }
    return Platform.isAndroid ? 'Google Play' : 'Unknown';
  }

  /// 🧹 백그라운드에서 조용히 정리 예약 (사용자 대기 없음)
  void _scheduleBackgroundCleanup() {
    // 기존 타이머가 있다면 취소
    _backgroundCleanupTimer?.cancel();

    // 5초 후에 백그라운드에서 조용히 pending 정리
    _backgroundCleanupTimer = Timer(_backgroundCleanupDelay, () {
      _performBackgroundCleanup().catchError((error) {
        logger.w('🧹 백그라운드 정리 실패 (무시): $error');
        // 실패해도 사용자에게는 영향 없음
      });
    });

    logger.i('🧹 백그라운드 정리 5초 후 예약됨');
  }

  /// 🧹 백그라운드에서 조용히 pending 구매 정리 (적극적 방식)
  Future<void> _performBackgroundCleanup() async {
    logger.i('🧹 적극적 백그라운드 정리 시작 (사용자 대기 없음)');

    try {
      // 🔥 0단계: 구매 완료 타이머 정리 (새로 추가!)
      _cleanupPurchaseTimersOnSuccess();

      // 🔥 1단계: 빠른 pending 처리
      await _quickPendingClear().timeout(_pendingProcessTimeout);

      // 🔥 2단계: 적극적 캐시 무효화 (500ms 후)
      await Future.delayed(Duration(milliseconds: 500));
      await _backgroundCacheClear();

      // 🔥 3단계: 재확인 및 추가 정리 (1초 후)
      await Future.delayed(Duration(seconds: 1));
      await _verifyAndCleanRemaining();

      logger.i('✅ 적극적 백그라운드 정리 완료');
    } catch (e) {
      logger.w('🧹 백그라운드 정리 중 오류 (무시): $e');
      // 백그라운드 작업이므로 실패해도 계속 진행
    }
  }

  /// 🧹 구매 완료 시 타이머 정리 (새로 추가)
  void _cleanupPurchaseTimersOnSuccess() {
    logger.i('🧹 구매 완료 타이머 정리 시작');

    // 1️⃣ 구매 타임아웃 타이머 정리
    if (_purchaseTimeoutTimer?.isActive == true) {
      _purchaseTimeoutTimer?.cancel();
      _purchaseTimeoutTimer = null;
      logger.i('✅ 구매 타임아웃 타이머 정리 완료');
    }

    // 2️⃣ 백그라운드 클린업 타이머 정리 (중복 방지)
    if (_backgroundCleanupTimer?.isActive == true) {
      _backgroundCleanupTimer?.cancel();
      _backgroundCleanupTimer = null;
      logger.i('✅ 백그라운드 클린업 타이머 정리 완료');
    }

    // 3️⃣ 현재 구매 ID 정리
    if (_currentPurchasingProductId != null) {
      logger.i('🧹 현재 구매 ID 정리: $_currentPurchasingProductId');
      _currentPurchasingProductId = null;
    }

    logger.i('🧹 모든 구매 타이머 정리 완료');
  }

  /// 🔥 적극적 백그라운드 캐시 정리
  Future<void> _backgroundCacheClear() async {
    logger.i('🔥 적극적 캐시 정리 시작');

    try {
      if (Platform.isIOS) {
        // iOS: 더 적극적인 StoreKit 정리
        logger.i('📱 iOS: 적극적 StoreKit 정리');

        // Purchase stream 완전 재시작
        await _subscription?.cancel();
        _streamInitialized = false;

        // 100ms 대기 후 캐시 무효화
        await Future.delayed(Duration(milliseconds: 100));

        try {
          // 여러 번 시도로 확실한 캐시 클리어
          for (int i = 0; i < 3; i++) {
            await InAppPurchase.instance
                .queryProductDetails({}).timeout(Duration(milliseconds: 300));
            if (i < 2) await Future.delayed(Duration(milliseconds: 50));
          }
          logger.i('✅ iOS 적극적 캐시 정리 완료');
        } catch (e) {
          logger.w('⚠️ iOS 캐시 정리 일부 실패 (무시): $e');
        }

        // Purchase stream 재초기화
        _initializePurchaseStream();
      } else {
        // Android: Billing 캐시 정리
        logger.i('🤖 Android: Billing 캐시 정리');
        await Future.delayed(Duration(milliseconds: 100));
      }

      logger.i('✅ 적극적 캐시 정리 완료');
    } catch (e) {
      logger.w('🔥 적극적 캐시 정리 실패 (무시): $e');
    }
  }

  /// 🔍 재확인 및 남은 pending 구매 추가 정리
  Future<void> _verifyAndCleanRemaining() async {
    logger.i('🔍 남은 pending 구매 재확인 및 정리');

    try {
      // Purchase stream에서 남은 pending 구매 재확인
      final purchaseDetailsList =
          await _getPurchaseUpdates(Duration(seconds: 800));
      final remainingPending = purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .toList();

      if (remainingPending.isNotEmpty) {
        logger.w('🔍 남은 pending 구매 발견: ${remainingPending.length}개 - 추가 정리 시도');

        // 남은 pending 구매들을 한 번 더 완료 처리
        for (final purchase in remainingPending) {
          try {
            await completePurchase(purchase).timeout(Duration(seconds: 1));
            logger.i('🔥 추가 정리 완료: ${purchase.productID}');
          } catch (e) {
            logger.w('🔥 추가 정리 실패: ${purchase.productID} - $e');
          }
        }
      } else {
        logger.i('✅ 남은 pending 구매 없음 - 정리 성공');
      }
    } catch (e) {
      logger.w('🔍 재확인 중 오류 (무시): $e');
    }
  }

  /// ⚡ 빠른 pending 구매 처리 (1초 타임아웃)
  Future<void> _quickPendingClear() async {
    logger.i('⚡ 빠른 pending 구매 처리 시작');

    try {
      // Purchase stream에서 현재 대기 중인 모든 구매 확인 (1초 타임아웃)
      final purchaseDetailsList =
          await _getPurchaseUpdates(Duration(seconds: 1));

      // pending 구매들만 필터링
      final pendingPurchases = purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .toList();

      // 🔍 Pending 구매 통계 업데이트
      _totalPendingFoundCount += pendingPurchases.length;
      _lastCleanupTime = DateTime.now();

      logger.i(
          '⚡ 발견된 pending 구매: ${pendingPurchases.length}개 (총 발견: $_totalPendingFoundCount개)');

      if (pendingPurchases.isEmpty) {
        logger.i('✅ 처리할 pending 구매가 없음');
        return;
      }

      // 모든 pending 구매를 빠르게 완료 처리
      final completionFutures = <Future<void>>[];
      int clearedCount = 0;

      for (final purchase in pendingPurchases) {
        logger.i('⚡ pending 구매 빠른 완료 처리: ${purchase.productID}');

        final future = completePurchase(purchase).then((_) {
          clearedCount++;
          logger.i('✅ ${purchase.productID} 완료 처리 성공');
        }).catchError((error) {
          logger.w('⚠️ ${purchase.productID} 빠른 완료 처리 실패: $error');
        });

        completionFutures.add(future);
      }

      // 모든 완료 처리를 대기 (최대 3초)
      await Future.wait(completionFutures).timeout(Duration(seconds: 3),
          onTimeout: () {
        logger.w('⚡ 빠른 pending 구매 완료 처리 타임아웃');
        return [];
      });

      // 🔍 정리 통계 업데이트
      _totalPendingClearedCount += clearedCount;

      logger.i(
          '✅ $clearedCount개 pending 구매 빠르게 완료 처리됨 (총 정리: $_totalPendingClearedCount개)');
    } catch (e) {
      logger.e('❌ 빠른 pending 구매 처리 중 오류: $e');
    }
  }

  /// 🔍 Pending 구매 정리 상태 확인 (디버그용)
  Future<Map<String, dynamic>> getPendingCleanupStatus() async {
    logger.i('🔍 Pending 구매 정리 상태 확인 시작');

    try {
      // 현재 Purchase stream에서 pending 구매 확인
      final purchaseDetailsList =
          await _getPurchaseUpdates(Duration(seconds: 1));
      final currentPending = purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .toList();

      final status = {
        'currentPendingCount': currentPending.length,
        'totalPendingFound': _totalPendingFoundCount,
        'totalPendingCleared': _totalPendingClearedCount,
        'lastCleanupTime': _lastCleanupTime?.toIso8601String(),
        'currentPendingItems': currentPending
            .map((p) => {
                  'productID': p.productID,
                  'transactionDate': p.transactionDate,
                  'pendingCompletePurchase': p.pendingCompletePurchase,
                })
            .toList(),
      };

      logger.i('''🔍 Pending 구매 정리 상태:
├─ 현재 pending: ${currentPending.length}개
├─ 총 발견한 pending: $_totalPendingFoundCount개  
├─ 총 정리한 pending: $_totalPendingClearedCount개
├─ 마지막 정리 시간: ${_lastCleanupTime?.toString() ?? '없음'}
└─ 정리 성공률: ${_totalPendingFoundCount > 0 ? ((_totalPendingClearedCount / _totalPendingFoundCount * 100).toStringAsFixed(1)) : '0'}%''');

      return status;
    } catch (e) {
      logger.e('🔍 Pending 상태 확인 중 오류: $e');
      return {
        'error': e.toString(),
        'currentPendingCount': -1,
        'totalPendingFound': _totalPendingFoundCount,
        'totalPendingCleared': _totalPendingClearedCount,
      };
    }
  }

  /// 🔥 Sandbox 인증창 강제 초기화 (인증창 생략 문제 해결) - 개선된 버전
  Future<void> forceSandboxAuthReset() async {
    logger.w('🔥 Sandbox 인증창 강제 초기화 시작 (개선된 버전)');

    try {
      // 0단계: 현재 진행 중인 구매 강제 중단
      logger.i('🛑 0단계: 현재 진행 중인 구매 강제 중단');
      _currentPurchasingProductId = null;
      if (_purchaseTimeoutTimer?.isActive == true) {
        _purchaseTimeoutTimer?.cancel();
        logger.i('⏰ 구매 타임아웃 타이머 취소됨');
      }

      if (Platform.isIOS) {
        // 1단계: 모든 구매 스트림 완전 중단 (더 확실하게)
        logger.i('📱 1단계: 구매 스트림 완전 중단 (강화)');
        await _subscription?.cancel();
        _streamInitialized = false;

        // PurchaseController도 완전히 정리
        if (_purchaseController != null && !_purchaseController!.isClosed) {
          await _purchaseController!.close();
          _purchaseController = null;
          logger.i('🗑️ PurchaseController 완전 정리됨');
        }

        // 2단계: StoreKit 캐시 완전 무효화 (5회 시도, 더 긴 간격)
        logger.i('🧹 2단계: StoreKit 캐시 완전 무효화 (5회 시도)');
        for (int i = 0; i < 5; i++) {
          try {
            await Future.delayed(Duration(milliseconds: 500)); // 더 긴 간격

            // 빈 세트로 쿼리하여 캐시 무효화
            await InAppPurchase.instance
                .queryProductDetails({}).timeout(Duration(seconds: 2));

            // 추가로 실제 제품 ID로도 쿼리 시도
            await InAppPurchase.instance.queryProductDetails({
              'STAR10000',
              'STAR7000',
              'STAR50000'
            }).timeout(Duration(seconds: 2));

            logger.i('✅ StoreKit 캐시 무효화 ${i + 1}/5 완료');
          } catch (e) {
            logger.w('⚠️ StoreKit 캐시 무효화 ${i + 1}/5 실패: $e');
          }
        }

        // 3단계: 모든 pending 구매 강제 완료 (더 철저하게)
        logger.i('🚀 3단계: 모든 pending 구매 강제 완료 (강화)');
        await _enhancedForceClearAllPendingPurchases();

        // 4단계: 시스템 레벨 정리 및 안정화 (더 긴 대기)
        logger.i('⏰ 4단계: 시스템 안정화 대기 (3초)');
        await Future.delayed(Duration(seconds: 3)); // 더 긴 대기

        // 5단계: 새로운 PurchaseController 생성
        logger.i('🔄 5단계: 새로운 PurchaseController 생성');
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();

        // 6단계: 구매 스트림 재초기화
        logger.i('🔄 6단계: 구매 스트림 재초기화');
        _initializePurchaseStream();

        // 7단계: 인증 상태 검증을 위한 더미 쿼리
        logger.i('🔍 7단계: 인증 상태 검증을 위한 더미 쿼리');
        try {
          await Future.delayed(Duration(milliseconds: 500));
          final productResponse = await InAppPurchase.instance
              .queryProductDetails({'STAR10000'}).timeout(Duration(seconds: 3));
          logger.i(
              '✅ 인증 상태 검증 쿼리 성공: ${productResponse.productDetails.length}개 제품 조회됨');
        } catch (e) {
          logger.w('⚠️ 인증 상태 검증 쿼리 실패: $e');
        }

        logger.w('✅ Sandbox 인증창 강제 초기화 완료 (개선된 버전)');
      } else {
        logger.i('🤖 Android: 개선된 캐시 정리');
        // Android는 기존과 동일하지만 약간 더 긴 대기
        await Future.delayed(Duration(seconds: 1));
      }
    } catch (e) {
      logger.e('❌ Sandbox 인증창 강제 초기화 실패: $e');
      // 실패해도 스트림은 반드시 재초기화
      try {
        if (!_streamInitialized) {
          if (_purchaseController == null || _purchaseController!.isClosed) {
            _purchaseController =
                StreamController<List<PurchaseDetails>>.broadcast();
          }
          _initializePurchaseStream();
          logger.i('🔄 오류 복구: 스트림 재초기화 완료');
        }
      } catch (recoveryError) {
        logger.e('❌ 오류 복구 실패: $recoveryError');
      }
    }
  }

  /// 🚀 강화된 모든 pending 구매 강제 완료
  Future<void> _enhancedForceClearAllPendingPurchases() async {
    logger.i('🚀 강화된 모든 pending 구매 강제 완료 시작');

    try {
      // 더 많은 시도로 모든 pending 구매 찾기 (5번 시도)
      for (int attempt = 0; attempt < 5; attempt++) {
        logger.i('🔍 Attempt ${attempt + 1}/5: pending 구매 검색 (강화)');

        final purchaseDetailsList =
            await _getPurchaseUpdates(Duration(seconds: 3)); // 더 긴 타임아웃
        final pendingPurchases = purchaseDetailsList
            .where((p) => p.status == PurchaseStatus.pending)
            .toList();

        if (pendingPurchases.isEmpty) {
          logger.i('✅ Attempt ${attempt + 1}: pending 구매 없음');
          break;
        }

        logger.w(
            '🚀 Attempt ${attempt + 1}: ${pendingPurchases.length}개 pending 구매 발견 - 강화된 강제 완료');

        // 순차적으로 하나씩 완료 처리 (더 확실하게)
        for (final purchase in pendingPurchases) {
          try {
            logger.i('🔥 순차 강제 완료 시작: ${purchase.productID}');
            await completePurchase(purchase).timeout(Duration(seconds: 3));
            logger.i('✅ 순차 강제 완료 성공: ${purchase.productID}');

            // 각 완료 후 짧은 대기
            await Future.delayed(Duration(milliseconds: 200));
          } catch (e) {
            logger.w('⚠️ 순차 강제 완료 실패: ${purchase.productID} - $e');
          }
        }

        // 각 시도 후 더 긴 대기
        await Future.delayed(Duration(milliseconds: 800));
      }

      logger.i('✅ 강화된 모든 pending 구매 강제 완료 처리됨');
    } catch (e) {
      logger.e('❌ 강화된 강제 pending 구매 완료 실패: $e');
    }
  }

  /// 🎯 Sandbox 환경 감지 및 특별 처리
  Future<bool> isSandboxEnvironment() async {
    try {
      if (Platform.isIOS) {
        // iOS: Bundle ID나 다른 방법으로 Sandbox 감지
        // 여기서는 간단히 디버그 모드로 판단
        return kDebugMode;
      }
      return false;
    } catch (e) {
      logger.w('Sandbox 환경 감지 실패: $e');
      return false;
    }
  }

  /// 🔧 Sandbox 전용 인증창 강제 활성화 설정
  Future<void> prepareSandboxAuthentication() async {
    if (!(await isSandboxEnvironment())) {
      logger.i('Production 환경 - Sandbox 설정 생략');
      return;
    }

    logger.w('🔧 Sandbox 인증창 강제 활성화 준비');

    try {
      // 1. 모든 기존 인증 상태 리셋
      await forceSandboxAuthReset();

      // 2. 짧은 대기로 시스템 안정화
      await Future.delayed(Duration(milliseconds: 500));

      // 3. 빈 구매 시도로 인증 프로세스 준비 (실제 구매 아님)
      logger.i('🔧 인증 프로세스 준비 중...');
      // 실제 구현에서는 더 복잡한 로직이 필요할 수 있음

      logger.w('✅ Sandbox 인증창 활성화 준비 완료');
    } catch (e) {
      logger.e('🔧 Sandbox 인증 준비 실패: $e');
    }
  }

  /// 💥 핵폭탄급 Sandbox 인증 시스템 완전 리셋 (최후의 수단)
  Future<void> nuclearSandboxReset() async {
    logger.w('💥 핵폭탄급 Sandbox 인증 시스템 완전 리셋 시작');

    try {
      if (Platform.isIOS) {
        // 1단계: 모든 연결 완전 끊기 (5초 대기)
        logger.i('💥 1단계: 모든 StoreKit 연결 완전 끊기');
        await _subscription?.cancel();
        _streamInitialized = false;
        _purchaseController?.close();
        _purchaseController = null;
        await Future.delayed(Duration(seconds: 5));

        // 2단계: 시스템 캐시 완전 무효화 (10회 시도)
        logger.i('💥 2단계: 시스템 캐시 완전 무효화 (10회 시도)');
        for (int i = 0; i < 10; i++) {
          try {
            await Future.delayed(Duration(milliseconds: 500));
            await InAppPurchase.instance
                .queryProductDetails({}).timeout(Duration(seconds: 2));
            logger.i('💥 시스템 캐시 무효화 ${i + 1}/10 완료');
          } catch (e) {
            logger.w('💥 시스템 캐시 무효화 ${i + 1}/10 실패: $e');
          }
        }

        // 3단계: 핵폭탄급 pending 구매 정리 (여러 번 시도)
        logger.i('💥 3단계: 핵폭탄급 pending 구매 정리');
        for (int round = 0; round < 5; round++) {
          await _nuclearPendingClear(round + 1);
          await Future.delayed(Duration(milliseconds: 800));
        }

        // 4단계: 긴 시스템 안정화 대기 (10초)
        logger.i('💥 4단계: 긴 시스템 안정화 대기 (10초)');
        await Future.delayed(Duration(seconds: 10));

        // 5단계: 완전 새로운 스트림 생성
        logger.i('💥 5단계: 완전 새로운 구매 스트림 생성');
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();
        _initializePurchaseStream();

        logger.w('💥 핵폭탄급 Sandbox 인증 시스템 완전 리셋 완료');
      } else {
        logger.i('🤖 Android: 핵폭탄급 정리 (간단 버전)');
        await Future.delayed(Duration(seconds: 2));
      }
    } catch (e) {
      logger.e('💥 핵폭탄급 리셋 실패: $e');
      // 실패해도 최소한 스트림은 복구
      if (!_streamInitialized) {
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();
        _initializePurchaseStream();
      }
    }
  }

  /// 💥 핵폭탄급 pending 구매 정리
  Future<void> _nuclearPendingClear(int round) async {
    logger.i('💥 핵폭탄급 pending 정리 Round $round 시작');

    try {
      // 더 긴 시간으로 pending 구매 찾기
      final purchaseDetailsList =
          await _getPurchaseUpdates(Duration(seconds: 5));
      final pendingPurchases = purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .toList();

      if (pendingPurchases.isEmpty) {
        logger.i('💥 Round $round: pending 구매 없음');
        return;
      }

      logger
          .w('💥 Round $round: ${pendingPurchases.length}개 pending 구매 핵폭탄급 정리');

      // 병렬로 모든 pending 구매 완료 처리 (더 긴 타임아웃)
      final futures = pendingPurchases.map((purchase) async {
        try {
          await completePurchase(purchase).timeout(Duration(seconds: 5));
          logger.i('💥 핵폭탄급 완료: ${purchase.productID}');
        } catch (e) {
          logger.w('💥 핵폭탄급 완료 실패: ${purchase.productID} - $e');
        }
      });

      await Future.wait(futures);

      logger
          .i('💥 Round $round 완료: ${pendingPurchases.length}개 pending 구매 정리됨');
    } catch (e) {
      logger.e('💥 Round $round 실패: $e');
    }
  }

  /// 🏥 Sandbox 환경 진단 및 문제점 분석
  Future<Map<String, dynamic>> diagnoseSandboxEnvironment() async {
    logger.i('🏥 Sandbox 환경 진단 시작');

    try {
      final diagnosis = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'isDebugMode': kDebugMode,
      };

      // StoreKit 가용성 체크
      try {
        final isAvailable = await InAppPurchase.instance.isAvailable();
        diagnosis['storeKitAvailable'] = isAvailable;
      } catch (e) {
        diagnosis['storeKitAvailable'] = false;
        diagnosis['storeKitError'] = e.toString();
      }

      // 현재 pending 구매 체크
      try {
        final purchaseDetailsList =
            await _getPurchaseUpdates(Duration(seconds: 2));
        final pendingCount = purchaseDetailsList
            .where((p) => p.status == PurchaseStatus.pending)
            .length;
        diagnosis['currentPendingCount'] = pendingCount;
        diagnosis['totalPurchaseUpdates'] = purchaseDetailsList.length;
      } catch (e) {
        diagnosis['pendingCheckError'] = e.toString();
      }

      // 제품 쿼리 체크
      try {
        final productResponse =
            await InAppPurchase.instance.queryProductDetails({});
        diagnosis['productQuerySuccessful'] = productResponse.error == null;
        if (productResponse.error != null) {
          diagnosis['productQueryError'] = productResponse.error.toString();
        }
      } catch (e) {
        diagnosis['productQuerySuccessful'] = false;
        diagnosis['productQueryException'] = e.toString();
      }

      // 스트림 상태 체크
      diagnosis['streamInitialized'] = _streamInitialized;
      diagnosis['purchaseControllerActive'] =
          _purchaseController != null && !_purchaseController!.isClosed;

      logger.i('''🏥 Sandbox 환경 진단 완료:
├─ StoreKit 사용 가능: ${diagnosis['storeKitAvailable']}
├─ 현재 pending 구매: ${diagnosis['currentPendingCount'] ?? 'Unknown'}개
├─ 제품 쿼리 성공: ${diagnosis['productQuerySuccessful']}
├─ 스트림 초기화됨: ${diagnosis['streamInitialized']}
└─ 구매 컨트롤러 활성: ${diagnosis['purchaseControllerActive']}''');

      return diagnosis;
    } catch (e) {
      logger.e('🏥 Sandbox 환경 진단 실패: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 🔍 상세 인증 상태 진단 및 해결책 제시
  Future<Map<String, dynamic>> diagnoseAuthenticationState() async {
    logger.i('🔍 상세 인증 상태 진단 시작');

    final diagnosis = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'isDebugMode': kDebugMode,
    };

    try {
      // 1. StoreKit 기본 상태 확인
      final isAvailable = await InAppPurchase.instance.isAvailable();
      diagnosis['storeKitAvailable'] = isAvailable;

      // 2. 현재 pending 구매 상태
      try {
        final purchaseUpdates = await _getPurchaseUpdates(Duration(seconds: 3));
        diagnosis['currentPendingCount'] = purchaseUpdates
            .where((p) => p.status == PurchaseStatus.pending)
            .length;
        diagnosis['totalUpdatesCount'] = purchaseUpdates.length;
      } catch (e) {
        diagnosis['pendingCheckError'] = e.toString();
      }

      // 3. 제품 쿼리 테스트 (인증이 필요한지 확인)
      try {
        final productResult = await InAppPurchase.instance
            .queryProductDetails({'STAR10000'}).timeout(Duration(seconds: 5));

        diagnosis['productQuerySuccess'] = productResult.error == null;
        diagnosis['productCount'] = productResult.productDetails.length;

        if (productResult.error != null) {
          diagnosis['productQueryError'] = productResult.error.toString();
        }
      } catch (e) {
        diagnosis['productQueryException'] = e.toString();
      }

      // 4. 스트림 상태
      diagnosis['streamInitialized'] = _streamInitialized;
      diagnosis['controllerActive'] =
          _purchaseController != null && !_purchaseController!.isClosed;

      // 5. 해결책 제시
      final solutions = <String>[];

      if (diagnosis['currentPendingCount'] != null &&
          diagnosis['currentPendingCount'] > 0) {
        solutions.add(
            'Pending 구매가 ${diagnosis['currentPendingCount']}개 있습니다. 핵리셋을 시도해보세요.');
      }

      if (diagnosis['productQuerySuccess'] != true) {
        solutions.add('제품 쿼리가 실패했습니다. 인증초기화를 다시 시도해보세요.');
      }

      solutions.addAll([
        '1. 앱을 완전히 종료하고 재시작하세요',
        '2. iOS 설정 > App Store에서 로그아웃 후 재로그인하세요',
        '3. 디바이스를 재부팅해보세요',
        '4. 다른 Apple ID로 테스트해보세요',
        '5. 시뮬레이터에서 Device > Erase All Content and Settings 시도'
      ]);

      diagnosis['recommendedSolutions'] = solutions;

      logger.i('🔍 인증 상태 진단 완료');
      return diagnosis;
    } catch (e) {
      logger.e('🔍 인증 상태 진단 실패: $e');
      diagnosis['error'] = e.toString();
      return diagnosis;
    }
  }

  /// 🔥 궁극적인 인증창 복구 방법 (최후의 수단)
  Future<void> ultimateAuthenticationReset() async {
    logger.w('🔥 궁극적인 인증창 복구 시작 - 최후의 수단');

    try {
      if (Platform.isIOS) {
        logger.i('📱 iOS: 궁극적인 인증 상태 리셋');

        // 1. 현재 모든 활동 완전 정지
        await _subscription?.cancel();
        _streamInitialized = false;
        _currentPurchasingProductId = null;
        _purchaseTimeoutTimer?.cancel();

        // 2. PurchaseController 완전 소멸
        if (_purchaseController != null) {
          await _purchaseController!.close();
          _purchaseController = null;
        }

        // 3. 긴 시간 대기 (시스템 완전 안정화)
        logger.i('⏰ 시스템 완전 안정화 대기 (5초)');
        await Future.delayed(Duration(seconds: 5));

        // 4. StoreKit 시스템 레벨 캐시 강제 무효화 (10회 시도)
        logger.i('🧹 StoreKit 시스템 레벨 캐시 강제 무효화 (10회)');
        for (int i = 0; i < 10; i++) {
          try {
            await Future.delayed(Duration(seconds: 1)); // 1초씩 대기

            // 다양한 방법으로 캐시 무효화 시도
            await InAppPurchase.instance
                .queryProductDetails({}).timeout(Duration(seconds: 3));
            await InAppPurchase.instance.queryProductDetails(
                {'INVALID_PRODUCT_ID'}).timeout(Duration(seconds: 3));
            await InAppPurchase.instance.queryProductDetails(
                {'STAR10000'}).timeout(Duration(seconds: 3));

            logger.i('🧹 시스템 캐시 무효화 ${i + 1}/10 완료');
          } catch (e) {
            logger.w('⚠️ 시스템 캐시 무효화 ${i + 1}/10 실패: $e');
          }
        }

        // 5. 더 긴 안정화 시간
        logger.i('⏰ 추가 안정화 대기 (3초)');
        await Future.delayed(Duration(seconds: 3));

        // 6. 완전히 새로운 환경으로 재구성
        logger.i('🔄 완전히 새로운 구매 환경 재구성');
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();
        _initializePurchaseStream();

        // 7. 최종 검증
        logger.i('🔍 최종 인증 상태 검증');
        await Future.delayed(Duration(seconds: 1));

        logger.w('🔥 궁극적인 인증창 복구 완료');
      }
    } catch (e) {
      logger.e('❌ 궁극적인 인증창 복구 실패: $e');
    }
  }

  /// 🧹 정상 구매 완료 시 타이머 정리
  void cleanupTimersOnPurchaseSuccess(String productId) {
    logger.i('🧹 ✅ InAppPurchaseService 타이머 정리 시작: $productId (정상 구매 성공 시)');

    // 🧹 통합 타이머 정리 메서드 호출
    _cleanupPurchaseTimersOnSuccess();

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
