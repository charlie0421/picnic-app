// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentListModelImpl _$$CommentListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$CommentListModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CommentListModelImplToJson(
        _$CommentListModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      commentId: json['comment_id'] as String,
      userId: json['user_id'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      myLike: json['myLike'] == null
          ? null
          : UserCommentLikeModel.fromJson(
              json['myLike'] as Map<String, dynamic>),
      user: json['user'] == null
          ? null
          : UserProfilesModel.fromJson(json['user'] as Map<String, dynamic>),
      likes: (json['likes'] as num).toInt(),
      replies: (json['replies'] as num).toInt(),
      content: json['content'] as String,
      isLiked: json['isLiked'] as bool?,
      isReplied: json['isReplied'] as bool?,
      parentCommentId: json['parent_comment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'comment_id': instance.commentId,
      'user_id': instance.userId,
      'children': instance.children,
      'myLike': instance.myLike,
      'user': instance.user,
      'likes': instance.likes,
      'replies': instance.replies,
      'content': instance.content,
      'isLiked': instance.isLiked,
      'isReplied': instance.isReplied,
      'parent_comment_id': instance.parentCommentId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
