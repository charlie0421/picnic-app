// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/vote/artist_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistGroupModelImpl _$$ArtistGroupModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArtistGroupModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArtistGroupModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as Map<String, dynamic>),
          image: $checkedConvert('image', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ArtistGroupModelImplToJson(
        _$ArtistGroupModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
    };
