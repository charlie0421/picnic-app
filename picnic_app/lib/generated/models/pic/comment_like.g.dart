// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/pic/comment_like.dart';

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
          user_id: $checkedConvert('user_id', (v) => (v as num).toInt()),
          created_at:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$UserCommentLikeModelImplToJson(
        _$UserCommentLikeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'created_at': instance.created_at.toIso8601String(),
    };
