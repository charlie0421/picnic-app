import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart'
    show formatCandyRewardAmount;
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy_helper.dart';
import 'package:picnic_lib/ui/style.dart';

const String kStarCandyAsset = 'assets/icons/store/currency_star_candy.png';
const String kBonusStarCandyAsset =
    'assets/icons/store/currency_bonus_star_candy.png';

/// Loads a SKU-specific star-candy image, falling back to the generic star
/// candy asset when the server publishes a product before its artwork ships.
Image buildStarCandyProductImage({
  required String productId,
  required double width,
  required double height,
}) => Image.asset(
  PurchaseStarCandyHelper.productIconAssetPath(productId),
  package: 'picnic_lib',
  width: width,
  height: height,
  errorBuilder: (_, _, _) => Image.asset(
    kStarCandyAsset,
    key: Key('purchase-product-image-fallback-$productId'),
    package: 'picnic_lib',
    width: width,
    height: height,
  ),
);

/// The reward a product is expected to grant, laid out for a store list row.
///
/// Star candy and bonus star candy are deliberately never added together: they
/// have different value. Every part is a [Wrap] child rather than a fixed [Row] so a
/// 320dp screen at 2x text scale reflows instead of overflowing; the host tile
/// has to grow with it (`StoreListTile.flexibleHeight`).
///
/// Amounts stay [BigInt] end to end - this is the same preview the purchase
/// confirmation quotes, and both must be able to say what a very large catalog
/// row would pay without silently truncating.
class PurchaseRewardPreviewView extends StatelessWidget {
  const PurchaseRewardPreviewView({super.key, required this.preview});

  final PurchaseRewardPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final bonusTotal = preview.productBonus + preview.eventBonus;
    String amount(BigInt value) => formatCandyRewardAmount(value, locale);
    String plus(BigInt value) =>
        l10n.purchase_reward_plus_amount(amount(value));

    return Semantics(
      key: const Key('purchase-reward-extension'),
      container: true,
      label: [
        '${l10n.wallet_star_candy} ${amount(preview.base)}',
        if (bonusTotal > BigInt.zero)
          '${l10n.wallet_bonus_star_candy} ${plus(bonusTotal)}',
        if (preview.hasProductBonus)
          '${l10n.purchase_reward_product_bonus} ${plus(preview.productBonus)}',
        if (preview.hasEventBonus)
          '${l10n.purchase_reward_event_bonus} ${plus(preview.eventBonus)}',
      ].join(', '),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      kStarCandyAsset,
                      package: 'picnic_lib',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      amount(preview.base),
                      key: const Key('purchase-star-candy-panel'),
                      style: getTextStyle(AppTypo.body14B, AppColors.point900),
                    ),
                  ],
                ),
                if (bonusTotal > BigInt.zero) ...[
                  const SizedBox(width: 8),
                  KeyedSubtree(
                    key: const Key('purchase-bonus-components'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (preview.hasProductBonus) ...[
                          Image.asset(
                            kBonusStarCandyAsset,
                            package: 'picnic_lib',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            amount(preview.productBonus),
                            key: const Key('purchase-provenance-chip-product'),
                            style: getTextStyle(
                              AppTypo.body14B,
                              AppColors.point900,
                            ),
                          ),
                        ],
                        if (preview.hasProductBonus && preview.hasEventBonus)
                          Text(
                            ' + ',
                            style: getTextStyle(
                              AppTypo.body14B,
                              AppColors.grey500,
                            ),
                          ),
                        if (preview.hasEventBonus) ...[
                          Image.asset(
                            kBonusStarCandyAsset,
                            package: 'picnic_lib',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 2),
                          KeyedSubtree(
                            key: const Key('purchase-event-bonus'),
                            child: Text(
                              '${l10n.purchase_reward_event_short} ${amount(preview.eventBonus)}',
                              key: const Key('purchase-provenance-chip-event'),
                              style: getTextStyle(
                                AppTypo.body14B,
                                AppColors.point900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
