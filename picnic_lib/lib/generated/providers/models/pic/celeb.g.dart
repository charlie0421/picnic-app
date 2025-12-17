// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/pic/celeb.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CelebModel _$CelebModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_CelebModel',
  json,
  ($checkedConvert) {
    final val = _CelebModel(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      nameKo: $checkedConvert('name_ko', (v) => v as String),
      nameEn: $checkedConvert('name_en', (v) => v as String),
      thumbnail: $checkedConvert('thumbnail', (v) => v as String?),
      users: $checkedConvert(
        'users',
        (v) => (v as List<dynamic>?)
            ?.map((e) => UserProfilesModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'nameKo': 'name_ko', 'nameEn': 'name_en'},
);

Map<String, dynamic> _$CelebModelToJson(_CelebModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.nameKo,
      'name_en': instance.nameEn,
      'thumbnail': instance.thumbnail,
      'users': instance.users?.map((e) => e.toJson()).toList(),
    };
