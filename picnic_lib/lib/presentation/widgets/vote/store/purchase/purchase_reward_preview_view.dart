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
    final starCandyPanel = _CurrencyAmountPanel(
      key: const Key('purchase-star-candy-panel'),
      label: l10n.wallet_star_candy,
      amount: formatCandyRewardAmount(preview.base, locale),
      assetPath: kStarCandyAsset,
      iconSize: iconSize,
    );
    if (!preview.hasProductBonus && !preview.hasEventBonus) {
      return starCandyPanel;
    }

    final bonusPanel = _BonusBenefitPanel(preview: preview, iconSize: iconSize);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackPanels = constraints.maxWidth < 270 || textScale > 1.35;
        if (stackPanels) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: double.infinity, child: starCandyPanel),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: bonusPanel),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: starCandyPanel),
            const SizedBox(width: 8),
            Expanded(flex: 7, child: bonusPanel),
          ],
        );
      },
    );
  }
}

class _CurrencyAmountPanel extends StatelessWidget {
  const _CurrencyAmountPanel({
    super.key,
    required this.label,
    required this.amount,
    required this.assetPath,
    required this.iconSize,
  });

  final String label;
  final String amount;
  final String assetPath;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $amount',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: kCandyBoostPurple.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCandyBoostPurple.withValues(alpha: .2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kCandyBoostPurple.withValues(alpha: .14),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Image.asset(
                assetPath,
                package: 'picnic_lib',
                width: iconSize,
                height: iconSize,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: getTextStyle(AppTypo.body16B, kCandyBoostPurple),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusBenefitPanel extends StatelessWidget {
  const _BonusBenefitPanel({required this.preview, required this.iconSize});

  final PurchaseRewardPreview preview;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final total = l10n.purchase_reward_plus_amount(
      formatCandyRewardAmount(
        preview.productBonus + preview.eventBonus,
        locale,
      ),
    );
    final semanticsParts = [
      '${l10n.wallet_bonus_star_candy} $total',
      if (preview.hasProductBonus)
        '${l10n.purchase_reward_product_bonus} ${_plus(context, preview.productBonus)}',
      if (preview.hasEventBonus)
        '${l10n.purchase_reward_event_bonus} ${_plus(context, preview.eventBonus)}',
    ];

    return Semantics(
      container: true,
      label: semanticsParts.join(', '),
      excludeSemantics: true,
      child: Container(
        key: const Key('purchase-bonus-benefit-panel'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kCandyBoostPurple.withValues(alpha: .11),
              kCandyBoostPink.withValues(alpha: .13),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCandyBoostPink.withValues(alpha: .38)),
          boxShadow: [
            BoxShadow(
              color: kCandyBoostPink.withValues(alpha: .09),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  kBonusStarCandyAsset,
                  package: 'picnic_lib',
                  width: iconSize + 5,
                  height: iconSize + 5,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.wallet_bonus_star_candy,
                    maxLines: 2,
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                total,
                key: const Key('purchase-bonus-total'),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textAlign: TextAlign.end,
                style: getTextStyle(AppTypo.title18B, kCandyBoostPurple),
              ),
            ),
            if (preview.hasProductBonus || preview.hasEventBonus) ...[
              const SizedBox(height: 7),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  if (preview.hasProductBonus)
                    _ProvenanceChip(
                      key: const Key('purchase-provenance-chip-product'),
                      label: l10n.purchase_reward_product_bonus,
                      amount: _plus(context, preview.productBonus),
                      emphasized: false,
                    ),
                  if (preview.hasEventBonus)
                    KeyedSubtree(
                      key: const Key('purchase-event-bonus'),
                      child: _ProvenanceChip(
                        key: const Key('purchase-provenance-chip-event'),
                        label: l10n.purchase_reward_event_bonus,
                        amount: _plus(context, preview.eventBonus),
                        emphasized: true,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _plus(BuildContext context, BigInt amount) {
    final l10n = AppLocalizations.of(context);
    return l10n.purchase_reward_plus_amount(
      formatCandyRewardAmount(amount, Localizations.localeOf(context)),
    );
  }
}

class _ProvenanceChip extends StatelessWidget {
  const _ProvenanceChip({
    super.key,
    required this.label,
    required this.amount,
    required this.emphasized,
  });

  final String label;
  final String amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? kCandyBoostPink : kCandyBoostPurple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: emphasized
            ? kCandyBoostPink.withValues(alpha: .12)
            : Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        '$label $amount',
        style: getTextStyle(AppTypo.caption10SB, color),
      ),
    );
  }
}
