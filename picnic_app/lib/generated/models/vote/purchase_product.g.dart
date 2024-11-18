// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/vote/purchase_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseProductImpl _$$PurchaseProductImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$PurchaseProductImpl',
      json,
      ($checkedConvert) {
        final val = _$PurchaseProductImpl(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          price: $checkedConvert('price', (v) => (v as num).toDouble()),
          star_candy: $checkedConvert('star_candy', (v) => (v as num).toInt()),
          bonus_star_candy:
              $checkedConvert('bonus_star_candy', (v) => (v as num).toInt()),
          productDetails: $checkedConvert(
              'product_details',
              (v) => const ProductDetailsConverter()
                  .fromJson(v as Map<String, dynamic>?)),
        );
        return val;
      },
      fieldKeyMap: const {'productDetails': 'product_details'},
    );

Map<String, dynamic> _$$PurchaseProductImplToJson(
        _$PurchaseProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'price': instance.price,
      'star_candy': instance.star_candy,
      'bonus_star_candy': instance.bonus_star_candy,
      'product_details':
          const ProductDetailsConverter().toJson(instance.productDetails),
    };
