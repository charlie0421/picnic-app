import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseCampaignAttempt {
  const PurchaseCampaignAttempt({
    required this.attemptId,
    required this.productId,
    required this.displayedCampaign,
  });
  final String attemptId;
  final String productId;
  final ActivePromotionCampaignModel? displayedCampaign;
}

class PurchaseExecutionContext {
  PurchaseExecutionContext({required this.attempt, required this.launchedAt});
  final PurchaseCampaignAttempt attempt;
  final DateTime launchedAt;

  /// 이 시도의 런치 호출이 **성공으로 반환된** 순번 (레지스트리 전역 카운터).
  /// null 이면 `initiatePurchase` 가 아직 돌아오지 않았다.
  ///
  /// 시계가 아니라 단조 증가 순번인 것이 핵심이다. 이 값의 유일한 용도는
  /// "다른 런치가 이 런치보다 **뒤에** 성공했는가"를 판정하는 것인데
  /// ([PurchaseCampaignAttemptRegistry.cancellationCandidates] 의 증거 (b)),
  /// 시각으로 비교하면 같은 밀리초에 들어온 두 런치나 기기 시계 조정에
  /// 판정이 흔들린다. 순번은 우리가 직접 증가시키므로 그런 여지가 없다.
  int? launchSuccessSequence;

  bool get launched => launchSuccessSequence != null;

  String? transactionId;
}

