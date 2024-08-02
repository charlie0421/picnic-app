// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppVersionModelImpl _$$AppVersionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AppVersionModelImpl(
      id: (json['id'] as num).toInt(),
      ios: json['ios'] as Map<String, dynamic>,
      android: json['android'] as Map<String, dynamic>,
      macos: json['macos'] as Map<String, dynamic>,
      windows: json['windows'] as Map<String, dynamic>,
      linux: json['linux'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$AppVersionModelImplToJson(
        _$AppVersionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ios': instance.ios,
      'android': instance.android,
      'macos': instance.macos,
      'windows': instance.windows,
      'linux': instance.linux,
    };
