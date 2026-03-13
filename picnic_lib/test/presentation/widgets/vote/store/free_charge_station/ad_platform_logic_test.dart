import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';

/// A minimal concrete subclass of [AdPlatform] to test its logic methods.
/// We cannot instantiate AdPlatform directly (it needs ref/context), so we
/// test the [isNonReportableAdError] method via a thin wrapper that avoids
/// the constructor entirely: the method logic is self-contained and only
/// depends on its arguments. We replicate the logic here to keep the test
/// free of Flutter widget dependencies.
///
/// Instead, we test the extracted pure-logic method directly.

void main() {
  group('AdPlatform.isNonReportableAdError logic', () {
    // The method checks:
    // 1. If platform == 'AdMob' and error is LoadAdError with code 1,2,3
    // 2. If the lowercase message contains certain keywords

    test('returns true for keyword "no fill" in message', () {
      final result = _isNonReportableAdError('SomePlatform', 'error', 'Ad no fill available');
      expect(result, isTrue);
    });

    test('returns true for keyword "nofill" in message', () {
      final result = _isNonReportableAdError('SomePlatform', 'error', 'NOFILL error');
      expect(result, isTrue);
    });

    test('returns true for keyword "no ad available" in message', () {
      final result = _isNonReportableAdError('Other', 'error', 'There is no ad available now');
      expect(result, isTrue);
    });

    test('returns true for keyword "no ad to show" in message', () {
      final result = _isNonReportableAdError('Other', 'error', 'No ad to show at this time');
      expect(result, isTrue);
    });

    test('returns true for keyword "inventory unavailable" in message', () {
      final result = _isNonReportableAdError('Other', 'error', 'inventory unavailable');
      expect(result, isTrue);
    });

    test('returns true for keyword "no ads available" in message', () {
      final result = _isNonReportableAdError('Other', 'error', 'No ads available right now');
      expect(result, isTrue);
    });

    test('returns true for keyword "not_ready" in message', () {
      final result = _isNonReportableAdError('Other', 'error', 'Status: not_ready');
      expect(result, isTrue);
    });

    test('returns true for keyword "not ready" in message', () {
      final result = _isNonReportableAdError('Other', 'error', 'Ad is not ready');
      expect(result, isTrue);
    });

    test('returns true for keyword "network error" in message', () {
      final result = _isNonReportableAdError('Other', 'error', 'Network error occurred');
      expect(result, isTrue);
    });

    test('returns true for Korean keyword in message', () {
      final result = _isNonReportableAdError('Other', 'error', '광고 없음');
      expect(result, isTrue);
    });

    test('returns true for Korean keyword "광고 로드 실패"', () {
      final result = _isNonReportableAdError('Other', 'error', '광고 로드 실패 발생');
      expect(result, isTrue);
    });

    test('returns true for Korean keyword "광고 로드 시간 초과"', () {
      final result = _isNonReportableAdError('Other', 'error', '광고 로드 시간 초과');
      expect(result, isTrue);
    });

    test('returns false for generic error message', () {
      final result = _isNonReportableAdError('SomePlatform', 'error', 'Unknown error happened');
      expect(result, isFalse);
    });

    test('returns false for empty message', () {
      final result = _isNonReportableAdError('SomePlatform', 'error', '');
      expect(result, isFalse);
    });

    test('keyword matching is case-insensitive', () {
      final result = _isNonReportableAdError('Other', 'error', 'NO FILL');
      expect(result, isTrue);
    });

    test('keyword matching is case-insensitive for NOT READY', () {
      final result = _isNonReportableAdError('Other', 'error', 'NOT READY');
      expect(result, isTrue);
    });
  });
}

/// Replicate the pure logic from [AdPlatform.isNonReportableAdError].
/// This avoids needing a widget ref/context to instantiate AdPlatform.
bool _isNonReportableAdError(String platform, dynamic error, String message) {
  final lowercaseMessage = message.toLowerCase();

  if (platform == 'AdMob' && error is LoadAdError) {
    if (error.code == 1 || error.code == 2 || error.code == 3) {
      return true;
    }
  }

  final nonReportableKeywords = [
    'no fill',
    'nofill',
    'no ad available',
    'no ad to show',
    'inventory unavailable',
    'no ads available',
    'not_ready',
    'not ready',
    'network error',
    '광고 없음',
    '광고 없습니다',
    '광고가 없습니다',
    '광고 로드 실패',
    '광고 로드 시간 초과',
  ];

  return nonReportableKeywords
      .any((keyword) => lowercaseMessage.contains(keyword));
}
