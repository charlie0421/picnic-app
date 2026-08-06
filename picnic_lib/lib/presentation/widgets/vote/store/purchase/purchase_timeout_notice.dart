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
PurchaseTimeoutNotice resolvePurchaseTimeoutNotice({
  required bool isIOS,
  required bool resumedSincePurchaseLaunch,
  required AppLifecycleState? currentLifecycleState,
}) {
  final stillInStoreSheet =
      !isIOS &&
      !resumedSincePurchaseLaunch &&
      currentLifecycleState != AppLifecycleState.resumed;
  return stillInStoreSheet
      ? PurchaseTimeoutNotice.paymentUnconfirmed
      : PurchaseTimeoutNotice.paymentAccepted;
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
  final Map<String, bool> _resumedSinceLaunchByProduct = {};

  /// 이 상품의 스토어 결제 시트가 이제 사용자 앞에 있다 - 관찰 시작.
  void recordLaunch(String productId) {
    _resumedSinceLaunchByProduct[_canonicalize(productId)] = false;
  }

  /// resumed 복귀는 "열려 있던 결제 시트가 닫혔다"는 뜻이므로, 관찰 중인
  /// 모든 런치에 기록한다.
  void recordResumed() {
    for (final key in _resumedSinceLaunchByProduct.keys) {
      _resumedSinceLaunchByProduct[key] = true;
    }
  }

  /// 런치 기록이 없는 상품(전역 타이머의 null 포함)은 판단 근거가 없으므로
  /// true 를 돌려 기존 접수 안내가 유지되게 한다 - 미확정 문구는 "아직 시트
  /// 안"이라는 적극적 근거가 있을 때만 쓴다.
  bool resumedSinceLaunch(String? productId) {
    if (productId == null) return true;
    return _resumedSinceLaunchByProduct[_canonicalize(productId)] ?? true;
  }

  /// 이 시도의 안내가 끝났거나 시도가 정리됐다 - 관찰 종료.
  void clear(String? productId) {
    if (productId == null) return;
    _resumedSinceLaunchByProduct.remove(_canonicalize(productId));
  }
}
