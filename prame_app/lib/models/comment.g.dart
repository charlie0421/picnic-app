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
      id: json['id'] as int,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      myLike: json['myLike'] == null
          ? null
          : UserCommentLikeModel.fromJson(
              json['myLike'] as Map<String, dynamic>),
      likes: json['likes'] as int,
      content: json['content'] as String,
      article: ArticleModel.fromJson(json['article'] as Map<String, dynamic>),
      parentId: json['parentId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CommentModelToJson(CommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'children': instance.children,
      'myLike': instance.myLike,
      'user': instance.user,
      'likes': instance.likes,
      'content': instance.content,
      'article': instance.article,
      'parentId': instance.parentId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
