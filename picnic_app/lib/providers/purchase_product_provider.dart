import 'package:intl/intl.dart';
import 'package:picnic_app/models/vote/purchase_product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/providers/purchase_product_provider.g.dart';

@riverpod
class PurchaseProductList extends _$PurchaseProductList {
  @override
  List<PurchaseProduct> build() {
    return [
      PurchaseProduct(
        id: 'STAR100',
        title: Intl.message('STARCANDY100'),
        price: 0.99,
        star_candy: 100,
        bonus_star_candy: 0,
      ),
      PurchaseProduct(
        id: 'STAR200',
        title: Intl.message('STARCANDY200'),
        price: 1.99,
        star_candy: 200,
        bonus_star_candy: 25,
      ),
      PurchaseProduct(
        id: 'STAR600',
        title: Intl.message('STARCANDY600'),
        price: 5.99,
        star_candy: 600,
        bonus_star_candy: 85,
      ),
      PurchaseProduct(
        id: 'STAR1000',
        title: Intl.message('STARCANDY1000'),
        price: 9.99,
        star_candy: 1000,
        bonus_star_candy: 150,
      ),
      PurchaseProduct(
        id: 'STAR2000',
        title: Intl.message('STARCANDY2000'),
        price: 19.99,
        star_candy: 2000,
        bonus_star_candy: 320,
      ),
      PurchaseProduct(
        id: 'STAR3000',
        title: Intl.message('STARCANDY3000'),
        price: 29.99,
        star_candy: 3000,
        bonus_star_candy: 540,
      ),
      PurchaseProduct(
        id: 'STAR4000',
        title: Intl.message('STARCANDY4000'),
        price: 39.99,
        star_candy: 4000,
        bonus_star_candy: 760,
      ),
      PurchaseProduct(
        id: 'STAR5000',
        title: Intl.message('STARCANDY5000'),
        price: 49.99,
        star_candy: 5000,
        bonus_star_candy: 1000,
      ),
    ];
  }
}
