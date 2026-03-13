import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';

void main() {
  group('AdPlatformType', () {
    test('has 6 values', () {
      expect(AdPlatformType.values.length, 6);
    });

    test('contains all expected values', () {
      expect(AdPlatformType.values, contains(AdPlatformType.admob));
      expect(AdPlatformType.values, contains(AdPlatformType.unity));
      expect(AdPlatformType.values, contains(AdPlatformType.pangle));
      expect(AdPlatformType.values, contains(AdPlatformType.tapjoy));
      expect(AdPlatformType.values, contains(AdPlatformType.pincrux));
      expect(AdPlatformType.values, contains(AdPlatformType.custom));
    });

    test('index order is correct', () {
      expect(AdPlatformType.admob.index, 0);
      expect(AdPlatformType.unity.index, 1);
      expect(AdPlatformType.pangle.index, 2);
      expect(AdPlatformType.tapjoy.index, 3);
      expect(AdPlatformType.pincrux.index, 4);
      expect(AdPlatformType.custom.index, 5);
    });

    test('name property returns correct string', () {
      expect(AdPlatformType.admob.name, 'admob');
      expect(AdPlatformType.unity.name, 'unity');
      expect(AdPlatformType.pangle.name, 'pangle');
      expect(AdPlatformType.tapjoy.name, 'tapjoy');
      expect(AdPlatformType.pincrux.name, 'pincrux');
      expect(AdPlatformType.custom.name, 'custom');
    });
  });
}
