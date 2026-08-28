import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

part '../../../generated/providers/models/purchase/purchase_settlement_result.freezed.dart';
part '../../../generated/providers/models/purchase/purchase_settlement_result.g.dart';

enum PurchasePromotionState {
  pendingTime,
  eligible,
  ineligible,
  granted,
  rejected,
  cancelledByRefund,
}

class PurchasePromotionStateConverter
    implements JsonConverter<PurchasePromotionState, String> {
  const PurchasePromotionStateConverter();
  @override
  PurchasePromotionState fromJson(String value) => switch (value) {
    'PENDING_TIME' => PurchasePromotionState.pendingTime,
    'ELIGIBLE' => PurchasePromotionState.eligible,
    'INELIGIBLE' => PurchasePromotionState.ineligible,
    'GRANTED' => PurchasePromotionState.granted,
    'REJECTED' => PurchasePromotionState.rejected,
    'CANCELLED_BY_REFUND' => PurchasePromotionState.cancelledByRefund,
    _ => throw FormatException('Unknown purchase promotion state: $value'),
  };
  @override
  String toJson(PurchasePromotionState value) => switch (value) {
    PurchasePromotionState.pendingTime => 'PENDING_TIME',
    PurchasePromotionState.eligible => 'ELIGIBLE',
    PurchasePromotionState.ineligible => 'INELIGIBLE',
    PurchasePromotionState.granted => 'GRANTED',
    PurchasePromotionState.rejected => 'REJECTED',
    PurchasePromotionState.cancelledByRefund => 'CANCELLED_BY_REFUND',
  };
}

const purchaseSettlementKeys = {
  'contract_version',
  'operation_id',
  'replayed',
  'base_star_amount',
  'base_bonus_amount',
  'promotion',
  'wallet',
};
/// Optional revenue keys the server may add to a `wallet.v1` settlement.
///
/// Both are optional and independent: `currency` may arrive without `value`
/// (the Google fallback resolves a currency but never a provider-attested
/// amount), and neither key is present on responses shaped for clients that
/// did not declare `purchase_revenue_v1`.
const purchaseSettlementOptionalKeys = {'currency', 'value'};

/// Wire encoding for `value`: a decimal string, never a JSON number.
///
/// Amounts cross this boundary as strings for the same reason every other
/// amount in this contract does — a JSON float loses precision in transit.
/// [WalletAmountConverter] is not reusable here: it is BigInt-only and this is
/// a fractional currency amount.
class PurchaseRevenueValueConverter implements JsonConverter<num?, Object?> {
  const PurchaseRevenueValueConverter();

  @override
  num? fromJson(Object? value) {
    if (value == null) return null;
    if (value is! String || !RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
      throw const FormatException(
        'Purchase revenue value must be a decimal string',
      );
    }
    return num.parse(value);
  }

  @override
  Object? toJson(num? value) => value?.toString();
}

const purchasePromotionKeys = {
  'resolution_id',
  'state',
  'campaign_version_id',
  'promo_bonus_amount',
  'domain_code',
};

@freezed
abstract class PurchasePromotionResultModel
    with _$PurchasePromotionResultModel {
  const factory PurchasePromotionResultModel({
    @JsonKey(name: 'resolution_id') required String resolutionId,
    @PurchasePromotionStateConverter() required PurchasePromotionState state,
    @JsonKey(name: 'campaign_version_id') required String? campaignVersionId,
    @JsonKey(name: 'promo_bonus_amount')
    @WalletAmountConverter()
    required BigInt promoBonusAmount,
    @JsonKey(name: 'domain_code') required String? domainCode,
  }) = _PurchasePromotionResultModel;

  factory PurchasePromotionResultModel.fromJson(Map<String, dynamic> json) =>
      _$PurchasePromotionResultModelFromJson(
        requireExactContractKeys(json, purchasePromotionKeys),
      );
}

