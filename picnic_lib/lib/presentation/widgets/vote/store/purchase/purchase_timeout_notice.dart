import 'package:flutter/widgets.dart';

/// 90초 안전망 타임아웃이 발동했을 때 사용자에게 보여 줄 안내의 종류.
enum PurchaseTimeoutNotice {
  /// 결제가 접수된 것으로 볼 수 있는 상태.
  ///
  /// 기존 `purchase_payment_accepted_message`("결제가 접수되었습니다...")를
  /// 보여 준다. 이중 결제 방지 안내이므로 이 팝업 자체를 없애면 안 된다.
  paymentAccepted,

  /// 결제 확인 자체가 불확실한 상태.
  ///
  /// 사용자가 아직 스토어 결제 시트 안에 있을 수 있으므로, 결제를 이미
  /// 확인했다고 단정하지 않는 `purchase_payment_unconfirmed_message`를
  /// 보여 준다.
  paymentUnconfirmed,

  /// 팝업을 띄우지 않는다.
  ///
  /// 이 시도의 런치 이후 식별자 없는 취소/에러가 관측됐고 구매 증거
  /// (pending/purchased 이벤트)가 전혀 없다 = 사실상 사용자가 취소한
  /// 시도다. 취소 이벤트가 거래 ID 없이 도착하면 불변식상 attempt/타이머를
  /// 지울 수 없어 90초 안전망이 살아남는데, 그때 "결제가 접수되었습니다"를
  /// 띄우면 방금 취소한 사용자에게 무의미한(그리고 틀린) 안내가 된다
  /// (iOS 실기기, 2026-08-06). 구매 증거가 하나라도 관측된 시도는 이
  /// 값으로 판정되지 않는다 - 이중 결제 방지 안내가 안전 기본값이다.
  suppressed,
}

/// 안전망 타임아웃 시점의 안내 문구를 고른다.
///
/// Android 는 Google Play Billing 이 결제 시트를 별도 Transparent Activity 로
/// 띄우므로, 시트가 열려 있는 동안 Flutter 앱은 inactive/paused 로 전환되고
/// 시트가 닫혀야 resumed 로 복귀한다. 따라서 "구매 런치 이후 resumed 가 한
/// 번도 없었고 지금도 resumed 가 아니다" = 사용자가 여전히 Play 결제 시트
/// 안에 있다(방치 포함)고 볼 수 있고, 이때 "결제가 접수되었습니다"는 아직
/// 일어나지 않았을 결제를 단정하는 안내가 된다.
///
/// iOS 는 SK2 purchase() 가 시트 상호작용이 끝날 때까지 블로킹 반환이라 이
/// 상태가 원천적으로 존재하지 않는다. 다만 resumed *이벤트*와 purchase()
/// 반환의 순서는 보장되지 않으므로(런치 반환 직후 플래그를 리셋하면 그 전에
/// 도착한 resumed 가 지워질 수 있다), iOS 는 플랫폼 가드로 항상
/// [PurchaseTimeoutNotice.paymentAccepted] 를 유지해 기존 동작을 바꾸지
/// 않는다.
///
/// [currentLifecycleState] 는 이중 안전장치다: resumed 이벤트를 놓쳤더라도
/// 지금 앱이 전면(resumed)이라면 사용자는 결제 시트 안에 있지 않으므로 기존
/// 안내를 유지한다 (null 이면 판단 근거가 없으므로 이벤트 추적만 따른다).
///
/// [identitylessCancellationObserved] 와 [purchaseEvidenceObserved] 는
/// "사실상 취소" 판정([PurchaseTimeoutNotice.suppressed])의 근거다. 취소
/// 관측만으로는 생략하지 않는다 - 결제가 실제로 이뤄졌는데 이벤트가 90초
/// 안에 도착하지 않은 드문 경우에 이 팝업이 유일한 이중 결제 안전장치이므로,
/// 구매 증거가 전혀 없을 때만 생략한다. 두 값 모두 판단 근거가 없으면
/// 보수적 기본값(증거 있음/취소 없음)으로 두어 기존 안내가 유지되게 한다.
PurchaseTimeoutNotice resolvePurchaseTimeoutNotice({
  required bool isIOS,
  required bool resumedSincePurchaseLaunch,
  required AppLifecycleState? currentLifecycleState,
  bool identitylessCancellationObserved = false,
  bool purchaseEvidenceObserved = true,
}) {
  // 사실상 취소: 식별자 없는 취소/에러가 관측됐고 구매 흔적이 0이며,
  // 시트가 닫혀 있는 시도다. 플랫폼 공통 - Android 도 responseCode 3 이
  // 식별자 없이 도착한다. 시트 닫힘 조건은 취소 서사와의 정합 확인이다:
  // 진짜 사용자 취소는 항상 시트가 닫힌 뒤이므로, 시트가 열린 채(방치)라면
  // 그 취소 관측은 이 시도의 것이 아니다. 판정은 resumed *이벤트* 또는
  // 현재 전면 상태 중 하나면 충분하다 - iOS 는 resumed 이벤트가 런치
  // 반환보다 먼저 지나가 관찰이 리셋될 수 있어(이벤트만 요구하면 iOS 취소
  // 억제가 레이스로 무력화된다, Sol 2차 재검증 MEDIUM-1) 현재 상태를
  // 함께 본다.
  final sheetClosed =
      resumedSincePurchaseLaunch ||
      currentLifecycleState == AppLifecycleState.resumed;
  if (identitylessCancellationObserved &&
      !purchaseEvidenceObserved &&
      sheetClosed) {
    return PurchaseTimeoutNotice.suppressed;
  }
  final stillInStoreSheet =
      !isIOS &&
      !resumedSincePurchaseLaunch &&
      currentLifecycleState != AppLifecycleState.resumed;
  return stillInStoreSheet
      ? PurchaseTimeoutNotice.paymentUnconfirmed
      : PurchaseTimeoutNotice.paymentAccepted;
}

