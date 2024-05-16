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
      nameKo: json['nameKo'] as String,
      nameEn: json['nameEn'] as String,
      thumbnail: json['thumbnail'] as String,
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CelebModelToJson(CelebModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameKo': instance.nameKo,
      'nameEn': instance.nameEn,
      'thumbnail': instance.thumbnail,
      'users': instance.users,
    };
