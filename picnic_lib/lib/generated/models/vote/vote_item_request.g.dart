// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/vote_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteItemRequestImpl _$$VoteItemRequestImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VoteItemRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$VoteItemRequestImpl(
          id: $checkedConvert('id', (v) => v as String),
          voteId: $checkedConvert('vote_id', (v) => (v as num).toInt()),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteId': 'vote_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$$VoteItemRequestImplToJson(
        _$VoteItemRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_id': instance.voteId,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
