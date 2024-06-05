// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentListModel _$CommentListModelFromJson(Map<String, dynamic> json) =>
    CommentListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CommentListModelToJson(CommentListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) => CommentModel(
      id: (json['id'] as num).toInt(),
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: json['user'] == null
          ? null
          : UserProfilesModel.fromJson(json['user'] as Map<String, dynamic>),
      myLike: json['myLike'] == null
          ? null
          : UserCommentLikeModel.fromJson(
              json['myLike'] as Map<String, dynamic>),
      likes: (json['likes'] as num).toInt(),
      content: json['content'] as String,
      parentId: (json['parentId'] as num?)?.toInt(),
      created_at: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CommentModelToJson(CommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'children': instance.children,
      'myLike': instance.myLike,
      'user': instance.user,
      'likes': instance.likes,
      'content': instance.content,
      'parentId': instance.parentId,
      'created_at': instance.created_at.toIso8601String(),
    };
