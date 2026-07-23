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
  }) = _PurchaseSettlementResultModel;

  factory PurchaseSettlementResultModel.fromJson(Map<String, dynamic> json) =>
      parseCanonicalPurchaseSettlement(json);
  factory PurchaseSettlementResultModel.fromLegacyJson(
    Map<String, dynamic> json,
  ) => parseLegacyPurchaseSettlement(json);
}

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
  final exact = requireExactContractKeys(json, purchaseSettlementKeys);
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
