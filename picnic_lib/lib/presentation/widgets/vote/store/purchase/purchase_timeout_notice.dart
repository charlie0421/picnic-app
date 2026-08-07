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
/// 이 시도의 스토어 결제 시트가 **닫혀 있는가** - 순수 lifecycle 판정.
///
/// Android 는 Play 결제 시트가 별도 Activity 라 시트가 떠 있는 동안 앱이
/// resumed 로 복귀하지 못한다. 그래서 "런치 이후 resumed 를 한 번도 못
/// 받았고 지금도 전면이 아니다" = **사용자가 그 상품의 결제 시트 안에 있다**
/// 이고, 이것은 `queryPastPurchases` 가 구조적으로 답할 수 없는 사실이다
/// (Play 는 진행 중인 결제 Activity 를 어떤 쿼리로도 노출하지 않는다).
///
/// 두 신호를 OR 로 보는 이유: resumed *이벤트* 는 런치 반환보다 먼저 지나가
/// 관찰이 리셋될 수 있으므로(iOS), 현재 전면 상태를 이중 안전장치로 함께
/// 본다. 판단 근거가 없으면([currentLifecycleState] 가 null 이고 관찰도
/// 없으면) 관찰 기본값이 보수적으로 "닫힘" 이라, 시트 보호가 아니라 기존
/// 동작이 유지된다.
///
/// 이것은 **90초 안내 문구 판정 전용**이다. 시도를 지우는 정리 후보 판정은
/// 이 술어를 쓰면 안 된다 - [isPurchaseSheetProvenClosed] 를 쓴다. 두 판정의
/// 비용이 비대칭이기 때문이다: 문구를 틀리면 팝업이 한 번 더 보일 뿐이지만,
/// 정리를 틀리면 **진행 중인 결제의 스피너와 이중결제 가드가 사라진다**.
/// 그래서 문구 쪽은 "지금 전면이면 닫힌 것으로 본다"는 느슨한 판정을 유지하고
/// (그 관대함이 iOS 취소 억제를 살린다), 정리 쪽은 양성 전이 증거를 요구한다.
bool isPurchaseSheetClosed({
  required bool resumedSincePurchaseLaunch,
  required AppLifecycleState? currentLifecycleState,
}) =>
    resumedSincePurchaseLaunch ||
    currentLifecycleState == AppLifecycleState.resumed;

