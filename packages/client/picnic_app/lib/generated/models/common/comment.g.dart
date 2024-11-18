// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/common/comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$CommentModelImpl',
      json,
      ($checkedConvert) {
        final val = _$CommentModelImpl(
          commentId: $checkedConvert('comment_id', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String?),
          children: $checkedConvert(
              'children',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          myLike: $checkedConvert(
              'my_like',
              (v) => v == null
                  ? null
                  : UserCommentLikeModel.fromJson(v as Map<String, dynamic>)),
          user: $checkedConvert(
              'user_profiles',
              (v) => v == null
                  ? null
                  : UserProfilesModel.fromJson(v as Map<String, dynamic>)),
          likes: $checkedConvert('likes', (v) => (v as num).toInt()),
          replies: $checkedConvert('replies', (v) => (v as num).toInt()),
          content:
              $checkedConvert('content', (v) => v as Map<String, dynamic>?),
          isLikedByMe: $checkedConvert('is_liked_by_me', (v) => v as bool?),
          isReportedByMe:
              $checkedConvert('is_reported_by_me', (v) => v as bool?),
          isBlindedByAdmin:
              $checkedConvert('is_blinded_by_admin', (v) => v as bool?),
          isRepliedByMe: $checkedConvert('is_replied_by_me', (v) => v as bool?),
          post: $checkedConvert(
              'post',
              (v) => v == null
                  ? null
                  : PostModel.fromJson(v as Map<String, dynamic>)),
          locale: $checkedConvert('locale', (v) => v as String?),
          parentCommentId:
              $checkedConvert('parent_comment_id', (v) => v as String?),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          deletedAt: $checkedConvert('deleted_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'commentId': 'comment_id',
        'userId': 'user_id',
        'myLike': 'my_like',
        'user': 'user_profiles',
        'isLikedByMe': 'is_liked_by_me',
        'isReportedByMe': 'is_reported_by_me',
        'isBlindedByAdmin': 'is_blinded_by_admin',
        'isRepliedByMe': 'is_replied_by_me',
        'parentCommentId': 'parent_comment_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'deletedAt': 'deleted_at'
      },
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'comment_id': instance.commentId,
      'user_id': instance.userId,
      'children': instance.children?.map((e) => e.toJson()).toList(),
      'my_like': instance.myLike?.toJson(),
      'user_profiles': instance.user?.toJson(),
      'likes': instance.likes,
      'replies': instance.replies,
      'content': instance.content,
      'is_liked_by_me': instance.isLikedByMe,
      'is_reported_by_me': instance.isReportedByMe,
      'is_blinded_by_admin': instance.isBlindedByAdmin,
      'is_replied_by_me': instance.isRepliedByMe,
      'post': instance.post?.toJson(),
      'locale': instance.locale,
      'parent_comment_id': instance.parentCommentId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
