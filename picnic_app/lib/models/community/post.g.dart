// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostModelImpl _$$PostModelImplFromJson(Map<String, dynamic> json) =>
    _$PostModelImpl(
      post_id: json['post_id'] as String,
      user_id: json['user_id'] as String,
      board_id: json['board_id'] as String,
      title: json['title'] as String,
      content: json['content'] as List<dynamic>,
      view_count: (json['view_count'] as num).toInt(),
      is_hidden: json['is_hidden'] as bool,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      boards: BoardModel.fromJson(json['boards'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PostModelImplToJson(_$PostModelImpl instance) =>
    <String, dynamic>{
      'post_id': instance.post_id,
      'user_id': instance.user_id,
      'board_id': instance.board_id,
      'title': instance.title,
      'content': instance.content,
      'view_count': instance.view_count,
      'is_hidden': instance.is_hidden,
      'created_at': instance.created_at.toIso8601String(),
      'updated_at': instance.updated_at.toIso8601String(),
      'boards': instance.boards,
    };
