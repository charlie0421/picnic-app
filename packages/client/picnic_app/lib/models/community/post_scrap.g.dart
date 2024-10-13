// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_scrap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostScrapModelImpl _$$PostScrapModelImplFromJson(Map<String, dynamic> json) =>
    _$PostScrapModelImpl(
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      userProfiles: json['user_profiles'] == null
          ? null
          : UserProfilesModel.fromJson(
              json['user_profiles'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      board: json['board'] == null
          ? null
          : BoardModel.fromJson(json['board'] as Map<String, dynamic>),
      post: json['post'] == null
          ? null
          : PostModel.fromJson(json['post'] as Map<String, dynamic>),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$PostScrapModelImplToJson(
        _$PostScrapModelImpl instance) =>
    <String, dynamic>{
      'post_id': instance.postId,
      'user_id': instance.userId,
      'user_profiles': instance.userProfiles,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'board': instance.board,
      'post': instance.post,
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
