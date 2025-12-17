// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/vote/vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VoteModel _$VoteModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_VoteModel',
  json,
  ($checkedConvert) {
    final val = _VoteModel(
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
            ?.map((e) => VoteItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      visibleAt: $checkedConvert(
        'visible_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      stopAt: $checkedConvert(
        'stop_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      startAt: $checkedConvert(
        'start_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      isEnded: $checkedConvert('is_ended', (v) => v as bool?),
      isUpcoming: $checkedConvert('is_upcoming', (v) => v as bool?),
      isPartnership: $checkedConvert('is_partnership', (v) => v as bool?),
      partner: $checkedConvert('partner', (v) => v as String?),
      reward: $checkedConvert(
        'reward',
        (v) => (v as List<dynamic>?)
            ?.map((e) => RewardModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
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
    'isPartnership': 'is_partnership',
  },
);

Map<String, dynamic> _$VoteModelToJson(_VoteModel instance) =>
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

_VoteItemModel _$VoteItemModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_VoteItemModel',
      json,
      ($checkedConvert) {
        final val = _VoteItemModel(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          voteTotal: $checkedConvert('vote_total', (v) => (v as num?)?.toInt()),
          starCandyTotal: $checkedConvert(
            'star_candy_total',
            (v) => (v as num?)?.toInt(),
          ),
          starCandyBonusTotal: $checkedConvert(
            'star_candy_bonus_total',
            (v) => (v as num?)?.toInt(),
          ),
          voteId: $checkedConvert('vote_id', (v) => (v as num).toInt()),
          artist: $checkedConvert(
            'artist',
            (v) => v == null
                ? null
                : ArtistModel.fromJson(v as Map<String, dynamic>),
          ),
          artistGroup: $checkedConvert(
            'artist_group',
            (v) => v == null
                ? null
                : ArtistGroupModel.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteTotal': 'vote_total',
        'starCandyTotal': 'star_candy_total',
        'starCandyBonusTotal': 'star_candy_bonus_total',
        'voteId': 'vote_id',
        'artistGroup': 'artist_group',
      },
    );

Map<String, dynamic> _$VoteItemModelToJson(_VoteItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.voteTotal,
      'star_candy_total': instance.starCandyTotal,
      'star_candy_bonus_total': instance.starCandyBonusTotal,
      'vote_id': instance.voteId,
      'artist': instance.artist?.toJson(),
      'artist_group': instance.artistGroup?.toJson(),
    };

_VoteAchieve _$VoteAchieveFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_VoteAchieve',
  json,
  ($checkedConvert) {
    final val = _VoteAchieve(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      voteId: $checkedConvert('vote_id', (v) => (v as num).toInt()),
      rewardId: $checkedConvert('reward_id', (v) => (v as num).toInt()),
      order: $checkedConvert('order', (v) => (v as num).toInt()),
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      reward: $checkedConvert(
        'reward',
        (v) => RewardModel.fromJson(v as Map<String, dynamic>),
      ),
      vote: $checkedConvert(
        'vote',
        (v) => VoteModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'voteId': 'vote_id', 'rewardId': 'reward_id'},
);

Map<String, dynamic> _$VoteAchieveToJson(_VoteAchieve instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_id': instance.voteId,
      'reward_id': instance.rewardId,
      'order': instance.order,
      'amount': instance.amount,
      'reward': instance.reward.toJson(),
      'vote': instance.vote.toJson(),
    };
