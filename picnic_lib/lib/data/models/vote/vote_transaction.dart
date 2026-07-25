import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

part '../../../generated/providers/models/vote/vote_transaction.freezed.dart';
part '../../../generated/providers/models/vote/vote_transaction.g.dart';

const _voteResultKeys = {
  'operation_id',
  'replayed',
  'votePickId',
  'updatedVoteTotal',
  'addedVoteTotal',
  'updatedAt',
  'usage',
  'wallet',
};
const _voteUsageKeys = {
  'cotton_candy_usage',
  'star_candy_bonus_usage',
  'star_candy_usage',
};

@freezed
abstract class VoteTransactionRequest with _$VoteTransactionRequest {
  const factory VoteTransactionRequest({
    required int voteId,
    required int voteItemId,
    required BigInt amount,
    required String requestId,
  }) = _VoteTransactionRequest;
}

@freezed
abstract class VoteUsageModel with _$VoteUsageModel {
  const factory VoteUsageModel({
    @JsonKey(name: 'cotton_candy_usage')
    @WalletAmountConverter()
    required BigInt cottonCandy,
    @JsonKey(name: 'star_candy_bonus_usage')
    @WalletAmountConverter()
    required BigInt bonusStarCandy,
    @JsonKey(name: 'star_candy_usage')
    @WalletAmountConverter()
    required BigInt starCandy,
  }) = _VoteUsageModel;

  factory VoteUsageModel.fromJson(Map<String, dynamic> json) =>
      _$VoteUsageModelFromJson(requireExactContractKeys(json, _voteUsageKeys));
}

@freezed
abstract class VoteTransactionResultModel with _$VoteTransactionResultModel {
  const VoteTransactionResultModel._();

  const factory VoteTransactionResultModel({
    @JsonKey(name: 'operation_id') required String operationId,
    required bool replayed,
    @JsonKey(name: 'votePickId') required int votePickId,
    @JsonKey(name: 'updatedVoteTotal') required int updatedVoteTotal,
    @JsonKey(name: 'addedVoteTotal') required int addedVoteTotal,
    @JsonKey(name: 'updatedAt') required DateTime updatedAt,
    required VoteUsageModel usage,
    required WalletSummaryModel wallet,
  }) = _VoteTransactionResultModel;

  Map<String, dynamic> toLegacyDialogMap() => {
    'operation_id': operationId,
    'replayed': replayed,
    'votePickId': votePickId,
    'updatedVoteTotal': updatedVoteTotal,
    'addedVoteTotal': addedVoteTotal,
    'updatedAt': updatedAt.toIso8601String(),
    'usage': usage.toJson(),
    'wallet': wallet.toJson(),
  };

  factory VoteTransactionResultModel.fromJson(Map<String, dynamic> json) =>
      _$VoteTransactionResultModelFromJson(
        requireExactContractKeys(json, _voteResultKeys),
      );
}
