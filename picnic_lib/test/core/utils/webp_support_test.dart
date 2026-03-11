import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';

void main() {
  group('WebPSupportInfo', () {
    test('default values are false', () {
      const info = WebPSupportInfo();
      expect(info.webp, isFalse);
      expect(info.animatedWebp, isFalse);
    });

    test('custom values', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: true);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isTrue);
    });

    test('partial values', () {
      const info = WebPSupportInfo(webp: true);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isFalse);
    });
  });

  group('WebPSupportChecker', () {
    test('instance is singleton', () {
      final a = WebPSupportChecker.instance;
      final b = WebPSupportChecker.instance;
      expect(identical(a, b), isTrue);
    });

    test('supportInfo initially null', () {
      WebPSupportChecker.instance.reset();
      expect(WebPSupportChecker.instance.supportInfo, isNull);
    });

    test('reset clears cached info', () {
      WebPSupportChecker.instance.reset();
      expect(WebPSupportChecker.instance.supportInfo, isNull);
    });
  });
}
