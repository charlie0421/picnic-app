// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetaModel _$MetaModelFromJson(Map<String, dynamic> json) => MetaModel(
      currentPage: json['currentPage'] as int,
      itemCount: json['itemCount'] as int,
      itemsPerPage: json['itemsPerPage'] as int,
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
    );

Map<String, dynamic> _$MetaModelToJson(MetaModel instance) => <String, dynamic>{
      'currentPage': instance.currentPage,
      'itemCount': instance.itemCount,
      'itemsPerPage': instance.itemsPerPage,
      'totalItems': instance.totalItems,
      'totalPages': instance.totalPages,
    };
