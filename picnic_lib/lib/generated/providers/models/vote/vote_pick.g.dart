// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/vote/vote_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VotePickModel _$VotePickModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_VotePickModel',
      json,
      ($checkedConvert) {
        final val = _VotePickModel(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          vote: $checkedConvert(
            'vote',
            (v) => VoteModel.fromJson(v as Map<String, dynamic>),
          ),
          voteItem: $checkedConvert(
            'vote_item',
            (v) => VoteItemModel.fromJson(v as Map<String, dynamic>),
          ),
          amount: $checkedConvert('amount', (v) => (v as num?)?.toInt()),
          starCandyUsage: $checkedConvert(
            'star_candy_usage',
            (v) => (v as num?)?.toInt(),
          ),
          starCandyBonusUsage: $checkedConvert(
            'star_candy_bonus_usage',
            (v) => (v as num?)?.toInt(),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteItem': 'vote_item',
        'starCandyUsage': 'star_candy_usage',
        'starCandyBonusUsage': 'star_candy_bonus_usage',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$VotePickModelToJson(_VotePickModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote': instance.vote.toJson(),
      'vote_item': instance.voteItem.toJson(),
      'amount': instance.amount,
      'star_candy_usage': instance.starCandyUsage,
      'star_candy_bonus_usage': instance.starCandyBonusUsage,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
