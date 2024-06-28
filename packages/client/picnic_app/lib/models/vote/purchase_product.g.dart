// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseProductImpl _$$PurchaseProductImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseProductImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      star_candy: (json['star_candy'] as num).toInt(),
      bonus_star_candy: (json['bonus_star_candy'] as num).toInt(),
      productDetails: const ProductDetailsConverter()
          .fromJson(json['productDetails'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$$PurchaseProductImplToJson(
        _$PurchaseProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'price': instance.price,
      'star_candy': instance.star_candy,
      'bonus_star_candy': instance.bonus_star_candy,
      'productDetails':
          const ProductDetailsConverter().toJson(instance.productDetails),
    };
