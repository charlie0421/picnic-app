import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

part '../../../generated/providers/models/wallet/currency_history.freezed.dart';
part '../../../generated/providers/models/wallet/currency_history.g.dart';

const _currencyHistoryItemKeys = {
  'id',
  'currency',
  'event_type',
  'origin',
  'delta',
  'balance_effect',
  'expires_at',
  'purchase_id',
  'refund_id',
  'grant_id',
  'operation_id',
  'created_at',
};

const _currencyHistoryPageKeys = {
  'items',
  'total_count',
  'next_cursor',
  'snapshot_at',
};

@freezed
abstract class CurrencyHistoryItemModel with _$CurrencyHistoryItemModel {
  const factory CurrencyHistoryItemModel({
    required String id,
    @WalletCurrencyConverter() required WalletCurrency currency,
    @JsonKey(name: 'event_type') required String eventType,
    required String origin,
    @WalletAmountConverter() required BigInt delta,
    @JsonKey(name: 'balance_effect')
    @WalletAmountConverter()
    required BigInt balanceEffect,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'purchase_id') String? purchaseId,
    @JsonKey(name: 'refund_id') String? refundId,
    @JsonKey(name: 'grant_id') String? grantId,
    @JsonKey(name: 'operation_id') required String operationId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _CurrencyHistoryItemModel;

  factory CurrencyHistoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyHistoryItemModelFromJson(
        requireExactContractKeys(json, _currencyHistoryItemKeys),
      );
}

@freezed
abstract class CurrencyHistoryPageModel with _$CurrencyHistoryPageModel {
  const factory CurrencyHistoryPageModel({
    required List<CurrencyHistoryItemModel> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _CurrencyHistoryPageModel;

  factory CurrencyHistoryPageModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyHistoryPageModelFromJson(
        requireExactContractKeys(json, _currencyHistoryPageKeys),
      );
}
