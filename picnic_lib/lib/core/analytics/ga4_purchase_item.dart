import 'package:picnic_lib/core/analytics/ga4_parameters.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';

/// `purchase` 이벤트의 Item 수준 파라미터 (스펙 §2-9).
///
/// GA4 표준 Item 필드는 `item_id` / `item_name` 뿐이고,
/// `virtual_currency_name` / `base_amount` / `bonus_amount` 는 표준 필드가
/// 아니므로 Item 의 커스텀 parameters 맵으로 실어 보낸다.
class Ga4PurchaseItem {
  const Ga4PurchaseItem({
    required this.itemId,
    required this.itemName,
    required this.virtualCurrencyName,
    required this.baseAmount,
    required this.bonusAmount,
  });

  /// 구매 상품 고유 ID. 예: `star100`
  final String? itemId;

  /// 구매 상품명. 예: `STAR100`
  final String? itemName;

  /// 구매한 가상 재화 이름. 예: `별사탕`
  final String? virtualCurrencyName;

  /// 상품의 기본 지급 수량. 예: `100`
  final num? baseAmount;

  /// 프로모션 추가 지급 수량. 예: `25`
  final num? bonusAmount;

  /// 표준 필드로 매핑되는 값들 (`item_id`, `item_name`).
  String get resolvedItemId => Ga4Parameters.stringValue(itemId);

  String get resolvedItemName => Ga4Parameters.stringValue(itemName);

  /// 비표준 Item 파라미터 맵.
  Map<String, Object> toCustomParameters() => Ga4Parameters.build(
        strings: <String, String?>{
          Ga4Param.virtualCurrencyName: virtualCurrencyName,
        },
        numbers: <String, num?>{
          Ga4Param.baseAmount: baseAmount,
          Ga4Param.bonusAmount: bonusAmount,
        },
        eventNameForLog: Ga4Event.purchase,
      );
}
