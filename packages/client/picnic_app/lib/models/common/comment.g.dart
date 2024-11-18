// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      user: json['user_profiles'] == null
          ? null
          : UserProfilesModel.fromJson(
              json['user_profiles'] as Map<String, dynamic>),
      likes: (json['likes'] as num).toInt(),
      replies: (json['replies'] as num).toInt(),
      content: json['content'] as Map<String, dynamic>?,
      isLikedByMe: json['isLikedByMe'] as bool?,
      isReportedByMe: json['isReportedByMe'] as bool?,
      isBlindedByAdmin: json['isBlindedByAdmin'] as bool?,
      isRepliedByMe: json['isRepliedByMe'] as bool?,
      post: json['post'] == null
          ? null
          : PostModel.fromJson(json['post'] as Map<String, dynamic>),
      locale: json['locale'] as String?,
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
      'user_profiles': instance.user,
      'likes': instance.likes,
      'replies': instance.replies,
      'content': instance.content,
      'isLikedByMe': instance.isLikedByMe,
      'isReportedByMe': instance.isReportedByMe,
      'isBlindedByAdmin': instance.isBlindedByAdmin,
      'isRepliedByMe': instance.isRepliedByMe,
      'post': instance.post,
      'locale': instance.locale,
      'parent_comment_id': instance.parentCommentId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
