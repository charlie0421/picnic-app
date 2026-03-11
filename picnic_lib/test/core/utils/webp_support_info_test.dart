import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';

void main() {
  group('WebPSupportInfo', () {
    test('기본값은 false', () {
      const info = WebPSupportInfo();
      expect(info.webp, isFalse);
      expect(info.animatedWebp, isFalse);
    });

    test('webp만 지원', () {
      const info = WebPSupportInfo(webp: true);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isFalse);
    });

    test('모두 지원', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: true);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isTrue);
    });

    test('animatedWebp만 true (비정상 케이스)', () {
      const info = WebPSupportInfo(animatedWebp: true);
      expect(info.webp, isFalse);
      expect(info.animatedWebp, isTrue);
    });
  });
}
