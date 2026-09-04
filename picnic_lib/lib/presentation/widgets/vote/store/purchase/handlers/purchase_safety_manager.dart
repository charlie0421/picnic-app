import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/restore_purchase_handler.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

/// 🎯 심플 구매 안전망 - 3-State 솔루션 (Simple is Better!)
class PurchaseSafetyManager implements PurchaseSafetyManagerInterface {
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey;
  final VoidCallback _resetPurchaseState;

  static const Duration _safetyTimeout = Duration(seconds: 90);
  static const Duration _basePurchaseCooldown = Duration(
    minutes: 1,
  ); // 🎯 기본 60초
  static const Duration _consecutivePurchaseCooldown = Duration(
    minutes: 1,
  ); // 🔄 연속 구매도 60초 동일 적용

  // 🔄 연속 구매 추적
  int _consecutivePurchaseCount = 0;
  DateTime? _firstPurchaseInSession;

  Timer? _safetyTimer;
  final Map<String, Timer> _safetyTimersByProduct = {};

  /// 상품별 안전망이 이미 발동해 사용자에게 안내가 한 번 갔는지.
  ///
  /// 정산 미확정 안내는 두 경로로 도착한다: 90초 안전망, 그리고 그보다
  /// 늦게 끝나는 검증 재시도 루프의 결과. 예산 계산상 안전망이 먼저 울리는
  /// 것이 정상이므로(90초 < 30초×3 + 백오프), 나중에 도착한 결과가 같은
  /// 안내를 한 번 더 띄우지 않게 이 플래그로 막는다.
  final Set<String> _timeoutAnnouncedProducts = {};

  /// 서버 정산이 진행 중이라 재구매를 막아 둔 상품.
  final Set<String> _settlementPendingProducts = {};

  /// 상품별 안전망 타이머가 발동할 때 알려 줄 어템프트 ID.
  ///
  /// 타이머를 앞당겨 발동시키는 [markSettlementPending] 가 콜백에 같은
  /// 어템프트를 넘겨야 한다.
  final Map<String, String?> _safetyAttemptByProduct = {};
  bool _safetyTimeoutTriggered = false;
  DateTime? _safetyTimeoutTime;

  /// 타임아웃 안내 표시 콜백. 어느 상품의 타이머가 울렸는지(전역 타이머면
  /// null)를 전달한다 - UI 가 시도별 관찰 상태(resumed 수신 여부)로 문구를
  /// 고를 수 있어야 하기 때문이다. 상품별 타이머가 공존할 때 productId 없이
  /// 는 다른 시도의 상태를 읽게 된다.
  void Function(String? productId)? onTimeoutUIReset;
  void Function(String productId, String? attemptId)? onProductTimeout;

  // 🎯 3-State 심플 솔루션 - 이것만으로 모든 문제 해결!
  bool _isPurchaseInProgress = false; // 현재 구매 진행 중?
  String? _lastProcessedTransactionId; // 마지막 처리된 실제 거래 ID
  DateTime? _lastPurchaseTime; // 마지막 구매 시도 시간
  String? _currentProductId; // 현재 진행 중인 상품 ID
  final Set<String> _activeProducts = {};

  // 🧩 상품별 쿨타임/연속 구매 세션 추적
  final Map<String, DateTime> _lastPurchaseTimeByProduct =
      {}; // productId -> last attempt time
  final Map<String, int> _consecutivePurchaseCountByProduct =
      {}; // productId -> count
  final Map<String, DateTime> _firstPurchaseInSessionByProduct =
      {}; // productId -> first in session
  final Map<String, DateTime> _productCooldownUntil =
      {}; // productId -> enforced cooldown until

  PurchaseSafetyManager({
    required GlobalKey<LoadingOverlayWithIconState> loadingKey,
    required VoidCallback resetPurchaseState,
  }) : _loadingKey = loadingKey,
       _resetPurchaseState = resetPurchaseState;

  /// 상품별 맵의 키. 타이머는 서버 카탈로그 ID(STAR100)로 시작되고 정산은 Play
  /// 이벤트의 소문자 productID(star100)로 중지되므로, casing을 통일하지 않으면
  /// Android에서 성공한 구매의 안전망 타이머가 영원히 살아남아 90초 뒤
  /// 타임아웃 팝업을 띄우고 _activeProducts에 유령이 남아 재구매를 막는다.
  static String _key(String productId) =>
      PurchaseCampaignAttemptRegistry.canonicalProductKey(productId);

