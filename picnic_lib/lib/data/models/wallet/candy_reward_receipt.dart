import 'package:flutter/foundation.dart' show immutable;
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

@immutable
class CandyRewardReceiptItem {
  factory CandyRewardReceiptItem({
    required WalletCurrency currency,
    required BigInt grantedAmount,
    required BigInt? balanceAfter,
    DateTime? expiresAt,
  }) {
    assert(grantedAmount > BigInt.zero);
    return CandyRewardReceiptItem._(
      currency: currency,
      grantedAmount: grantedAmount,
      balanceAfter: balanceAfter,
      expiresAt: expiresAt,
    );
  }

  const CandyRewardReceiptItem._({
    required this.currency,
    required this.grantedAmount,
    required this.balanceAfter,
    this.expiresAt,
  });

  final WalletCurrency currency;
  final BigInt grantedAmount;
  final BigInt? balanceAfter;
  final DateTime? expiresAt;
}

@immutable
class CandyRewardReceipt {
  factory CandyRewardReceipt({
    required String referenceKey,
    required List<CandyRewardReceiptItem> items,
    String? supportingMessageKey,
  }) {
    assert(items.isNotEmpty);
    return CandyRewardReceipt._(
      referenceKey: referenceKey,
      items: items,
      supportingMessageKey: supportingMessageKey,
    );
  }

  const CandyRewardReceipt._({
    required this.referenceKey,
    required this.items,
    this.supportingMessageKey,
  });

  final String referenceKey;
  final List<CandyRewardReceiptItem> items;
  final String? supportingMessageKey;
}

BigInt _balanceFor(WalletSummaryModel wallet, WalletCurrency currency) =>
    switch (currency) {
      WalletCurrency.starCandy => wallet.star,
      WalletCurrency.bonusStarCandy => wallet.bonus,
      WalletCurrency.cottonCandy => wallet.cotton,
    };

CandyRewardReceipt? receiptFromAdReward(AdRewardStatusModel status) {
  final grant = status.grant;
  if (status.state != AdRewardState.granted ||
      grant == null ||
      grant.amount <= BigInt.zero) {
    return null;
  }
  return CandyRewardReceipt(
    referenceKey:
        'AD:${status.reference.type.wireValue}:${status.reference.id}:${grant.id}',
    items: [
      CandyRewardReceiptItem(
        currency: grant.currency,
        grantedAmount: grant.amount,
        balanceAfter: _balanceFor(status.wallet, grant.currency),
        expiresAt: grant.currency == WalletCurrency.cottonCandy
            ? grant.expiresAt
            : null,
      ),
    ],
  );
}

CandyRewardReceipt? receiptFromPurchase(PurchaseSettlementResultModel result) {
  final promo = result.promotion;
  final promoBonus = promo?.state == PurchasePromotionState.granted
      ? promo!.promoBonusAmount
      : BigInt.zero;
  final candidates = [
    (WalletCurrency.starCandy, result.baseStarAmount),
    (WalletCurrency.bonusStarCandy, result.baseBonusAmount + promoBonus),
  ];
  final items = candidates
      .where((entry) => entry.$2 > BigInt.zero)
      .map(
        (entry) => CandyRewardReceiptItem(
          currency: entry.$1,
          grantedAmount: entry.$2,
          balanceAfter: _balanceFor(result.wallet, entry.$1),
        ),
      )
      .toList(growable: false);
  if (items.isEmpty) return null;
  return CandyRewardReceipt(
    referenceKey: 'PURCHASE:${result.operationId}',
    items: items,
  );
}
