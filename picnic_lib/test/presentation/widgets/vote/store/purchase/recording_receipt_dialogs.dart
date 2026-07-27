import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

/// Records which of the two receipts a settlement was presented with.
///
/// Production's implementation is `PurchaseDialogHandler`, which needs a
/// `BuildContext` and a live `PurchaseService` (StoreKit/Play init plus the
/// receipt queue) to construct. What the settlement tests need from it is only
/// which receipt a settlement routes to and what it was handed;
/// `handlers/purchase_dialog_handler_test.dart` covers that the two receipts
/// really do differ - the plain one carries no supporting message, the late one
/// carries the delay explanation.
class RecordingReceiptDialogs implements PurchaseReceiptDialogs {
  RecordingReceiptDialogs({Future<void> Function()? whilePresenting})
    : _whilePresenting = whilePresenting;

  /// Runs for the duration of either receipt, so a test can observe the state
  /// the user's second tap would see while the dialog is on screen.
  final Future<void> Function()? _whilePresenting;

  int plainReceipts = 0;
  int lateReceipts = 0;
  final List<PurchaseSettlementResultModel> results = [];
  final List<ActivePromotionCampaignModel?> campaigns = [];

  @override
  Future<void> showSuccessDialog({
    required PurchaseSettlementResultModel result,
    required ActivePromotionCampaignModel? displayedCampaign,
  }) {
    plainReceipts++;
    results.add(result);
    campaigns.add(displayedCampaign);
    return _whilePresenting?.call() ?? Future<void>.value();
  }

  @override
  Future<void> showLatePurchaseSuccessDialog({
    required PurchaseSettlementResultModel result,
    required ActivePromotionCampaignModel? displayedCampaign,
  }) {
    lateReceipts++;
    results.add(result);
    campaigns.add(displayedCampaign);
    return _whilePresenting?.call() ?? Future<void>.value();
  }
}
