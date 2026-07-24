import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

void main() {
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

  test('ad receipt accepts only a granted positive grant', () {
    expect(receiptFromAdReward(grantedAd(amount: BigInt.one)), isNotNull);
    expect(receiptFromAdReward(deniedAd()), isNull);
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
}) => PurchaseSettlementResultModel(
  contractVersion: 'wallet.v1',
  operationId: 'operation-1',
  replayed: false,
  baseStarAmount: baseStar,
  baseBonusAmount: baseBonus,
  promotion: PurchasePromotionResultModel(
    resolutionId: 'resolution-1',
    state: PurchasePromotionState.granted,
    campaignVersionId: 'campaign-1',
    promoBonusAmount: promoBonus,
    domainCode: null,
  ),
  wallet: wallet(),
);

AdRewardStatusModel grantedAd({required BigInt amount}) => AdRewardStatusModel(
  reference: const AdRewardReference(
    type: AdRewardReferenceType.pangleClaim,
    id: 'reference-1',
  ),
  state: AdRewardState.granted,
  grant: AdRewardGrantModel(
    id: 'grant-1',
    currency: WalletCurrency.cottonCandy,
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
