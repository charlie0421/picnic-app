// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_like.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCommentLikeListModel _$UserCommentLikeListModelFromJson(
        Map<String, dynamic> json) =>
    UserCommentLikeListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => UserCommentLikeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserCommentLikeListModelToJson(
        UserCommentLikeListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

UserCommentLikeModel _$UserCommentLikeModelFromJson(
        Map<String, dynamic> json) =>
    UserCommentLikeModel(
      id: (json['id'] as num).toInt(),
      user_id: (json['user_id'] as num).toInt(),
      created_at: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserCommentLikeModelToJson(
        UserCommentLikeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'created_at': instance.created_at.toIso8601String(),
    };
