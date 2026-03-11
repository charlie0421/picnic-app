import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';

void main() {
  group('Constants', () {
    test('webWidth 기본값', () {
      expect(Constants.webWidth, equals(375));
    });

    test('webHeight 기본값', () {
      expect(Constants.webHeight, equals(812));
    });

    test('snackBarDuration 기본값', () {
      expect(Constants.snackBarDuration, equals(const Duration(seconds: 5)));
    });
  });

  group('NavBarConstants', () {
    test('bottomNavHeight', () {
      expect(NavBarConstants.bottomNavHeight, equals(52.0));
    });

    test('bottomNavOuterMargin', () {
      expect(NavBarConstants.bottomNavOuterMargin, equals(16.0));
    });
  });

  group('parseLocale', () {
    test('단순 언어 코드', () {
      final locale = parseLocale('ko');
      expect(locale.languageCode, equals('ko'));
    });

    test('언어_국가 코드', () {
      final locale = parseLocale('zh_CN');
      expect(locale.languageCode, equals('zh'));
      expect(locale.countryCode, equals('CN'));
    });

    test('zh_TW', () {
      final locale = parseLocale('zh_TW');
      expect(locale.languageCode, equals('zh'));
      expect(locale.countryCode, equals('TW'));
    });

    test('bn_BD', () {
      final locale = parseLocale('bn_BD');
      expect(locale.languageCode, equals('bn'));
      expect(locale.countryCode, equals('BD'));
    });

    test('영어', () {
      final locale = parseLocale('en');
      expect(locale.languageCode, equals('en'));
    });

    test('일본어', () {
      final locale = parseLocale('ja');
      expect(locale.languageCode, equals('ja'));
    });
  });

  group('countryMap', () {
    test('ko는 KR', () {
      expect(countryMap['ko'], equals('KR'));
    });

    test('en은 US', () {
      expect(countryMap['en'], equals('US'));
    });

    test('ja는 JP', () {
      expect(countryMap['ja'], equals('JP'));
    });

    test('zh_CN은 CN', () {
      expect(countryMap['zh_CN'], equals('CN'));
    });

    test('12개 국가 매핑 존재', () {
      expect(countryMap.length, equals(12));
    });
  });

  group('languageMap', () {
    test('ko는 한국어', () {
      expect(languageMap['ko'], equals('한국어'));
    });

    test('en은 English', () {
      expect(languageMap['en'], equals('English'));
    });

    test('ja는 日本語', () {
      expect(languageMap['ja'], equals('日本語'));
    });

    test('12개 언어 매핑 존재', () {
      expect(languageMap.length, equals(12));
    });
  });

  group('webDesignSize', () {
    test('크기 확인', () {
      expect(webDesignSize, equals(const Size(600, 800)));
    });
  });

  group('SnackType enum', () {
    test('4개 유형 존재', () {
      expect(SnackType.values.length, equals(4));
    });

    test('모든 유형 존재', () {
      expect(SnackType.success, isNotNull);
      expect(SnackType.error, isNotNull);
      expect(SnackType.info, isNotNull);
      expect(SnackType.warning, isNotNull);
    });
  });
}
