// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostModelImpl _$$PostModelImplFromJson(Map<String, dynamic> json) =>
    _$PostModelImpl(
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      userProfiles: json['user_profiles'] == null
          ? null
          : UserProfilesModel.fromJson(
              json['user_profiles'] as Map<String, dynamic>),
      boardId: json['board_id'] as String,
      title: json['title'] as String,
      content: json['content'] as List<dynamic>,
      viewCount: (json['view_count'] as num).toInt(),
      replyCount: (json['reply_count'] as num).toInt(),
      isHidden: json['is_hidden'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      board: json['board'] == null
          ? null
          : BoardModel.fromJson(json['board'] as Map<String, dynamic>),
      isAnonymous: json['is_anonymous'] as bool,
      isScraped: json['is_scraped'] as bool?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$PostModelImplToJson(_$PostModelImpl instance) =>
    <String, dynamic>{
      'post_id': instance.postId,
      'user_id': instance.userId,
      'user_profiles': instance.userProfiles,
      'board_id': instance.boardId,
      'title': instance.title,
      'content': instance.content,
      'view_count': instance.viewCount,
      'reply_count': instance.replyCount,
      'is_hidden': instance.isHidden,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'board': instance.board,
      'is_anonymous': instance.isAnonymous,
      'is_scraped': instance.isScraped,
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
