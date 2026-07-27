// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/wallet/currency_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CurrencyHistoryItemModel _$CurrencyHistoryItemModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_CurrencyHistoryItemModel',
  json,
  ($checkedConvert) {
    final val = _CurrencyHistoryItemModel(
      id: $checkedConvert('id', (v) => v as String),
      currency: $checkedConvert(
        'currency',
        (v) => const WalletCurrencyConverter().fromJson(v as String),
      ),
      eventType: $checkedConvert('event_type', (v) => v as String),
      origin: $checkedConvert('origin', (v) => v as String),
      delta: $checkedConvert(
        'delta',
        (v) => const WalletAmountConverter().fromJson(v),
      ),
      balanceEffect: $checkedConvert(
        'balance_effect',
        (v) => const WalletAmountConverter().fromJson(v),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      purchaseId: $checkedConvert('purchase_id', (v) => v as String?),
      refundId: $checkedConvert('refund_id', (v) => v as String?),
      grantId: $checkedConvert('grant_id', (v) => v as String?),
      operationId: $checkedConvert('operation_id', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'eventType': 'event_type',
    'balanceEffect': 'balance_effect',
    'expiresAt': 'expires_at',
    'purchaseId': 'purchase_id',
    'refundId': 'refund_id',
    'grantId': 'grant_id',
    'operationId': 'operation_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$CurrencyHistoryItemModelToJson(
  _CurrencyHistoryItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'currency': const WalletCurrencyConverter().toJson(instance.currency),
  'event_type': instance.eventType,
  'origin': instance.origin,
  'delta': const WalletAmountConverter().toJson(instance.delta),
  'balance_effect': const WalletAmountConverter().toJson(
    instance.balanceEffect,
  ),
  'expires_at': instance.expiresAt?.toIso8601String(),
  'purchase_id': instance.purchaseId,
  'refund_id': instance.refundId,
  'grant_id': instance.grantId,
  'operation_id': instance.operationId,
  'created_at': instance.createdAt.toIso8601String(),
};

_CurrencyHistoryPageModel _$CurrencyHistoryPageModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_CurrencyHistoryPageModel',
  json,
  ($checkedConvert) {
    final val = _CurrencyHistoryPageModel(
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  CurrencyHistoryItemModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      totalCount: $checkedConvert(
        'total_count',
        (v) => const WalletAmountConverter().fromJson(v),
      ),
      nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      snapshotAt: $checkedConvert(
        'snapshot_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'totalCount': 'total_count',
    'nextCursor': 'next_cursor',
    'snapshotAt': 'snapshot_at',
  },
);

Map<String, dynamic> _$CurrencyHistoryPageModelToJson(
  _CurrencyHistoryPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total_count': const WalletAmountConverter().toJson(instance.totalCount),
  'next_cursor': instance.nextCursor,
  'snapshot_at': instance.snapshotAt.toIso8601String(),
};
