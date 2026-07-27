// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/vote/vote_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VoteUsageModel _$VoteUsageModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_VoteUsageModel',
      json,
      ($checkedConvert) {
        final val = _VoteUsageModel(
          cottonCandy: $checkedConvert(
            'cotton_candy_usage',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          bonusStarCandy: $checkedConvert(
            'star_candy_bonus_usage',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          starCandy: $checkedConvert(
            'star_candy_usage',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'cottonCandy': 'cotton_candy_usage',
        'bonusStarCandy': 'star_candy_bonus_usage',
        'starCandy': 'star_candy_usage',
      },
    );

Map<String, dynamic> _$VoteUsageModelToJson(
  _VoteUsageModel instance,
) => <String, dynamic>{
  'cotton_candy_usage': const WalletAmountConverter().toJson(
    instance.cottonCandy,
  ),
  'star_candy_bonus_usage': const WalletAmountConverter().toJson(
    instance.bonusStarCandy,
  ),
  'star_candy_usage': const WalletAmountConverter().toJson(instance.starCandy),
};

_VoteTransactionResultModel _$VoteTransactionResultModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_VoteTransactionResultModel',
  json,
  ($checkedConvert) {
    final val = _VoteTransactionResultModel(
      operationId: $checkedConvert('operation_id', (v) => v as String),
      replayed: $checkedConvert('replayed', (v) => v as bool),
      votePickId: $checkedConvert('votePickId', (v) => (v as num).toInt()),
      updatedVoteTotal: $checkedConvert(
        'updatedVoteTotal',
        (v) => (v as num).toInt(),
      ),
      addedVoteTotal: $checkedConvert(
        'addedVoteTotal',
        (v) => (v as num).toInt(),
      ),
      updatedAt: $checkedConvert(
        'updatedAt',
        (v) => DateTime.parse(v as String),
      ),
      usage: $checkedConvert(
        'usage',
        (v) => VoteUsageModel.fromJson(v as Map<String, dynamic>),
      ),
      wallet: $checkedConvert(
        'wallet',
        (v) => WalletSummaryModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'operationId': 'operation_id'},
);

Map<String, dynamic> _$VoteTransactionResultModelToJson(
  _VoteTransactionResultModel instance,
) => <String, dynamic>{
  'operation_id': instance.operationId,
  'replayed': instance.replayed,
  'votePickId': instance.votePickId,
  'updatedVoteTotal': instance.updatedVoteTotal,
  'addedVoteTotal': instance.addedVoteTotal,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'usage': instance.usage.toJson(),
  'wallet': instance.wallet.toJson(),
};
