import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/locale_utils.dart';

void main() {
  group('getLocaleTextFromJsonWithLocale', () {
    test('정확한 언어 코드로 텍스트 반환', () {
      final json = {'en': 'Hello', 'ko': '안녕', 'ja': 'こんにちは'};
      expect(getLocaleTextFromJsonWithLocale(json, 'ko'), equals('안녕'));
      expect(getLocaleTextFromJsonWithLocale(json, 'en'), equals('Hello'));
      expect(getLocaleTextFromJsonWithLocale(json, 'ja'), equals('こんにちは'));
    });

    test('없는 언어는 en으로 폴백', () {
      final json = {'en': 'Hello', 'ko': '안녕'};
      expect(getLocaleTextFromJsonWithLocale(json, 'fr'), equals('Hello'));
    });

    test('en도 없으면 빈 문자열 반환', () {
      final json = {'ko': '안녕'};
      expect(getLocaleTextFromJsonWithLocale(json, 'fr'), equals(''));
    });

    test('빈 JSON은 빈 문자열 반환', () {
      expect(getLocaleTextFromJsonWithLocale({}, 'ko'), equals(''));
    });

    test('중국어 zh_CN은 zh로 변환', () {
      final json = {'zh': '你好', 'en': 'Hello'};
      expect(getLocaleTextFromJsonWithLocale(json, 'zh_CN'), equals('你好'));
      expect(getLocaleTextFromJsonWithLocale(json, 'zh-cn'), equals('你好'));
    });

    test('중국어 zh_TW는 zh-TW로 변환', () {
      final json = {'zh-TW': '你好', 'zh': '你好简体', 'en': 'Hello'};
      expect(
          getLocaleTextFromJsonWithLocale(json, 'zh_TW'), equals('你好'));
      expect(
          getLocaleTextFromJsonWithLocale(json, 'zh-tw'), equals('你好'));
    });

    test('벵골어 bn_BD는 bn으로 변환', () {
      final json = {'bn': 'হ্যালো', 'en': 'Hello'};
      expect(
          getLocaleTextFromJsonWithLocale(json, 'bn_BD'), equals('হ্যালো'));
    });
  });
}
