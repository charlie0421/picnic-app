// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/vote/purchase_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PurchaseProduct _$PurchaseProductFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_PurchaseProduct',
      json,
      ($checkedConvert) {
        final val = _PurchaseProduct(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          price: $checkedConvert('price', (v) => (v as num).toDouble()),
          starCandy: $checkedConvert('star_candy', (v) => (v as num).toInt()),
          bonusStarCandy: $checkedConvert(
            'bonus_star_candy',
            (v) => (v as num).toInt(),
          ),
          productDetails: $checkedConvert(
            'product_details',
            (v) => const ProductDetailsConverter().fromJson(
              v as Map<String, dynamic>?,
            ),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'starCandy': 'star_candy',
        'bonusStarCandy': 'bonus_star_candy',
        'productDetails': 'product_details',
      },
    );

Map<String, dynamic> _$PurchaseProductToJson(_PurchaseProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'price': instance.price,
      'star_candy': instance.starCandy,
      'bonus_star_candy': instance.bonusStarCandy,
      'product_details': const ProductDetailsConverter().toJson(
        instance.productDetails,
      ),
    };