class PurchaseCampaignAttemptRegistry {
  PurchaseCampaignAttemptRegistry({DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final Map<String, PurchaseExecutionContext> _byProduct = {};
  final Map<String, String> _attemptByTransaction = {};
  final Set<String> _completedTransactions = {};
  DateTime? _identitylessTerminalAt;

  /// [recordIdentitylessTermination] 이 호출될 때마다 증가한다.
  ///
  /// [consumeIdentitylessTermination] 이 "내가 확인한 그 관측"만 소진하도록
  /// 하는 세대 표식이다. 스토어 왕복(비동기) 사이에 **새** 취소가 관측되면
  /// 세대가 달라져 소진이 거부되고, 그 새 관측은 다음 스윕을 정당화하기 위해
  /// 살아남는다 (Sol 3차 재검증 #3).
  int _terminationGeneration = 0;

  /// 지금까지 성공한 런치의 수. [PurchaseExecutionContext.launchSuccessSequence]
  /// 가 여기서 부여된다.
  int _launchSuccessCount = 0;

  /// Supabase 카탈로그 ID는 대문자(STAR100), Google Play 이벤트의 productID는
  /// 소문자(star100)다. Casing만 다른 같은 상품이 같은 컨텍스트로 모이지 않으면
  /// 정상 결제 이벤트가 orphan으로 폐기된다.
  static String canonicalProductKey(String productId) =>
      productId.trim().toUpperCase();

  PurchaseCampaignAttempt? operator [](String productId) =>
      _byProduct[canonicalProductKey(productId)]?.attempt;
  bool contains(String productId) =>
      _byProduct.containsKey(canonicalProductKey(productId));

  /// 지금 등록돼 있는 모든 상품의 시도 **스냅샷**.
  List<PurchaseCampaignAttempt> get activeAttempts =>
      _byProduct.values.map((c) => c.attempt).toList(growable: false);

  bool get isEmpty => _byProduct.isEmpty;

  /// 어느 시도의 것인지 증명할 수 없는 종결 이벤트(취소·실패)를 관측했다고
  /// 기록한다.
  ///
  /// 귀속이 아니다 - 이 호출은 어떤 시도도 지우지 않고, 시도 하나를 지목하지도
  /// 않는다. 기록하는 사실은 딱 하나, **"이 시각에 결제 하나가 끝났다"** 이다.
  ///
  /// 이 시각은 이벤트의 **도착** 시각이지 발생 시각이 아니다. 그래서
  /// [cancellationCandidates] 는 이것을 "이 관측보다 뒤에 시작된 시도는
  /// 제외" 라는 필터로만 쓰고, **어느 시도가 끝났는지는 결코 이 시각으로
  /// 판정하지 않는다** - 지연된 이전 종결 이벤트는 현재 시도의 런치 뒤에
  /// 도착할 수 있기 때문이다 (Sol 3차 재검증 #1). 그 판정은 결제 시트가
  /// 닫혔다는 lifecycle 증거가 함께 있을 때만 성립한다.
  void recordIdentitylessTermination() {
    _identitylessTerminalAt = _now().toUtc();
    _terminationGeneration++;
  }

  /// 지금 들고 있는 관측의 세대. 스토어 왕복 **전에** 읽어 두었다가
  /// [consumeIdentitylessTermination] 에 되돌려 준다.
  int get terminationGeneration => _terminationGeneration;

  /// 스토어 큐를 실제로 확인한 뒤 호출한다 - 관측 하나가 검증된 스윕 한 번을
  /// 넘어서 계속 남아 미래의 정리를 정당화하지 못하게 소진시킨다.
  ///
  /// [generation] 이 현재 세대와 다르면 아무것도 소진하지 않고 false 를
  /// 돌려준다. 그 사이에 도착한 취소는 이 스윕이 확인한 사실이 아니므로,
  /// 무조건 소진하면 그 취소가 남긴 시도는 90초 안전망까지 스피너로 남는다
  /// (Sol 3차 재검증 #3 - 원래 결함의 재발).
  bool consumeIdentitylessTermination(int generation) {
    if (generation != _terminationGeneration) return false;
    _identitylessTerminalAt = null;
    return true;
  }

  bool get hasIdentitylessTermination => _identitylessTerminalAt != null;

  /// 정리해도 되는 **후보** 시도들. 후보라는 것이 곧 정리 사유는 아니다 -
  /// 호출자([reconcileCancelledAttemptsIfQueueEmpty])가 여기에 "스토어 큐에
  /// 살아 있는 결제가 하나도 없었다"는 실측을 더해야 실제로 지운다.
  ///
  /// 모든 후보는 두 가지 전제를 먼저 만족해야 한다.
  ///
  /// - [PurchaseExecutionContext.launched] - 런치 호출이 이미 반환됐다.
  ///   아직 반환 전이면 initiatePurchase 가 돌고 있는 정상 진행 중 시도다.
  /// - [PurchaseExecutionContext.transactionId] 가 null - 이 시도에 묶인
  ///   스토어 트랜잭션이 없다. 묶여 있다면 실결제가 정산 중이라는 뜻이다.
  ///
  /// 그 위에 **이 시도의 결제 플로가 끝났다는 양성 증거**가 하나 필요하다.
  /// 두 가지 중 하나면 된다.
  ///
  /// **(b) 더 뒤에 성공한 런치가 있다.** 스토어는 동시에 하나의 결제 플로만
  /// 허용한다 - Play 는 별도 Activity 로 플로를 띄우고 두 번째를 거부하며,
  /// StoreKit 도 같은 결제를 중첩시키지 않는다. 그래서 **다른 런치가
  /// 성공적으로 반환됐다는 사실 자체가, 이 시도의 플로는 그 전에 끝났다는
  /// 스토어 자신의 증명**이다. 실제 결함 시나리오(A 취소 → B 구매)가 정확히
  /// 이 경우다. 판정은 [PurchaseExecutionContext.launchSuccessSequence] 순번
  /// 비교이므로 이벤트 도착 시각에 의존하지 않는다.
  ///
  /// **(a) 이 시도의 결제 시트가 닫혔고, 그 뒤로 종결 이벤트를 관측했다.**
  /// [isPaymentSheetClosed] 는 상품별 lifecycle 관찰이다 - Android 는 Play
  /// 결제 시트가 별도 Activity 라 시트가 떠 있는 동안 앱이 resumed 로
  /// 복귀하지 못하므로, "런치 후 resumed 없음 + 지금도 비전면" 이 곧 "사용자가
  /// 그 상품의 결제 시트 안에 있다" 이다.
  ///
  /// 왜 (a) 에 lifecycle 이 필요한가 - 이것이 3라운드의 방향 전환이다.
  /// 앞선 두 라운드는 "종결 이벤트 관측 + 큐 실측 empty" 로 충분하다고 봤다.
  /// iOS 는 그게 성립한다: `SKPaymentQueue` 가 `purchasing`/`deferred` 를
  /// 들고 있어 [UnfinishedPurchaseScan.liveInFlight] 로 시트 안 사용자가
  /// 보인다. **Android 는 구조적으로 성립하지 않는다** - `queryPastPurchases`
  /// 는 소유된 구매만 답하고, 사용자가 들어가 있는 Play 결제 Activity 는 어떤
  /// 쿼리로도 보이지 않는다. 그래서 큐는 항상 empty 로 답하고, 지연된 **이전**
  /// 종결 이벤트가 그 순간 도착하면 지금 결제 중인 정상 시도가 후보가 되어
  /// 지워졌다 (Sol 3차 재검증 #1·#2). 큐를 더 정교하게 읽어서는 닫히지
  /// 않는다 - 큐에 없는 사실이기 때문이다. lifecycle 신호가 정확히 그 구멍을
  /// 메운다.
  ///
  /// 시간 조건([DateTime] 비교)은 남겨 두지만 더 이상 단독으로 하중을 받지
  /// 않는다. 관측 시각은 이벤트 **도착** 시각이라 발생 시각이 아니고, 그래서
  /// "이 관측보다 뒤에 시작된 시도는 제외" 라는 필터로만 쓸 수 있다.
  List<PurchaseCampaignAttempt> cancellationCandidates({
    required bool Function(String productId) isPaymentSheetClosed,
  }) {
    final terminalAt = _identitylessTerminalAt;
    return _byProduct.values
        .where((c) => _flowProvenEnded(c, terminalAt, isPaymentSheetClosed))
        .map((c) => c.attempt)
        .toList(growable: false);
  }

  bool _flowProvenEnded(
    PurchaseExecutionContext c,
    DateTime? terminalAt,
    bool Function(String productId) isPaymentSheetClosed,
  ) {
    final sequence = c.launchSuccessSequence;
    if (sequence == null || c.transactionId != null) return false;
    // (b) 이 런치보다 뒤에 성공한 런치가 있다 = 스토어가 이 플로의 종료를
    //     증명했다.
    if (_launchSuccessCount > sequence) return true;
    // (a) 관측된 종결 + 이 시도의 시트가 닫혀 있음.
    return terminalAt != null &&
        !terminalAt.isBefore(c.launchedAt) &&
        isPaymentSheetClosed(c.attempt.productId);
  }

  bool begin(PurchaseCampaignAttempt attempt) =>
      _byProduct
          .putIfAbsent(
            canonicalProductKey(attempt.productId),
            () => PurchaseExecutionContext(
              attempt: attempt,
              launchedAt: _now().toUtc(),
            ),
          )
          .attempt ==
      attempt;

  bool removeIfMatches(String productId, String attemptId) {
    final key = canonicalProductKey(productId);
    if (_byProduct[key]?.attempt.attemptId != attemptId) return false;
    _byProduct.remove(key);
    return true;
  }

  bool applyLaunchResult(
    String productId,
    String attemptId,
    Map<String, dynamic> result,
  ) {
    final terminal =
        result['wasCancelled'] == true || result['success'] != true;
    if (terminal) return removeIfMatches(productId, attemptId);
    final context = _byProduct[canonicalProductKey(productId)];
    if (context?.attempt.attemptId == attemptId &&
        context!.launchSuccessSequence == null) {
      // 순번은 한 시도에 한 번만 부여한다. 두 번 부여하면 이 시도가 스스로
      // 최신 런치가 되어, 자기보다 뒤에 성공한 런치가 있다는 증거 (b) 가
      // 조용히 사라진다.
      context.launchSuccessSequence = ++_launchSuccessCount;
    }
    return false;
  }

  /// Binds a StoreKit/Play event to the attempt that was locked at launch.
  ///
  /// A transaction id is mandatory: product id alone is not transaction
  /// identity. Restores are recovery traffic and never consume a live launch.
  PurchaseCampaignAttempt? bind(PurchaseDetails purchase) {
    final transactionId = purchase.purchaseID;
    final context = _byProduct[canonicalProductKey(purchase.productID)];
    final transactionAt = _transactionAt(purchase);
    if (transactionId == null ||
        transactionId.isEmpty ||
        purchase.status == PurchaseStatus.restored ||
        _completedTransactions.contains(transactionId) ||
        context == null ||
        _staleBeforeLaunch(context, transactionAt)) {
      return null;
    }
    final existingAttemptId = _attemptByTransaction[transactionId];
    if (existingAttemptId != null) {
      return context.attempt.attemptId == existingAttemptId
          ? context.attempt
          : null;
    }
    if (!context.launched || context.transactionId != null) {
      return null;
    }
    context.transactionId = transactionId;
    _attemptByTransaction[transactionId] = context.attempt.attemptId;
    return context.attempt;
  }

  /// bind()에 짧은 런치 유예를 더한 버전.
  ///
  /// 스토어 처리가 매우 빠르면(재인증 직후의 Apple 샌드박스 등) purchased
  /// 이벤트가 initiatePurchase의 런치 결과(applyLaunchResult →
  /// launched=true)보다 먼저 도착해 launched 게이트에 걸린다. 그대로
  /// orphan으로 보내면 적립은 되지만 영수증 다이얼로그가 생략된다
  /// (iOS 실기기, 2026-07-28). 시도가 등록돼 있는 동안 잠깐 기다렸다가
  /// 다시 bind한다. 런치가 실패로 끝나면 시도가 제거되어 즉시 중단된다.
  Future<PurchaseCampaignAttempt?> bindWithLaunchGrace(
    PurchaseDetails purchase, {
    int retries = 15,
    Duration delay = const Duration(milliseconds: 200),
  }) async {
    var attempt = bind(purchase);
    while (attempt == null && retries-- > 0 && _hasPendingLaunchRace(purchase)) {
      await Future.delayed(delay);
      attempt = bind(purchase);
    }
    return attempt;
  }

  /// 이 이벤트가 아직 [launched] 세팅 전인 활성 시도를 만날 수 있는 상태인지.
  ///
  /// [bind] 는 거래ID(purchaseID)가 있는 이벤트만 처리한다 - 거래ID가 없는
  /// 이벤트는 재시도해도 절대 bind되지 않으므로(아래 참고) 재시도할 이유가
  /// 없다.
  ///
  /// `purchased` 뿐 아니라 `error`/`canceled` 도 같은 레이스를 겪는다 -
  /// 스토어 스트림이 initiatePurchase()의 launched=true 세팅보다 먼저
  /// 도착할 수 있다.
  bool _hasPendingLaunchRace(PurchaseDetails purchase) {
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.error &&
        purchase.status != PurchaseStatus.canceled) {
      return false;
    }
    final hasTransactionId =
        purchase.purchaseID != null && purchase.purchaseID!.isNotEmpty;
    return hasTransactionId && contains(purchase.productID);
  }

  // 거래ID(purchaseID) 없는 error/canceled 이벤트를 상품ID만으로 활성
  // 시도에 묶는 폴백(구 currentTerminalWithoutId)은 제거했다. productID는
  // 거래 식별자가 아니고 레지스트리는 상품당 컨텍스트를 하나만 들고 있으므로,
  // 상품ID만으로 매칭하면 이미 안전망으로 정리된 이전 시도의 지연 이벤트가
  // 같은 상품의 새 시도(재시도/재구매)를 잘못 지울 수 있다 (Codex Frontier
  // 리뷰, PR #137 - productID가 전혀 없는 경우의 "유일한 활성 시도" 발견적
  // 규칙도, productID는 있지만 purchaseID가 없는 경우의 상품 매칭도 둘 다
  // 이 위험을 갖고 있었다). 거래ID 없는 error/canceled 이벤트는 어떤 시도와도
  // 묶지 않는다 - 호출자(`PurchaseStarCandyState._processPurchaseDetail`)가
  // 전역 로딩 오버레이만 내리는 것으로 대응한다.

  /// 이벤트가 이 시도보다 "명백히 과거"인지.
  ///
  /// transactionDate는 스토어 서버 시계(iOS는 Apple), launchedAt은 기기
  /// 시계라 그대로 비교하면 기기 시계가 조금만 빨라도 방금 산 구매가
  /// 전부 stale로 폐기된다 (iOS 무한 로딩, 2026-07-28). 허용 오차를
  /// 넘어서는 과거만 stale로 보고, transactionDate가 null이면 시간으로는
  /// 판정하지 않는다 — 신원은 transactionId + launched 게이트가 지킨다.
  static bool _staleBeforeLaunch(
    PurchaseExecutionContext context,
    DateTime? transactionAt,
  ) =>
      transactionAt != null &&
      transactionAt.isBefore(
        context.launchedAt.subtract(
          PurchaseConstants.purchaseClockSkewTolerance,
        ),
      );

  DateTime? _transactionAt(PurchaseDetails purchase) {
    final raw = purchase.transactionDate;
    if (raw == null) return null;
    final milliseconds = int.tryParse(raw);
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  bool finish(PurchaseDetails purchase, String attemptId) {
    final transactionId = purchase.purchaseID;
    if (transactionId == null ||
        _attemptByTransaction[transactionId] != attemptId) {
      return false;
    }
    _completedTransactions.add(transactionId);
    _attemptByTransaction.remove(transactionId);
    return removeIfMatches(purchase.productID, attemptId);
  }
}

/// 관측된 취소로 종결됐을 수 있는 시도를, 스토어 큐 실측이 그것을 뒷받침할
/// 때만 정리한다.
///
/// 두 가지 독립된 증거를 **모두** 요구한다.
///
/// 1. [PurchaseCampaignAttemptRegistry.cancellationCandidates] - 시도별
///    양성 증거. 관측된 종결 이벤트가 없으면 후보가 아예 없고, 그 관측보다
///    나중에 시작된 시도·런치가 아직 안 끝난 시도·실결제 트랜잭션이 묶인
///    시도는 후보에서 빠진다.
/// 2. [verifyStoreQueueEmpty] - 스토어 큐에 정산 대상도 **살아 있는 결제도**
///    (iOS purchasing/deferred) 없었다는 실측.
///
/// 왜 둘 다인가. 큐가 비어 보이는 것은 stale 의 증명이 아니다 - iOS 는
/// 사용자가 결제 시트 안에 있는 동안에도 정산 대상을 0건으로 답하고, Android
/// 는 결제 Activity 자체를 못 본다. "큐 empty" 하나만 근거로 등록된 시도
/// 전부를 지우면, 다른 상품 탭이나 지연된 식별자 없는 취소가 스윕을
/// 트리거했을 때 **지금 결제가 진행 중인 정상 시도와 그 이중결제 가드**까지
/// 같이 지워질 수 있다 (Sol 교차 리뷰 MAJOR, 2026-08-07). 반대로 관측
/// 하나만으로 지우는 것은 PR #137 이 막아 둔 귀속 오류다 - 거래ID 없는
/// 이벤트는 어떤 시도의 것인지 증명하지 못한다.
///
/// 두 증거의 역할 분담이 여기서 갈린다. **후보 판정이 "이 시도의 결제 플로가
/// 끝났다"를 증명하고**(뒤이은 런치 성공, 또는 시트 닫힘 + 관측된 종결),
/// **큐 실측은 "그 시도가 돈을 남기지 않았다"를 증명한다.** 큐가 답할 수 있는
/// 것은 후자뿐이며, Android 에서는 전자를 아예 답할 수 없다 - 그래서 전자는
/// 큐가 아니라 런치 순번과 lifecycle 로 판정한다.
///
/// 원래 고치려던 결함은 그대로 고쳐진다. 상품 A 를 취소하면 사용자는 앱으로
/// 돌아오고(=A 의 시트가 닫혔다), 취소 관측이 기록되며, A 의 실패
/// 트랜잭션은 살아 있는 결제로 세지 않으므로(iOS `failed` 는 결제가 아니라
/// **끝난** 결제다) 큐 실측이 empty 로 답해 A 가 정리된다. 취소 이벤트가
/// 아예 오지 않았더라도 사용자가 이어서 상품 B 를 런치하면 증거 (b) 가 A 를
/// 정리한다. 어느 경로든 A 의 버튼 스피너는 90초 안전망을 기다리지 않고
/// 내려간다 (실기기 재현, 2026-08-07).
///
/// [verifyStoreQueueEmpty] 는 "확인했고 비어 있었다"만 true 여야 한다.
/// 스윕이 실결제를 발견해 그 자리에서 정산한 경우(found>0, settled>0)는
/// false 여야 한다 - 그건 "아무 일도 없었다"가 아니라 "방금 돈이 오갔다"라서,
/// 시도를 조용히 지우면 영수증도 안전망도 없이 사라진다.
///
/// 반환값은 실제로 지워진 시도들이다. 호출자가 상품별 후처리(안전망 타이머
/// 해제, 런치 관찰 종료, 리페인트)를 한다.
Future<List<PurchaseCampaignAttempt>> reconcileCancelledAttemptsIfQueueEmpty({
  required PurchaseCampaignAttemptRegistry attempts,
  required bool Function(String productId) isPaymentSheetClosed,
  required Future<bool> Function() verifyStoreQueueEmpty,
  bool Function()? isStillLive,
}) async {
  // 스토어 왕복 **전에** 세대를 읽는다. 왕복 중에 새 취소가 관측되면 세대가
  // 달라져 소진이 거부되고, 그 관측은 다음 스윕의 근거로 살아남는다.
  final generation = attempts.terminationGeneration;
  // 스냅샷인 것이 핵심이다 - 스토어 큐 조회(비동기)를 사이에 두고 이 목록을
  // 지우므로, 조회가 도는 동안 시작된 새 시도는 이 목록에 없어 지워지지 않는다.
  final snapshot = attempts.cancellationCandidates(
    isPaymentSheetClosed: isPaymentSheetClosed,
  );
  if (snapshot.isEmpty) return const [];

  if (!await verifyStoreQueueEmpty()) return const [];
  if (!(isStillLive?.call() ?? true)) return const [];

  // 왕복이 도는 동안 시트 상태가 바뀌었을 수 있다 - 후보 자격을 지금 다시
  // 계산해 스냅샷과 교집합을 취한다. 재계산은 "그 사이 시트가 다시 열린
  // 시도"를 걸러 내고, 스냅샷과의 교집합은 "그 사이 새로 시작된 시도"를
  // 걸러 낸다. 소진보다 **먼저** 해야 한다 - 소진하면 증거 (a) 의 관측이
  // 사라져 재계산이 자기 자신을 무효화한다.
  final stillCandidates = attempts
      .cancellationCandidates(isPaymentSheetClosed: isPaymentSheetClosed)
      .map((a) => a.attemptId)
      .toSet();

  // 큐를 실제로 확인했다 - 확인한 그 세대의 관측만 소진해, 관측 하나가
  // 앞으로의 정리까지 계속 정당화하지 못하게 한다.
  attempts.consumeIdentitylessTermination(generation);

  final cleared = <PurchaseCampaignAttempt>[];
  for (final attempt in snapshot) {
    if (!stillCandidates.contains(attempt.attemptId)) continue;
    // removeIfMatches: 조회가 도는 동안 같은 상품에서 새 시도가 시작됐다면
    // attemptId 가 달라 지워지지 않는다.
    if (attempts.removeIfMatches(attempt.productId, attempt.attemptId)) {
      cleared.add(attempt);
    }
  }
  return cleared;
}

/// The two receipt dialogs a settled purchase can be presented with.
///
/// Implemented in production by `PurchaseDialogHandler`.
///
/// This is deliberately one object rather than two interchangeable
/// `Future<void> Function(result, campaign)` parameters. With two callbacks the
/// caller picks the pairing, and handing the late presenter to the plain slot -
/// the regression `2a0592811` fixed - is a swap no test downstream of the
/// caller can see, because both sides have the same type. Passing the pair as
/// one object leaves nothing to swap: the routing decision lives in
/// [PurchaseSettlementPresentation.present] below, where it is under test.
abstract interface class PurchaseReceiptDialogs {
  /// 🎉 The plain receipt for a purchase that settled inside the safety window.
  Future<void> showSuccessDialog({
    required PurchaseSettlementResultModel result,
    required ActivePromotionCampaignModel? displayedCampaign,
  });

  /// ⏰ The receipt for a purchase the user was already told had timed out.
  Future<void> showLatePurchaseSuccessDialog({
    required PurchaseSettlementResultModel result,
    required ActivePromotionCampaignModel? displayedCampaign,
  });
}

/// Production seam between PurchaseService's verified result callback and the
/// dialog layer. It deliberately forwards the same immutable result and the
/// campaign captured before StoreKit/Play was launched.
class PurchaseSettlementPresentation {
  const PurchaseSettlementPresentation();

  Future<void> present({
    required PurchaseSettlementResultModel result,
    required PurchaseCampaignAttempt attempt,
    required bool isLate,
    required PurchaseReceiptDialogs dialogs,
  }) => isLate
      ? dialogs.showLatePurchaseSuccessDialog(
          result: result,
          displayedCampaign: attempt.displayedCampaign,
        )
      : dialogs.showSuccessDialog(
          result: result,
          displayedCampaign: attempt.displayedCampaign,
        );
}
