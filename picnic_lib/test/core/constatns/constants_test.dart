import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';

void main() {
  group('parseLocale', () {
    test('단순 언어 코드 (ko)', () {
      final locale = parseLocale('ko');
      expect(locale.languageCode, equals('ko'));
      expect(locale.countryCode, isNull);
    });

    test('단순 언어 코드 (en)', () {
      final locale = parseLocale('en');
      expect(locale.languageCode, equals('en'));
    });

    test('언더스코어가 포함된 코드 (zh_CN)', () {
      final locale = parseLocale('zh_CN');
      expect(locale.languageCode, equals('zh'));
      expect(locale.countryCode, equals('CN'));
    });

    test('언더스코어가 포함된 코드 (zh_TW)', () {
      final locale = parseLocale('zh_TW');
      expect(locale.languageCode, equals('zh'));
      expect(locale.countryCode, equals('TW'));
    });

    test('언더스코어가 포함된 코드 (bn_BD)', () {
      final locale = parseLocale('bn_BD');
      expect(locale.languageCode, equals('bn'));
      expect(locale.countryCode, equals('BD'));
    });

    test('일본어 (ja)', () {
      final locale = parseLocale('ja');
      expect(locale.languageCode, equals('ja'));
    });
  });

  group('countryMap', () {
    test('주요 언어의 국가 코드가 정의되어 있음', () {
      expect(countryMap['ko'], equals('KR'));
      expect(countryMap['en'], equals('US'));
      expect(countryMap['ja'], equals('JP'));
      expect(countryMap['zh_CN'], equals('CN'));
      expect(countryMap['zh_TW'], equals('TW'));
    });

    test('동남아 언어 국가 코드', () {
      expect(countryMap['th'], equals('TH'));
      expect(countryMap['vi'], equals('VN'));
      expect(countryMap['id'], equals('ID'));
      expect(countryMap['fil'], equals('PH'));
      expect(countryMap['my'], equals('MM'));
    });

    test('12개 언어가 정의되어 있음', () {
      expect(countryMap.length, equals(12));
    });
  });

  group('languageMap', () {
    test('주요 언어 이름이 정의되어 있음', () {
      expect(languageMap['ko'], equals('한국어'));
      expect(languageMap['en'], equals('English'));
      expect(languageMap['ja'], equals('日本語'));
      expect(languageMap['es'], equals('Español'));
    });

    test('중국어 간체/번체 구분', () {
      expect(languageMap['zh_CN'], equals('简体中文'));
      expect(languageMap['zh_TW'], equals('繁體中文'));
    });

    test('countryMap과 동일한 키 세트', () {
      expect(languageMap.keys.toSet(), equals(countryMap.keys.toSet()));
    });
  });

  group('Constants', () {
    test('웹 너비/높이 기본값', () {
      expect(Constants.webWidth, equals(375));
      expect(Constants.webHeight, equals(812));
    });

    test('스낵바 지속 시간은 5초', () {
      expect(Constants.snackBarDuration, equals(const Duration(seconds: 5)));
    });
  });

  group('NavBarConstants', () {
    test('하단 내비게이션 높이', () {
      expect(NavBarConstants.bottomNavHeight, equals(52.0));
    });

    test('하단 내비게이션 외곽 마진', () {
      expect(NavBarConstants.bottomNavOuterMargin, equals(16.0));
    });
  });

  group('webDesignSize', () {
    test('웹 디자인 사이즈', () {
      expect(webDesignSize, equals(const Size(600, 800)));
    });
  });
}