/// 스토어 이벤트의 productID 가 가리킬 수 있는 서버 상품 ID 후보들.
///
/// 스토어 표기는 서버 ID 에 iOS 앱 접두사 또는 Android 네임스페이스가 붙은
/// 형태일 수 있다 (PaymentProductIdPolicy.effectiveProductId 의 역방향).
/// 활성 attempt 게이트가 이벤트 표기 그대로만 조회하면, 접두사가 설정된
/// 환경에서 런치 확정 전에 도착한 실결제 이벤트가 게이트에 걸려 증거가
/// 유실된다 (Sol 2차 재검증). 현재 앱 설정은 두 값 모두 비어 있어 후보가
/// 원본 하나뿐이지만, 설정이 바뀌어도 조용히 뚫리지 않도록 역해석을
/// 정책과 나란히 유지한다.
List<String> serverProductIdCandidatesForStoreEvent(
  String eventProductId, {
  required String iosAppPrefix,
  required String androidNamespace,
}) {
  final candidates = <String>[eventProductId];
  if (iosAppPrefix.isNotEmpty &&
      eventProductId.length > iosAppPrefix.length &&
      eventProductId.toUpperCase().startsWith(iosAppPrefix.toUpperCase())) {
    candidates.add(eventProductId.substring(iosAppPrefix.length));
  }
  if (androidNamespace.isNotEmpty &&
      eventProductId.length > androidNamespace.length &&
      eventProductId.toLowerCase().startsWith(androidNamespace.toLowerCase())) {
    candidates.add(eventProductId.substring(androidNamespace.length));
  }
  return candidates;
}

/// 구매 런치별 resumed 관찰 상태.
///
/// **상품(=안전망 타이머 키) 단위**로 "런치 이후 resumed 가 있었는지"를
/// 기록한다. 단일 boolean 으로 추적하면 서로 다른 상품의 안전망 타이머가
/// 공존할 때(A 시트를 닫은 뒤 식별자 없는 취소로 A 의 타이머가 남은 상태에서
/// B 를 런치) 마지막 런치가 이전 시도의 이력을 덮어, 이미 시트를 닫고 나온
/// 시도에도 미확정 문구가 나간다.
///
/// 순수 관찰 상태다: attempt 레지스트리·안전망 타이머·다이얼로그 상태에는
/// 관여하지 않는다.
class PurchaseLaunchLifecycleTracker {
  PurchaseLaunchLifecycleTracker({String Function(String)? canonicalize})
    : _canonicalize = canonicalize ?? _identity;

  static String _identity(String value) => value;

  final String Function(String) _canonicalize;
  final Map<String, PurchaseLaunchObservation> _observationsByProduct = {};

  /// 런치 기록이 아직 없을 때 도착한 구매 증거의 latch.
  ///
  /// purchased 이벤트는 런치 확정보다 먼저 도착할 수 있다
  /// (bindWithLaunchGrace 가 흡수하는 레이스와 동일). 그때 증거를 버리면
  /// 직후의 [recordLaunch] 가 증거 없음으로 초기화해, 이후 식별자 없는
  /// 취소가 관측되면 실결제 시도의 팝업이 잘못 생략된다 (Sol 2차 리뷰
  /// HIGH-2). 증거는 생략을 **막는** 방향으로만 작용하므로 오래된 latch 가
  /// 남아도 안전 방향 오류(팝업 표시)다.
  final Set<String> _evidenceBeforeLaunch = {};

