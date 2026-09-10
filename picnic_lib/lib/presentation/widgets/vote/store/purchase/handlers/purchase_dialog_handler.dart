import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_confirm_dialog.dart';

// The confirmation moved to its own widget so it can be pumped - and its
// numbers asserted - without constructing a PurchaseService. These pure
// helpers moved with it; re-exported so existing importers keep resolving.
export 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_confirm_dialog.dart'
    show extractStarSuffix, parseProductDescription;

enum PurchaseSuccessKind { generic, checking, granted }

typedef PurchaseSuccessDecision = ({
  PurchaseSuccessKind kind,
  BigInt? promoBonusAmount,
});

typedef PurchaseReceiptPresenter =
    Future<void> Function(
      BuildContext context,
      CandyRewardReceipt receipt, {
      String? supportingMessage,
    });

Future<void> _showPurchaseReceipt(
  BuildContext context,
  CandyRewardReceipt receipt, {
  String? supportingMessage,
}) => showCandyRewardReceiptDialog(
  context,
  receipt,
  supportingMessage: supportingMessage,
);

/// Presents a verified settlement to the user - the **single** routing rule for
/// "the server settled this, tell the user".
///
/// Two callers share it and must not drift apart: the store's
/// [PurchaseDialogHandler] (a purchase the user is watching) and
/// [GlobalPurchaseListener]'s headless settlement (a purchase that arrived with
/// no store on screen - an Ask to Buy approval, a recovered transaction, a
/// settlement that landed after the user walked away). Both have to make the
/// same call about *what* to show, because the difference is only whether a
/// route was mounted.
///
/// The rule: a redelivered settlement is acknowledged, never re-presented as a
/// fresh grant. It re-reports an operation an earlier delivery already settled
/// and already showed, so the receipt would tell the user they just received
/// candy they already had. The balance stays correct either way - the caller
/// applies `result.wallet` regardless.
Future<void> presentPurchaseSettlement(
  BuildContext context,
  PurchaseSettlementResultModel result, {
  String? supportingMessage,
  PurchaseReceiptPresenter presenter = _showPurchaseReceipt,
}) async {
  if (isSettlementRedelivery(result)) {
    acknowledgePurchaseSettlement(context);
    return;
  }
  final receipt = receiptFromPurchase(result);
  if (receipt == null) return;
  await presenter(context, receipt, supportingMessage: supportingMessage);
}

/// ♻️ 재전달(redelivery)·기지급 중복 정산의 안내.
///
/// A settlement with no amounts to show - either a redelivery of an operation
/// already presented, or a duplicate the server reports as grant-confirmed
/// (whose response carries the verdict but no amounts). The purchase did
/// succeed, and until 1.3.0 the second case was shown an *error* ("이전 거래
/// 처리 중") for candy the user already owned.
void acknowledgePurchaseSettlement(BuildContext context) {
  showSimpleDialog(
    content: AppLocalizations.of(context).dialog_message_purchase_success,
  );
}

PurchaseSuccessDecision decidePurchaseSuccess(
  PurchaseSettlementResultModel result,
  ActivePromotionCampaignModel? displayedCampaign,
) {
  final promotion = result.promotion;
  if (promotion == null || displayedCampaign == null) {
    return (kind: PurchaseSuccessKind.generic, promoBonusAmount: null);
  }
  if (promotion.state == PurchasePromotionState.pendingTime ||
      promotion.state == PurchasePromotionState.eligible) {
    return (kind: PurchaseSuccessKind.checking, promoBonusAmount: null);
  }
  if (promotion.state == PurchasePromotionState.granted &&
      promotion.campaignVersionId == displayedCampaign.campaignVersionId) {
    return (
      kind: PurchaseSuccessKind.granted,
      promoBonusAmount: promotion.promoBonusAmount,
    );
  }
  return (kind: PurchaseSuccessKind.generic, promoBonusAmount: null);
}

/// Pure logic: determine if debug info should be shown based on environment info.
@visibleForTesting
bool shouldShowDebugInfo(Map<String, dynamic> envInfo) {
  final isTestFlight =
      envInfo['environment'] == 'sandbox' &&
      !envInfo['isDebugMode'] &&
      (envInfo['installerStore'] == 'com.apple.testflight' ||
          envInfo['installerStore'] == null);
  return kDebugMode || isTestFlight;
}

/// 🎭 구매 관련 다이얼로그 관리자
class PurchaseDialogHandler implements PurchaseReceiptDialogs {
  final BuildContext _context;
  final PurchaseService _purchaseService;
  final BuildContext? Function() _receiptContext;
  final PurchaseReceiptPresenter _receiptPresenter;

  PurchaseDialogHandler({
    required BuildContext context,
    required PurchaseService purchaseService,
    BuildContext? Function()? receiptContext,
    PurchaseReceiptPresenter receiptPresenter = _showPurchaseReceipt,
  }) : _context = context,
       _purchaseService = purchaseService,
       _receiptContext = receiptContext ?? (() => navigatorKey.currentContext),
       _receiptPresenter = receiptPresenter;

