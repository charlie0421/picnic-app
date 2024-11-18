// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/community/post_scrap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostScrapModelImpl _$$PostScrapModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$PostScrapModelImpl',
      json,
      ($checkedConvert) {
        final val = _$PostScrapModelImpl(
          postId: $checkedConvert('post_id', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String),
          userProfiles: $checkedConvert(
              'user_profiles',
              (v) => v == null
                  ? null
                  : UserProfilesModel.fromJson(v as Map<String, dynamic>)),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          board: $checkedConvert(
              'board',
              (v) => v == null
                  ? null
                  : BoardModel.fromJson(v as Map<String, dynamic>)),
          post: $checkedConvert(
              'post',
              (v) => v == null
                  ? null
                  : PostModel.fromJson(v as Map<String, dynamic>)),
          deletedAt: $checkedConvert('deleted_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'postId': 'post_id',
        'userId': 'user_id',
        'userProfiles': 'user_profiles',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'deletedAt': 'deleted_at'
      },
    );

Map<String, dynamic> _$$PostScrapModelImplToJson(
        _$PostScrapModelImpl instance) =>
    <String, dynamic>{
      'post_id': instance.postId,
      'user_id': instance.userId,
      'user_profiles': instance.userProfiles?.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'board': instance.board?.toJson(),
      'post': instance.post?.toJson(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
