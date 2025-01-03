// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/pic/comment_like.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserCommentLikeModelImpl _$$UserCommentLikeModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$UserCommentLikeModelImpl',
      json,
      ($checkedConvert) {
        final val = _$UserCommentLikeModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          userId: $checkedConvert('user_id', (v) => (v as num).toInt()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'userId': 'user_id', 'createdAt': 'created_at'},
    );

Map<String, dynamic> _$$UserCommentLikeModelImplToJson(
        _$UserCommentLikeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'created_at': instance.createdAt.toIso8601String(),
    };
