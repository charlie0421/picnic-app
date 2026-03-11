import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';

void main() {
  group('AdPlatformType enum', () {
    test('6개의 플랫폼 타입이 정의됨', () {
      expect(AdPlatformType.values.length, equals(6));
    });

    test('모든 플랫폼 타입 존재 확인', () {
      expect(AdPlatformType.admob, isNotNull);
      expect(AdPlatformType.unity, isNotNull);
      expect(AdPlatformType.pangle, isNotNull);
      expect(AdPlatformType.tapjoy, isNotNull);
      expect(AdPlatformType.pincrux, isNotNull);
      expect(AdPlatformType.custom, isNotNull);
    });

    test('index 순서 확인', () {
      expect(AdPlatformType.admob.index, equals(0));
      expect(AdPlatformType.unity.index, equals(1));
      expect(AdPlatformType.pangle.index, equals(2));
      expect(AdPlatformType.tapjoy.index, equals(3));
      expect(AdPlatformType.pincrux.index, equals(4));
      expect(AdPlatformType.custom.index, equals(5));
    });

    test('name 문자열 확인', () {
      expect(AdPlatformType.admob.name, equals('admob'));
      expect(AdPlatformType.unity.name, equals('unity'));
      expect(AdPlatformType.pangle.name, equals('pangle'));
      expect(AdPlatformType.tapjoy.name, equals('tapjoy'));
      expect(AdPlatformType.pincrux.name, equals('pincrux'));
      expect(AdPlatformType.custom.name, equals('custom'));
    });
  });
}
