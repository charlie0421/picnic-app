import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart'
    show formatCandyRewardAmount;
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_palette.dart';
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
  const PurchaseRewardPreviewView({
    super.key,
    required this.preview,
    this.iconSize = 18,
  });

  final PurchaseRewardPreview preview;
  final double iconSize;

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
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InlineCurrency(
                key: const Key('purchase-star-candy-panel'),
                label: l10n.wallet_star_candy,
                amount: amount(preview.base),
                assetPath: kStarCandyAsset,
                iconSize: iconSize,
              ),
              if (bonusTotal > BigInt.zero)
                _InlineCurrency(
                  key: const Key('purchase-bonus-total'),
                  label: l10n.wallet_bonus_star_candy,
                  amount: plus(bonusTotal),
                  assetPath: kBonusStarCandyAsset,
                  iconSize: iconSize,
                  emphasized: preview.hasEventBonus,
                ),
            ],
          ),
          if (preview.hasProductBonus || preview.hasEventBonus) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              runSpacing: 3,
              children: [
                if (preview.hasProductBonus)
                  Text(
                    '${l10n.purchase_reward_product_bonus} ${plus(preview.productBonus)}',
                    key: const Key('purchase-provenance-chip-product'),
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                if (preview.hasEventBonus)
                  KeyedSubtree(
                    key: const Key('purchase-event-bonus'),
                    child: Text(
                      '${l10n.purchase_reward_event_bonus} ${plus(preview.eventBonus)}',
                      key: const Key('purchase-provenance-chip-event'),
                      style: getTextStyle(AppTypo.caption10SB, kCandyBoostPink),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineCurrency extends StatelessWidget {
  const _InlineCurrency({
    super.key,
    required this.label,
    required this.amount,
    required this.assetPath,
    required this.iconSize,
    this.emphasized = false,
  });

  final String label;
  final String amount;
  final String assetPath;
  final double iconSize;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            package: 'picnic_lib',
            width: iconSize,
            height: iconSize,
          ),
          const SizedBox(width: 3),
          Text(
            '$label $amount',
            style: getTextStyle(
              AppTypo.caption12B,
              emphasized ? kCandyBoostPink : AppColors.point900,
            ),
          ),
        ],
      ),
    );
  }
}
