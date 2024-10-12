// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_scrap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostScrapModelImpl _$$PostScrapModelImplFromJson(Map<String, dynamic> json) =>
    _$PostScrapModelImpl(
      post_id: json['post_id'] as String,
      user_id: json['user_id'] as String,
      user_profiles: json['user_profiles'] == null
          ? null
          : UserProfilesModel.fromJson(
              json['user_profiles'] as Map<String, dynamic>),
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
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
      'post_id': instance.post_id,
      'user_id': instance.user_id,
      'user_profiles': instance.user_profiles,
      'created_at': instance.created_at.toIso8601String(),
      'updated_at': instance.updated_at.toIso8601String(),
      'board': instance.board,
      'post': instance.post,
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
