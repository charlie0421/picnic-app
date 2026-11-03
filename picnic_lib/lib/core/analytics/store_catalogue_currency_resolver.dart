import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/analytics/iso_4217_currency.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';

/// 보류된 매출 이벤트의 통화를 스토어 카탈로그에서 되찾는다.
///
/// 정산 시점에 카탈로그가 메모리에 없어 통화를 못 구한 복구 구매가 대상이다.
/// 그 조건은 영구적이지 않다 — 사용자가 스토어에 들어가거나 앱이 카탈로그를
/// 다시 불러오면 같은 상품의 통화를 알 수 있다. 이 resolver 가 없으면 보류
/// 상태를 진행시킬 것이 아무것도 없어 항목은 만료될 때까지 그대로 남는다.
class StoreCatalogueCurrencyResolver implements PurchaseCurrencyResolver {
  const StoreCatalogueCurrencyResolver(this._container);

  final ProviderContainer _container;

  @override
  Future<String?> resolve(String storeProductId) async {
    // 이미 로드돼 있으면 그것으로 끝낸다. 대부분의 재시도가 여기서 끝나야
    // 하고, 캐시 히트에 네트워크 대기를 섞을 이유가 없다.
    final state = _container.read(storeProductsProvider);
    final fromCache = _currencyIn(state.value, storeProductId);
    if (fromCache != null) return fromCache;

    // provider 가 terminal error 로 굳었으면 `.future` 는 같은 오류를 영원히
    // 다시 준다. 그 상태로 두면 스토어가 회복해도 보류 항목은 스스로 회복하지
    // 못하고 만료된다 — 이 resolver 가 존재하는 이유가 사라진다.
    if (state.hasError && !state.isLoading) {
      logger.w('스토어 카탈로그가 오류 상태 — 무효화 후 재조회: $storeProductId');
      _container.invalidate(storeProductsProvider);
    }

    // 캐시가 비어 있으면 실제로 불러온다. 이 호출은 결제 경로가 아니라
    // outbox drain 에서 오고, 호출부가 timeout 으로 상한을 준다.
    try {
      final loaded = await _container.read(storeProductsProvider.future);
      return _currencyIn(loaded, storeProductId);
    } catch (e, s) {
      logger.w('스토어 카탈로그 재조회 실패: $storeProductId', error: e, stackTrace: s);
      return null;
    }
  }

  String? _currencyIn(List<ProductDetails>? products, String storeProductId) {
    if (products == null) return null;
    for (final product in products) {
      if (product.id == storeProductId) {
        return normalizeIso4217(product.currencyCode);
      }
    }
    // storage v1 에서 올라온 항목은 canonical 대문자 ID 를 들고 있어 스토어
    // ID 와 대소문자가 다를 수 있다(Play SKU 는 소문자 강제).
    final target = storeProductId.toUpperCase();
    for (final product in products) {
      if (product.id.toUpperCase() == target) {
        return normalizeIso4217(product.currencyCode);
      }
    }
    return null;
  }
}
