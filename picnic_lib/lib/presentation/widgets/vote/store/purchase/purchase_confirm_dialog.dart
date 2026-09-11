import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
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
    this.currentWallet,
  });

  final Map<String, dynamic> serverProduct;
  final List<ProductDetails> storeProducts;
  final WalletSummaryModel? currentWallet;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: EdgeInsets.zero,
      title: _buildHero(
        context,
        l10n,
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
          const SizedBox(height: 12),
          Container(
            key: const Key('purchase-confirm-price'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
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
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
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
    AppLocalizations l10n, {
    required bool hasEventBonus,
    required int? totalMultiplierTenths,
  }) {
    return Container(
      key: const Key('purchase-confirm-hero'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.purchase_confirm_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
          if (hasEventBonus) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.candy_boost_day,
                  style: getTextStyle(AppTypo.caption12B, kCandyBoostPink),
                ),
                if (totalMultiplierTenths != null)
                  CandyBoostBadge(totalMultiplierTenths: totalMultiplierTenths),
              ],
            ),
          ],
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
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatCandyRewardAmount(preview.base, locale),
                            textAlign: TextAlign.end,
                            style: getTextStyle(
                              AppTypo.title18B,
                              kCandyBoostPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (currentWallet != null) ...[
                  const SizedBox(height: 8),
                  _balanceProjection(
                    key: const Key('purchase-confirm-star-balance'),
                    l10n: l10n,
                    locale: locale,
                    current: currentWallet!.star,
                    expected: currentWallet!.star + preview.base,
                  ),
                ],
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
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.grey200)),
              ),
              child: Column(
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
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.wallet_bonus_star_candy,
                                style: getTextStyle(
                                  AppTypo.body14B,
                                  AppColors.grey800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: l10n.purchase_reward_estimate_note,
                              child: Icon(
                                Icons.info_outline_rounded,
                                key: const Key(
                                  'purchase-confirm-estimate-info',
                                ),
                                size: 15,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              preview.hasEventBonus
                                  ? '${l10n.purchase_reward_total_short} ${formatCandyRewardAmount(preview.productBonus + preview.eventBonus, locale)}'
                                  : formatCandyRewardAmount(
                                      preview.productBonus,
                                      locale,
                                    ),
                              key: preview.hasEventBonus
                                  ? const Key('purchase-confirm-bonus-total')
                                  : null,
                              textAlign: TextAlign.end,
                              style: getTextStyle(
                                AppTypo.body16B,
                                kCandyBoostPurple,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (preview.hasEventBonus) ...[
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        children: [
                          if (preview.hasProductBonus)
                            _bonusSourceCapsule(
                              key: const Key('purchase-confirm-product-bonus'),
                              label: l10n.purchase_reward_base_short,
                              amount: formatCandyRewardAmount(
                                preview.productBonus,
                                locale,
                              ),
                              emphasized: false,
                            ),
                          if (preview.hasProductBonus && preview.hasEventBonus)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                '+',
                                style: getTextStyle(
                                  AppTypo.body14B,
                                  AppColors.grey500,
                                ),
                              ),
                            ),
                          if (preview.hasEventBonus)
                            _bonusSourceCapsule(
                              key: const Key('purchase-confirm-event-bonus'),
                              label: l10n.purchase_reward_event_short,
                              amount: formatCandyRewardAmount(
                                preview.eventBonus,
                                locale,
                              ),
                              emphasized: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (currentWallet != null) ...[
                    const SizedBox(height: 8),
                    _balanceProjection(
                      key: const Key('purchase-confirm-bonus-balance'),
                      l10n: l10n,
                      locale: locale,
                      current: currentWallet!.bonus,
                      expected:
                          currentWallet!.bonus +
                          preview.productBonus +
                          preview.eventBonus,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
    ];
  }

  Widget _bonusSourceCapsule({
    required Key key,
    required String label,
    required String amount,
    required bool emphasized,
  }) {
    final color = emphasized ? kCandyBoostPink : AppColors.grey700;
    final backgroundColor = emphasized
        ? kCandyBoostPink.withValues(alpha: .08)
        : AppColors.grey100;
    final borderColor = emphasized
        ? kCandyBoostPink.withValues(alpha: .16)
        : AppColors.grey300;
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$label $amount',
        style: getTextStyle(AppTypo.caption12B, color),
      ),
    );
  }

  Widget _balanceProjection({
    required Key key,
    required AppLocalizations l10n,
    required Locale locale,
    required BigInt current,
    required BigInt expected,
  }) => Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.grey100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Text(
            l10n.purchase_current_balance(
              formatCandyRewardAmount(current, locale),
            ),
            style: getTextStyle(AppTypo.caption12M, AppColors.grey700),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: AppColors.grey500,
            ),
          ),
          Text(
            l10n.purchase_expected_balance(
              formatCandyRewardAmount(expected, locale),
            ),
            style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
          ),
        ],
      ),
    ),
  );

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
