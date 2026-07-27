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

  PurchaseCampaignAttempt? operator [](String productId) =>
      _byProduct[productId]?.attempt;
  bool contains(String productId) => _byProduct.containsKey(productId);

  bool begin(PurchaseCampaignAttempt attempt) =>
      _byProduct
          .putIfAbsent(
            attempt.productId,
            () => PurchaseExecutionContext(
              attempt: attempt,
              launchedAt: _now().toUtc(),
            ),
          )
          .attempt ==
      attempt;

  bool removeIfMatches(String productId, String attemptId) {
    if (_byProduct[productId]?.attempt.attemptId != attemptId) return false;
    _byProduct.remove(productId);
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
    final context = _byProduct[productId];
    if (context?.attempt.attemptId == attemptId) context!.launched = true;
    return false;
  }

  /// Binds a StoreKit/Play event to the attempt that was locked at launch.
  ///
  /// A transaction id is mandatory: product id alone is not transaction
  /// identity. Restores are recovery traffic and never consume a live launch.
  PurchaseCampaignAttempt? bind(PurchaseDetails purchase) {
    final transactionId = purchase.purchaseID;
    final context = _byProduct[purchase.productID];
    final transactionAt = _transactionAt(purchase);
    if (transactionId == null ||
        transactionId.isEmpty ||
        purchase.status == PurchaseStatus.restored ||
        _completedTransactions.contains(transactionId) ||
        context == null ||
        transactionAt == null ||
        transactionAt.isBefore(context.launchedAt)) {
      return null;
    }
    final existingAttemptId = _attemptByTransaction[transactionId];
    if (existingAttemptId != null) {
      final context = _byProduct[purchase.productID];
      return context?.attempt.attemptId == existingAttemptId
          ? context!.attempt
          : null;
    }
    if (!context.launched || context.transactionId != null) {
      return null;
    }
    context.transactionId = transactionId;
    _attemptByTransaction[transactionId] = context.attempt.attemptId;
    return context.attempt;
  }

  PurchaseCampaignAttempt? currentTerminalWithoutId(PurchaseDetails purchase) {
    if (purchase.purchaseID != null ||
        (purchase.status != PurchaseStatus.error &&
            purchase.status != PurchaseStatus.canceled)) {
      return null;
    }
    final context = _byProduct[purchase.productID];
    final transactionAt = _transactionAt(purchase);
    return context != null &&
            context.launched &&
            transactionAt != null &&
            !transactionAt.isBefore(context.launchedAt)
        ? context.attempt
        : null;
  }

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
