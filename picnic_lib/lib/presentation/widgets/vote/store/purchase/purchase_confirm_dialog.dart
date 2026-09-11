import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart'
    show formatCandyRewardAmount;
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_palette.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview_view.dart'
    show buildStarCandyProductImage, kBonusStarCandyAsset, kStarCandyAsset;
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy_helper.dart';
import 'package:picnic_lib/ui/style.dart';

/// 🔒 The purchase confirmation - the last screen before real money moves.
///
/// It uses the **same** [PurchaseRewardPreview] calculation as the product card,
/// with the latest settled promotion captured just before confirmation opens,
/// after pending-attempt reconciliation. Amounts remain estimates: the server
/// decides the promotion at settlement time, not this widget.
class PurchaseConfirmDialog extends StatelessWidget {
  const PurchaseConfirmDialog({
    super.key,
    required this.serverProduct,
    required this.storeProducts,
    required this.displayedPromotion,
  });

  final Map<String, dynamic> serverProduct;
  final List<ProductDetails> storeProducts;

  /// Captured immediately before this dialog opens. Never re-read here: a
  /// refresh mid-dialog must not change what the user is agreeing to.
  final ResolvedPaymentBadgePromotion? displayedPromotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productId = serverProduct['id'] as String;
    final preview = purchaseRewardPreviewForProduct(
      serverProduct,
      multiplierTenths: displayedPromotion?.multiplierTenths,
      extraBonusBps: displayedPromotion?.extraBonusBps,
    );
    final totalMultiplierTenths = preview.totalMultiplierTenths;

