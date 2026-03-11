import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/extensions/portal_type_extension.dart';

void main() {
  group('PortalTypeExtension.stringValue', () {
    test('vote', () {
      expect(PortalType.vote.stringValue, equals('vote'));
    });

    test('goongHap', () {
      expect(PortalType.goongHap.stringValue, equals('goongHap'));
    });

    test('pic', () {
      expect(PortalType.pic.stringValue, equals('pic'));
    });

    test('community', () {
      expect(PortalType.community.stringValue, equals('community'));
    });

    test('novel', () {
      expect(PortalType.novel.stringValue, equals('novel'));
    });

    test('mypage', () {
      expect(PortalType.mypage.stringValue, equals('mypage'));
    });
  });

  group('PortalTypeExtension.fromString', () {
    test('vote 문자열에서 변환', () {
      expect(
        PortalTypeExtension.fromString('vote'),
        equals(PortalType.vote),
      );
    });

    test('goongHap 문자열에서 변환', () {
      expect(
        PortalTypeExtension.fromString('goongHap'),
        equals(PortalType.goongHap),
      );
    });

    test('pic 문자열에서 변환', () {
      expect(
        PortalTypeExtension.fromString('pic'),
        equals(PortalType.pic),
      );
    });

    test('community 문자열에서 변환', () {
      expect(
        PortalTypeExtension.fromString('community'),
        equals(PortalType.community),
      );
    });

    test('novel 문자열에서 변환', () {
      expect(
        PortalTypeExtension.fromString('novel'),
        equals(PortalType.novel),
      );
    });

    test('mypage 문자열에서 변환', () {
      expect(
        PortalTypeExtension.fromString('mypage'),
        equals(PortalType.mypage),
      );
    });

    test('알 수 없는 문자열은 예외 발생', () {
      expect(
        () => PortalTypeExtension.fromString('unknown'),
        throwsException,
      );
    });
  });

  group('라운드트립 변환', () {
    test('모든 PortalType 라운드트립', () {
      for (final type in PortalType.values) {
        final str = type.stringValue;
        final restored = PortalTypeExtension.fromString(str);
        expect(restored, equals(type));
      }
    });
  });
}
