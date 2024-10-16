// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteModelImpl _$$VoteModelImplFromJson(Map<String, dynamic> json) =>
    _$VoteModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as Map<String, dynamic>,
      voteCategory: json['vote_category'] as String?,
      mainImage: json['main_image'] as String?,
      waitImage: json['wait_image'] as String?,
      resultImage: json['result_image'] as String?,
      voteContent: json['vote_content'] as String?,
      voteItem: (json['vote_item'] as List<dynamic>?)
          ?.map((e) => VoteItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      visibleAt: DateTime.parse(json['visible_at'] as String),
      stopAt: DateTime.parse(json['stop_at'] as String),
      startAt: DateTime.parse(json['start_at'] as String),
      isEnded: json['is_ended'] as bool?,
      isUpcoming: json['is_upcoming'] as bool?,
      reward: (json['reward'] as List<dynamic>?)
          ?.map((e) => RewardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$VoteModelImplToJson(_$VoteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'vote_category': instance.voteCategory,
      'main_image': instance.mainImage,
      'wait_image': instance.waitImage,
      'result_image': instance.resultImage,
      'vote_content': instance.voteContent,
      'vote_item': instance.voteItem,
      'created_at': instance.createdAt?.toIso8601String(),
      'visible_at': instance.visibleAt.toIso8601String(),
      'stop_at': instance.stopAt.toIso8601String(),
      'start_at': instance.startAt.toIso8601String(),
      'is_ended': instance.isEnded,
      'is_upcoming': instance.isUpcoming,
      'reward': instance.reward,
    };

_$VoteItemModelImpl _$$VoteItemModelImplFromJson(Map<String, dynamic> json) =>
    _$VoteItemModelImpl(
      id: (json['id'] as num).toInt(),
      voteTotal: (json['vote_total'] as num).toInt(),
      voteId: (json['vote_id'] as num).toInt(),
      artist: ArtistModel.fromJson(json['artist'] as Map<String, dynamic>),
      artistGroup: ArtistGroupModel.fromJson(
          json['artist_group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VoteItemModelImplToJson(_$VoteItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.voteTotal,
      'vote_id': instance.voteId,
      'artist': instance.artist,
      'artist_group': instance.artistGroup,
    };
