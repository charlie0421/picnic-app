// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostModelImpl _$$PostModelImplFromJson(Map<String, dynamic> json) =>
    _$PostModelImpl(
      post_id: json['post_id'] as String,
      user_id: json['user_id'] as String,
      user_profiles: json['user_profiles'] == null
          ? null
          : UserProfilesModel.fromJson(
              json['user_profiles'] as Map<String, dynamic>),
      board_id: json['board_id'] as String,
      title: json['title'] as String,
      content: json['content'] as List<dynamic>,
      view_count: (json['view_count'] as num).toInt(),
      reply_count: (json['reply_count'] as num).toInt(),
      is_hidden: json['is_hidden'] as bool,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      board: json['board'] == null
          ? null
          : BoardModel.fromJson(json['board'] as Map<String, dynamic>),
      is_anonymous: json['is_anonymous'] as bool,
      is_scraped: json['is_scraped'] as bool?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$PostModelImplToJson(_$PostModelImpl instance) =>
    <String, dynamic>{
      'post_id': instance.post_id,
      'user_id': instance.user_id,
      'user_profiles': instance.user_profiles,
      'board_id': instance.board_id,
      'title': instance.title,
      'content': instance.content,
      'view_count': instance.view_count,
      'reply_count': instance.reply_count,
      'is_hidden': instance.is_hidden,
      'created_at': instance.created_at.toIso8601String(),
      'updated_at': instance.updated_at.toIso8601String(),
      'board': instance.board,
      'is_anonymous': instance.is_anonymous,
      'is_scraped': instance.is_scraped,
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
