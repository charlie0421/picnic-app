import 'package:picnic_lib/data/models/vote/purchase_product.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/purchase_product_provider.g.dart';

@riverpod
class PurchaseProductList extends _$PurchaseProductList {
  @override
  List<PurchaseProduct> build() {
    return [
      PurchaseProduct(
        id: 'STAR100',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy100,
        price: 0.99,
        starCandy: 100,
        bonusStarCandy: 0,
      ),
      PurchaseProduct(
        id: 'STAR200',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy200,
        price: 1.99,
        starCandy: 200,
        bonusStarCandy: 25,
      ),
      PurchaseProduct(
        id: 'STAR600',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy600,
        price: 5.99,
        starCandy: 600,
        bonusStarCandy: 85,
      ),
      PurchaseProduct(
        id: 'STAR1000',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy1000,
        price: 9.99,
        starCandy: 1000,
        bonusStarCandy: 150,
      ),
      PurchaseProduct(
        id: 'STAR2000',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy2000,
        price: 19.99,
        starCandy: 2000,
        bonusStarCandy: 320,
      ),
      PurchaseProduct(
        id: 'STAR3000',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy3000,
        price: 29.99,
        starCandy: 3000,
        bonusStarCandy: 540,
      ),
      PurchaseProduct(
        id: 'STAR4000',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy4000,
        price: 39.99,
        starCandy: 4000,
        bonusStarCandy: 760,
      ),
      PurchaseProduct(
        id: 'STAR5000',
        title: AppLocalizations.of(navigatorKey.currentContext!).starCandy5000,
        price: 49.99,
        starCandy: 5000,
        bonusStarCandy: 1000,
      ),
    ];
  }
}
