// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistModelImpl _$$ArtistModelImplFromJson(Map<String, dynamic> json) =>
    _$ArtistModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as Map<String, dynamic>,
      yy: (json['yy'] as num?)?.toInt(),
      mm: (json['mm'] as num?)?.toInt(),
      dd: (json['dd'] as num?)?.toInt(),
      gender: json['gender'] as String,
      image: json['image'] as String,
      artist_group: ArtistGroupModel.fromJson(
          json['artist_group'] as Map<String, dynamic>),
      isBookmarked: json['isBookmarked'] as bool?,
      originalIndex: (json['originalIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ArtistModelImplToJson(_$ArtistModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'yy': instance.yy,
      'mm': instance.mm,
      'dd': instance.dd,
      'gender': instance.gender,
      'image': instance.image,
      'artist_group': instance.artist_group,
      'isBookmarked': instance.isBookmarked,
      'originalIndex': instance.originalIndex,
    };
