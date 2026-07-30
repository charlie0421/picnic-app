import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

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

/// Pure logic: parse a product description into main and bonus parts.
/// Returns a record with mainDescription and optional bonusDescription.
@visibleForTesting
({String mainDescription, String? bonusDescription}) parseProductDescription(
  String fullDescription,
) {
  if (fullDescription.contains('+')) {
    final parts = fullDescription.split('+');
    final mainDescription = parts[0].trim();
    final bonusDescription = '+${parts.sublist(1).join('+').trim()}';
    return (
      mainDescription: mainDescription,
      bonusDescription: bonusDescription,
    );
  }
  return (mainDescription: fullDescription, bonusDescription: null);
}

/// Pure logic: extract the star image suffix from a product ID.
/// e.g., 'STAR100' -> '100', 'STAR50' -> '50'
@visibleForTesting
String extractStarSuffix(String productId) {
  return productId.replaceAll('STAR', '');
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
    required ActivePromotionCampaignModel? displayedCampaign,
  }) async {
    return await showDialog<bool>(
      context: _context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                package: 'picnic_lib',
                'assets/icons/store/star_${serverProduct['id'].replaceAll('STAR', '')}.png',
                width: 50.w,
                height: 50.w,
              ),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).purchase_confirm_title,
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).purchase_confirm_message,
                style: getTextStyle(AppTypo.body14R, AppColors.grey700),
              ),
              if (displayedCampaign != null) ...[
                SizedBox(height: 8),
                Text(
                  displayedCampaign.localizedDisplayName(
                    Localizations.localeOf(context).languageCode,
                  ),
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500),
                ),
              ],
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary500.withValues(alpha: 0.08),
                      AppColors.primary500.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 스타캔디 아이콘 - 더 크고 매력적으로
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary500.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            package: 'picnic_lib',
                            'assets/icons/store/star_${serverProduct['id'].replaceAll('STAR', '')}.png',
                            width: 48,
                            height: 48,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serverProduct['id'],
                                style: getTextStyle(
                                  AppTypo.body16B,
                                  AppColors.grey900,
                                ),
                              ),
                              SizedBox(height: 6),
                              // 상품 설명을 파싱해서 메인 설명과 보너스 분리
                              ...(() {
                                final fullDescription = getLocaleTextFromJson(
                                  serverProduct['description'],
                                );

                                // '+' 기호를 기준으로 분리
                                if (fullDescription.contains('+')) {
                                  final parts = fullDescription.split('+');
                                  final mainDescription = parts[0].trim();
                                  final bonusDescription =
                                      '+${parts.sublist(1).join('+').trim()}';

                                  return [
                                    Text(
                                      mainDescription,
                                      style: getTextStyle(
                                        AppTypo.caption12R,
                                        AppColors.grey600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      bonusDescription,
                                      style: getTextStyle(
                                        AppTypo.caption12B,
                                        AppColors.point900,
                                      ),
                                    ),
                                  ];
                                } else {
                                  // '+' 기호가 없는 경우 전체를 메인 설명으로 표시
                                  return [
                                    Text(
                                      fullDescription,
                                      style: getTextStyle(
                                        AppTypo.caption12R,
                                        AppColors.grey600,
                                      ),
                                    ),
                                  ];
                                }
                              })(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // 구분선
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary500.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // 가격 정보 - 더 강조해서 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).purchase_payment_amount,
                          style: getTextStyle(
                            AppTypo.body14M,
                            AppColors.grey600,
                          ),
                        ),
                        Text(
                          '${serverProduct['price']} \$',
                          style: getTextStyle(
                            AppTypo.body16B,
                            AppColors.primary500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: getTextStyle(AppTypo.body14R, AppColors.grey500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
              child: Text(
                AppLocalizations.of(context).purchase_confirm_button,
                style: getTextStyle(AppTypo.body14B, Colors.white),
              ),
            ),
          ],
        );
      },
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
    required ActivePromotionCampaignModel? displayedCampaign,
  }) async {
    logger.i('[PurchaseDialogHandler] Showing success dialog');
    final context = _receiptContext();
    if (context == null) {
      logger.e('Navigator context is null in showSuccessDialog');
      return;
    }
    final checking =
        result.promotion?.state == PurchasePromotionState.pendingTime ||
        result.promotion?.state == PurchasePromotionState.eligible;
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
    required ActivePromotionCampaignModel? displayedCampaign,
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
