import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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

  /// [performBackgroundCleanup] 본체가 실제로 실행된 횟수.
  ///
  /// single-flight 게이트가 겹치는 호출을 진행 중인 실행에 합류시키는지
  /// 테스트가 확인하는 지표다.
  @visibleForTesting
  int backgroundCleanupRunCount = 0;

  /// 진행 중인 [performBackgroundCleanup] 실행(single-flight 게이트).
  ///
  /// 이 게이트가 없으면 연속 구매마다 [InAppPurchaseCacheManager
  /// .scheduleBackgroundCleanup]이 5초 뒤 새 정리를 예약하고, 그 정리의
  /// `verifyAndCleanRemaining()`이 매번 `getPurchaseUpdates(800s)`로 새
  /// 스트림 구독을 연다. 이전 구매의 정리가 아직 끝나지 않았으면 그 구독은
  /// 살아 있는 채로 남고, `purchaseStream`은 broadcast라 다음 구매 이벤트가
  /// 오면 그때까지 쌓인 모든 이전 구독이 동시에 깨어나 각자
  /// `completePurchase()`를 중복 실행한다 - 연속 구매가 늘수록 매 이벤트마다
  /// 처리량이 배수로 늘어나 결제가 점점 느려진다.
  Future<void>? _backgroundCleanupInFlight;

  /// 진행 중인 정리에 합류한 호출이 있었는지.
  ///
  /// single-flight 게이트만 있으면, 진행 중인 정리가 이미 자신의
  /// `getPurchaseUpdates(800s)` 대기에 들어간 뒤에 도착한 구매는 그 정리에
  /// 합류할 뿐 자신의 pending 상태를 다시 훑히지 못한 채 끝난다 - 그 사이
  /// 도착한 이벤트가 우연히 그 대기를 깨우지 않는 한, 진행 중인 정리가 보는
  /// 스냅샷에는 늦게 합류한 구매의 상태가 반영되지 않을 수 있다. 이 플래그는
  /// 진행 중인 정리가 끝난 직후 신선한 정리를 한 번 더(딱 한 번만) 돌려
  /// 그 구간을 메운다.
  bool _backgroundCleanupRerunRequested = false;

  /// `_subscription`/`_streamInitialized` 를 만지는 4개 캐시-리셋 메서드
  /// (fastCacheClear/comprehensiveClear/aggressiveCacheClear/
  /// backgroundCacheClear) 사이의 직렬화 게이트.
  ///
  /// 이 게이트가 없으면, 예를 들어 스토어 화면이 열리며 부르는
  /// `clearTransactions()` 와 이전 구매의 백그라운드 정리가 부르는
  /// `backgroundCacheClear()` 가 겹칠 때 한쪽의 cancel/재구독이 다른 쪽의
  /// 진행 중인 재구독을 밟을 수 있다 - 최악의 경우 구독을 잃거나(이벤트
  /// 유실) 중복 구독(이중 정산)으로 이어진다.
  Future<void>? _cacheResetInFlight;

  /// 캐시-리셋 직렬화 게이트가 실제로 겹침을 막았는지 테스트가 확인하는
  /// 진입/종료 로그.
  @visibleForTesting
  final List<String> cacheResetLog = [];

  /// 진행 중인 [InAppPurchaseCacheManager.getPurchaseUpdates] 대기를 즉시
  /// 끝내는 콜백들.
  ///
  /// `verifyAndCleanRemaining()` 의 800초 대기처럼, dispose() 시점에 이미
  /// 열려 있던 대기는 예전엔 스스로 타임아웃되거나 스트림 이벤트를 받을
  /// 때까지 끊을 방법이 없었다. dispose() 가 이 목록의 콜백을 모두 불러
  /// 그 자리에서(빈 결과로) 끝낸다 - 취소만 하고 안 끝내면, 그 결과를
  /// 기다리던 `_performBackgroundCleanup()` 의 finally 가 영원히 돌지 않아
  /// `_backgroundCleanupInFlight` 가 해제되지 않는다.
  final List<void Function()> _pendingUpdateResolvers = [];

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
      '🧪 디버그 모드 ${enabled ? "활성화" : "비활성화"}: 타임아웃 시간 ${getTimeoutDescription()}',
    );
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
    logger.i(
      '🧪 구매 지연 시뮬레이션 ${enabled ? "활성화" : "비활성화"}: ${enabled ? delayText : "즉시 실행"}',
    );
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

  /// How many times a subscription to `purchaseStream` has actually been
  /// created in this process.
  ///
  /// The invariant this pins is "exactly one delivery path for the process
  /// lifetime". `purchaseStream` is a broadcast stream, so a second subscriber
  /// would receive every event *as well* - two settlements for one charge, two
  /// receipt dialogs, and two chances to finish a transaction. The guard below
  /// makes that impossible; this counter is how a test proves it, and it is why
  /// opening and closing the store must not move it.
  int get purchaseStreamSubscriptions => _purchaseStreamSubscriptions;
  int _purchaseStreamSubscriptions = 0;

  /// How many times a handler has been registered.
  ///
  /// One in a healthy process: [GlobalPurchaseListener] is the only owner.
  /// A second registration means something re-took the delivery path (a Phoenix
  /// restart legitimately does), and the log below says so.
  int get purchaseHandlerRegistrations => _purchaseHandlerRegistrations;
  int _purchaseHandlerRegistrations = 0;

  void initialize(Function(List<PurchaseDetails>) onPurchaseUpdate) {
    if (_streamInitialized && !identical(_onPurchaseUpdate, onPurchaseUpdate)) {
      // 구매 이벤트 전달 경로는 앱 수명 동안 하나여야 한다. 여기서 핸들러가
      // 교체되는 것은 정상 경로가 아니다(Phoenix 재시작/핫 리스타트가 새
      // 트리를 세우는 경우만 정당하다). 이전에는 스토어 화면이 열릴 때마다
      // 교체됐고, 그래서 스토어가 없는 동안 도착한 이벤트는 아무도 받지
      // 않았다.
      logger.w('⚠️ 구매 스트림 핸들러 교체 - 전달 경로 소유자가 바뀐다');
    }
    _onPurchaseUpdate = onPurchaseUpdate;
    _purchaseHandlerRegistrations++;
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
    await processPendingTransactions();
    logger.i('✨ 앱 시작: 처리되지 않은 구매 정리 완료');
  }

  /// iOS의 SKPaymentQueue에 남아있는 트랜잭션 중 실패분만 정리합니다.
  ///
  /// purchased/restored 트랜잭션은 **과금이 끝난 회수 자산**이다 - 여기서
  /// finish하면 서버 재검증 기회가 영원히 사라진다(과금-미적립). 실제로
  /// 초기 스테이징에서 검증 실패로 남은 결제들이 이 강제 정리에 전부
  /// 소멸했다 (2026-07-28). 그 트랜잭션들은 purchaseStream 재전달이
  /// 검증→적립→finish로 처리하므로 여기서는 건드리지 않고, 결제가
  /// 성립하지 않은 failed만 정리해 큐 막힘을 푼다.
  Future<void> _clearIosPendingTransactions() async {
    if (!Platform.isIOS) {
      return;
    }
    logger.i('iOS: SKPaymentQueue의 실패 트랜잭션 정리 시작');
    try {
      final transactions = await SKPaymentQueueWrapper().transactions();
      if (transactions.isEmpty) {
        logger.i('iOS: SKPaymentQueue에 정리할 트랜잭션 없음');
        return;
      }
      for (final transaction in transactions) {
        if (transaction.transactionState !=
            SKPaymentTransactionStateWrapper.failed) {
          logger.i(
            'iOS: 트랜잭션 보존(재전달 처리 대상): '
            '${transaction.transactionIdentifier} '
            '(${transaction.transactionState})',
          );
          continue;
        }
        try {
          await SKPaymentQueueWrapper().finishTransaction(transaction);
          logger.i('iOS: 실패 트랜잭션 정리: ${transaction.transactionIdentifier}');
        } catch (e) {
          logger.e(
            'iOS: 실패 트랜잭션 정리 실패: ${transaction.transactionIdentifier}, error: $e',
          );
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
          'Purchase stream event: ${purchaseDetailsList.length} purchases',
        );

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
          logger.w(
            '🧹 구매 스트림 오류로 인한 현재 구매 ID 정리: $_currentPurchasingProductId',
          );
          _currentPurchasingProductId = null;
        }
        _onPurchaseUpdate([]);
      },
    );

    _streamInitialized = true;
    _purchaseStreamSubscriptions++;
    logger.d('Purchase stream initialized successfully');
  }

  void _resetPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();

    // 🧪 디버그 모드일 때 짧은 타임아웃 사용
    final timeout = getCurrentTimeout();

    _purchaseTimeoutTimer = Timer(timeout, () {
      logger.w(
        '⏰ Purchase timeout - no updates for ${timeout.inSeconds}s ${debugMode ? "(디버그 모드)" : ""}',
      );

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

  /// [onStoreLaunchStart] 는 스토어 결제 플로를 실제로 여는 호출
  /// (`buyConsumable`/`buyNonConsumable`) **직전에** 동기적으로 불린다.
  ///
  /// 호출자가 "이 결제 시트에 대한 lifecycle 관찰"의 기준점을 잡는 자리다.
  /// `makePurchase` 진입 시점이 아니라 여기여야 하는 이유는, 진입 이후에도
  /// pending 조회(`_getPendingPurchasesForProduct`)라는 스토어 왕복이
  /// 한 번 더 있고, 그 사이의 백그라운드 왕복까지 기준점 안에 들어오면
  /// 시트가 뜨기도 전에 "시트가 열렸다 닫혔다"로 오판되기 때문이다
  /// (Sol 5차 재검증 MAJOR).
  Future<bool> makePurchase(
    ProductDetails productDetails, {
    bool isConsumable = true,
    String? applicationUserName,
    void Function()? onStoreLaunchStart,
  }) async {
    logger.i('🚀 즉시 구매 시작: ${productDetails.id} (${productDetails.price})');

    // 🔍 구매 시도 시작 시 취소 상태 초기화
    _lastPurchaseWasCancelled = false;

    // 🚨 현재 구매 중인 제품 ID 설정 (타임아웃 추적용)
    _currentPurchasingProductId = productDetails.id;

    try {
      // 🛡️ StoreKit 레벨 중복 방지: 현재 pending 구매 확인
      final currentPendingPurchases = await _getPendingPurchasesForProduct(
        productDetails.id,
      );
      if (currentPendingPurchases.isNotEmpty) {
        logger.w('🚫 StoreKit에서 이미 진행 중인 구매 감지: ${productDetails.id}');
        logger.w('   → 진행 중인 구매: ${currentPendingPurchases.length}개');

        // 기존 pending 중 결제가 성립하지 않은 것(error/canceled)만 정리한다.
        // purchased/restored는 과금이 끝난 회수 자산 - 여기서 완료하면
        // 검증 없이 영수증이 소멸한다(과금-미적립). 재전달 파이프라인이
        // 검증→적립→finish로 처리하도록 남겨 둔다.
        for (final pendingPurchase in currentPendingPurchases) {
          if (pendingPurchase.status == PurchaseStatus.purchased ||
              pendingPurchase.status == PurchaseStatus.restored) {
            logger.i(
              '📋 결제 완료 트랜잭션 보존(재전달 처리 대상): '
              '${pendingPurchase.productID}',
            );
            continue;
          }
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

      // Android에서 applicationUserName은 BillingFlow의 obfuscatedAccountId로
      // 전달되어 Google 구매에 구매자 계정이 각인된다. wallet.v1 서버
      // (cotton-candy-engine verify_receipt)는 이 값과 정산 대상 user id의
      // 일치를 요구하므로(GOOGLE_OWNER_MISMATCH), 누락 시 스테이징/신서버
      // 검증이 전부 실패한다. 결제 도중 계정이 바뀌어도 원 구매자에게만
      // 적립되도록 하는 소유자 바인딩이기도 하다.
      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: applicationUserName,
      );

      // Android는 autoConsume을 끈다: 소비(consume)는 서버 정산이 확인된
      // 뒤에만 completePurchase()로 수행한다. 그래야 검증 실패/이벤트 유실
      // 시 구매가 Google에 남아 queryPastPurchases()로 복구할 수 있다.
      // iOS는 플러그인이 autoConsume=true를 강제한다(assert).
      //
      // 여기부터가 "스토어 결제 플로 런치"다 - 이 줄과 아래 호출 사이에는
      // await 가 없으므로, 기준점 이후의 비전면 전이는 전부 이 결제 시트의
      // 것이다.
      onStoreLaunchStart?.call();
      final result = isConsumable
          ? await InAppPurchase.instance.buyConsumable(
              purchaseParam: purchaseParam,
              autoConsume: Platform.isIOS,
            )
          : await InAppPurchase.instance.buyNonConsumable(
              purchaseParam: purchaseParam,
            );

      if (result) {
        logger.i('✅ 구매 요청 성공 - 백그라운드 정리 예약');
        _resetPurchaseTimeout();

        // 🧹 구매 성공 후 백그라운드에서 조용히 정리 (사용자 대기 없음)
        scheduleBackgroundCleanup();
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
      'cancelled by user',
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
    String productId,
  ) async {
    try {
      final purchaseDetailsList = await getPurchaseUpdates(
        Duration(milliseconds: 300),
      );
      return purchaseDetailsList
          .where(
            (p) =>
                p.productID == productId && p.status == PurchaseStatus.pending,
          )
          .toList();
    } catch (e) {
      logger.w('pending 구매 조회 실패: $e');
      return [];
    }
  }

  Future<List<ProductDetails>> getProducts(Set<String> productIds) async {
    logger.i('Fetching ${productIds.length} products');

    final response = await InAppPurchase.instance.queryProductDetails(
      productIds,
    );

    if (response.error != null) {
      logger.e('Product query error: ${response.error}');
      throw Exception('Failed to fetch products: ${response.error}');
    }

    logger.i(
      'Products fetched successfully: ${response.productDetails.length}',
    );
    return response.productDetails;
  }

  Future<void> restorePurchases() async {
    logger.i('🔄 즉시 복원 시작...');
    try {
      await InAppPurchase.instance.restorePurchases();
      logger.i('✅ 복원 요청 성공 - 백그라운드 정리 예약');

      // 🧹 복원 성공 후 백그라운드에서 조용히 정리 (사용자 대기 없음)
      scheduleBackgroundCleanup();
    } catch (e) {
      logger.e('❌ 복원 실패: $e');
      rethrow;
    }
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        purchaseDetails.status == PurchaseStatus.pending) {
      logger.w(
        '⏸️ Android pending 구매는 acknowledge 하지 않음: '
        '${purchaseDetails.productID}',
      );
      return;
    }
    logger.i('Completing purchase: ${purchaseDetails.productID}');
    try {
      await InAppPurchase.instance.completePurchase(purchaseDetails);
      logger.i('Purchase completed successfully');
    } catch (e) {
      logger.e('Complete purchase failed: $e');
      rethrow;
    }
  }

  /// 서버 정산이 확정된 구매의 최종 완료 처리.
  ///
  /// Android에서 completePurchase()는 acknowledge만 수행한다
  /// (in_app_purchase_android 0.4.0+8). consumable은 consume까지 해야
  /// 재구매가 가능하고 queryPastPurchases에서 사라지므로, autoConsume을 끈
  /// 대신 여기서 명시적으로 소비한다. consume 실패 시 acknowledge로
  /// fallback해 최소한 3일 미확인 자동환불은 막고, 구매가 스토어에 남아
  /// 다음 reconcile이 소비를 재시도한다.
  ///
  /// 반환값은 스토어 트랜잭션이 **실제로 소비(consume)까지 끝났는지**다 -
  /// 호출자(`PurchaseService._reconcileUnfinishedPurchases`)가 이 값으로
  /// settled/preserved를 가른다. consume과 acknowledge fallback이 모두
  /// 실패해도 예외를 던지지 않는다(다음 reconcile이 재시도하도록 트랜잭션을
  /// 보존하는 게 목적이므로) - 그래서 실패를 false로 명시해야 한다. 예외를
  /// 던지지 않으면서 항상 성공한 것처럼 반환하면(과거 버전의 버그) 호출자는
  /// Play 큐에 미소비 트랜잭션이 남아 있는데도 "완료"로 믿게 된다.
  ///
  /// acknowledge fallback **성공도 완료가 아니다** (Sol 머지 게이트 리뷰,
  /// PR #137): 소비형 상품이 acknowledge만 된 상태는 3일 자동환불은 막지만
  /// Play에는 여전히 소유(owned)로 남아 다음 구매가 ITEM_ALREADY_OWNED로
  /// 실패한다. true를 돌리면 스윕이 settled로 세어 preserved==0을 근거로
  /// 구매 게이트를 여는데, 그 게이트가 연 구매는 실제로는 실패할 상태다.
  /// fallback은 환불 차단용으로 실행하되 반환은 false로 해 reconcile이
  /// consume을 재시도하게 한다.
  Future<bool> finalizeSettledPurchase(PurchaseDetails purchaseDetails) async {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        purchaseDetails.status == PurchaseStatus.pending) {
      logger.w(
        '⏸️ Android pending 구매는 consume/acknowledge 하지 않음: '
        '${purchaseDetails.productID}',
      );
      return false;
    }
    if (!Platform.isAndroid) {
      try {
        await completePurchase(purchaseDetails);
        return true;
      } catch (e) {
        logger.w('완료 처리 실패(다음 reconcile 재시도): $e');
        return false;
      }
    }
    try {
      final addition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final result = await addition.consumePurchase(purchaseDetails);
      if (result.responseCode == BillingResponse.ok) {
        logger.i('✅ 정산 확정 구매 소비(consume) 완료: ${purchaseDetails.productID}');
        return true;
      }
      logger.w(
        '⚠️ consume 실패(${result.responseCode}) - acknowledge로 fallback: '
        '${purchaseDetails.productID}',
      );
    } catch (e) {
      logger.w('⚠️ consume 예외 - acknowledge로 fallback: $e');
    }
    try {
      await completePurchase(purchaseDetails);
      logger.w(
        '⚠️ acknowledge fallback 성공 - 환불 창은 닫혔지만 미소비 상태이므로 '
        '보존으로 보고(다음 reconcile이 consume 재시도): '
        '${purchaseDetails.productID}',
      );
      return false;
    } catch (e) {
      logger.w('acknowledge fallback도 실패(다음 reconcile 재시도): $e');
      return false;
    }
  }

  Future<void> clearTransactions({bool includePendingPurchases = false}) async {
    logger.i(
      'Clearing transactions (includePending: $includePendingPurchases)',
    );

    try {
      if (includePendingPurchases) {
        // 🧹 실제 pending 구매 처리 후 캐시 정리 (구매 시에만)
        await comprehensiveClear();
      } else {
        // ⚡ 빠른 캐시 클리어만 (초기화 시)
        await fastCacheClear();
      }

      // 🧹 iOS 캐시 클리어 (기존 로직 유지)
      if (Platform.isIOS) {
        try {
          await iosCacheClear();
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
  ///
  /// 여기서 내리는 타이머와 `_currentPurchasingProductId` 는 **하나의** 진행
  /// 중인 구매에 속한 상태다. 그래서 다른 상품의 정산이(특히 아직 finish 되지
  /// 않은 과거 트랜잭션의 재전달이) 이 정리를 호출하면, 지금 결제창에 있는
  /// 구매의 타임아웃 추적을 대신 지운다 — 그 구매가 응답 없이 멈추면 타임아웃
  /// 콜백이 아예 발동하지 않는다. 진행 중인 상품과 일치할 때만(또는 진행 중인
  /// 구매가 없을 때만) 정리한다.
  void cleanupTimersOnPurchaseSuccess(String productId) {
    final inFlight = _currentPurchasingProductId;
    if (inFlight != null &&
        inFlight.trim().toUpperCase() != productId.trim().toUpperCase()) {
      logger.i('🧹 ⏭️ 진행 중인 다른 구매($inFlight)의 타이머는 보존: $productId');
      return;
    }

    logger.i('🧹 ✅ InAppPurchaseService 타이머 정리 시작: $productId (정상 구매 성공 시)');

    // 🧹 통합 타이머 정리 메서드 호출
    cleanupPurchaseTimersOnSuccess();

    logger.i('🧹 ✅ InAppPurchaseService 타이머 정리 완료: $productId (정상 구매 성공 시)');
  }

  void dispose() {
    logger.i('Disposing InAppPurchaseService');

    _purchaseTimeoutTimer?.cancel();
    _backgroundCleanupTimer?.cancel(); // 🧹 백그라운드 정리 타이머도 정리
    // 진행 중인 정리가 합류된 채 남긴 재실행 요청도 함께 무효화한다 -
    // 그대로 두면 dispose() 이후에 최대 800초짜리 새 스트림 구독이 열린다.
    _backgroundCleanupRerunRequested = false;
    // 이미 열려 있던 getPurchaseUpdates() 대기(최악의 경우
    // verifyAndCleanRemaining()의 800초 대기)도 그 자리에서 끝낸다 - 구독만
    // 끊으면 그 결과를 기다리던 finally 가 영원히 돌지 않는다.
    for (final resolve in List<void Function()>.from(_pendingUpdateResolvers)) {
      resolve();
    }
    _subscription?.cancel();
    _purchaseController?.close();
    _streamInitialized = false;
  }
}