  /// 이 상품의 스토어 결제 시트가 이제 사용자 앞에 있다 - 관찰 시작.
  ///
  /// [storeAliases] 는 이 시도의 이벤트가 달고 도착할 수 있는 스토어 상품
  /// ID 들이다 (iOS 는 앱 접두사, Android dev 는 네임스페이스가 붙어 서버
  /// ID 와 canonical 키가 달라진다 - Sol 2차 리뷰 HIGH-3). 같은 관찰
  /// 객체를 별칭 키로도 등록해 어느 표기로 도착해도 같은 시도로 모인다.
  void recordLaunch(String productId, {Iterable<String> storeAliases = const []}) {
    final keys = <String>{
      _canonicalize(productId),
      for (final alias in storeAliases)
        if (alias.trim().isNotEmpty) _canonicalize(alias),
    };
    final observation = PurchaseLaunchObservation._launched();
    observation.purchaseEvidenceObserved = keys.any(
      _evidenceBeforeLaunch.contains,
    );
    _evidenceBeforeLaunch.removeAll(keys);
    for (final key in keys) {
      _observationsByProduct[key] = observation;
    }
  }

  /// resumed 복귀는 "열려 있던 결제 시트가 닫혔다"는 뜻이므로, 관찰 중인
  /// 모든 런치에 기록한다.
  void recordResumed() {
    for (final observation in _observationsByProduct.values) {
      observation.resumedSinceLaunch = true;
    }
  }

  /// 식별자 없는 취소/에러가 도착했다. 어느 시도의 것인지 증명할 수 없으므로
  /// (그래서 attempt/타이머도 지우지 못한다) 관찰 중인 모든 런치에 기록한다.
  /// 상태 판정이 아니라 문구/표시 판정에만 쓰인다.
  void recordIdentitylessCancellation() {
    for (final observation in _observationsByProduct.values) {
      observation.identitylessCancellationObserved = true;
    }
  }

  /// 이 상품의 구매 증거(pending/purchased/restored 이벤트)가 도착했다.
  ///
  /// 런치 기록이 아직 없으면 latch 해 뒀다가 [recordLaunch] 가 병합한다.
  void recordPurchaseEvidence(String productId) {
    final key = _canonicalize(productId);
    final observation = _observationsByProduct[key];
    if (observation != null) {
      observation.purchaseEvidenceObserved = true;
      return;
    }
    _evidenceBeforeLaunch.add(key);
  }

  /// 이 상품(별칭 포함)의 런치 관찰이 존재하는지.
  ///
  /// 런치 전 latch 를 걸지 말지 판단하는 쪽(State)이 "활성 시도가 있는
  /// 이벤트인지"를 가리는 데 쓴다.
  bool hasObservation(String productId) =>
      _observationsByProduct.containsKey(_canonicalize(productId));

  /// 런치 기록이 없는 상품(전역 타이머의 null 포함)은 판단 근거가 없으므로
  /// 보수적 관찰값(resumed 있음·구매 증거 있음·취소 관측 없음)을 돌려 기존
  /// 접수 안내가 유지되게 한다 - 생략과 미확정 문구는 적극적 근거가 있을
  /// 때만 쓴다.
  PurchaseLaunchObservation observationFor(String? productId) {
    if (productId == null) return PurchaseLaunchObservation._conservative();
    return _observationsByProduct[_canonicalize(productId)] ??
        PurchaseLaunchObservation._conservative();
  }

  /// [observationFor] 의 resumed 축약 (기존 테스트 호환).
  bool resumedSinceLaunch(String? productId) =>
      observationFor(productId).resumedSinceLaunch;

  /// 이 시도의 안내가 끝났거나 시도가 정리됐다 - 관찰 종료 (별칭 포함).
  void clear(String? productId) {
    if (productId == null) return;
    final observation = _observationsByProduct.remove(
      _canonicalize(productId),
    );
    if (observation == null) return;
    _observationsByProduct.removeWhere(
      (_, value) => identical(value, observation),
    );
  }
}

/// 한 구매 런치에 대해 관찰된 신호 묶음. 순수 관찰값이다.
class PurchaseLaunchObservation {
  PurchaseLaunchObservation._launched()
    : resumedSinceLaunch = false,
      purchaseEvidenceObserved = false,
      identitylessCancellationObserved = false;

  /// 판단 근거가 없을 때의 보수적 기본값: 어떤 적극적 판정(생략·미확정)도
  /// 트리거하지 않아 기존 접수 안내가 유지된다.
  PurchaseLaunchObservation._conservative()
    : resumedSinceLaunch = true,
      purchaseEvidenceObserved = true,
      identitylessCancellationObserved = false;

  bool resumedSinceLaunch;
  bool purchaseEvidenceObserved;
  bool identitylessCancellationObserved;
}
