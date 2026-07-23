import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';

typedef WalletIconBuilder = Widget Function(String asset, double dimension);

class WalletSummaryPanel extends ConsumerWidget {
  const WalletSummaryPanel({
    super.key,
    this.compact = false,
    this.alignment = MainAxisAlignment.start,
    this.assetPackage = 'picnic_lib',
    this.iconBuilder,
  });

  final bool compact;
  final MainAxisAlignment alignment;
  final String? assetPackage;
  final WalletIconBuilder? iconBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    return ref
        .watch(walletSummaryProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text(localizations.wallet_load_failed),
          data: (wallet) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WalletCurrencySegment(
                  asset: 'assets/icons/store/currency_star_candy.png',
                  label: localizations.wallet_star_candy,
                  amount: wallet.star,
                  compact: compact,
                  contentAlignment: _contentAlignment,
                  assetPackage: assetPackage,
                  iconBuilder: iconBuilder,
                ),
              ),
              Expanded(
                child: WalletCurrencySegment(
                  asset: 'assets/icons/store/currency_bonus_star_candy.png',
                  label: localizations.wallet_bonus_star_candy,
                  amount: wallet.bonus,
                  compact: compact,
                  contentAlignment: _contentAlignment,
                  assetPackage: assetPackage,
                  iconBuilder: iconBuilder,
                ),
              ),
              Expanded(
                child: WalletCurrencySegment(
                  asset: 'assets/icons/store/currency_cotton_candy.png',
                  label: localizations.wallet_cotton_candy,
                  amount: wallet.cotton,
                  secondary: buildCottonExpiryText(context, wallet),
                  compact: compact,
                  contentAlignment: _contentAlignment,
                  assetPackage: assetPackage,
                  iconBuilder: iconBuilder,
                ),
              ),
            ],
          ),
        );
  }

  CrossAxisAlignment get _contentAlignment {
    if (!compact) return CrossAxisAlignment.start;
    return switch (alignment) {
      MainAxisAlignment.center => CrossAxisAlignment.center,
      MainAxisAlignment.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
  }
}

String? buildCottonExpiryText(BuildContext context, WalletSummaryModel wallet) {
  final localizations = AppLocalizations.of(context);
  final values = <String>[];
  if (wallet.cottonExpiringAmount > BigInt.zero) {
    values.add(
      localizations.wallet_cotton_expires_today(
        formatWalletAmount(wallet.cottonExpiringAmount),
      ),
    );
  }
  if (wallet.cottonNextExpiresAt != null) {
    values.add(
      localizations.wallet_cotton_next_expiry(
        DateFormat.yMd(
          Localizations.localeOf(context).toString(),
        ).add_Hm().format(wallet.cottonNextExpiresAt!.toLocal()),
      ),
    );
  }
  return values.isEmpty ? null : values.join('\n');
}

class WalletCurrencySegment extends StatelessWidget {
  const WalletCurrencySegment({
    super.key,
    required this.asset,
    required this.label,
    required this.amount,
    this.secondary,
    this.compact = false,
    this.contentAlignment = CrossAxisAlignment.start,
    this.assetPackage = 'picnic_lib',
    this.iconBuilder,
  });

  final String asset;
  final String label;
  final BigInt amount;
  final String? secondary;
  final bool compact;
  final CrossAxisAlignment contentAlignment;
  final String? assetPackage;
  final WalletIconBuilder? iconBuilder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: contentAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconBuilder?.call(asset, compact ? 32 : 40) ??
              Image.asset(
                asset,
                package: assetPackage,
                width: compact ? 32 : 40,
                height: compact ? 32 : 40,
              ),
          Text(label, textAlign: TextAlign.left),
          Text(formatWalletAmount(amount), textAlign: TextAlign.left),
          if (secondary != null && !compact)
            Text(secondary!, textAlign: TextAlign.left),
        ],
      ),
    );
  }
}
