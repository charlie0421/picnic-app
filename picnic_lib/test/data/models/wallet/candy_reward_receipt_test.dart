import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

void main() {
  for (final entry in [
    (name: 'base star', baseStar: -1, baseBonus: 25, promoBonus: 225),
    (name: 'product bonus', baseStar: 100, baseBonus: -1, promoBonus: 2),
    (name: 'granted event bonus', baseStar: 100, baseBonus: 25, promoBonus: -1),
  ]) {
    test('negative ${entry.name} yields no receipt instead of throwing', () {
      final result = purchaseResult(
        baseStar: BigInt.from(entry.baseStar),
        baseBonus: BigInt.from(entry.baseBonus),
        promoBonus: BigInt.from(entry.promoBonus),
      );
      // These negative integer strings currently pass the wire converter.
      // Receipt presentation must reject them without interrupting settlement.
      final parsed = PurchaseSettlementResultModel.fromJson(result.toJson());

      expect(receiptFromPurchase(parsed), isNull);
    });
  }

  test('purchase receipt combines positive base and granted promo bonus', () {
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(100),
        baseBonus: BigInt.from(20),
        promoBonus: BigInt.from(30),
      ),
    );

    expect(receipt!.referenceKey, 'PURCHASE:operation-1');
    expect(receipt.items, hasLength(2));
    expect(receipt.items[0].currency, WalletCurrency.starCandy);
    expect(receipt.items[0].grantedAmount, BigInt.from(100));
    expect(receipt.items[0].balanceAfter, BigInt.from(500));
    expect(receipt.items[1].currency, WalletCurrency.bonusStarCandy);
    expect(receipt.items[1].grantedAmount, BigInt.from(50));
    expect(receipt.items[1].balanceAfter, BigInt.from(80));
  });

  test('purchase receipt omits zero-value currencies', () {
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(100),
        baseBonus: BigInt.zero,
        promoBonus: BigInt.zero,
      ),
    );
    expect(receipt!.items.map((item) => item.currency), [
      WalletCurrency.starCandy,
    ]);
  });

  test('the bonus row splits into the catalog part and the event part', () {
    // STAR200 under a 2x campaign: 25 catalog bonus, 225 from the event.
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(200),
        baseBonus: BigInt.from(25),
        promoBonus: BigInt.from(225),
      ),
    );

    final bonus = receipt!.items[1];
    expect(bonus.grantedAmount, BigInt.from(250));
    expect(bonus.parts.map((part) => part.kind), [
      CandyRewardPartKind.productBonus,
      CandyRewardPartKind.eventBonus,
    ]);
    expect(bonus.parts.map((part) => part.amount), [
      BigInt.from(25),
      BigInt.from(225),
    ]);
    expect(receipt.totalGranted, BigInt.from(450));
  });

  test('a bonus that is entirely the event names the event', () {
    // STAR100 has no catalog bonus, so every bonus candy came from the event.
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(100),
        baseBonus: BigInt.zero,
        promoBonus: BigInt.from(100),
      ),
    );

    expect(receipt!.items[1].parts.single.kind, CandyRewardPartKind.eventBonus);
    expect(receipt.items[1].parts.single.amount, BigInt.from(100));
    expect(receipt.totalGranted, BigInt.from(200));
  });

  test('a catalog bonus with no granted event stays unsplit', () {
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(200),
        baseBonus: BigInt.from(25),
        promoBonus: BigInt.zero,
      ),
    );

    expect(receipt!.items[1].parts, isEmpty);
    expect(receipt.totalGranted, BigInt.from(225));
  });

  test('the granted amount is the server one, never a client estimate', () {
    // A V1 15% preview of 101 candy would say floor(151.5 / 10) = 15; this
    // settlement granted 14, and the receipt reports what was granted.
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(100),
        baseBonus: BigInt.one,
        promoBonus: BigInt.from(14),
      ),
    );

    expect(receipt!.items[1].grantedAmount, BigInt.from(15));
    expect(receipt.items[1].parts.map((part) => part.amount), [
      BigInt.one,
      BigInt.from(14),
    ]);
    expect(receipt.totalGranted, BigInt.from(115));
  });

  test('a promotion still under review contributes no event part', () {
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(100),
        baseBonus: BigInt.from(20),
        promoBonus: BigInt.zero,
        state: PurchasePromotionState.pendingTime,
        domainCode: 'PROMO_REVIEW_REQUIRED',
      ),
    );

    expect(receipt!.items[1].grantedAmount, BigInt.from(20));
    expect(receipt.items[1].parts, isEmpty);
    expect(receipt.totalGranted, BigInt.from(120));
  });

  test('an ad reward keeps a single unsplit item', () {
    final receipt = receiptFromAdReward(grantedAd(amount: BigInt.from(20)));

    expect(receipt!.items.single.parts, isEmpty);
    expect(receipt.items.single.currency, WalletCurrency.cottonCandy);
  });

  test('redelivered purchase yields no receipt even with positive amounts', () {
    // An earlier delivery or session settled this operation and showed the
    // amounts, so this delivery grants nothing the user has not already seen.
    expect(
      receiptFromPurchase(
        purchaseResult(
          baseStar: BigInt.from(100),
          baseBonus: BigInt.from(20),
          promoBonus: BigInt.from(30),
          replayed: true,
        ),
      ),
      isNull,
    );
  });

  test('a replay our own verification retry caused still yields a receipt', () {
    // The first attempt settled on the server and then failed in transport, so
    // the retry sees `replayed` for candy the user was never shown.
    final receipt = receiptFromPurchase(
      purchaseResult(
        baseStar: BigInt.from(100),
        baseBonus: BigInt.from(20),
        promoBonus: BigInt.from(30),
        replayed: true,
        replayCausedByRetry: true,
      ),
    );

    expect(receipt!.items.map((item) => item.grantedAmount), [
      BigInt.from(100),
      BigInt.from(50),
    ]);
  });

  test('ad receipt accepts only a granted positive grant', () {
    expect(receiptFromAdReward(grantedAd(amount: BigInt.one)), isNotNull);
    expect(receiptFromAdReward(deniedAd()), isNull);
  });

  for (final currency in [
    WalletCurrency.starCandy,
    WalletCurrency.bonusStarCandy,
  ]) {
    test('ad receipt rejects a positive ${currency.name} grant', () {
      expect(
        receiptFromAdReward(grantedAd(amount: BigInt.one, currency: currency)),
        isNull,
      );
    });
  }

  test('legacy internal shortform view yields a bonus candy receipt', () {
    final receipt = receiptFromInternalShortformView(
      const InternalShortformViewResponse(
        ok: true,
        rewardAdded: 3,
        impressionId: 'impression-1',
        newBonus: 54,
      ),
    );

    expect(receipt!.referenceKey, 'AD:INTERNAL_IMPRESSION:impression-1:LEGACY');
    final item = receipt.items.single;
    expect(item.currency, WalletCurrency.bonusStarCandy);
    expect(item.grantedAmount, BigInt.from(3));
    expect(item.balanceAfter, BigInt.from(54));
    expect(item.expiresAt, isNull);
  });

  test('legacy internal shortform receipt survives a missing balance', () {
    // Older backends omit new_bonus; the dialog then renders its
    // balance-unavailable line instead of a stale number.
    final receipt = receiptFromInternalShortformView(
      const InternalShortformViewResponse(
        ok: true,
        rewardAdded: 1,
        impressionId: 'impression-1',
        newBonus: null,
      ),
    );

    expect(receipt!.items.single.balanceAfter, isNull);
  });

  test('wallet-aware internal shortform view yields no legacy receipt', () {
    // The recovery flow presents the receipt for a wallet-aware response;
    // building one here too would show the grant twice.
    final response = InternalShortformViewResponse(
      ok: true,
      rewardAdded: 3,
      impressionId: 'impression-1',
      newBonus: null,
      reward: grantedAd(amount: BigInt.from(3)),
    );

    expect(receiptFromInternalShortformView(response), isNull);
  });

  test('a zero legacy reward yields no receipt', () {
    expect(
      receiptFromInternalShortformView(
        const InternalShortformViewResponse(
          ok: true,
          rewardAdded: 0,
          impressionId: 'impression-1',
          newBonus: 54,
        ),
      ),
      isNull,
    );
  });

  for (final amount in [BigInt.zero, BigInt.from(-1)]) {
    test('receipt item rejects a non-positive granted amount: $amount', () {
      expect(
        () => CandyRewardReceiptItem(
          currency: WalletCurrency.cottonCandy,
          grantedAmount: amount,
          balanceAfter: BigInt.zero,
        ),
        throwsArgumentError,
      );
    });
  }

  test('receipt rejects an empty item list', () {
    expect(
      () => CandyRewardReceipt(referenceKey: 'TEST:empty', items: const []),
      throwsArgumentError,
    );
  });

  test('receipt items do not change when the source list changes', () {
    final sourceItems = [receiptItem(WalletCurrency.starCandy)];
    final receipt = CandyRewardReceipt(
      referenceKey: 'TEST:source-list',
      items: sourceItems,
    );

    sourceItems.add(receiptItem(WalletCurrency.bonusStarCandy));

    expect(receipt.items, hasLength(1));
    expect(receipt.items.single.currency, WalletCurrency.starCandy);
  });

  test('receipt items cannot be mutated directly', () {
    final receipt = CandyRewardReceipt(
      referenceKey: 'TEST:direct-mutation',
      items: [receiptItem(WalletCurrency.starCandy)],
    );

    expect(
      () => receipt.items[0] = receiptItem(WalletCurrency.bonusStarCandy),
      throwsUnsupportedError,
    );
  });
}

