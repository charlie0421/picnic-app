// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/vote_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VotePickModelImpl _$$VotePickModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VotePickModelImpl',
      json,
      ($checkedConvert) {
        final val = _$VotePickModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          vote: $checkedConvert(
              'vote', (v) => VoteModel.fromJson(v as Map<String, dynamic>)),
          voteItem: $checkedConvert('vote_item',
              (v) => VoteItemModel.fromJson(v as Map<String, dynamic>)),
          amount: $checkedConvert('amount', (v) => (v as num?)?.toInt()),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteItem': 'vote_item',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$$VotePickModelImplToJson(_$VotePickModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote': instance.vote.toJson(),
      'vote_item': instance.voteItem.toJson(),
      'amount': instance.amount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
