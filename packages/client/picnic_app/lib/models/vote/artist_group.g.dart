// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistGroupModelImpl _$$ArtistGroupModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtistGroupModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as Map<String, dynamic>,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$$ArtistGroupModelImplToJson(
        _$ArtistGroupModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
    };