  /// 안전망 타이머 시작
  void startSafetyTimer({String? productId, String? attemptId}) {
    if (productId != null) {
      final key = _key(productId);
      _safetyTimersByProduct.remove(key)?.cancel();
      _safetyAttemptByProduct[key] = attemptId;
      _safetyTimersByProduct[key] = Timer(_safetyTimeout, () {
        _safetyTimersByProduct.remove(key);
        _safetyAttemptByProduct.remove(key);
        _handleSafetyTimeout(productId);
        onProductTimeout?.call(productId, attemptId);
      });
      logger.i('🛡️ 상품별 안전망 타이머 시작: $productId');
      return;
    }
    _safetyTimer?.cancel();
    _safetyTimeoutTriggered = false;
    _safetyTimeoutTime = null;

    logger.i('🛡️ 안전망 타이머 시작 (${_safetyTimeout.inSeconds}초)');

    _safetyTimer = Timer(_safetyTimeout, () {
      if (!_safetyTimeoutTriggered) {
        _handleSafetyTimeout(null);
      }
    });
  }

  /// 안전망 타이머 중지
  void stopSafetyTimer({String? productId}) {
    if (productId != null) {
      _safetyTimersByProduct.remove(_key(productId))?.cancel();
      _safetyAttemptByProduct.remove(_key(productId));
      return;
    }
    if (_safetyTimer?.isActive == true) {
      logger.i('🛡️ 안전망 타이머 중지 - 정상 완료');
      _safetyTimer?.cancel();
    }
  }

