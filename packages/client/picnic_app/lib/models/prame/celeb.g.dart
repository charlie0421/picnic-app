// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celeb.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CelebListModel _$CelebListModelFromJson(Map<String, dynamic> json) =>
    CelebListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => CelebModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CelebListModelToJson(CelebListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

CelebModel _$CelebModelFromJson(Map<String, dynamic> json) => CelebModel(
      id: (json['id'] as num).toInt(),
      name_ko: json['name_ko'] as String,
      name_en: json['name_en'] as String,
      thumbnail: json['thumbnail'] as String?,
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CelebModelToJson(CelebModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.name_ko,
      'name_en': instance.name_en,
      'thumbnail': instance.thumbnail,
      'users': instance.users,
    };
