import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';

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

  final List<ProductDetails> _products = [];
  final bool _isAvailable = false;

  // 🛡️ 타임아웃 콜백과 취소 상태 추적
  void Function(String productId)? onPurchaseTimeout;
  bool lastPurchaseWasCancelled = false;
  String? _currentPurchaseProductId;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  void initialize(Function(List<PurchaseDetails>) onPurchaseUpdate) {
    _onPurchaseUpdate = onPurchaseUpdate;
    _initializePurchaseStream();
  }

  void _initializePurchaseStream() {
    if (_streamInitialized) {
      logger.w('Purchase stream already initialized');
      return;
    }

    try {
      logger.i('Initializing purchase stream...');

      _purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

      _subscription = InAppPurchase.instance.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: _handlePurchaseError,
        onDone: _handlePurchaseStreamDone,
      );

      _streamInitialized = true;
      logger.i('Purchase stream initialized successfully');
    } catch (e) {
      logger.e('Failed to initialize purchase stream: $e');
      rethrow;
    }
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    logger.i('Purchase update: ${purchaseDetailsList.length} transactions');

    for (var purchase in purchaseDetailsList) {
      logger.d('→ ${purchase.productID}: ${purchase.status}');

      // 🛡️ 현재 구매 제품에 대한 업데이트인 경우 처리
      if (purchase.productID == _currentPurchaseProductId) {
        _handleCurrentPurchaseUpdate(purchase);
      }
    }

    _resetPurchaseTimeout();

    try {
      _onPurchaseUpdate(purchaseDetailsList);
    } catch (e) {
      logger.e('Error in onPurchaseUpdate callback: $e');
    }

    if (!_purchaseController!.isClosed) {
      _purchaseController!.add(purchaseDetailsList);
    }
  }

  /// 🛡️ 현재 구매에 대한 업데이트 처리
  void _handleCurrentPurchaseUpdate(PurchaseDetails purchase) {
    switch (purchase.status) {
      case PurchaseStatus.canceled:
        lastPurchaseWasCancelled = true;
        _currentPurchaseProductId = null;
        _purchaseTimeoutTimer?.cancel();
        logger.i('🚫 구매 취소 감지: ${purchase.productID}');
        break;
      case PurchaseStatus.error:
        _determineCancellationFromError(purchase.error);
        _currentPurchaseProductId = null;
        _purchaseTimeoutTimer?.cancel();
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        lastPurchaseWasCancelled = false;
        _currentPurchaseProductId = null;
        _purchaseTimeoutTimer?.cancel();
        logger.i('✅ 구매 성공 감지: ${purchase.productID}');
        break;
      case PurchaseStatus.pending:
        // 계속 진행 중
        logger.d('⏳ 구매 진행 중: ${purchase.productID}');
        break;
    }
  }

  void _handlePurchaseError(dynamic error) {
    logger.e('Purchase stream error: $error');
    if (!_purchaseController!.isClosed) {
      _purchaseController!.addError(error);
    }
  }

  void _handlePurchaseStreamDone() {
    logger.i('Purchase stream completed');
    if (!_purchaseController!.isClosed) {
      _purchaseController!.close();
    }
  }

  void _resetPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(PurchaseConstants.purchaseTimeout, () {
      logger.w(
          'Purchase timeout - no updates for ${PurchaseConstants.purchaseTimeout.inSeconds}s');
    });
  }

  /// 🛡️ 구매 타임아웃 시작 (제품별)
  void _startPurchaseTimeout(String productId) {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(PurchaseConstants.purchaseTimeout, () {
      logger.w(
          '🚨 구매 타임아웃 발생: $productId (${PurchaseConstants.purchaseTimeout.inSeconds}초)');

      // 타임아웃 콜백 호출
      if (onPurchaseTimeout != null) {
        onPurchaseTimeout!(productId);
      }

      _currentPurchaseProductId = null;
    });
  }

  /// 🛡️ 에러로부터 취소 여부 판단
  void _determineCancellationFromError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 취소 관련 키워드 확인
    final cancelKeywords = [
      'cancel',
      'cancelled',
      'canceled',
      'user cancel',
      'abort',
      'touch id',
      'face id',
      'authentication',
      'biometric',
      'passcode',
      'user denied',
      'permission denied',
      'operation was cancelled',
    ];

    lastPurchaseWasCancelled =
        cancelKeywords.any((keyword) => errorString.contains(keyword));

    if (lastPurchaseWasCancelled) {
      logger.i('🚫 에러에서 취소 감지: $error');
    } else {
      logger.w('❌ 일반 에러 (취소 아님): $error');
    }
  }

  Future<bool> makePurchase(
    ProductDetails productDetails, {
    bool isConsumable = true,
  }) async {
    logger
        .i('Starting purchase: ${productDetails.id} (${productDetails.price})');

    // 🛡️ 현재 구매 제품 추적
    _currentPurchaseProductId = productDetails.id;
    lastPurchaseWasCancelled = false;

    try {
      if (Platform.isIOS) {
        await _prepareIOSPurchase();
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
        logger.i('Purchase initiated successfully');
        _startPurchaseTimeout(productDetails.id);
      } else {
        logger.w('Purchase initiation failed');
        // 🛡️ 실패 시 취소로 간주 (사용자가 인증을 거부했을 가능성)
        lastPurchaseWasCancelled = true;
        _currentPurchaseProductId = null;
      }

      return result;
    } catch (e) {
      logger.e('Purchase error: $e');
      // 🛡️ 에러 발생 시 취소 여부 판단
      _determineCancellationFromError(e);
      _currentPurchaseProductId = null;
      return false;
    }
  }

  Future<void> _prepareIOSPurchase() async {
    logger.d('Preparing iOS purchase environment');
    await _checkAndProcessPendingTransactions();
  }

  Future<void> _checkAndProcessPendingTransactions() async {
    try {
      if (Platform.isIOS) {
        logger.d('Checking for pending iOS transactions');
        // StoreKit2에서는 자동으로 관리되므로 별도 처리 불필요
      }
    } catch (e) {
      logger.w('Error checking pending transactions: $e');
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
    logger.i('Restoring purchases...');
    try {
      await InAppPurchase.instance.restorePurchases();
      logger.i('Purchases restored successfully');
    } catch (e) {
      logger.e('Restore purchases failed: $e');
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

  Future<void> clearTransactions() async {
    logger.i('Clearing transactions');

    if (Platform.isIOS) {
      try {
        await _aggressiveCacheClear();
        logger.i('iOS cache cleared successfully');
      } catch (e) {
        logger.w('iOS cache cleanup failed: $e');
      }
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
      try {
        return 'StoreKit2 (in_app_purchase 3.2.0+)';
      } catch (e) {
        return 'StoreKit Legacy';
      }
    }
    return Platform.isAndroid ? 'Google Play' : 'Unknown';
  }

  /// 🧹 정상 구매 완료 시 타이머 정리
  void cleanupTimersOnPurchaseSuccess(String productId) {
    // 1️⃣ 구매 타임아웃 타이머 정리
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;

    // 2️⃣ 현재 구매 상품 ID 정리
    _currentPurchaseProductId = null;

    // 3️⃣ 취소 상태 정리
    lastPurchaseWasCancelled = false;

    logger.i('🧹 ✅ InAppPurchaseService 타이머 정리 완료: $productId (정상 구매 성공 시)');
  }

  void dispose() {
    logger.i('Disposing InAppPurchaseService');

    _purchaseTimeoutTimer?.cancel();
    _subscription?.cancel();
    _purchaseController?.close();
    _streamInitialized = false;

    // 🛡️ 추적 상태 정리
    _currentPurchaseProductId = null;
    lastPurchaseWasCancelled = false;
    onPurchaseTimeout = null;
  }
}
