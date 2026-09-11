import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_palette.dart';
import 'package:picnic_lib/ui/style.dart';

Future<void> showCandyRewardReceiptDialog(
  BuildContext context,
  CandyRewardReceipt receipt, {
  String? supportingMessage,
}) => showDialog<void>(
  context: context,
  builder: (context) => CandyRewardReceiptDialog(
    receipt: receipt,
    supportingMessage: supportingMessage,
  ),
);

class CandyRewardReceiptDialog extends StatelessWidget {
  const CandyRewardReceiptDialog({
    super.key,
    required this.receipt,
    this.supportingMessage,
  });

  final CandyRewardReceipt receipt;
  final String? supportingMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 560),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  key: const Key('reward-celebration-hero'),
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Text(
                    l10n.candy_reward_receipt_title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...receipt.items.map(
                  (item) => CandyRewardReceiptRow(
                    item: item,
                    isPurchaseReceipt: receipt.referenceKey.startsWith(
                      'PURCHASE:',
                    ),
                  ),
                ),
                if (supportingMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    supportingMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('reward-confirm-cta'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.candy_reward_receipt_confirm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CandyRewardReceiptRow extends StatelessWidget {
  const CandyRewardReceiptRow({
    super.key,
    required this.item,
    required this.isPurchaseReceipt,
  });

  final CandyRewardReceiptItem item;
  final bool isPurchaseReceipt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = _currencyLabel(l10n, item.currency);
    final granted = _formatAmount(context, item.grantedAmount);
    final balance = item.balanceAfter == null
        ? null
        : _formatAmount(context, item.balanceAfter!);
    final baseSemantics = balance == null
        ? l10n.candy_reward_receipt_semantics_balance_unavailable(
            currency,
            granted,
          )
        : l10n.candy_reward_receipt_semantics(currency, granted, balance);
    final expiry = item.expiresAt == null
        ? null
        : l10n.candy_reward_receipt_expiry(
            _formatExpiry(context, item.expiresAt!),
          );
    final splitLines = item.parts
        .map(
          (part) =>
              '${_partLabel(l10n, part.kind)} '
              '${l10n.purchase_reward_plus_amount(_formatAmount(context, part.amount))}',
        )
        .toList(growable: false);
    final isBonus = item.currency == WalletCurrency.bonusStarCandy;
    final accent = isBonus ? kCandyBoostPink : kCandyBoostPurple;

    return Semantics(
      container: true,
      // `..._with_expiry` is just this locale's way of joining two clauses;
      // the split lines are appended with the same joiner so a screen reader
      // hears the same breakdown a sighted user sees.
      label:
          [
            if (expiry == null)
              baseSemantics
            else
              l10n.candy_reward_receipt_semantics_with_expiry(
                baseSemantics,
                expiry,
              ),
            ...splitLines,
          ].reduce(
            (joined, next) =>
                l10n.candy_reward_receipt_semantics_with_expiry(joined, next),
          ),
      excludeSemantics: true,
      child: Container(
        key: Key('reward-card-${item.currency.wireValue}'),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              _currencyAsset(item.currency),
              key: Key('reward-icon-${item.currency.wireValue}'),
              package: 'picnic_lib',
              width: 44,
              height: 44,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency,
                    style: getTextStyle(AppTypo.body14B, AppColors.grey800),
                  ),
                  if (isBonus && item.parts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.purchase_reward_total_short} $granted',
                      style: getTextStyle(AppTypo.body16B, kCandyBoostPurple),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.candy_reward_receipt_amount(granted),
                      style: getTextStyle(AppTypo.title18B, accent),
                    ),
                  ],
                  if (item.parts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < item.parts.length;
                            index++
                          ) ...[
                            if (index > 0)
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
                            _ReceiptProvenanceChip(
                              key: Key(
                                item.parts[index].kind ==
                                        CandyRewardPartKind.productBonus
                                    ? 'reward-provenance-chip-product'
                                    : 'reward-provenance-chip-event',
                              ),
                              label: _partShortLabel(
                                l10n,
                                item.parts[index].kind,
                              ),
                              amount: _formatAmount(
                                context,
                                item.parts[index].amount,
                              ),
                              emphasized:
                                  item.parts[index].kind ==
                                  CandyRewardPartKind.eventBonus,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    balance == null
                        ? l10n.candy_reward_receipt_balance_unavailable
                        : isPurchaseReceipt
                        ? l10n.candy_reward_receipt_purchase_balance(balance)
                        : l10n.candy_reward_receipt_balance(balance),
                    style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  ),
                  if (expiry != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      expiry,
                      style: getTextStyle(
                        AppTypo.caption10R,
                        AppColors.grey600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptProvenanceChip extends StatelessWidget {
  const _ReceiptProvenanceChip({
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
    final backgroundColor = emphasized
        ? kCandyBoostPink.withValues(alpha: .08)
        : AppColors.grey100;
    final borderColor = emphasized
        ? kCandyBoostPink.withValues(alpha: .16)
        : AppColors.grey300;
    return Container(
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
}

String _currencyLabel(AppLocalizations l10n, WalletCurrency currency) =>
    switch (currency) {
      WalletCurrency.starCandy => l10n.wallet_star_candy,
      WalletCurrency.bonusStarCandy => l10n.wallet_bonus_star_candy,
      WalletCurrency.cottonCandy => l10n.wallet_cotton_candy,
    };

String _partLabel(AppLocalizations l10n, CandyRewardPartKind kind) =>
    switch (kind) {
      CandyRewardPartKind.productBonus => l10n.purchase_reward_product_bonus,
      CandyRewardPartKind.eventBonus => l10n.purchase_reward_event_bonus,
    };

String _partShortLabel(AppLocalizations l10n, CandyRewardPartKind kind) =>
    switch (kind) {
      CandyRewardPartKind.productBonus => l10n.purchase_reward_base_short,
      CandyRewardPartKind.eventBonus => l10n.purchase_reward_event_short,
    };

String _currencyAsset(WalletCurrency currency) => switch (currency) {
  WalletCurrency.starCandy => 'assets/icons/store/currency_star_candy.png',
  WalletCurrency.bonusStarCandy =>
    'assets/icons/store/currency_bonus_star_candy.png',
  WalletCurrency.cottonCandy => 'assets/icons/store/currency_cotton_candy.png',
};

String _formatAmount(BuildContext context, BigInt amount) =>
    formatCandyRewardAmount(amount, Localizations.localeOf(context));

String formatCandyRewardAmount(BigInt amount, Locale locale) {
  final format = NumberFormat.decimalPattern(locale.toLanguageTag());
  final symbols = format.symbols;
  final integerPattern = symbols.DECIMAL_PATTERN.split('.').first;
  final patternGroups = integerPattern.split(',');
  final primaryGroupSize = _placeholderCount(patternGroups.last);
  final secondaryGroupSize = patternGroups.length > 2
      ? _placeholderCount(patternGroups[patternGroups.length - 2])
      : primaryGroupSize;
  final digits = amount.abs().toString();
  final groups = <String>[];
  var end = digits.length;
  var groupSize = primaryGroupSize;

  while (end > 0) {
    final start = (end - groupSize).clamp(0, end);
    groups.add(digits.substring(start, end));
    end = start;
    groupSize = secondaryGroupSize;
  }

  final grouped = groups.reversed.join(symbols.GROUP_SEP);
  final localized = _localizeDigits(grouped, symbols.ZERO_DIGIT);
  return amount.isNegative ? '${symbols.MINUS_SIGN}$localized' : localized;
}

int _placeholderCount(String pattern) =>
    pattern.replaceAll(RegExp('[^#0]'), '').length;

String _localizeDigits(String value, String zeroDigit) {
  final offset = zeroDigit.runes.single - '0'.codeUnitAt(0);
  if (offset == 0) return value;
  return value.replaceAllMapped(
    RegExp(r'[0-9]'),
    (match) => String.fromCharCode(match[0]!.codeUnitAt(0) + offset),
  );
}

String _formatExpiry(BuildContext context, DateTime value) => DateFormat.yMd(
  Localizations.localeOf(context).toLanguageTag(),
).add_Hm().format(value.toLocal());