CandyRewardReceiptItem receiptItem(WalletCurrency currency) =>
    CandyRewardReceiptItem(
      currency: currency,
      grantedAmount: BigInt.one,
      balanceAfter: BigInt.one,
    );

PurchaseSettlementResultModel purchaseResult({
  required BigInt baseStar,
  required BigInt baseBonus,
  required BigInt promoBonus,
  bool replayed = false,
  bool replayCausedByRetry = false,
  PurchasePromotionState state = PurchasePromotionState.granted,
  String? domainCode,
}) => PurchaseSettlementResultModel(
  contractVersion: 'wallet.v1',
  operationId: 'operation-1',
  replayed: replayed,
  replayCausedByRetry: replayCausedByRetry,
  baseStarAmount: baseStar,
  baseBonusAmount: baseBonus,
  promotion: PurchasePromotionResultModel(
    resolutionId: 'resolution-1',
    state: state,
    campaignVersionId: 'campaign-1',
    promoBonusAmount: promoBonus,
    domainCode: domainCode,
  ),
  wallet: wallet(),
);

AdRewardStatusModel grantedAd({
  required BigInt amount,
  WalletCurrency currency = WalletCurrency.cottonCandy,
}) => AdRewardStatusModel(
  reference: const AdRewardReference(
    type: AdRewardReferenceType.pangleClaim,
    id: 'reference-1',
  ),
  state: AdRewardState.granted,
  grant: AdRewardGrantModel(
    id: 'grant-1',
    currency: currency,
    amount: amount,
    grantedAt: DateTime.utc(2026, 7, 24),
    expiresAt: DateTime.utc(2026, 8, 24),
  ),
  wallet: wallet(),
  snapshotAt: DateTime.utc(2026, 7, 24),
);

AdRewardStatusModel deniedAd() => AdRewardStatusModel(
  reference: const AdRewardReference(
    type: AdRewardReferenceType.internalImpression,
    id: 'reference-2',
  ),
  state: AdRewardState.denied,
  grant: null,
  wallet: wallet(),
  snapshotAt: DateTime.utc(2026, 7, 24),
);

WalletSummaryModel wallet() => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(500),
  bonus: BigInt.from(80),
  cotton: BigInt.from(10),
  cottonExpiringAmount: BigInt.from(10),
  cottonNextExpiresAt: DateTime.utc(2026, 8, 24),
  snapshotAt: DateTime.utc(2026, 7, 24),
);
