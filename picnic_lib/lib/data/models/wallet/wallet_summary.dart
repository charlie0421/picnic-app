import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

part '../../../generated/providers/models/wallet/wallet_summary.freezed.dart';
part '../../../generated/providers/models/wallet/wallet_summary.g.dart';

const _walletSummaryKeys = {
  'contract_version',
  'star',
  'bonus',
  'cotton',
  'cotton_expiring_amount',
  'cotton_next_expires_at',
  'snapshot_at',
};

@freezed
abstract class WalletSummaryModel with _$WalletSummaryModel {
  const factory WalletSummaryModel({
    @JsonKey(name: 'contract_version') required String contractVersion,
    @WalletAmountConverter() required BigInt star,
    @WalletAmountConverter() required BigInt bonus,
    @WalletAmountConverter() required BigInt cotton,
    @JsonKey(name: 'cotton_expiring_amount')
    @WalletAmountConverter()
    required BigInt cottonExpiringAmount,
    @JsonKey(name: 'cotton_next_expires_at')
    required DateTime? cottonNextExpiresAt,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _WalletSummaryModel;

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$WalletSummaryModelFromJson(
        requireExactContractKeys(json, _walletSummaryKeys),
      );
}
