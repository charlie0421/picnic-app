import 'package:intl/intl.dart';
import 'package:picnic_app/models/vote/purchage_product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_product_provider.g.dart';

@riverpod
class PurchaseProductList extends _$PurchaseProductList {
  @override
  List<PurchageProduct> build() {
    return [
      PurchageProduct(
        id: 1,
        title: Intl.message('STAR 100'),
        price: 0.99,
        star_candy: 100,
        bonus_star_candy: 0,
      ),
      PurchageProduct(
        id: 2,
        title: Intl.message('STAR 200'),
        price: 1.99,
        star_candy: 200,
        bonus_star_candy: 25,
      ),
      PurchageProduct(
        id: 3,
        title: Intl.message('STAR 600'),
        price: 5.99,
        star_candy: 600,
        bonus_star_candy: 85,
      ),
      PurchageProduct(
        id: 4,
        title: Intl.message('STAR 1000'),
        price: 9.99,
        star_candy: 1000,
        bonus_star_candy: 150,
      ),
      PurchageProduct(
        id: 5,
        title: Intl.message('STAR 2000'),
        price: 19.99,
        star_candy: 2000,
        bonus_star_candy: 320,
      ),
      PurchageProduct(
        id: 6,
        title: Intl.message('STAR 3000'),
        price: 29.99,
        star_candy: 3000,
        bonus_star_candy: 540,
      ),
      PurchageProduct(
        id: 7,
        title: Intl.message('STAR 4000'),
        price: 39.99,
        star_candy: 4000,
        bonus_star_candy: 760,
      ),
      PurchageProduct(
        id: 8,
        title: Intl.message('STAR 5000'),
        price: 49.99,
        star_candy: 5000,
        bonus_star_candy: 1000,
      ),
    ];
  }
}
