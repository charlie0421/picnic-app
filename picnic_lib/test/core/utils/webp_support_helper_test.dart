import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:picnic_lib/core/utils/webp_support_helper.dart';

void main() {
  group('WebPSupportHelper', () {
    group('determineIOSSupport', () {
      test('supports WebP for iOS 14', () {
        final info = WebPSupportHelper.determineIOSSupport('14.0');
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isTrue);
      });

      test('supports WebP for iOS 17.2.1', () {
        final info = WebPSupportHelper.determineIOSSupport('17.2.1');
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isTrue);
      });

      test('does not support WebP for iOS 13', () {
        final info = WebPSupportHelper.determineIOSSupport('13.7');
        expect(info.webp, isFalse);
        expect(info.animatedWebp, isFalse);
      });

      test('does not support WebP for iOS 12', () {
        final info = WebPSupportHelper.determineIOSSupport('12.0');
        expect(info.webp, isFalse);
        expect(info.animatedWebp, isFalse);
      });

      test('handles empty version string', () {
        final info = WebPSupportHelper.determineIOSSupport('');
        expect(info.webp, isFalse);
        expect(info.animatedWebp, isFalse);
      });

      test('handles invalid version string', () {
        final info = WebPSupportHelper.determineIOSSupport('abc');
        expect(info.webp, isFalse);
        expect(info.animatedWebp, isFalse);
      });

      test('supports WebP for iOS 16', () {
        final info = WebPSupportHelper.determineIOSSupport('16.0');
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isTrue);
      });
    });

    group('determineAndroidSupport', () {
      test('supports both for SDK 17+', () {
        final info = WebPSupportHelper.determineAndroidSupport(17);
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isTrue);
      });

      test('supports only static WebP for SDK 14-16', () {
        final info = WebPSupportHelper.determineAndroidSupport(14);
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isFalse);
      });

      test('does not support WebP for SDK 13', () {
        final info = WebPSupportHelper.determineAndroidSupport(13);
        expect(info.webp, isFalse);
        expect(info.animatedWebp, isFalse);
      });

      test('supports both for modern SDK 33', () {
        final info = WebPSupportHelper.determineAndroidSupport(33);
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isTrue);
      });

      test('SDK 16 supports static but not animated', () {
        final info = WebPSupportHelper.determineAndroidSupport(16);
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isFalse);
      });
    });

    group('getWebSupport', () {
      test('always returns full support', () {
        final info = WebPSupportHelper.getWebSupport();
        expect(info.webp, isTrue);
        expect(info.animatedWebp, isTrue);
      });
    });

    group('getUnknownPlatformSupport', () {
      test('always returns no support', () {
        final info = WebPSupportHelper.getUnknownPlatformSupport();
        expect(info.webp, isFalse);
        expect(info.animatedWebp, isFalse);
      });
    });

    group('shouldUseCachedInfo', () {
      test('returns true when cached info exists', () {
        const info = WebPSupportInfo(webp: true, animatedWebp: true);
        expect(WebPSupportHelper.shouldUseCachedInfo(info), isTrue);
      });

      test('returns false when cached info is null', () {
        expect(WebPSupportHelper.shouldUseCachedInfo(null), isFalse);
      });
    });
  });

  group('WebPSupportInfo', () {
    test('defaults to false', () {
      const info = WebPSupportInfo();
      expect(info.webp, isFalse);
      expect(info.animatedWebp, isFalse);
    });

    test('can be created with true values', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: true);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isTrue);
    });

    test('can have mixed values', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: false);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isFalse);
    });
  });
}
