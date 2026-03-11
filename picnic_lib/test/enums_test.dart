import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/extensions/portal_type_extension.dart';

void main() {
  group('PolicyLanguage', () {
    test('2개의 언어가 정의됨', () {
      expect(PolicyLanguage.values.length, equals(2));
    });

    test('text 값 확인', () {
      expect(PolicyLanguage.en.text, equals('en'));
      expect(PolicyLanguage.ko.text, equals('ko'));
    });
  });

  group('PolicyType', () {
    test('3개의 타입이 정의됨', () {
      expect(PolicyType.values.length, equals(3));
    });

    test('모든 타입 존재', () {
      expect(PolicyType.privacy, isNotNull);
      expect(PolicyType.terms, isNotNull);
      expect(PolicyType.withdraw, isNotNull);
    });

    test('index 순서 확인', () {
      expect(PolicyType.privacy.index, equals(0));
      expect(PolicyType.terms.index, equals(1));
      expect(PolicyType.withdraw.index, equals(2));
    });
  });

  group('PortalType', () {
    test('6개의 포탈 타입이 정의됨', () {
      expect(PortalType.values.length, equals(6));
    });

    test('모든 포탈 타입 존재', () {
      expect(PortalType.vote, isNotNull);
      expect(PortalType.goongHap, isNotNull);
      expect(PortalType.pic, isNotNull);
      expect(PortalType.community, isNotNull);
      expect(PortalType.novel, isNotNull);
      expect(PortalType.mypage, isNotNull);
    });

    test('index 순서 확인', () {
      expect(PortalType.vote.index, equals(0));
      expect(PortalType.goongHap.index, equals(1));
      expect(PortalType.pic.index, equals(2));
      expect(PortalType.community.index, equals(3));
      expect(PortalType.novel.index, equals(4));
      expect(PortalType.mypage.index, equals(5));
    });
  });

  group('Gender', () {
    test('2개의 성별이 정의됨', () {
      expect(Gender.values.length, equals(2));
    });

    test('모든 성별 존재', () {
      expect(Gender.male, isNotNull);
      expect(Gender.female, isNotNull);
    });

    test('index 순서 확인', () {
      expect(Gender.male.index, equals(0));
      expect(Gender.female.index, equals(1));
    });
  });

  group('PortalTypeExtension', () {
    test('stringValue 전체 매핑', () {
      expect(PortalType.vote.stringValue, equals('vote'));
      expect(PortalType.goongHap.stringValue, equals('goongHap'));
      expect(PortalType.pic.stringValue, equals('pic'));
      expect(PortalType.community.stringValue, equals('community'));
      expect(PortalType.novel.stringValue, equals('novel'));
      expect(PortalType.mypage.stringValue, equals('mypage'));
    });

    test('fromString 전체 매핑', () {
      expect(PortalTypeExtension.fromString('vote'), equals(PortalType.vote));
      expect(PortalTypeExtension.fromString('goongHap'), equals(PortalType.goongHap));
      expect(PortalTypeExtension.fromString('pic'), equals(PortalType.pic));
      expect(PortalTypeExtension.fromString('community'), equals(PortalType.community));
      expect(PortalTypeExtension.fromString('novel'), equals(PortalType.novel));
      expect(PortalTypeExtension.fromString('mypage'), equals(PortalType.mypage));
    });

    test('fromString 알 수 없는 값이면 Exception', () {
      expect(
        () => PortalTypeExtension.fromString('unknown'),
        throwsA(isA<Exception>()),
      );
    });

    test('roundtrip stringValue → fromString', () {
      for (final type in PortalType.values) {
        expect(
          PortalTypeExtension.fromString(type.stringValue),
          equals(type),
        );
      }
    });
  });
}
