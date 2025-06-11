// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/vote_item_request_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteItemRequestUserImpl _$$VoteItemRequestUserImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VoteItemRequestUserImpl',
      json,
      ($checkedConvert) {
        final val = _$VoteItemRequestUserImpl(
          id: $checkedConvert('id', (v) => v as String),
          voteId: $checkedConvert('vote_id', (v) => (v as num).toInt()),
          userId: $checkedConvert('user_id', (v) => v as String),
          artistId: $checkedConvert('artist_id', (v) => (v as num).toInt()),
          status: $checkedConvert('status', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          artist: $checkedConvert(
              'artist',
              (v) => v == null
                  ? null
                  : ArtistModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteId': 'vote_id',
        'userId': 'user_id',
        'artistId': 'artist_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$$VoteItemRequestUserImplToJson(
        _$VoteItemRequestUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_id': instance.voteId,
      'user_id': instance.userId,
      'artist_id': instance.artistId,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'artist': instance.artist?.toJson(),
    };
