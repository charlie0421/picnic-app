// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_like.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserCommentLikeModelImpl _$$UserCommentLikeModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserCommentLikeModelImpl(
      id: (json['id'] as num).toInt(),
      user_id: (json['user_id'] as num).toInt(),
      created_at: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$UserCommentLikeModelImplToJson(
        _$UserCommentLikeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'created_at': instance.created_at.toIso8601String(),
    };
