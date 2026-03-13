import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';

/// Coverage-focused tests for SplashImage data classes covering uncovered lines:
/// - SplashConfigPayload._resolveImageUrl with cdnPath variations
/// - SplashConfigPayload._parseVersion edge cases
/// - SplashImageData._parseDate with empty string and non-string value
void main() {
  group('SplashConfigPayload._resolveImageUrl edge cases', () {
    test('parses with relative cdnPath returns null without Environment', () {
      // Relative cdnPath requires Environment.cdnUrl which is not initialized in test
      // so _resolveImageUrl catches the LateInitializationError and returns null
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "splash/image.jpg", "version": 1}',
      );
      // Without Environment configured, this returns null due to catch block
      expect(payload, isNull);
    });

    test('parses with cdnPath starting with slash returns null without Environment', () {
      // Relative cdnPath with leading slash also requires Environment.cdnUrl
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "/splash/leading-slash.jpg", "version": 1}',
      );
      // Without Environment configured, this returns null due to catch block
      expect(payload, isNull);
    });

    test('parses with http:// cdnPath', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "http://cdn.example.com/splash.jpg", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'http://cdn.example.com/splash.jpg');
    });

    test('prefers cdnUrl over cdnPath when both present', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/url.jpg", "cdn_path": "path.jpg", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/url.jpg');
    });

    test('empty cdnUrl falls back to cdnPath', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "", "cdn_path": "https://cdn.example.com/fallback.jpg", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/fallback.jpg');
    });

    test('whitespace-only cdnUrl falls back to cdnPath', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "   ", "cdn_path": "https://cdn.example.com/ws.jpg", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/ws.jpg');
    });

    test('returns null when both cdnUrl and cdnPath are empty', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "", "cdn_path": "", "version": 1}',
      );
      expect(payload, isNull);
    });

    test('returns null when both cdnUrl and cdnPath are missing', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"version": 1}',
      );
      expect(payload, isNull);
    });
  });

  group('SplashConfigPayload._parseVersion edge cases', () {
    test('handles VERSION uppercase key', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.jpg", "VERSION": 10}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 10);
    });

    test('handles numeric version as double', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.jpg", "version": 3.5}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 3);
    });

    test('handles empty string version defaults to 1', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.jpg", "version": ""}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });

    test('handles non-parseable string version defaults to 1', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.jpg", "version": "abc"}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });
  });

  group('SplashConfigPayload enabled/expired', () {
    test('isValid returns false for empty imageUrl', () {
      // This case should not happen due to _resolveImageUrl check
      // but test the property directly
      final payload = SplashConfigPayload(
        imageUrl: '',
        version: 1,
      );
      expect(payload.isValid, isFalse);
    });

    test('isExpired returns false when expiresAt is null', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://cdn.example.com/img.jpg',
        version: 1,
        expiresAt: null,
      );
      expect(payload.isExpired, isFalse);
    });
  });

  group('SplashImageData._parseDate edge cases', () {
    test('handles null date value', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': null,
      });
      expect(data.startDate, isNull);
    });

    test('handles empty string date value', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': '',
      });
      expect(data.startDate, isNull);
    });

    test('handles integer date value (non-string)', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': 12345,
      });
      expect(data.startDate, isNull);
    });

    test('handles boolean date value (non-string)', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': true,
      });
      expect(data.startDate, isNull);
    });

    test('handles valid ISO 8601 date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': '2025-06-15T12:00:00Z',
      });
      expect(data.startDate, isNotNull);
      expect(data.startDate!.year, 2025);
      expect(data.startDate!.month, 6);
    });

    test('handles unparseable date string returns null', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': 'invalid-date-string',
      });
      expect(data.startDate, isNull);
    });
  });

  group('SplashImageData fromJson key aliases', () {
    test('uses imageUrl key when image_url is missing', () {
      final data = SplashImageData.fromJson({
        'imageUrl': 'https://example.com/alias.jpg',
      });
      expect(data.imageUrl, 'https://example.com/alias.jpg');
    });

    test('uses empty string when both keys are missing', () {
      final data = SplashImageData.fromJson({});
      expect(data.imageUrl, '');
      expect(data.isValid, isFalse);
    });

    test('uses startDate key when starts_at is missing', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'startDate': '2025-01-01T00:00:00Z',
      });
      expect(data.startDate, isNotNull);
    });

    test('uses endDate key when ends_at is missing', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'endDate': '2030-01-01T00:00:00Z',
      });
      expect(data.endDate, isNotNull);
    });
  });
}
