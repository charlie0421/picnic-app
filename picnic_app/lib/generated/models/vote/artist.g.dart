// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/vote/artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistModelImpl _$$ArtistModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArtistModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArtistModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as Map<String, dynamic>),
          yy: $checkedConvert('yy', (v) => (v as num?)?.toInt()),
          mm: $checkedConvert('mm', (v) => (v as num?)?.toInt()),
          dd: $checkedConvert('dd', (v) => (v as num?)?.toInt()),
          birth_date: $checkedConvert('birth_date',
              (v) => v == null ? null : DateTime.parse(v as String)),
          gender: $checkedConvert('gender', (v) => v as String?),
          artist_group: $checkedConvert(
              'artist_group',
              (v) => v == null
                  ? null
                  : ArtistGroupModel.fromJson(v as Map<String, dynamic>)),
          image: $checkedConvert('image', (v) => v as String?),
          created_at: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updated_at: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          deleted_at: $checkedConvert('deleted_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          isBookmarked: $checkedConvert('is_bookmarked', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {'isBookmarked': 'is_bookmarked'},
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
      'artist_group': instance.artist_group?.toJson(),
      'image': instance.image,
      'created_at': instance.created_at?.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
      'deleted_at': instance.deleted_at?.toIso8601String(),
      'is_bookmarked': instance.isBookmarked,
    };
