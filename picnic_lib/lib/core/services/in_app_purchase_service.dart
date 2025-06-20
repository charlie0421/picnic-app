import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
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

  // 🔍 Pending 구매 정리 상태 추적
  int _totalPendingFoundCount = 0;
  int _totalPendingClearedCount = 0;
  DateTime? _lastCleanupTime;

  final List<ProductDetails> _products = [];
  final bool _isAvailable = false;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  // 성능 최적화 상수
  static const Duration _fastCacheTimeout = Duration(milliseconds: 500);
  static const Duration _backgroundCleanupDelay = Duration(seconds: 5);
  static const Duration _pendingProcessTimeout = Duration(seconds: 2);

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
    logger.i('🚀 즉시 구매 시작: ${productDetails.id} (${productDetails.price})');

    try {
      // ⚡ 구매 전 대기 시간 완전 제거 - 즉시 구매 진행!
      logger.i('⚡ 구매 전 처리 건너뛰기 - 즉시 구매 진행');

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
      }

      return result;
    } catch (e) {
      logger.e('💥 구매 오류: $e');
      return false;
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
      // 🔥 1단계: 빠른 pending 처리
      await _quickPendingClear().timeout(_pendingProcessTimeout);

      // 🔥 2단계: 적극적 캐시 무효화 (500ms 후)
      await Future.delayed(Duration(milliseconds: 500));
      await _backgroundCacheClear();

      // �� 3단계: 재확인 및 추가 정리 (1초 후)
      await Future.delayed(Duration(seconds: 1));
      await _verifyAndCleanRemaining();

      logger.i('✅ 적극적 백그라운드 정리 완료');
    } catch (e) {
      logger.w('🧹 백그라운드 정리 중 오류 (무시): $e');
      // 백그라운드 작업이므로 실패해도 계속 진행
    }
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
          await _getPurchaseUpdates(Duration(milliseconds: 800));
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

  void dispose() {
    logger.i('Disposing InAppPurchaseService');

    _purchaseTimeoutTimer?.cancel();
    _backgroundCleanupTimer?.cancel(); // 🧹 백그라운드 정리 타이머도 정리
    _subscription?.cancel();
    _purchaseController?.close();
    _streamInitialized = false;
  }
}
