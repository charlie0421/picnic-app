// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/wallet/wallet_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletSummaryModel _$WalletSummaryModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_WalletSummaryModel',
      json,
      ($checkedConvert) {
        final val = _WalletSummaryModel(
          contractVersion: $checkedConvert(
            'contract_version',
            (v) => v as String,
          ),
          star: $checkedConvert(
            'star',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          bonus: $checkedConvert(
            'bonus',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          cotton: $checkedConvert(
            'cotton',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          cottonExpiringAmount: $checkedConvert(
            'cotton_expiring_amount',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          cottonNextExpiresAt: $checkedConvert(
            'cotton_next_expires_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          snapshotAt: $checkedConvert(
            'snapshot_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'contractVersion': 'contract_version',
        'cottonExpiringAmount': 'cotton_expiring_amount',
        'cottonNextExpiresAt': 'cotton_next_expires_at',
        'snapshotAt': 'snapshot_at',
      },
    );

Map<String, dynamic> _$WalletSummaryModelToJson(_WalletSummaryModel instance) =>
    <String, dynamic>{
      'contract_version': instance.contractVersion,
      'star': const WalletAmountConverter().toJson(instance.star),
      'bonus': const WalletAmountConverter().toJson(instance.bonus),
      'cotton': const WalletAmountConverter().toJson(instance.cotton),
      'cotton_expiring_amount': const WalletAmountConverter().toJson(
        instance.cottonExpiringAmount,
      ),
      'cotton_next_expires_at': instance.cottonNextExpiresAt?.toIso8601String(),
      'snapshot_at': instance.snapshotAt.toIso8601String(),
    };
