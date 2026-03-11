import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';

void main() {
  group('ChargeStationItem', () {
    test('creates with required fields', () {
      final item = ChargeStationItem(
        id: 'item-1',
        title: 'Watch Ad',
        isMission: false,
        platformType: AdPlatformType.admob,
        onPressed: () {},
      );
      expect(item.id, 'item-1');
      expect(item.title, 'Watch Ad');
      expect(item.isMission, isFalse);
      expect(item.platformType, AdPlatformType.admob);
      expect(item.index, 0);
      expect(item.bonusText, '1');
    });

    test('creates with custom index and bonusText', () {
      final item = ChargeStationItem(
        id: 'item-2',
        title: 'Mission',
        isMission: true,
        platformType: AdPlatformType.tapjoy,
        index: 3,
        onPressed: () {},
        bonusText: '5',
      );
      expect(item.index, 3);
      expect(item.bonusText, '5');
      expect(item.isMission, isTrue);
    });
  });

  group('AdPlatformType', () {
    test('has all expected values', () {
      expect(AdPlatformType.values.length, 6);
      expect(AdPlatformType.values, contains(AdPlatformType.admob));
      expect(AdPlatformType.values, contains(AdPlatformType.unity));
      expect(AdPlatformType.values, contains(AdPlatformType.pangle));
      expect(AdPlatformType.values, contains(AdPlatformType.tapjoy));
      expect(AdPlatformType.values, contains(AdPlatformType.pincrux));
      expect(AdPlatformType.values, contains(AdPlatformType.custom));
    });
  });
}
