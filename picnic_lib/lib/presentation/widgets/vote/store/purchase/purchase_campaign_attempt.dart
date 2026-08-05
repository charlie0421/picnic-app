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
    var attempt = bind(purchase) ?? currentTerminalWithoutId(purchase);
    while (attempt == null && retries-- > 0 && _hasPendingLaunchRace(purchase)) {
      await Future.delayed(delay);
      attempt = bind(purchase) ?? currentTerminalWithoutId(purchase);
    }
    return attempt;
  }

  /// 이 이벤트가 아직 [launched] 세팅 전인 활성 시도를 만날 수 있는 상태인지.
  ///
  /// `purchased` 뿐 아니라 `error`/`canceled` 도 같은 레이스를 겪는다 -
  /// 스토어 스트림이 initiatePurchase()의 launched=true 세팅보다 먼저
  /// 도착할 수 있다. productID가 없는 이벤트는 활성 시도가 남아 있는 한
  /// (어느 상품인지는 [currentTerminalWithoutId] 가 재시도 시점에 다시
  /// 판별한다) 계속 재시도할 후보가 있다고 본다.
  bool _hasPendingLaunchRace(PurchaseDetails purchase) {
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.error &&
        purchase.status != PurchaseStatus.canceled) {
      return false;
    }
    return purchase.productID.trim().isEmpty
        ? _byProduct.isNotEmpty
        : contains(purchase.productID);
  }

  PurchaseCampaignAttempt? currentTerminalWithoutId(PurchaseDetails purchase) {
    // Android Play Billing 은 식별자 없는 에러/취소에서 purchaseID 를 null이
    // 아니라 빈 문자열로 채워 보낸다 (실기기 재현: responseCode 3). null과
    // 동일하게 "식별자 없음"으로 다뤄야 한다.
    final hasTransactionId =
        purchase.purchaseID != null && purchase.purchaseID!.isNotEmpty;
    if (hasTransactionId ||
        (purchase.status != PurchaseStatus.error &&
            purchase.status != PurchaseStatus.canceled)) {
      return null;
    }
    var context = _byProduct[canonicalProductKey(purchase.productID)];
    // Android Play Billing 에러/취소는 productID까지 빈 채로 도착할 수 있다
    // (실기기 재현: responseCode 3, 결제창을 뒤로가기로 닫음). 상품ID로 못
    // 붙이면 orphan으로 폐기되고, 그 경로는 로딩 오버레이를 내리지 않아
    // 스피너가 무한정 남는다. 활성 시도가 정확히 하나뿐이면 판별 불가능한
    // 상태가 아니므로 그 시도로 본다 - 둘 이상이면 여전히 폐기한다.
    if (context == null && purchase.productID.trim().isEmpty) {
      context = _byProduct.length == 1 ? _byProduct.values.single : null;
    }
    final transactionAt = _transactionAt(purchase);
    return context != null &&
            context.launched &&
            !_staleBeforeLaunch(context, transactionAt)
        ? context.attempt
        : null;
  }

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
