import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/splash_image_helper.dart';

void main() {
  // ── parseDate ──────────────────────────────────────────────────────────

  group('SplashImageHelper.parseDate', () {
    test('returns null for null input', () {
      expect(SplashImageHelper.parseDate(null), isNull);
    });

    test('returns null for empty string', () {
      expect(SplashImageHelper.parseDate(''), isNull);
    });

    test('returns null for non-string value', () {
      expect(SplashImageHelper.parseDate(12345), isNull);
    });

    test('returns null for non-string types like list', () {
      expect(SplashImageHelper.parseDate([1, 2, 3]), isNull);
    });

    test('parses valid ISO 8601 date string', () {
      final result = SplashImageHelper.parseDate('2025-06-15T10:30:00.000Z');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 6);
      expect(result.day, 15);
    });

    test('parses date-only string', () {
      final result = SplashImageHelper.parseDate('2025-01-01');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 1);
      expect(result.day, 1);
    });

    test('returns null for invalid date string', () {
      expect(SplashImageHelper.parseDate('not-a-date'), isNull);
    });

    test('returns null for boolean value', () {
      expect(SplashImageHelper.parseDate(true), isNull);
    });
  });

  // ── parseVersion ───────────────────────────────────────────────────────

  group('SplashImageHelper.parseVersion', () {
    test('returns null for null input', () {
      expect(SplashImageHelper.parseVersion(null), isNull);
    });

    test('returns int from int value', () {
      expect(SplashImageHelper.parseVersion(5), 5);
    });

    test('returns int from double value', () {
      expect(SplashImageHelper.parseVersion(3.7), 3);
    });

    test('returns int from numeric string', () {
      expect(SplashImageHelper.parseVersion('42'), 42);
    });

    test('returns null for empty string', () {
      expect(SplashImageHelper.parseVersion(''), isNull);
    });

    test('returns null for non-numeric string', () {
      expect(SplashImageHelper.parseVersion('abc'), isNull);
    });

    test('returns null for boolean value', () {
      expect(SplashImageHelper.parseVersion(true), isNull);
    });

    test('returns null for list value', () {
      expect(SplashImageHelper.parseVersion([1]), isNull);
    });
  });

  // ── resolveImageUrl ────────────────────────────────────────────────────

  group('SplashImageHelper.resolveImageUrl', () {
    const baseCdn = 'https://cdn.example.com';

    test('returns cdnUrl when non-empty string', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          'https://direct.url/image.png',
          null,
          baseCdn,
        ),
        'https://direct.url/image.png',
      );
    });

    test('trims whitespace from cdnUrl', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          '  https://direct.url/image.png  ',
          null,
          baseCdn,
        ),
        'https://direct.url/image.png',
      );
    });

    test('returns null when both cdnUrl and cdnPath are null', () {
      expect(
        SplashImageHelper.resolveImageUrl(null, null, baseCdn),
        isNull,
      );
    });

    test('returns null when both cdnUrl and cdnPath are empty', () {
      expect(
        SplashImageHelper.resolveImageUrl('', '', baseCdn),
        isNull,
      );
    });

    test('returns cdnPath as-is when it starts with http://', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          null,
          'http://other.cdn/img.png',
          baseCdn,
        ),
        'http://other.cdn/img.png',
      );
    });

    test('returns cdnPath as-is when it starts with https://', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          null,
          'https://other.cdn/img.png',
          baseCdn,
        ),
        'https://other.cdn/img.png',
      );
    });

    test('combines baseCdnUrl and cdnPath', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          null,
          'images/splash.png',
          baseCdn,
        ),
        'https://cdn.example.com/images/splash.png',
      );
    });

    test('handles baseCdnUrl with trailing slash', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          null,
          'images/splash.png',
          'https://cdn.example.com/',
        ),
        'https://cdn.example.com/images/splash.png',
      );
    });

    test('handles cdnPath with leading slash', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          null,
          '/images/splash.png',
          baseCdn,
        ),
        'https://cdn.example.com/images/splash.png',
      );
    });

    test('removes base prefix from cdnPath if present', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          null,
          'https://cdn.example.com/images/splash.png',
          baseCdn,
        ),
        'https://cdn.example.com/images/splash.png',
      );
    });

    test('prefers cdnUrl over cdnPath', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          'https://preferred.url/img.png',
          'fallback/path.png',
          baseCdn,
        ),
        'https://preferred.url/img.png',
      );
    });

    test('falls back to cdnPath when cdnUrl is non-string', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          123,
          'path/img.png',
          baseCdn,
        ),
        'https://cdn.example.com/path/img.png',
      );
    });

    test('trims whitespace from cdnPath', () {
      expect(
        SplashImageHelper.resolveImageUrl(
          null,
          '  path/img.png  ',
          baseCdn,
        ),
        'https://cdn.example.com/path/img.png',
      );
    });
  });

  // ── parseSplashConfig ──────────────────────────────────────────────────

  group('SplashImageHelper.parseSplashConfig', () {
    const baseCdn = 'https://cdn.example.com';

    test('returns null for null input', () {
      expect(SplashImageHelper.parseSplashConfig(null, baseCdn), isNull);
    });

    test('returns null for empty string', () {
      expect(SplashImageHelper.parseSplashConfig('', baseCdn), isNull);
    });

    test('returns null for invalid JSON', () {
      expect(
        SplashImageHelper.parseSplashConfig('not json', baseCdn),
        isNull,
      );
    });

    test('returns null for JSON array instead of object', () {
      expect(
        SplashImageHelper.parseSplashConfig('[1,2,3]', baseCdn),
        isNull,
      );
    });

    test('returns null when no image URL can be resolved', () {
      expect(
        SplashImageHelper.parseSplashConfig(
          jsonEncode({'version': 1}),
          baseCdn,
        ),
        isNull,
      );
    });

    test('parses valid config with cdnUrl', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': 2,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['imageUrl'], 'https://img.example.com/splash.png');
      expect(result['version'], 2);
      expect(result['enabled'], true);
      expect(result['expiresAt'], isNull);
    });

    test('parses config with cdn_url snake_case key', () {
      final raw = jsonEncode({
        'cdn_url': 'https://img.example.com/splash.png',
        'version': 1,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['imageUrl'], 'https://img.example.com/splash.png');
    });

    test('parses config with cdnPath', () {
      final raw = jsonEncode({
        'cdnPath': 'assets/splash.png',
        'version': 1,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['imageUrl'], 'https://cdn.example.com/assets/splash.png');
    });

    test('parses config with cdn_path snake_case key', () {
      final raw = jsonEncode({
        'cdn_path': 'assets/splash.png',
        'version': 3,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['imageUrl'], 'https://cdn.example.com/assets/splash.png');
      expect(result['version'], 3);
    });

    test('parses expiresAt field', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': 1,
        'expiresAt': '2025-12-31T23:59:59.000Z',
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['expiresAt'], isA<DateTime>());
      expect((result['expiresAt'] as DateTime).year, 2025);
    });

    test('parses expires_at snake_case field', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': 1,
        'expires_at': '2025-06-01T00:00:00.000Z',
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['expiresAt'], isA<DateTime>());
    });

    test('parses enabled=false', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': 1,
        'enabled': false,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['enabled'], false);
    });

    test('defaults enabled to true when not present', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': 1,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result!['enabled'], true);
    });

    test('defaults version to 1 when not present', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result!['version'], 1);
    });

    test('parses Version with capital V', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'Version': 7,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result!['version'], 7);
    });

    test('parses VERSION uppercase', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'VERSION': 9,
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result!['version'], 9);
    });

    test('handles string version', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': '15',
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result!['version'], 15);
    });

    test('ignores invalid expiresAt string', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': 1,
        'expiresAt': 'not-a-date',
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result, isNotNull);
      expect(result!['expiresAt'], isNull);
    });

    test('ignores empty expiresAt string', () {
      final raw = jsonEncode({
        'cdnUrl': 'https://img.example.com/splash.png',
        'version': 1,
        'expiresAt': '',
      });
      final result = SplashImageHelper.parseSplashConfig(raw, baseCdn);
      expect(result!['expiresAt'], isNull);
    });
  });

  // ── isPlatformMatch ────────────────────────────────────────────────────

  group('SplashImageHelper.isPlatformMatch', () {
    test('returns true when cachedPlatform is null', () {
      expect(SplashImageHelper.isPlatformMatch(null, 'ios'), true);
    });

    test('returns true when cachedPlatform is "all"', () {
      expect(SplashImageHelper.isPlatformMatch('all', 'android'), true);
    });

    test('returns true when platforms match', () {
      expect(SplashImageHelper.isPlatformMatch('ios', 'ios'), true);
    });

    test('returns false when platforms differ', () {
      expect(SplashImageHelper.isPlatformMatch('ios', 'android'), false);
    });

    test('returns true when cachedPlatform is "all" for any current', () {
      expect(SplashImageHelper.isPlatformMatch('all', 'macos'), true);
    });
  });

  // ── shouldShowStatus ───────────────────────────────────────────────────

  group('SplashImageHelper.shouldShowStatus', () {
    test('returns false when patch check disabled and no external message', () {
      expect(
        SplashImageHelper.shouldShowStatus(
          enablePatchCheck: false,
          isCheckingUpdate: false,
          updateStatus: '',
          externalStatusMessage: null,
        ),
        false,
      );
    });

    test('returns true when patch check enabled and isCheckingUpdate', () {
      expect(
        SplashImageHelper.shouldShowStatus(
          enablePatchCheck: true,
          isCheckingUpdate: true,
          updateStatus: '',
          externalStatusMessage: null,
        ),
        true,
      );
    });

    test('returns true when patch check enabled and updateStatus non-empty',
        () {
      expect(
        SplashImageHelper.shouldShowStatus(
          enablePatchCheck: true,
          isCheckingUpdate: false,
          updateStatus: 'Downloading...',
          externalStatusMessage: null,
        ),
        true,
      );
    });

    test('returns true when external status message is non-empty', () {
      expect(
        SplashImageHelper.shouldShowStatus(
          enablePatchCheck: false,
          isCheckingUpdate: false,
          updateStatus: '',
          externalStatusMessage: 'Loading...',
        ),
        true,
      );
    });

    test('returns false when external message is empty string', () {
      expect(
        SplashImageHelper.shouldShowStatus(
          enablePatchCheck: false,
          isCheckingUpdate: false,
          updateStatus: '',
          externalStatusMessage: '',
        ),
        false,
      );
    });

    test(
        'returns false when patch check disabled and not checking and no status',
        () {
      expect(
        SplashImageHelper.shouldShowStatus(
          enablePatchCheck: true,
          isCheckingUpdate: false,
          updateStatus: '',
          externalStatusMessage: null,
        ),
        false,
      );
    });
  });

  // ── resolveStatusMessage ───────────────────────────────────────────────

  group('SplashImageHelper.resolveStatusMessage', () {
    test('returns external message when provided', () {
      expect(
        SplashImageHelper.resolveStatusMessage(
          externalStatusMessage: 'External',
          updateStatus: 'Internal',
        ),
        'External',
      );
    });

    test('returns updateStatus when external is null', () {
      expect(
        SplashImageHelper.resolveStatusMessage(
          externalStatusMessage: null,
          updateStatus: 'Checking...',
        ),
        'Checking...',
      );
    });

    test('returns empty string when both are empty/null', () {
      expect(
        SplashImageHelper.resolveStatusMessage(
          externalStatusMessage: null,
          updateStatus: '',
        ),
        '',
      );
    });
  });

  // ── isExpired ──────────────────────────────────────────────────────────

  group('SplashImageHelper.isExpired', () {
    test('returns false when endDate is null', () {
      expect(SplashImageHelper.isExpired(null), false);
    });

    test('returns true when endDate is in the past', () {
      final pastDate = DateTime(2020, 1, 1);
      expect(
        SplashImageHelper.isExpired(pastDate, now: DateTime(2025, 1, 1)),
        true,
      );
    });

    test('returns false when endDate is in the future', () {
      final futureDate = DateTime(2030, 1, 1);
      expect(
        SplashImageHelper.isExpired(futureDate, now: DateTime(2025, 1, 1)),
        false,
      );
    });

    test('returns false when endDate equals now', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      expect(SplashImageHelper.isExpired(now, now: now), false);
    });
  });
}