  /// 🔒 구매 확인 다이얼로그 - 우발적 구매 방지
  Future<bool?> showPurchaseConfirmDialog({
    required Map<String, dynamic> serverProduct,
    required List<ProductDetails> storeProducts,
    required ResolvedPaymentBadgePromotion? displayedPromotion,
  }) async {
    return await showDialog<bool>(
      context: _context,
      barrierDismissible: true,
      builder: (BuildContext context) => PurchaseConfirmDialog(
        serverProduct: serverProduct,
        storeProducts: storeProducts,
        displayedPromotion: displayedPromotion,
      ),
    );
  }

  /// 🔴 에러 다이얼로그
  Future<void> showErrorDialog(String message) async {
    try {
      final envInfo = await _purchaseService.receiptVerificationService
          .getEnvironmentInfo();
      final isTestFlight =
          envInfo['environment'] == 'sandbox' &&
          !envInfo['isDebugMode'] &&
          (envInfo['installerStore'] == 'com.apple.testflight' ||
              envInfo['installerStore'] == null);
      final shouldShowDebugInfo = kDebugMode || isTestFlight;

      if (shouldShowDebugInfo) {
        final debugInfo =
            '''
환경: ${envInfo['environment']}
플랫폼: ${envInfo['platform']}
설치 스토어: ${envInfo['installerStore'] ?? 'null'}
앱 이름: ${envInfo['appName']}
버전: ${envInfo['version']} (${envInfo['buildNumber']})
디버그 모드: ${envInfo['isDebugMode']}

오류: $message
''';
        showSimpleDialog(content: debugInfo, type: DialogType.error);
      } else {
        showSimpleDialog(content: message, type: DialogType.error);
      }
    } catch (e) {
      showSimpleDialog(content: message, type: DialogType.error);
    }
  }

  /// 🎉 구매 성공 다이얼로그
  @override
  Future<void> showSuccessDialog({
    required PurchaseSettlementResultModel result,
    required ResolvedPaymentBadgePromotion? displayedPromotion,
  }) async {
    logger.i('[PurchaseDialogHandler] Showing success dialog');
    final context = _receiptContext();
    if (context == null) {
      logger.e('Navigator context is null in showSuccessDialog');
      return;
    }
    final checking =
        displayedPromotion != null &&
        (result.promotion?.state == PurchasePromotionState.pendingTime ||
            result.promotion?.state == PurchasePromotionState.eligible);
    await presentPurchaseSettlement(
      context,
      result,
      supportingMessage: checking
          ? AppLocalizations.of(context).candy_boost_promotion_checking
          : null,
      presenter: _receiptPresenter,
    );
  }

  /// ⏰ 늦은 구매 성공 다이얼로그
  @override
  Future<void> showLatePurchaseSuccessDialog({
    required PurchaseSettlementResultModel result,
    required ResolvedPaymentBadgePromotion? displayedPromotion,
  }) async {
    logger.i('[PurchaseDialogHandler] Showing late purchase success dialog');

    final context = _receiptContext();
    if (context == null) {
      logger.e('Navigator context is null in showLatePurchaseSuccessDialog');
      return;
    }
    await presentPurchaseSettlement(
      context,
      result,
      supportingMessage: AppLocalizations.of(
        context,
      ).candy_boost_late_purchase_explanation,
      presenter: _receiptPresenter,
    );
  }

  /// ♻️ 서버가 이미 정산을 확정한 구매(지급 확정 중복)의 안내.
  ///
  /// The duplicate verdict carries no amounts, so there is no receipt to build.
  /// Same acknowledgement a redelivered settlement gets - see
  /// [acknowledgePurchaseSettlement].
  Future<void> showAlreadySettledDialog() async {
    final context = _receiptContext();
    if (context == null) {
      logger.e('Navigator context is null in showAlreadySettledDialog');
      return;
    }
    acknowledgePurchaseSettlement(context);
  }

  Future<void> showPurchaseAlreadyPendingDialog() async {
    showSimpleDialog(
      content: AppLocalizations.of(_context).candy_boost_purchase_pending,
    );
  }

  /// ⚠️ 예상치 못한 중복 에러 다이얼로그
  Future<void> showUnexpectedDuplicateDialog() async {
    showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Server Processing Issue'),
        content: Text(
          '''An error occurred even though the server has relaxed duplicate checks for consumable products.

Possible causes:
1. Server deployment not fully applied yet
2. Other types of network errors
3. May be resolved by trying again later

Solutions:
1. Try again in 1-2 minutes (wait for server deployment completion)
2. If it still doesn't work, restart the app
3. Contact customer support if the problem persists

Duplicate purchases should be normally allowed for consumable products.''',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
