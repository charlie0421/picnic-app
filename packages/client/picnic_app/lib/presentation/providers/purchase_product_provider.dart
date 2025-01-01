import 'package:intl/intl.dart';
import 'package:picnic_app/data/models/vote/purchase_product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/purchase_product_provider.g.dart';

@riverpod
class PurchaseProductList extends _$PurchaseProductList {
  @override
  List<PurchaseProduct> build() {
    return [
      PurchaseProduct(
        id: 'STAR100',
        title: Intl.message('STARCANDY100'),
        price: 0.99,
        starCandy: 100,
        bonusStarCandy: 0,
      ),
      PurchaseProduct(
        id: 'STAR200',
        title: Intl.message('STARCANDY200'),
        price: 1.99,
        starCandy: 200,
        bonusStarCandy: 25,
      ),
      PurchaseProduct(
        id: 'STAR600',
        title: Intl.message('STARCANDY600'),
        price: 5.99,
        starCandy: 600,
        bonusStarCandy: 85,
      ),
      PurchaseProduct(
        id: 'STAR1000',
        title: Intl.message('STARCANDY1000'),
        price: 9.99,
        starCandy: 1000,
        bonusStarCandy: 150,
      ),
      PurchaseProduct(
        id: 'STAR2000',
        title: Intl.message('STARCANDY2000'),
        price: 19.99,
        starCandy: 2000,
        bonusStarCandy: 320,
      ),
      PurchaseProduct(
        id: 'STAR3000',
        title: Intl.message('STARCANDY3000'),
        price: 29.99,
        starCandy: 3000,
        bonusStarCandy: 540,
      ),
      PurchaseProduct(
        id: 'STAR4000',
        title: Intl.message('STARCANDY4000'),
        price: 39.99,
        starCandy: 4000,
        bonusStarCandy: 760,
      ),
      PurchaseProduct(
        id: 'STAR5000',
        title: Intl.message('STARCANDY5000'),
        price: 49.99,
        starCandy: 5000,
        bonusStarCandy: 1000,
      ),
    ];
  }
}
