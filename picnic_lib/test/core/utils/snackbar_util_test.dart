import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';

void main() {
  group('SnackType', () {
    test('4개 유형 존재', () {
      expect(SnackType.values.length, equals(4));
    });

    test('모든 유형 name 확인', () {
      expect(SnackType.success.name, equals('success'));
      expect(SnackType.error.name, equals('error'));
      expect(SnackType.info.name, equals('info'));
      expect(SnackType.warning.name, equals('warning'));
    });

    test('index 확인', () {
      expect(SnackType.success.index, equals(0));
      expect(SnackType.error.index, equals(1));
      expect(SnackType.info.index, equals(2));
      expect(SnackType.warning.index, equals(3));
    });
  });

  group('SnackbarUtil', () {
    test('싱글톤 패턴', () {
      final a = SnackbarUtil();
      final b = SnackbarUtil();
      expect(identical(a, b), isTrue);
    });

    test('scaffoldMessengerKey 초기 상태', () {
      expect(SnackbarUtil.scaffoldMessengerKey.currentState, isNull);
    });
  });
}