/// 이 시도의 결제 시트가 **닫혔음이 증명됐는가** - 정리 후보 판정 전용.
///
/// [isPurchaseSheetClosed] 와 갈라지는 이유는 딱 하나, **런치 직후의 창**이다.
/// Android 의 `buyConsumable` 은 Play 결제 Activity 가 실제로 전면에 오기
/// **전에** true 로 돌아온다. 그 짧은 순간 앱은 아직 resumed 이고, "지금
/// 전면이다"만 보는 판정은 이제 막 시트를 띄운 시도를 "닫혔다"로 오판한다.
/// 거기에 지연된 이전 종결 관측이 겹치면 그 시도가 후보가 되고, Android
/// `queryPastPurchases` 는 진행 중인 결제 Activity 를 볼 수 없어 빈 큐로
/// 답하므로 - 사용자가 결제 시트 안에 있는 채로 시도가 지워진다
/// (Sol 4차 재검증 MAJOR).
///
/// 그래서 여기서는 "지금 resumed 인가"가 아니라 **런치 이후 실제로 비전면
/// 전이를 거쳤는가**를 본다. 시트가 뜨면 반드시 비전면 전이가 먼저 일어나므로,
/// 그 전이를 보지 못했다면 시트는 아직 열리기 전이거나 열려 있는 중이다.
///
/// 관찰 창은 런치 **반환** 이 아니라 스토어 런치 호출(`buyConsumable`)
/// **직전**부터다 ([PurchaseLaunchLifecycleTracker.recordLaunch] 의
/// `foregroundExitsAtLaunchStart`). 이 한 칸이 플랫폼 분기 없이 두 스토어를
/// 모두 맞춘다. 구매 버튼을 누른 시점이 아니라 런치 호출 직전인 이유는,
/// 그 사이의 중복 방지 검증·상품 조회 중에 일어난 백그라운드 왕복이
/// 결제 시트의 것으로 오인되면 안 되기 때문이다 (Sol 5차 재검증 MAJOR).
///
/// - iOS: StoreKit 은 시트 상호작용이 끝나야 런치 호출이 반환된다. 즉 전이
///   (비전면 → resumed)가 **런치 호출이 도는 동안** 전부 지나가고, 반환 시점의
///   앱은 이미 전면이다. 요청 시점부터 세면 그 전이가 창 안에 들어와
///   `leftForeground` 가 서고, 현재 resumed 와 합쳐져 곧바로 "닫힘"이 된다 -
///   기존 iOS 취소 정리 경로가 그대로 산다.
/// - Android: 런치 호출이 도는 동안에는 전이가 없다(시트는 아직 안 떴다).
///   그래서 반환 직후에는 `leftForeground` 가 서지 않아 후보가 되지 않고,
///   시트가 떠서 전이가 일어난 뒤 사용자가 닫고 돌아와야 비로소 닫힘이 된다.
///
/// 두 번째 항(`leftForeground && 지금 resumed`)은 resumed *이벤트* 를 놓친
/// 경우의 이중 안전장치다 - 한 번 나갔던 앱이 지금 전면이라면 시트는 닫혔다.
bool isPurchaseSheetProvenClosed({
  required bool leftForegroundSincePurchaseLaunch,
  required bool returnedToForegroundSincePurchaseLaunch,
  required AppLifecycleState? currentLifecycleState,
}) =>
    returnedToForegroundSincePurchaseLaunch ||
    (leftForegroundSincePurchaseLaunch &&
        currentLifecycleState == AppLifecycleState.resumed);

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
  final sheetClosed = isPurchaseSheetClosed(
    resumedSincePurchaseLaunch: resumedSincePurchaseLaunch,
    currentLifecycleState: currentLifecycleState,
  );
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

  /// 앱이 전면을 떠난 횟수(단조 증가). 시각이 아니라 순번인 이유는
  /// [PurchaseExecutionContext.launchSuccessSequence] 와 같다 - 우리가 직접
  /// 세므로 기기 시계나 이벤트 도착 지연에 흔들리지 않는다.
  ///
  /// 호출자는 스토어 결제 플로를 실제로 여는 호출(`buyConsumable`) **직전에**
  /// 이 값을 읽어 두었다가 [recordLaunch] 에 되돌려 준다. 그러면 "런치 호출이
  /// 도는 동안 전이가 있었는가"를 알 수 있고, 그것이 iOS(블로킹 반환)와
  /// Android(즉시 반환)를 플랫폼 분기 없이 가른다 -
  /// [isPurchaseSheetProvenClosed] 참고.
  ///
  /// **더 이른 시점에서 읽으면 안 된다.** 구매 진입부터 실제 런치까지는
  /// 중복 방지 검증·상품 조회·pending 조회라는 비동기 사전 처리가 있고, 그
  /// 동안의 백그라운드 왕복까지 창에 들어오면 시트가 뜨기도 전에
  /// `leftForeground` 가 서서 방금 시작한 시도가 정리 후보가 된다
  /// (Sol 5차 재검증 MAJOR).
  int get foregroundExitCount => _foregroundExitCount;
  int _foregroundExitCount = 0;

  /// 이 상품의 스토어 결제 시트가 이제 사용자 앞에 있다 - 관찰 시작.
  ///
  /// [storeAliases] 는 이 시도의 이벤트가 달고 도착할 수 있는 스토어 상품
  /// ID 들이다 (iOS 는 앱 접두사, Android dev 는 네임스페이스가 붙어 서버
  /// ID 와 canonical 키가 달라진다 - Sol 2차 리뷰 HIGH-3). 같은 관찰
  /// 객체를 별칭 키로도 등록해 어느 표기로 도착해도 같은 시도로 모인다.
  ///
  /// [foregroundExitsAtLaunchStart] 는 스토어 런치 호출 **직전**에 읽어 둔
  /// [foregroundExitCount] 다. 이걸 넘겨 주면 비전면 전이의 관찰 창이 런치
  /// **반환**이 아니라 런치 **요청** 시점부터 열려, 런치 호출이 도는 동안
  /// 지나간 전이(iOS 블로킹 반환)도 이 시도의 것으로 잡힌다. 생략하면 창은
  /// 반환 시점부터 열린다 - 보수적인 쪽(전이 없음 = 아직 닫힘 아님)이다.
  void recordLaunch(
    String productId, {
    Iterable<String> storeAliases = const [],
    int? foregroundExitsAtLaunchStart,
  }) {
    final keys = <String>{
      _canonicalize(productId),
      for (final alias in storeAliases)
        if (alias.trim().isNotEmpty) _canonicalize(alias),
    };
    final observation = PurchaseLaunchObservation._launched();
    observation.purchaseEvidenceObserved = keys.any(
      _evidenceBeforeLaunch.contains,
    );
    observation.leftForegroundSinceLaunch =
        _foregroundExitCount >
        (foregroundExitsAtLaunchStart ?? _foregroundExitCount);
    _evidenceBeforeLaunch.removeAll(keys);
    for (final key in keys) {
      _observationsByProduct[key] = observation;
    }
  }

  /// resumed 복귀는 "열려 있던 결제 시트가 닫혔다"는 뜻이므로, 관찰 중인
  /// 모든 런치에 기록한다.
  ///
  /// 정리 후보 판정이 쓰는 것은 [PurchaseLaunchObservation.resumedSinceLaunch]
  /// 가 아니라 **비전면 전이를 거친 뒤의** 복귀다. 전이를 본 적 없는 관찰은
  /// 아직 시트가 뜨기 전이므로 이 resumed 는 "닫혔다"의 증거가 아니다.
  void recordResumed() {
    for (final observation in _observationsByProduct.values) {
      observation.resumedSinceLaunch = true;
      if (observation.leftForegroundSinceLaunch) {
        observation.returnedToForegroundSinceLaunch = true;
      }
    }
  }

  /// 앱이 전면을 떠났다(inactive/paused/hidden/detached).
  ///
  /// Android 는 Play 결제 시트가 별도 Activity 라 시트가 뜨면 반드시 이
  /// 전이가 먼저 일어난다. 그래서 이 관찰이 "시트가 실제로 열렸다"의 증거이고,
  /// 뒤이은 [recordResumed] 와 짝을 이뤄야 "닫혔다"가 된다.
  void recordLeftForeground() {
    _foregroundExitCount++;
    for (final observation in _observationsByProduct.values) {
      observation.leftForegroundSinceLaunch = true;
    }
  }

  /// 식별자 없는 취소/에러가 도착했다. 어느 시도의 것인지 증명할 수 없으므로
  /// (그래서 attempt/타이머도 지우지 못한다) **활성 관찰이 정확히 하나일
  /// 때만** 그 시도의 것으로 기록한다. 둘 이상이면 기록하지 않는다 - 다른
  /// 상품의 취소가 실결제 시도(이벤트 지연 중)의 이중 결제 경고까지 지울 수
  /// 있기 때문이다 (Sol 머지 게이트 리뷰, PR #137). 기록하지 못한 비용은
  /// 취소한 사용자에게 팝업이 한 번 더 보이는 것뿐이고(현상 유지), 잘못
  /// 기록한 비용은 경고 유실이므로 보수 쪽을 택한다. 상태 판정이 아니라
  /// 문구/표시 판정에만 쓰인다.
  void recordIdentitylessCancellation() {
    final distinctObservations = _observationsByProduct.values.toSet();
    if (distinctObservations.length != 1) return;
    distinctObservations.single.identitylessCancellationObserved = true;
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
      leftForegroundSinceLaunch = false,
      returnedToForegroundSinceLaunch = false,
      purchaseEvidenceObserved = false,
      identitylessCancellationObserved = false;

  /// 판단 근거가 없을 때의 보수적 기본값: 어떤 적극적 판정(생략·미확정)도
  /// 트리거하지 않아 기존 접수 안내가 유지된다.
  ///
  /// 런치 관찰이 없는 상품은 정리 후보 판정에서도 기존 동작(시트 닫힘)을
  /// 유지한다. 런치가 성공한 시도는 항상 관찰을 갖고 있으므로 - `recordLaunch`
  /// 는 런치 결과 적용과 같은 동기 블록에서 불린다 - 이 기본값이 4차 반례의
  /// "런치 직후" 창을 열어 주지는 않는다.
  PurchaseLaunchObservation._conservative()
    : resumedSinceLaunch = true,
      leftForegroundSinceLaunch = true,
      returnedToForegroundSinceLaunch = true,
      purchaseEvidenceObserved = true,
      identitylessCancellationObserved = false;

  bool resumedSinceLaunch;

  /// 런치 이후(정확히는 런치 **요청** 이후) 앱이 전면을 떠난 적이 있는가.
  /// 결제 시트가 실제로 열렸다는 증거다.
  bool leftForegroundSinceLaunch;

  /// 그 비전면 전이를 거친 **뒤에** resumed 로 복귀했는가. 결제 시트가
  /// 닫혔다는 양성 증거이며, 정리 후보 판정이 요구하는 것이 이것이다.
  bool returnedToForegroundSinceLaunch;

  bool purchaseEvidenceObserved;
  bool identitylessCancellationObserved;
}
