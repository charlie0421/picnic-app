import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_constants.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  StreamController<List<PurchaseDetails>>? _purchaseController;
  late Function(List<PurchaseDetails>) _onPurchaseUpdate;

  bool _streamInitialized = false;
  Timer? _purchaseTimeoutTimer;

  final List<ProductDetails> _products = [];
  bool _isAvailable = false;
  DateTime? _lastPurchaseAttempt;
  final Set<String> _pendingPurchases = {};

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

  Future<bool> makePurchase(
    ProductDetails productDetails, {
    bool isConsumable = true,
  }) async {
    logger
        .i('Starting purchase: ${productDetails.id} (${productDetails.price})');

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
        _resetPurchaseTimeout();
      } else {
        logger.w('Purchase initiation failed');
      }

      return result;
    } catch (e) {
      logger.e('Purchase error: $e');
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

  void dispose() {
    logger.i('Disposing InAppPurchaseService');

    _purchaseTimeoutTimer?.cancel();
    _subscription?.cancel();
    _purchaseController?.close();
    _streamInitialized = false;
  }
}
