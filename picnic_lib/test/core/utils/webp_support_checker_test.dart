import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';

void main() {
  group('WebPSupportInfo', () {
    test('default constructor has false values', () {
      const info = WebPSupportInfo();
      expect(info.webp, false);
      expect(info.animatedWebp, false);
    });

    test('webp true, animatedWebp false', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: false);
      expect(info.webp, true);
      expect(info.animatedWebp, false);
    });

    test('both true', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: true);
      expect(info.webp, true);
      expect(info.animatedWebp, true);
    });

    test('both false', () {
      const info = WebPSupportInfo(webp: false, animatedWebp: false);
      expect(info.webp, false);
      expect(info.animatedWebp, false);
    });

    test('webp false, animatedWebp true', () {
      const info = WebPSupportInfo(webp: false, animatedWebp: true);
      expect(info.webp, false);
      expect(info.animatedWebp, true);
    });
  });

  group('WebPSupportChecker', () {
    test('singleton instance exists', () {
      expect(WebPSupportChecker.instance, isNotNull);
    });

    test('initial supportInfo is null', () {
      WebPSupportChecker.instance.reset();
      expect(WebPSupportChecker.instance.supportInfo, isNull);
    });

    test('reset clears cached info', () {
      WebPSupportChecker.instance.reset();
      expect(WebPSupportChecker.instance.supportInfo, isNull);
    });

    test('instance is same object on multiple accesses', () {
      final instance1 = WebPSupportChecker.instance;
      final instance2 = WebPSupportChecker.instance;
      expect(identical(instance1, instance2), true);
    });

    test('multiple resets do not cause errors', () {
      WebPSupportChecker.instance.reset();
      WebPSupportChecker.instance.reset();
      WebPSupportChecker.instance.reset();
      expect(WebPSupportChecker.instance.supportInfo, isNull);
    });
  });
}