    return AlertDialog(
      scrollable: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: EdgeInsets.zero,
      title: _buildHero(
        context,
        l10n,
        productId,
        hasEventBonus: preview.hasEventBonus,
        totalMultiplierTenths: totalMultiplierTenths,
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.purchase_confirm_message,
            style: getTextStyle(AppTypo.body14R, AppColors.grey700),
          ),
          const SizedBox(height: 12),
          _productHeader(context, productId),
          const SizedBox(height: 12),
          ..._breakdownRows(context, l10n, preview),
          const SizedBox(height: 10),
          Text(
            key: const Key('purchase-confirm-estimate-note'),
            l10n.purchase_reward_estimate_note,
            style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('purchase-confirm-price'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: kCandyBoostPurple.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: kCandyBoostPurple.withValues(alpha: .18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.purchase_payment_amount,
                    style: getTextStyle(AppTypo.body14B, AppColors.grey700),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _priceLabel(),
                    textAlign: TextAlign.end,
                    style: getTextStyle(AppTypo.title18B, kCandyBoostPurple),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.cancel,
            style: getTextStyle(AppTypo.body14R, AppColors.grey500),
          ),
        ),
        ElevatedButton(
          key: const Key('purchase-confirm-cta'),
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(132, 50),
            backgroundColor: kCandyBoostPurple,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: kCandyBoostPurple.withValues(alpha: .35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.purchase_confirm_button,
              maxLines: 1,
              style: getTextStyle(AppTypo.body16B, Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(
    BuildContext context,
    AppLocalizations l10n,
    String productId, {
    required bool hasEventBonus,
    required int? totalMultiplierTenths,
  }) {
    return Container(
      key: const Key('purchase-confirm-hero'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCandyBoostPurple, kCandyBoostPink],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -8,
            top: -12,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 58,
              color: Colors.white.withValues(alpha: .16),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _productImage(productId, size: 40.w),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.purchase_confirm_title,
                      style: getTextStyle(AppTypo.title18B, Colors.white),
                    ),
                    if (hasEventBonus) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.candy_boost_day,
                            style: getTextStyle(
                              AppTypo.caption12B,
                              Colors.white,
                            ),
                          ),
                          if (totalMultiplierTenths != null)
                            CandyBoostBadge(
                              totalMultiplierTenths: totalMultiplierTenths,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productHeader(BuildContext context, String productId) {
    final fullDescription = getLocaleTextFromJson(serverProduct['description']);
    final parsed = parseProductDescription(fullDescription);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _productImage(productId, size: 42),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productId,
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
                const SizedBox(height: 4),
                Text(
                  parsed.mainDescription,
                  style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Star candy and bonus star candy stay in independent visual and semantic
  /// groups. Only the two bonus-star-candy sources are added together.
  List<Widget> _breakdownRows(
    BuildContext context,
    AppLocalizations l10n,
    PurchaseRewardPreview preview,
  ) {
    final locale = Localizations.localeOf(context);
    String plus(BigInt amount) => l10n.purchase_reward_plus_amount(
      formatCandyRewardAmount(amount, locale),
    );
    return [
      if (preview.base > BigInt.zero)
        Semantics(
          container: true,
          label:
              '${l10n.wallet_star_candy} ${formatCandyRewardAmount(preview.base, locale)}',
          excludeSemantics: true,
          child: Container(
            key: const Key('purchase-confirm-star-candy-panel'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kCandyBoostPurple.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kCandyBoostPurple.withValues(alpha: .2),
              ),
            ),
            child: Row(
              key: const Key('purchase-confirm-base'),
              children: [
                Image.asset(
                  kStarCandyAsset,
                  package: 'picnic_lib',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.wallet_star_candy,
                    style: getTextStyle(AppTypo.body14B, AppColors.grey800),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    formatCandyRewardAmount(preview.base, locale),
                    textAlign: TextAlign.end,
                    style: getTextStyle(AppTypo.title18B, kCandyBoostPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (preview.productBonus + preview.eventBonus > BigInt.zero)
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Semantics(
            container: true,
            label: [
              '${l10n.wallet_bonus_star_candy} ${plus(preview.productBonus + preview.eventBonus)}',
              if (preview.hasProductBonus)
                '${l10n.purchase_reward_product_bonus} ${plus(preview.productBonus)}',
              if (preview.hasEventBonus)
                '${l10n.purchase_reward_event_bonus} ${plus(preview.eventBonus)}',
            ].join(', '),
            excludeSemantics: true,
            child: Container(
              key: const Key('purchase-confirm-bonus-benefit-panel'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kCandyBoostPurple.withValues(alpha: .12),
                    kCandyBoostPink.withValues(alpha: .14),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: kCandyBoostPink.withValues(alpha: .36),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    key: const Key('purchase-confirm-bonus-total'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            kBonusStarCandyAsset,
                            package: 'picnic_lib',
                            width: 34,
                            height: 34,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.wallet_bonus_star_candy,
                              style: getTextStyle(
                                AppTypo.body14B,
                                AppColors.grey800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          plus(preview.productBonus + preview.eventBonus),
                          textAlign: TextAlign.end,
                          style: getTextStyle(
                            AppTypo.title18B,
                            kCandyBoostPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (preview.hasProductBonus || preview.hasEventBonus) ...[
                    const SizedBox(height: 10),
                    if (preview.hasProductBonus)
                      _provenanceChip(
                        rowKey: const Key('purchase-confirm-product-bonus'),
                        label: l10n.purchase_reward_product_bonus,
                        amount: plus(preview.productBonus),
                        emphasized: false,
                      ),
                    if (preview.hasProductBonus && preview.hasEventBonus)
                      const SizedBox(height: 6),
                    if (preview.hasEventBonus)
                      _provenanceChip(
                        rowKey: const Key('purchase-confirm-event-bonus'),
                        label: l10n.purchase_reward_event_bonus,
                        amount: plus(preview.eventBonus),
                        emphasized: true,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
    ];
  }

  Widget _provenanceChip({
    required Key rowKey,
    required String label,
    required String amount,
    required bool emphasized,
  }) {
    final color = emphasized ? kCandyBoostPink : kCandyBoostPurple;
    return Container(
      key: rowKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? kCandyBoostPink.withValues(alpha: .11)
            : Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: getTextStyle(AppTypo.caption12B, color)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: getTextStyle(AppTypo.body14B, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(String productId, {required double size}) =>
      buildStarCandyProductImage(
        productId: productId,
        width: size,
        height: size,
      );

  /// The store's own localized price when this product is in the catalogue we
  /// already fetched, otherwise the server's plain USD figure.
  ///
  /// Read-only: matching stays exactly the policy the purchase path uses, and
  /// nothing here changes what is bought.
  String _priceLabel() => PurchaseStarCandyHelper.productPriceLabel(
    serverProduct: serverProduct,
    storeProducts: storeProducts,
    isAndroid: Platform.isAndroid,
    inappAppNamePrefix: Environment.inappAppNamePrefix,
    environment: Environment.currentEnvironment,
    paymentProductNamespace: Environment.storeQueryNamespace,
  );
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
String extractStarSuffix(String productId) {
  return productId.replaceAll('STAR', '');
}