  /// 안전망 타이머 정리
  void disposeSafetyTimer() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    for (final timer in _safetyTimersByProduct.values) {
      timer.cancel();
    }
    _safetyTimersByProduct.clear();
    _safetyAttemptByProduct.clear();
    logger.i('🛡️ 안전망 타이머 정리 완료');
  }

  /// 안전망 타임아웃 처리
  void _handleSafetyTimeout(String? productId) {
    _safetyTimeoutTriggered = true;
    _safetyTimeoutTime = DateTime.now();

    logger.w('⏰ 안전망 타임아웃 발동! 90초 경과');

    _loadingKey.currentState?.hide();
    if (productId != null) {
      _activeProducts.remove(_key(productId));
      _timeoutAnnouncedProducts.add(_key(productId));
    } else {
      _resetPurchaseState();
    }

    onTimeoutUIReset?.call(productId);
  }

  /// 서버 정산이 아직 진행 중임이 확인된 상품의 UI 정리 + 재구매 차단.
  ///
  /// 상품별 안전망 타이머는 "사용자를 스피너 앞에 방치하지 않는다"는
  /// 보험이다. 정산이 진행 중이라는 사실이 **확인된** 순간 그 보험은 목적을
  /// 다했고, 타이머를 그대로 남겨 두면 같은 안내가 90초 뒤 한 번 더 뜬다
  /// (= C-4 의 중복 다이얼로그). 그래서 타이머를 앞당겨 내리고, 상품을
  /// 활성 목록에서 빼 스피너를 풀고, 대신 쿨다운으로 재구매를 막는다.
  ///
  /// 늦게 도착하는 정산이 유실되지는 않는다: 어템프트에 bind 되지 않은
  /// `purchased` 이벤트는 `_settleOrphanPurchase` 의 무헤드 정산 경로가
  /// 받아 지갑까지 반영한다. 이 타이머는 그 경로의 전제가 아니다.
  ///
  /// 반환값은 **이미 안내가 한 번 갔는지**다. true 면 호출자는 안내를
  /// 다시 띄우지 않는다.
  bool markSettlementPending(
    String productId, {
    Duration cooldown = PurchaseConstants.settlementPendingCooldown,
  }) {
    final key = _key(productId);
    final alreadyAnnounced = _timeoutAnnouncedProducts.contains(key);

    _safetyTimersByProduct.remove(key)?.cancel();
    _safetyAttemptByProduct.remove(key);
    _activeProducts.remove(key);
    // 이 상품만 내린다 - 다른 상품의 구매가 진행 중이면 그 진행 상태는
    // 유지되어야 한다.
    _isPurchaseInProgress = _activeProducts.isNotEmpty;
    _settlementPendingProducts.add(key);
    _timeoutAnnouncedProducts.add(key);

    // 늦은 정산이 도착하면 "인증이 오래 걸렸지만 구매는 완료됐다" 안내로
    // 라우팅되도록, 안전망이 울린 것과 동일한 상태로 만든다.
    _safetyTimeoutTriggered = true;
    _safetyTimeoutTime ??= DateTime.now();

    activateDuplicateCooldown(productId: productId, cooldown: cooldown);
    _loadingKey.currentState?.hide();

    logger.w(
      '⏳ 서버 정산 진행 중 - 스피너 해제 + 재구매 ${cooldown.inSeconds}s 차단: '
      '$productId (안내 기존 발송: $alreadyAnnounced)',
    );
    return alreadyAnnounced;
  }

  /// 이 상품이 "정산 진행 중"으로 재구매 차단된 상태인지.
  ///
  /// 쿨다운 안내 문구를 고르는 데 쓴다. 일반 쿨다운은 "잠시 후 다시
  /// 시도"가 맞지만, 정산 진행 중인 상품은 그 반대(다시 결제하지 말 것)를
  /// 안내해야 한다.
  bool isSettlementPending(String productId) {
    final key = _key(productId);
    if (!_settlementPendingProducts.contains(key)) return false;
    final until = _productCooldownUntil[key];
    if (until == null || !DateTime.now().isBefore(until)) {
      _settlementPendingProducts.remove(key);
      return false;
    }
    return true;
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

  /// 🎯 상품별 구매 가능 체크.
  ///
  /// 구매를 거절할 수 있는 근거는 **두 가지뿐**이다:
  ///
  /// 1. 이 상품의 결제가 지금 진행 중이다([_activeProducts]).
  /// 2. 이 상품에 명시적 쿨다운이 걸려 있다([_productCooldownUntil]) — 즉
  ///    정산이 서버에서 아직 진행 중이거나([markSettlementPending]) 지급이
  ///    확인되지 않은 중복이 관측된([activateDuplicateCooldown]) 상태다.
  ///    둘 다 "다시 결제하면 이중 과금" 인 상태이므로 막는 것이 맞다.
  ///
  /// **정산이 끝난 구매는 근거가 아니다.** 예전에는 성공 직후
  /// `_lastPurchaseTimeByProduct` 를 근거로 같은 상품을 60초 동안 거절했고,
  /// UI 는 그것을 "이전 결제가 스토어에서 처리 중입니다. 잠시 후 다시 시도해
  /// 주세요." 로 안내했다 — 처리 중인 결제는 없고 그 결제는 이미 적립까지
  /// 끝났으므로 사실이 아니며, 소비형 상품의 정상적인 연속 구매가 그 거짓
  /// 안내로 막혔다 (1.3.0 TestFlight patch 8). 우발적 재결제는 어템프트 등록
  /// (`_purchaseAttempts`, 영수증 다이얼로그가 닫힐 때까지 유지) · 구매 확인
  /// 다이얼로그 · 스토어 결제 시트 · 300ms 연타 방지가 막는다.
  ///
  /// [_lastPurchaseTimeByProduct] 와 연속 구매 카운트는 그대로 유지된다:
  /// 명시적 쿨다운의 **길이**를 정하는 [_getAdaptiveCooldownForProduct] 가
  /// 그 값을 읽는다.
  bool canAttemptPurchaseForProduct(String productId) {
    if (_activeProducts.contains(_key(productId))) {
      logger.w('🛡️ 동일 상품 구매 진행 중 - 추가 구매 차단: $productId');
      return false;
    }

    final until = _productCooldownUntil[_key(productId)];
    if (until != null) {
      final now = DateTime.now();
      if (now.isBefore(until)) {
        final remaining = until.difference(now);
        logger.w(
          '🛡️ [상품별] 강제 쿨다운 차단: $productId - 남은 ${remaining.inSeconds}s, 종료 예정: ${until.toIso8601String()}',
        );
        return false;
      }
      // 만료된 오버라이드는 제거
      _productCooldownUntil.remove(_key(productId));
    }

    return true;
  }

  /// 🔄 적응형 쿨다운 시간 계산
  Duration _getAdaptiveCooldown() {
    // 🔄 연속 구매 세션 감지 (10분 내 구매들)
    if (_firstPurchaseInSession != null) {
      final sessionElapsed = DateTime.now().difference(
        _firstPurchaseInSession!,
      );
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
    final firstInSession = _firstPurchaseInSessionByProduct[_key(productId)];
    if (firstInSession != null) {
      final sessionElapsed = DateTime.now().difference(firstInSession);
      if (sessionElapsed.inMinutes > 10) {
        // 세션 리셋
        _consecutivePurchaseCountByProduct[_key(productId)] = 0;
        _firstPurchaseInSessionByProduct.remove(_key(productId));
      }
    }

    final count = _consecutivePurchaseCountByProduct[_key(productId)] ?? 0;
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
      final targetKey = _key(targetProductId);
      _lastPurchaseTimeByProduct[targetKey] = now;
      _firstPurchaseInSessionByProduct[targetKey] ??= now;
      _consecutivePurchaseCountByProduct[targetKey] =
          (_consecutivePurchaseCountByProduct[targetKey] ?? 0) + 1;

      final enforced =
          cooldown ?? _getAdaptiveCooldownForProduct(targetProductId);
      _productCooldownUntil[targetKey] = now.add(enforced);
      logger.w(
        '🛡️ [상품별] Duplicate JWS detected - cooldown enforced for '
        '$targetProductId (${enforced.inSeconds}s), until=${_productCooldownUntil[targetKey]!.toIso8601String()}',
      );
    } else {
      final cooldown = _getAdaptiveCooldown();
      logger.w(
        '🛡️ Duplicate JWS detected - cooldown activated (no productId) (${cooldown.inSeconds}s)',
      );
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
  ///
  /// **실제로 구매를 막는 시간**만 보고한다 — 즉 [canAttemptPurchaseForProduct]
  /// 가 보는 명시적 오버라이드(`activateDuplicateCooldown` /
  /// `markSettlementPending`)뿐이다. 정산이 끝난 구매의 적응형 창은 더 이상
  /// 구매를 막지 않으므로(같은 메서드의 주석 참고) 여기서 보고하면 없는 차단을
  /// 있다고 말하는 셈이 된다.
  Duration? remainingCooldownForProduct(String productId) {
    final now = DateTime.now();
    final until = _productCooldownUntil[_key(productId)];
    if (until != null && now.isBefore(until)) {
      return until.difference(now);
    }
    return null;
  }

  /// 🧹 상품별 쿨타임/세션 상태 초기화 (일반 오류/취소 시 사용)
  void clearProductCooldown(String productId) {
    _lastPurchaseTimeByProduct.remove(_key(productId));
    _consecutivePurchaseCountByProduct.remove(_key(productId));
    _firstPurchaseInSessionByProduct.remove(_key(productId));
    _productCooldownUntil.remove(_key(productId));
    _settlementPendingProducts.remove(_key(productId));
    _timeoutAnnouncedProducts.remove(_key(productId));
    if (_currentProductId != null &&
        _key(_currentProductId!) == _key(productId)) {
      _currentProductId = null;
    }
    logger.i('🧹 [상품별] 쿨타임 초기화: $productId');
  }

  /// 🎯 심플 구매 시작 + 연속 구매 추적 (3줄로 해결!)
  void recordPurchaseAttempt({String? productId}) {
    _isPurchaseInProgress = true;
    _lastPurchaseTime = DateTime.now();
    if (productId != null) {
      _activeProducts.add(_key(productId));
      // 새 시도는 새 안내 사이클이다. 이전 시도의 "이미 안내함" 표시를
      // 남겨 두면 이번 시도의 정산 미확정 안내가 조용히 삼켜진다.
      _timeoutAnnouncedProducts.remove(_key(productId));
      _settlementPendingProducts.remove(_key(productId));
      // 성공 시에만 상품별 쿨타임을 적용하므로 여기서는 상품 ID만 저장
      _currentProductId = productId;
    }

    // 🔄 연속 구매 세션 추적
    _firstPurchaseInSession ??= _lastPurchaseTime;
    _consecutivePurchaseCount++;

    logger.i('🎯 구매 시작: $productId (연속 $_consecutivePurchaseCount회째)');
  }

  /// 🎯 심플 구매 완료 + 타이머 정리 (3줄로 해결!)
  ///
  /// [armRepurchaseCooldown] 이 false 면 이 상품의 재구매 쿨다운을 새로 세우지
  /// 않는다. **이미 정산이 끝난 트랜잭션의 재전달**을 처리할 때 쓴다.
  ///
  /// iOS 는 정산이 확인되지 않은 트랜잭션을 절대 finish 하지 않으므로, 아직
  /// finish 되지 않은 과거 결제는 앱 실행마다·새 구매와 나란히 다시 전달된다.
  /// 그 재전달을 새 결제처럼 다뤄 쿨다운을 세우면, 정작 사용자가 지금 하려는
  /// 구매가 "이전 결제가 스토어에서 처리 중입니다. 잠시 후 다시 시도해
  /// 주세요." 로 막힌다 — 처리 중인 결제는 없고, 그 결제는 이미 적립까지
  /// 끝났다 (1.3.0 TestFlight patch 8 의 연속 구매 오차단).
  void completePurchaseSession(
    String productId, {
    bool armRepurchaseCooldown = true,
  }) {
    final transactionId =
        '${productId}_${DateTime.now().millisecondsSinceEpoch}';
    _activeProducts.remove(_key(productId));
    // 다른 상품의 결제가 아직 진행 중이면 전역 진행 플래그를 내리지 않는다 -
    // 재전달 하나가 진행 중인 다른 구매의 상태를 지우면 안 된다.
    _isPurchaseInProgress = _activeProducts.isNotEmpty;
    _lastProcessedTransactionId = transactionId;

    if (armRepurchaseCooldown) {
      // ✅ 성공 직후에도 연속 구매를 막기 위해 최근 시도 시간을 현재로 갱신
      _lastPurchaseTime = DateTime.now();
      _currentProductId = productId;
      _lastPurchaseTimeByProduct[_key(productId)] = _lastPurchaseTime!;
      _firstPurchaseInSessionByProduct[_key(productId)] ??= _lastPurchaseTime!;
      _consecutivePurchaseCountByProduct[_key(productId)] =
          (_consecutivePurchaseCountByProduct[_key(productId)] ?? 0) + 1;
    }

    // 🛡️ 정상 구매 완료 시 안전망 타이머 정리
    stopSafetyTimer(productId: productId);

    logger.i(
      '🎯 구매 완료: $transactionId '
      '(타이머 정리됨, 재구매 쿨다운: $armRepurchaseCooldown)',
    );
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
      if (completedPurchase?.pendingCompletePurchase == true &&
          !(defaultTargetPlatform == TargetPlatform.android &&
              completedPurchase!.status == PurchaseStatus.pending)) {
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

  /// 🍎 iOS 전용 클린 작업 (최적화)
  Future<void> _performIOSCleanup(String productId) async {
    logger.i('🧹 🍎 iOS StoreKit 클린 작업');

    try {
      // StoreKit 트랜잭션 큐 정리를 위한 짧은 대기 (최적화: 500ms → 300ms)
      await Future.delayed(Duration(milliseconds: 300));

      // 현재 트랜잭션들 확인 및 완료 처리 (최적화: 2초 → 1초)
      final recentPurchases = await InAppPurchase.instance.purchaseStream
          .take(1)
          .timeout(Duration(seconds: 1))
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
            purchase.pendingCompletePurchase &&
            purchase.status != PurchaseStatus.pending) {
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
    _activeProducts.clear();
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

  void resetProductState(String productId, {String reason = '상품 상태 리셋'}) {
    _activeProducts.remove(_key(productId));
    stopSafetyTimer(productId: productId);
    logger.i('🔄 상품별 상태 리셋: $productId ($reason)');
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
      '[플랫폼별] 🔍 $platform 구매 판별: $productId (진행중: $_isPurchaseInProgress)',
    );

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
        purchaseDetails,
        transactionId,
        productId,
      );
    }
  }

  /// 🍎 iOS 전용 구매 판별 - 유연하고 관대한 처리
  bool _isActualPurchaseIOS(
    dynamic purchaseDetails,
    String transactionId,
    String productId,
  ) {
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
          '[iOS] 🍎 iOS 유연성: 최근 구매 시도와 연관된 $statusText 구매 (${elapsed.inSeconds}초 전)',
        );
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
          '[iOS] 🍎 iOS 극한 fallback: 3분 이내 $statusText 구매 (${elapsed.inMinutes}분 전) - 신중히 허용',
        );
        return true;
      }
    }

    final status = purchaseDetails.status.toString();
    logger.w('[iOS] 🍎 iOS 차단: 연관성 없는 구매 ($status)');
    return false;
  }

  /// 🤖 Android 전용 구매 판별 - 엄격하고 직선적인 처리
  bool _isActualPurchaseAndroid(
    dynamic purchaseDetails,
    String transactionId,
    String productId,
  ) {
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
          '[Android] 🤖 Android 엄격 허용: 최근 구매 시도 (${elapsed.inSeconds}초 전)',
        );
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
      'aborted',
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
      'LAErrorUserCancel',
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
    final isLate =
        !isActivePurchasing &&
        _safetyTimeoutTriggered &&
        _safetyTimeoutTime != null;

    if (isLate) {
      logger.i('🛡️ 늦은 구매 성공 감지');
    }

    return isLate;
  }

  /// 늦은 구매인지 판별 (상품 단위)
  ///
  /// 상품별 안전망 타임아웃은 해당 상품을 활성 목록에서 제거하므로, 타임아웃 이후에
  /// 검증이 도착한 구매만 늦은 구매로 판별된다. 다른 상품이 타임아웃되어도 진행 중인
  /// 이 상품의 구매는 영향을 받지 않는다.
  bool isLatePurchaseForProduct(String productId) =>
      isLatePurchase(_activeProducts.contains(_key(productId)));

  /// 늦은 구매 성공 리셋
  void resetLatePurchaseSuccess() {
    _safetyTimeoutTriggered = false;
    _safetyTimeoutTime = null;
    logger.i('🛡️ 늦은 구매 성공 상태 리셋됨');
  }

  /// 구매 결과 처리
  ///
  /// [showErrorDialog] 에 넘기는 값은 사용자 문장이 아니라 **에러 코드**다.
  /// arb 매핑은 UI 계층(`PurchaseStarCandyState`)이 한다 — 여기서 한국어
  /// 문장을 만들면 비한국어 사용자에게 한국어 오류가 노출된다.
  Future<void> handlePurchaseResult(
    Map<String, dynamic> purchaseResult,
    bool isActivePurchasing,
    Function(String) showErrorDialog, {
    String? productId,
    String? attemptId,
  }) async {
    final success = purchaseResult['success'] as bool;
    final wasCancelled = purchaseResult['wasCancelled'] as bool;
    final errorMessage = purchaseResult['errorMessage'] as String?;

    if (wasCancelled) {
      logger.i('[심플] 구매 취소 - 조용히 처리');
      if (productId != null) {
        resetProductState(productId, reason: '구매 취소');
      } else {
        resetInternalState(reason: '구매 취소');
        _resetPurchaseState();
      }
      _loadingKey.currentState?.hide();
    } else if (!success) {
      logger.e('[심플] 구매 실패: $errorMessage');
      if (productId != null) {
        resetProductState(productId, reason: '구매 실패');
      } else {
        resetInternalState(reason: '구매 실패');
        _resetPurchaseState();
      }
      _loadingKey.currentState?.hide();
      await showErrorDialog(errorMessage ?? 'GENERIC');
    } else {
      logger.i('[심플] 구매 시작 성공');
      startSafetyTimer(productId: productId, attemptId: attemptId);
    }
  }

  // Getters
  bool get isSafetyTimeoutTriggered => _safetyTimeoutTriggered;
  DateTime? get safetyTimeoutTime => _safetyTimeoutTime;
  DateTime? get lastPurchaseAttempt => _lastPurchaseTime;
}
