// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteModelImpl _$$VoteModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VoteModelImpl',
      json,
      ($checkedConvert) {
        final val = _$VoteModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
          voteCategory: $checkedConvert('vote_category', (v) => v as String?),
          mainImage: $checkedConvert('main_image', (v) => v as String?),
          waitImage: $checkedConvert('wait_image', (v) => v as String?),
          resultImage: $checkedConvert('result_image', (v) => v as String?),
          voteContent: $checkedConvert('vote_content', (v) => v as String?),
          voteItem: $checkedConvert(
              'vote_item',
              (v) => (v as List<dynamic>?)
                  ?.map(
                      (e) => VoteItemModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          visibleAt: $checkedConvert('visible_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          stopAt: $checkedConvert(
              'stop_at', (v) => v == null ? null : DateTime.parse(v as String)),
          startAt: $checkedConvert('start_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          isEnded: $checkedConvert('is_ended', (v) => v as bool?),
          isUpcoming: $checkedConvert('is_upcoming', (v) => v as bool?),
          isPartnership: $checkedConvert('is_partnership', (v) => v as bool?),
          partner: $checkedConvert('partner', (v) => v as String?),
          reward: $checkedConvert(
              'reward',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => RewardModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteCategory': 'vote_category',
        'mainImage': 'main_image',
        'waitImage': 'wait_image',
        'resultImage': 'result_image',
        'voteContent': 'vote_content',
        'voteItem': 'vote_item',
        'createdAt': 'created_at',
        'visibleAt': 'visible_at',
        'stopAt': 'stop_at',
        'startAt': 'start_at',
        'isEnded': 'is_ended',
        'isUpcoming': 'is_upcoming',
        'isPartnership': 'is_partnership'
      },
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
      'vote_item': instance.voteItem?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt?.toIso8601String(),
      'visible_at': instance.visibleAt?.toIso8601String(),
      'stop_at': instance.stopAt?.toIso8601String(),
      'start_at': instance.startAt?.toIso8601String(),
      'is_ended': instance.isEnded,
      'is_upcoming': instance.isUpcoming,
      'is_partnership': instance.isPartnership,
      'partner': instance.partner,
      'reward': instance.reward?.map((e) => e.toJson()).toList(),
    };

_$VoteItemModelImpl _$$VoteItemModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VoteItemModelImpl',
      json,
      ($checkedConvert) {
        final val = _$VoteItemModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          voteTotal: $checkedConvert('vote_total', (v) => (v as num?)?.toInt()),
          voteId: $checkedConvert('vote_id', (v) => (v as num).toInt()),
          artist: $checkedConvert(
              'artist',
              (v) => v == null
                  ? null
                  : ArtistModel.fromJson(v as Map<String, dynamic>)),
          artistGroup: $checkedConvert(
              'artist_group',
              (v) => v == null
                  ? null
                  : ArtistGroupModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteTotal': 'vote_total',
        'voteId': 'vote_id',
        'artistGroup': 'artist_group'
      },
    );

Map<String, dynamic> _$$VoteItemModelImplToJson(_$VoteItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.voteTotal,
      'vote_id': instance.voteId,
      'artist': instance.artist?.toJson(),
      'artist_group': instance.artistGroup?.toJson(),
    };

_$VoteAchieveImpl _$$VoteAchieveImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VoteAchieveImpl',
      json,
      ($checkedConvert) {
        final val = _$VoteAchieveImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          voteId: $checkedConvert('vote_id', (v) => (v as num).toInt()),
          rewardId: $checkedConvert('reward_id', (v) => (v as num).toInt()),
          order: $checkedConvert('order', (v) => (v as num).toInt()),
          amount: $checkedConvert('amount', (v) => (v as num).toInt()),
          reward: $checkedConvert(
              'reward', (v) => RewardModel.fromJson(v as Map<String, dynamic>)),
          vote: $checkedConvert(
              'vote', (v) => VoteModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'voteId': 'vote_id', 'rewardId': 'reward_id'},
    );

Map<String, dynamic> _$$VoteAchieveImplToJson(_$VoteAchieveImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_id': instance.voteId,
      'reward_id': instance.rewardId,
      'order': instance.order,
      'amount': instance.amount,
      'reward': instance.reward.toJson(),
      'vote': instance.vote.toJson(),
    };
