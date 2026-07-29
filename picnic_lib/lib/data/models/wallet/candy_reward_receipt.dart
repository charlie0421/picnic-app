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
    if (grantedAmount <= BigInt.zero) {
      throw ArgumentError.value(
        grantedAmount,
        'grantedAmount',
        'must be greater than zero',
      );
    }
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
  }) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    return CandyRewardReceipt._(
      referenceKey: referenceKey,
      items: List.unmodifiable(items),
    );
  }

  const CandyRewardReceipt._({required this.referenceKey, required this.items});

  final String referenceKey;
  final List<CandyRewardReceiptItem> items;
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
      grant.currency != WalletCurrency.cottonCandy ||
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

/// Builds the receipt for a legacy internal-shortform view response.
///
/// The legacy contract carries no [AdRewardStatusModel]: the server credits
/// bonus star candy and reports only the credited amount (`reward_added`) and
/// the post-credit bonus balance (`new_bonus`, absent on older backends). A
/// wallet-aware response (`reward` present) has its receipt presented by the
/// ad reward recovery flow instead, so it yields none here.
CandyRewardReceipt? receiptFromInternalShortformView(
  InternalShortformViewResponse response,
) {
  if (response.reward != null || response.rewardAdded <= 0) return null;
  final newBonus = response.newBonus;
  return CandyRewardReceipt(
    referenceKey:
        'AD:${AdRewardReferenceType.internalImpression.wireValue}:${response.impressionId}:LEGACY',
    items: [
      CandyRewardReceiptItem(
        currency: WalletCurrency.bonusStarCandy,
        grantedAmount: BigInt.from(response.rewardAdded),
        balanceAfter: newBonus == null ? null : BigInt.from(newBonus),
      ),
    ],
  );
}

/// Builds the receipt for candy this settlement just added.
///
/// A redelivered settlement re-reports an operation an earlier delivery or
/// session already settled *and already showed*: the candy was credited then
/// and this delivery grants nothing new to report, so it has no receipt. A
/// replay our own verification retry caused is not a redelivery - the user was
/// shown nothing - and keeps its receipt. `result.wallet` still carries the
/// current balance and is applied by the caller either way.
CandyRewardReceipt? receiptFromPurchase(PurchaseSettlementResultModel result) {
  if (isSettlementRedelivery(result)) return null;
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
