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
      id: json['id'] as int,
      userId: json['userId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserCommentLikeModelToJson(
        UserCommentLikeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
