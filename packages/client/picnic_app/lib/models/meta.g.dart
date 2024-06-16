// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MetaModelImpl _$$MetaModelImplFromJson(Map<String, dynamic> json) =>
    _$MetaModelImpl(
      currentPage: (json['currentPage'] as num).toInt(),
      itemCount: (json['itemCount'] as num).toInt(),
      itemsPerPage: (json['itemsPerPage'] as num).toInt(),
      totalItems: (json['totalItems'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

Map<String, dynamic> _$$MetaModelImplToJson(_$MetaModelImpl instance) =>
    <String, dynamic>{
      'currentPage': instance.currentPage,
      'itemCount': instance.itemCount,
      'itemsPerPage': instance.itemsPerPage,
      'totalItems': instance.totalItems,
      'totalPages': instance.totalPages,
    };
