// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchage_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchageProductImpl _$$PurchageProductImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchageProductImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      star_candy: (json['star_candy'] as num).toInt(),
      bonus_star_candy: (json['bonus_star_candy'] as num).toInt(),
    );

Map<String, dynamic> _$$PurchageProductImplToJson(
        _$PurchageProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'price': instance.price,
      'star_candy': instance.star_candy,
      'bonus_star_candy': instance.bonus_star_candy,
    };
