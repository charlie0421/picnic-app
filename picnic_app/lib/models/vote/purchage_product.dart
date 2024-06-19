import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'purchage_product.freezed.dart';
part 'purchage_product.g.dart';

@reflector
@freezed
class PurchageProduct with _$PurchageProduct {
  const PurchageProduct._();

  const factory PurchageProduct({
    required int id,
    required String title,
    required double price,
    required int star_candy,
    required int bonus_star_candy,
  }) = _PurchageProduct;

  factory PurchageProduct.fromJson(Map<String, dynamic> json) =>
      _$PurchageProductFromJson(json);
}
