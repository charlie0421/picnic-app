// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/common/popup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PopupImpl _$$PopupImplFromJson(Map<String, dynamic> json) => $checkedCreate(
      r'_$PopupImpl',
      json,
      ($checkedConvert) {
        final val = _$PopupImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          title: $checkedConvert(
              'title', (v) => Map<String, String>.from(v as Map)),
          content: $checkedConvert(
              'content', (v) => Map<String, String>.from(v as Map)),
          image: $checkedConvert(
              'image',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as String),
                  )),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          deletedAt: $checkedConvert('deleted_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          startAt: $checkedConvert('start_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          stopAt: $checkedConvert(
              'stop_at', (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'deletedAt': 'deleted_at',
        'startAt': 'start_at',
        'stopAt': 'stop_at'
      },
    );

Map<String, dynamic> _$$PopupImplToJson(_$PopupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'image': instance.image,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'start_at': instance.startAt?.toIso8601String(),
      'stop_at': instance.stopAt?.toIso8601String(),
    };
