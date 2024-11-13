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
      birth_date: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      gender: json['gender'] as String?,
      artist_group: json['artist_group'] == null
          ? null
          : ArtistGroupModel.fromJson(
              json['artist_group'] as Map<String, dynamic>),
      image: json['image'] as String?,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updated_at: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      deleted_at: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      isBookmarked: json['isBookmarked'] as bool?,
    );

Map<String, dynamic> _$$ArtistModelImplToJson(_$ArtistModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'yy': instance.yy,
      'mm': instance.mm,
      'dd': instance.dd,
      'birth_date': instance.birth_date?.toIso8601String(),
      'gender': instance.gender,
      'artist_group': instance.artist_group,
      'image': instance.image,
      'created_at': instance.created_at?.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
      'deleted_at': instance.deleted_at?.toIso8601String(),
      'isBookmarked': instance.isBookmarked,
    };
