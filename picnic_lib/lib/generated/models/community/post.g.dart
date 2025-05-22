// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/community/post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostModelImpl _$$PostModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$PostModelImpl',
      json,
      ($checkedConvert) {
        final val = _$PostModelImpl(
          postId: $checkedConvert('post_id', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String?),
          userProfiles: $checkedConvert(
              'user_profiles',
              (v) => v == null
                  ? null
                  : UserProfilesModel.fromJson(v as Map<String, dynamic>)),
          boardId: $checkedConvert('board_id', (v) => v as String?),
          title: $checkedConvert('title', (v) => v as String?),
          content: $checkedConvert('content', (v) => v as List<dynamic>?),
          viewCount: $checkedConvert('view_count', (v) => (v as num?)?.toInt()),
          replyCount:
              $checkedConvert('reply_count', (v) => (v as num?)?.toInt()),
          isHidden: $checkedConvert('is_hidden', (v) => v as bool?),
          board: $checkedConvert(
              'boards',
              (v) => v == null
                  ? null
                  : BoardModel.fromJson(v as Map<String, dynamic>)),
          isAnonymous: $checkedConvert('is_anonymous', (v) => v as bool?),
          isScraped: $checkedConvert('is_scraped', (v) => v as bool?),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          deletedAt: $checkedConvert('deleted_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'postId': 'post_id',
        'userId': 'user_id',
        'userProfiles': 'user_profiles',
        'boardId': 'board_id',
        'viewCount': 'view_count',
        'replyCount': 'reply_count',
        'isHidden': 'is_hidden',
        'board': 'boards',
        'isAnonymous': 'is_anonymous',
        'isScraped': 'is_scraped',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'deletedAt': 'deleted_at'
      },
    );

Map<String, dynamic> _$$PostModelImplToJson(_$PostModelImpl instance) =>
    <String, dynamic>{
      'post_id': instance.postId,
      'user_id': instance.userId,
      'user_profiles': instance.userProfiles?.toJson(),
      'board_id': instance.boardId,
      'title': instance.title,
      'content': instance.content,
      'view_count': instance.viewCount,
      'reply_count': instance.replyCount,
      'is_hidden': instance.isHidden,
      'boards': instance.board?.toJson(),
      'is_anonymous': instance.isAnonymous,
      'is_scraped': instance.isScraped,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
