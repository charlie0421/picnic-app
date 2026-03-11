import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/util.dart';

void main() {
  group('numberFormatter', () {
    test('formats thousands with commas', () {
      expect(numberFormatter.format(1000), '1,000');
      expect(numberFormatter.format(1000000), '1,000,000');
    });

    test('formats small numbers without commas', () {
      expect(numberFormatter.format(0), '0');
      expect(numberFormatter.format(999), '999');
    });

    test('formats negative numbers', () {
      expect(numberFormatter.format(-1000), '-1,000');
    });

    test('formats large numbers', () {
      expect(numberFormatter.format(1234567890), '1,234,567,890');
    });
  });
}