@freezed
abstract class PurchaseSettlementResultModel
    with _$PurchaseSettlementResultModel {
  const factory PurchaseSettlementResultModel({
    @JsonKey(name: 'contract_version') required String contractVersion,
    @JsonKey(name: 'operation_id') required String operationId,
    required bool replayed,
    @JsonKey(name: 'base_star_amount')
    @WalletAmountConverter()
    required BigInt baseStarAmount,
    @JsonKey(name: 'base_bonus_amount')
    @WalletAmountConverter()
    required BigInt baseBonusAmount,
    required PurchasePromotionResultModel? promotion,
    required WalletSummaryModel wallet,

    /// ISO 4217 code for this transaction, when the server could establish one.
    ///
    /// Server-authoritative: when present it wins over anything the client's
    /// store catalogue says. Absent means the server had no verified currency
    /// for this transaction, not that the transaction had none.
    @JsonKey(name: 'currency') String? currency,

    /// Amount actually paid, in major units, when the provider attested one.
    ///
    /// Independent of [currency]: a settlement may carry a currency with no
    /// value. Only meaningful paired with [currency] — an amount without a
    /// currency is a candidate, never a revenue figure.
    @JsonKey(name: 'value') @PurchaseRevenueValueConverter() num? value,

    /// How *this* client came to see a `replayed` settlement. Never part of the
    /// wire contract: the server cannot know whose retry it is answering.
    ///
    /// `ReceiptVerificationService` sets it when a `replayed` settlement comes
    /// back to a request it sent *after* an earlier request for the same
    /// receipt. That earlier request settled on the server and then failed in
    /// transport, so the replay is one we caused ourselves and nothing has been
    /// shown to the user yet. Absent that, a `replayed` settlement was put
    /// there by an earlier delivery or session.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool replayCausedByRetry,

    /// 이 정산을 만들어 낸 영수증 큐 항목의 키. 계약의 일부가 아니다.
    ///
    /// 큐 항목은 "서버 정산 응답 확보"까지를 소유하고, analytics outbox 는 그
    /// 뒤부터를 소유한다. 소유권이 실제로 넘어간 뒤에만 큐를 비울 수 있어야
    /// 하는데, 그러려면 정산 결과가 자기를 낳은 큐 항목을 가리켜야 한다.
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? receiptQueueClientTraceId,
  }) = _PurchaseSettlementResultModel;

  factory PurchaseSettlementResultModel.fromJson(Map<String, dynamic> json) =>
      parseCanonicalPurchaseSettlement(json);
  factory PurchaseSettlementResultModel.fromLegacyJson(
    Map<String, dynamic> json,
  ) => parseLegacyPurchaseSettlement(json);
}

/// Whether this delivery re-reports a settlement this client has already
/// presented, i.e. one the user has been shown a receipt for.
///
/// `replayed` alone does not answer that. The retry loop in
/// `ReceiptVerificationService` re-sends a request whose response was lost in
/// transport; if the server had already settled it, the retry gets the original
/// amounts back with `replayed: true` while the user has still seen nothing. A
/// replay we did not cause is one an earlier delivery or session settled, and
/// only that one is a redelivery.
bool isSettlementRedelivery(PurchaseSettlementResultModel result) =>
    result.replayed && !result.replayCausedByRetry;

void validatePurchasePromotion(PurchasePromotionResultModel promotion) {
  final pending = promotion.state == PurchasePromotionState.pendingTime;
  if (pending && promotion.domainCode != 'PROMO_REVIEW_REQUIRED') {
    throw const FormatException('PENDING_TIME requires PROMO_REVIEW_REQUIRED');
  }
  if (!pending && promotion.domainCode != null) {
    throw const FormatException('Only PENDING_TIME may carry domain_code');
  }
  if (promotion.state != PurchasePromotionState.granted &&
      promotion.promoBonusAmount != BigInt.zero) {
    throw const FormatException('Only GRANTED may carry promotion amount');
  }
}

PurchaseSettlementResultModel parseCanonicalPurchaseSettlement(
  Map<String, dynamic> json,
) {
  final exact = requireContractKeys(
    json,
    required: purchaseSettlementKeys,
    optional: purchaseSettlementOptionalKeys,
  );
  if (exact['contract_version'] != 'wallet.v1') {
    throw const FormatException('Unsupported purchase contract_version');
  }
  final promotionJson = exact['promotion'];
  if (promotionJson is! Map) {
    throw const FormatException('Canonical promotion must be an object');
  }
  validatePurchasePromotion(
    PurchasePromotionResultModel.fromJson(
      Map<String, dynamic>.from(promotionJson),
    ),
  );
  return _$PurchaseSettlementResultModelFromJson(exact);
}

PurchaseSettlementResultModel parseLegacyPurchaseSettlement(
  Map<String, dynamic> json,
) {
  final withoutPromotion = {...purchaseSettlementKeys}..remove('promotion');
  final keys = json.keys.toSet();
  if (!(keys.length == withoutPromotion.length &&
          keys.containsAll(withoutPromotion)) &&
      !(keys.length == purchaseSettlementKeys.length &&
          keys.containsAll(purchaseSettlementKeys))) {
    throw const FormatException('Invalid legacy purchase key set');
  }
  if (json['promotion'] != null) {
    throw const FormatException('Non-null promotion requires canonical parser');
  }
  final exact = requireExactContractKeys({
    ...json,
    'promotion': null,
  }, purchaseSettlementKeys);
  if (exact['contract_version'] != 'wallet.v1') {
    throw const FormatException('Unsupported purchase contract_version');
  }
  return _$PurchaseSettlementResultModelFromJson(exact);
}
