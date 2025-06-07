// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/vote_request_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteRequestUserImpl _$$VoteRequestUserImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VoteRequestUserImpl',
      json,
      ($checkedConvert) {
        final val = _$VoteRequestUserImpl(
          id: $checkedConvert('id', (v) => v as String),
          voteRequestId: $checkedConvert('vote_request_id', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteRequestId': 'vote_request_id',
        'userId': 'user_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$$VoteRequestUserImplToJson(
        _$VoteRequestUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_request_id': instance.voteRequestId,
      'user_id': instance.userId,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
