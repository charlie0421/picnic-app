import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.candy_reward_receipt_title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: receipt.items
                        .map((item) => CandyRewardReceiptRow(item: item))
                        .toList(growable: false),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.candy_reward_receipt_confirm),
                ),
              ),
            ],
          ),
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
        ? l10n.candy_reward_receipt_balance_unavailable
        : _formatAmount(context, item.balanceAfter!);

    return Semantics(
      container: true,
      label: l10n.candy_reward_receipt_semantics(currency, granted, balance),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.balanceAfter == null
                        ? l10n.candy_reward_receipt_balance_unavailable
                        : l10n.candy_reward_receipt_balance(balance),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.expiresAt case final expiresAt?) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.candy_reward_receipt_expiry(
                        _formatExpiry(context, expiresAt),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.candy_reward_receipt_amount(granted),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
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

String _currencyAsset(WalletCurrency currency) => switch (currency) {
  WalletCurrency.starCandy => 'assets/icons/store/currency_star_candy.png',
  WalletCurrency.bonusStarCandy =>
    'assets/icons/store/currency_bonus_star_candy.png',
  WalletCurrency.cottonCandy => 'assets/icons/store/currency_cotton_candy.png',
};

String _formatAmount(BuildContext context, BigInt amount) =>
    formatWalletAmount(amount).replaceAll(
      ',',
      NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      ).symbols.GROUP_SEP,
    );

String _formatExpiry(BuildContext context, DateTime value) => DateFormat.yMd(
  Localizations.localeOf(context).toLanguageTag(),
).add_Hm().format(value.toLocal());
