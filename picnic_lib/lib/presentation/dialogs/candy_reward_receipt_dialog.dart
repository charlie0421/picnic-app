import 'dart:math' as math;

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
    final availableHeight = MediaQuery.sizeOf(context).height * .9;
    final desiredHeight = receipt.items.length > 2
        ? 620.0
        : receipt.items.length == 1
        ? 440.0
        : 560.0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 360,
        height: math.min(availableHeight, desiredHeight),
        child: Column(
          children: [
            Container(
              key: const Key('reward-celebration-hero'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kCandyBoostPurple, kCandyBoostPink],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PositionedDirectional(
                    start: 4,
                    top: -10,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white.withValues(alpha: .22),
                      size: 34,
                    ),
                  ),
                  PositionedDirectional(
                    end: 4,
                    bottom: -12,
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.white.withValues(alpha: .18),
                      size: 44,
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .14),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.celebration_rounded,
                          color: kCandyBoostPink,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        l10n.candy_reward_receipt_title,
                        textAlign: TextAlign.center,
                        style: getTextStyle(AppTypo.title18B, Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Column(
                  children: [
                    ...receipt.items.map(
                      (item) => CandyRewardReceiptRow(item: item),
                    ),
                    if (supportingMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        supportingMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: kCandyBoostPurple.withValues(alpha: .08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('reward-confirm-cta'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: kCandyBoostPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.candy_reward_receipt_confirm,
                      style: getTextStyle(AppTypo.body16B, Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CandyRewardReceiptRow extends StatelessWidget {
  const CandyRewardReceiptRow({super.key, required this.item});

  final CandyRewardReceiptItem item;

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
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBonus
                ? [
                    kCandyBoostPurple.withValues(alpha: .1),
                    kCandyBoostPink.withValues(alpha: .14),
                  ]
                : [kCandyBoostPurple.withValues(alpha: .08), Colors.white],
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: accent.withValues(alpha: isBonus ? .38 : .22),
            width: isBonus ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .16),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                _currencyAsset(item.currency),
                key: Key('reward-icon-${item.currency.wireValue}'),
                package: 'picnic_lib',
                width: 42,
                height: 42,
                excludeFromSemantics: true,
              ),
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
                  const SizedBox(height: 2),
                  Text(
                    l10n.candy_reward_receipt_amount(granted),
                    style: getTextStyle(AppTypo.title18B, accent),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      balance == null
                          ? l10n.candy_reward_receipt_balance_unavailable
                          : l10n.candy_reward_receipt_balance(balance),
                      style: getTextStyle(
                        AppTypo.caption10SB,
                        AppColors.grey600,
                      ),
                    ),
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
                  // Where the granted amount came from. The wallet balance is
                  // deliberately not repeated per line: these split one
                  // currency, they are not currencies of their own.
                  for (final part in item.parts) ...[
                    const SizedBox(height: 7),
                    _ReceiptProvenanceChip(
                      key: Key(
                        part.kind == CandyRewardPartKind.productBonus
                            ? 'reward-provenance-chip-product'
                            : 'reward-provenance-chip-event',
                      ),
                      label: _partLabel(l10n, part.kind),
                      amount: l10n.purchase_reward_plus_amount(
                        _formatAmount(context, part.amount),
                      ),
                      emphasized: part.kind == CandyRewardPartKind.eventBonus,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? kCandyBoostPink.withValues(alpha: .1)
            : Colors.white.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: .25)),
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
              style: getTextStyle(AppTypo.caption12B, color),
            ),
          ),
        ],
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
