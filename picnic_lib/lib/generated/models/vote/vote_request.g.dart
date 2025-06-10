// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/vote_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteRequestImpl _$$VoteRequestImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VoteRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$VoteRequestImpl(
          id: $checkedConvert('id', (v) => v as String),
          voteId: $checkedConvert('vote_id', (v) => v as String),
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

Map<String, dynamic> _$$VoteRequestImplToJson(_$VoteRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_id': instance.voteId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
