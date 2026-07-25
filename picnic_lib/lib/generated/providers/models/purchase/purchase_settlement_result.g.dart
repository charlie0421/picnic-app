// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/purchase/purchase_settlement_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PurchasePromotionResultModel _$PurchasePromotionResultModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_PurchasePromotionResultModel',
  json,
  ($checkedConvert) {
    final val = _PurchasePromotionResultModel(
      resolutionId: $checkedConvert('resolution_id', (v) => v as String),
      state: $checkedConvert(
        'state',
        (v) => const PurchasePromotionStateConverter().fromJson(v as String),
      ),
      campaignVersionId: $checkedConvert(
        'campaign_version_id',
        (v) => v as String?,
      ),
      promoBonusAmount: $checkedConvert(
        'promo_bonus_amount',
        (v) => const WalletAmountConverter().fromJson(v),
      ),
      domainCode: $checkedConvert('domain_code', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'resolutionId': 'resolution_id',
    'campaignVersionId': 'campaign_version_id',
    'promoBonusAmount': 'promo_bonus_amount',
    'domainCode': 'domain_code',
  },
);

Map<String, dynamic> _$PurchasePromotionResultModelToJson(
  _PurchasePromotionResultModel instance,
) => <String, dynamic>{
  'resolution_id': instance.resolutionId,
  'state': const PurchasePromotionStateConverter().toJson(instance.state),
  'campaign_version_id': instance.campaignVersionId,
  'promo_bonus_amount': const WalletAmountConverter().toJson(
    instance.promoBonusAmount,
  ),
  'domain_code': instance.domainCode,
};

_PurchaseSettlementResultModel _$PurchaseSettlementResultModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_PurchaseSettlementResultModel',
  json,
  ($checkedConvert) {
    final val = _PurchaseSettlementResultModel(
      contractVersion: $checkedConvert('contract_version', (v) => v as String),
      operationId: $checkedConvert('operation_id', (v) => v as String),
      replayed: $checkedConvert('replayed', (v) => v as bool),
      baseStarAmount: $checkedConvert(
        'base_star_amount',
        (v) => const WalletAmountConverter().fromJson(v),
      ),
      baseBonusAmount: $checkedConvert(
        'base_bonus_amount',
        (v) => const WalletAmountConverter().fromJson(v),
      ),
      promotion: $checkedConvert(
        'promotion',
        (v) => v == null
            ? null
            : PurchasePromotionResultModel.fromJson(v as Map<String, dynamic>),
      ),
      wallet: $checkedConvert(
        'wallet',
        (v) => WalletSummaryModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'contractVersion': 'contract_version',
    'operationId': 'operation_id',
    'baseStarAmount': 'base_star_amount',
    'baseBonusAmount': 'base_bonus_amount',
  },
);

Map<String, dynamic> _$PurchaseSettlementResultModelToJson(
  _PurchaseSettlementResultModel instance,
) => <String, dynamic>{
  'contract_version': instance.contractVersion,
  'operation_id': instance.operationId,
  'replayed': instance.replayed,
  'base_star_amount': const WalletAmountConverter().toJson(
    instance.baseStarAmount,
  ),
  'base_bonus_amount': const WalletAmountConverter().toJson(
    instance.baseBonusAmount,
  ),
  'promotion': instance.promotion?.toJson(),
  'wallet': instance.wallet.toJson(),
};
