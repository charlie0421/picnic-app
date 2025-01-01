// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/artist.dart';

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
          birthDate: $checkedConvert('birth_date',
              (v) => v == null ? null : DateTime.parse(v as String)),
          gender: $checkedConvert('gender', (v) => v as String?),
          artistGroup: $checkedConvert(
              'artist_group',
              (v) => v == null
                  ? null
                  : ArtistGroupModel.fromJson(v as Map<String, dynamic>)),
          image: $checkedConvert('image', (v) => v as String?),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          deletedAt: $checkedConvert('deleted_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          isBookmarked: $checkedConvert('isBookmarked', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'birthDate': 'birth_date',
        'artistGroup': 'artist_group',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'deletedAt': 'deleted_at'
      },
    );

Map<String, dynamic> _$$ArtistModelImplToJson(_$ArtistModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'yy': instance.yy,
      'mm': instance.mm,
      'dd': instance.dd,
      'birth_date': instance.birthDate?.toIso8601String(),
      'gender': instance.gender,
      'artist_group': instance.artistGroup?.toJson(),
      'image': instance.image,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'isBookmarked': instance.isBookmarked,
    };
