// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/vote/artist_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArtistGroupModel _$ArtistGroupModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ArtistGroupModel', json, ($checkedConvert) {
      final val = _ArtistGroupModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as Map<String, dynamic>),
        image: $checkedConvert('image', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ArtistGroupModelToJson(_ArtistGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
    };
