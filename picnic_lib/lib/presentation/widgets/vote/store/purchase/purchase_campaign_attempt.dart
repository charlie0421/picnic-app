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
  bool launched = false;
  String? transactionId;
}

class PurchaseCampaignAttemptRegistry {
  PurchaseCampaignAttemptRegistry({DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final Map<String, PurchaseExecutionContext> _byProduct = {};
  final Map<String, String> _attemptByTransaction = {};
  final Set<String> _completedTransactions = {};

  /// Supabase 카탈로그 ID는 대문자(STAR100), Google Play 이벤트의 productID는
  /// 소문자(star100)다. Casing만 다른 같은 상품이 같은 컨텍스트로 모이지 않으면
  /// 정상 결제 이벤트가 orphan으로 폐기된다.
  static String canonicalProductKey(String productId) =>
      productId.trim().toUpperCase();

  PurchaseCampaignAttempt? operator [](String productId) =>
      _byProduct[canonicalProductKey(productId)]?.attempt;
  bool contains(String productId) =>
      _byProduct.containsKey(canonicalProductKey(productId));

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
    if (context?.attempt.attemptId == attemptId) context!.launched = true;
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
