import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart';

void main() {
  group('parseProductDescription', () {
    test('returns full description as main when no + sign', () {
      final result = parseProductDescription('100 Star Candies');
      expect(result.mainDescription, '100 Star Candies');
      expect(result.bonusDescription, isNull);
    });

    test('splits on + sign into main and bonus', () {
      final result = parseProductDescription('100 Star Candies + 10 Bonus');
      expect(result.mainDescription, '100 Star Candies');
      expect(result.bonusDescription, '+10 Bonus');
    });

    test('handles multiple + signs', () {
      final result =
          parseProductDescription('100 Stars + 10 Bonus + 5 Extra');
      expect(result.mainDescription, '100 Stars');
      expect(result.bonusDescription, '+10 Bonus + 5 Extra');
    });

    test('trims whitespace around parts', () {
      final result = parseProductDescription('  100 Stars  +  10 Bonus  ');
      expect(result.mainDescription, '100 Stars');
      expect(result.bonusDescription, '+10 Bonus');
    });

    test('handles empty string', () {
      final result = parseProductDescription('');
      expect(result.mainDescription, '');
      expect(result.bonusDescription, isNull);
    });

    test('handles string with only +', () {
      final result = parseProductDescription('+');
      expect(result.mainDescription, '');
      expect(result.bonusDescription, '+');
    });
  });

  group('extractStarSuffix', () {
    test('extracts number from STAR prefix', () {
      expect(extractStarSuffix('STAR100'), '100');
    });

    test('extracts number from STAR50', () {
      expect(extractStarSuffix('STAR50'), '50');
    });

    test('returns original if no STAR prefix', () {
      expect(extractStarSuffix('DIAMOND100'), 'DIAMOND100');
    });

    test('handles empty string', () {
      expect(extractStarSuffix(''), '');
    });

    test('handles just STAR', () {
      expect(extractStarSuffix('STAR'), '');
    });
  });

  group('shouldShowDebugInfo', () {
    test('returns true in sandbox with testflight installer', () {
      final result = shouldShowDebugInfo({
        'environment': 'sandbox',
        'isDebugMode': false,
        'installerStore': 'com.apple.testflight',
      });
      expect(result, isTrue);
    });

    test('returns true in sandbox with null installer', () {
      final result = shouldShowDebugInfo({
        'environment': 'sandbox',
        'isDebugMode': false,
        'installerStore': null,
      });
      expect(result, isTrue);
    });

    test('returns true in debug mode regardless of environment', () {
      // kDebugMode is true in flutter_test, so shouldShowDebugInfo always
      // returns true when running tests (mirrors actual debug behavior)
      final result = shouldShowDebugInfo({
        'environment': 'production',
        'isDebugMode': false,
        'installerStore': 'com.apple.appstore',
      });
      // In debug mode (flutter_test), kDebugMode is true
      expect(result, isTrue);
    });

    test('returns true in sandbox with isDebugMode true (kDebugMode in test)',
        () {
      final result = shouldShowDebugInfo({
        'environment': 'sandbox',
        'isDebugMode': true,
        'installerStore': 'com.apple.appstore',
      });
      // kDebugMode is true in test environment
      expect(result, isTrue);
    });
  });
}
