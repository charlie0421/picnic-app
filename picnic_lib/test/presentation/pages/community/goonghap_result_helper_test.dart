import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_result_helper.dart';

void main() {
  group('GoonghapResultHelper.normalizeLanguageCode', () {
    test('returns zh-CN for Chinese Simplified', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('zh', 'CN'), 'zh-CN');
    });

    test('returns zh-TW for Chinese Traditional', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('zh', 'TW'), 'zh-TW');
    });

    test('returns zh for Chinese without country code', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('zh', ''), 'zh');
    });

    test('returns zh for Chinese with other country code', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('zh', 'HK'), 'zh');
    });

    test('returns ko for Korean', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('ko', 'KR'), 'ko');
    });

    test('returns en for English', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('en', 'US'), 'en');
    });

    test('returns ja for Japanese', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('ja', 'JP'), 'ja');
    });

    test('normalizes language to lowercase', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('ZH', 'CN'), 'zh-CN');
    });

    test('normalizes country to uppercase', () {
      expect(GoonghapResultHelper.normalizeLanguageCode('zh', 'cn'), 'zh-CN');
    });
  });

  group('GoonghapResultHelper.canPurchase', () {
    test('returns true when lastPurchaseTime is null', () {
      expect(
        GoonghapResultHelper.canPurchase(null, const Duration(seconds: 1)),
        isTrue,
      );
    });

    test('returns false when within cooldown', () {
      final recent = DateTime.now().subtract(const Duration(milliseconds: 200));
      expect(
        GoonghapResultHelper.canPurchase(recent, const Duration(seconds: 1)),
        isFalse,
      );
    });

    test('returns true when cooldown has elapsed', () {
      final old = DateTime.now().subtract(const Duration(seconds: 2));
      expect(
        GoonghapResultHelper.canPurchase(old, const Duration(seconds: 1)),
        isTrue,
      );
    });

    test('returns true when exactly at cooldown boundary', () {
      final exact = DateTime.now().subtract(const Duration(seconds: 1));
      expect(
        GoonghapResultHelper.canPurchase(exact, const Duration(seconds: 1)),
        isTrue,
      );
    });
  });
}
