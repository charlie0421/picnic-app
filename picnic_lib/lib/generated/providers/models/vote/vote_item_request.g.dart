// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/vote/vote_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VoteItemRequest _$VoteItemRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_VoteItemRequest',
      json,
      ($checkedConvert) {
        final val = _VoteItemRequest(
          id: $checkedConvert('id', (v) => v as String),
          voteId: $checkedConvert('vote_id', (v) => (v as num).toInt()),
          status: $checkedConvert('status', (v) => v as String),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteId': 'vote_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$VoteItemRequestToJson(_VoteItemRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_id': instance.voteId,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
