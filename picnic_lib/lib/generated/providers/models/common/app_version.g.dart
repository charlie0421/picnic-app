// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/common/app_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppVersionModel _$AppVersionModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AppVersionModel', json, ($checkedConvert) {
      final val = _AppVersionModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        ios: $checkedConvert('ios', (v) => v as Map<String, dynamic>),
        android: $checkedConvert('android', (v) => v as Map<String, dynamic>),
        macos: $checkedConvert('macos', (v) => v as Map<String, dynamic>),
        windows: $checkedConvert('windows', (v) => v as Map<String, dynamic>),
        linux: $checkedConvert('linux', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

Map<String, dynamic> _$AppVersionModelToJson(_AppVersionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ios': instance.ios,
      'android': instance.android,
      'macos': instance.macos,
      'windows': instance.windows,
      'linux': instance.linux,
    };
