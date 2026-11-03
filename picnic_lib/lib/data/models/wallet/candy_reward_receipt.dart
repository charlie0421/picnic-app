import 'package:flutter/foundation.dart' show immutable;
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

@immutable
class CandyRewardReceiptPart {
  const CandyRewardReceiptPart({required this.kind, required this.amount});

  final CandyRewardPartKind kind;
  final BigInt amount;
}

/// Where one slice of a granted amount came from.
///
/// Only ever a *sub*-division of an item the wallet already merges: bonus star
/// candy is one currency and one balance whether or not an event added to it.
enum CandyRewardPartKind { productBonus, eventBonus }

@immutable
class CandyRewardReceiptItem {
  factory CandyRewardReceiptItem({
    required WalletCurrency currency,
    required BigInt grantedAmount,
    required BigInt? balanceAfter,
    DateTime? expiresAt,
    List<CandyRewardReceiptPart> parts = const [],
  }) {
    if (grantedAmount <= BigInt.zero) {
      throw ArgumentError.value(
        grantedAmount,
        'grantedAmount',
        'must be greater than zero',
      );
    }
    if (parts.isNotEmpty) {
      if (parts.any((part) => part.amount <= BigInt.zero)) {
        throw ArgumentError.value(parts, 'parts', 'must all be positive');
      }
      final sum = parts.fold(BigInt.zero, (sum, part) => sum + part.amount);
      if (sum != grantedAmount) {
        // A split that does not add up would show the user a total that
        // disagrees with its own breakdown.
        throw ArgumentError.value(parts, 'parts', 'must sum to grantedAmount');
      }
    }
    return CandyRewardReceiptItem._(
      currency: currency,
      grantedAmount: grantedAmount,
      balanceAfter: balanceAfter,
      expiresAt: expiresAt,
      parts: List.unmodifiable(parts),
    );
  }

  const CandyRewardReceiptItem._({
    required this.currency,
    required this.grantedAmount,
    required this.balanceAfter,
    this.expiresAt,
    this.parts = const [],
  });

  final WalletCurrency currency;
  final BigInt grantedAmount;
  final BigInt? balanceAfter;
  final DateTime? expiresAt;

  /// What [grantedAmount] is made of, when it is worth saying. Empty for every
  /// amount that has only one source - an ad reward, a plain catalog bonus.
  final List<CandyRewardReceiptPart> parts;
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

  /// Everything this settlement added, across currencies.
  BigInt get totalGranted =>
      items.fold(BigInt.zero, (sum, item) => sum + item.grantedAmount);
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
  // Malformed grants must not throw during post-settlement presentation or
  // become different amounts through clamping. The caller still applies the
  // authoritative wallet and finishes the attempt when no receipt is shown.
  if (result.baseStarAmount < BigInt.zero ||
      result.baseBonusAmount < BigInt.zero ||
      promoBonus < BigInt.zero) {
    return null;
  }
  // The event's share is the server's granted amount - never a client
  // estimate, and never present unless the server actually granted it.
  final eventSplit = promoBonus > BigInt.zero
      ? <CandyRewardReceiptPart>[
          if (result.baseBonusAmount > BigInt.zero)
            CandyRewardReceiptPart(
              kind: CandyRewardPartKind.productBonus,
              amount: result.baseBonusAmount,
            ),
          CandyRewardReceiptPart(
            kind: CandyRewardPartKind.eventBonus,
            amount: promoBonus,
          ),
        ]
      : const <CandyRewardReceiptPart>[];
  final candidates = <(WalletCurrency, BigInt, List<CandyRewardReceiptPart>)>[
    (WalletCurrency.starCandy, result.baseStarAmount, const []),
    (
      WalletCurrency.bonusStarCandy,
      result.baseBonusAmount + promoBonus,
      eventSplit,
    ),
  ];
  final items = candidates
      .where((entry) => entry.$2 > BigInt.zero)
      .map(
        (entry) => CandyRewardReceiptItem(
          currency: entry.$1,
          grantedAmount: entry.$2,
          balanceAfter: _balanceFor(result.wallet, entry.$1),
          parts: entry.$3,
        ),
      )
      .toList(growable: false);
  if (items.isEmpty) return null;
  return CandyRewardReceipt(
    referenceKey: 'PURCHASE:${result.operationId}',
    items: items,
  );
}
