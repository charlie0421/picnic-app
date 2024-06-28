import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_app/reflector.dart';

part 'purchase_product.freezed.dart';
part 'purchase_product.g.dart';

@reflector
@freezed
class PurchaseProduct with _$PurchaseProduct {
  const PurchaseProduct._();

  const factory PurchaseProduct({
    required String id,
    required String title,
    required double price,
    required int star_candy,
    required int bonus_star_candy,
    @ProductDetailsConverter() ProductDetails? productDetails,
  }) = _PurchaseProduct;

  factory PurchaseProduct.fromJson(Map<String, dynamic> json) =>
      _$PurchaseProductFromJson(json);
}

class ProductDetailsConverter
    implements JsonConverter<ProductDetails?, Map<String, dynamic>?> {
  const ProductDetailsConverter();

  @override
  ProductDetails? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    // You need to fill in the details of how to create a ProductDetails object from JSON.
    // This is just a placeholder.
    return ProductDetails(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'],
      rawPrice: json['price'],
      currencyCode: json['countryCode'],
    );
  }

  @override
  Map<String, dynamic>? toJson(ProductDetails? object) {
    if (object == null) {
      return null;
    }

    // You need to fill in the details of how to convert a ProductDetails object to JSON.
    // This is just a placeholder.
    return {
      'id': object.id,
      'title': object.title,
      'description': object.description,
      'price': object.price,
    };
  }
}
