import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';

/// Extended tests for SplashImageData and SplashConfigPayload
/// focusing on uncovered branches and edge cases.
void main() {
  group('SplashConfigPayload._resolveImageUrl edge cases', () {
    test('cdn_path starting with http:// is treated as full URL', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "http://cdn.example.com/splash.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'http://cdn.example.com/splash.png');
    });

    test('cdnUrl with whitespace is trimmed', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "  https://cdn.example.com/splash.png  ", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/splash.png');
    });

    test('cdn_path with whitespace is trimmed', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "  https://cdn.example.com/splash.png  ", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/splash.png');
    });

    test('empty cdn_path returns null payload', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "", "version": 1}',
      );
      expect(payload, isNull);
    });

    test('cdnUrl is non-string type is treated as empty', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": 123, "cdn_path": "https://cdn.example.com/splash.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/splash.png');
    });

    test('cdn_path is non-string type and no cdnUrl returns null', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": 123, "version": 1}',
      );
      expect(payload, isNull);
    });

    test('whitespace-only cdnUrl falls back to cdn_path', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "   ", "cdn_path": "https://cdn.example.com/image.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/image.png');
    });

    test('whitespace-only cdn_path returns null', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "   ", "version": 1}',
      );
      expect(payload, isNull);
    });
  });

  group('SplashConfigPayload._parseVersion edge cases', () {
    test('version as negative number', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": -1}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, -1);
    });

    test('version as zero', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 0}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 0);
    });

    test('version as non-numeric string defaults to 1', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": "abc"}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });

    test('version as boolean is treated as null (defaults to 1)', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": true}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });

    test('version as list is treated as null (defaults to 1)', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": [1, 2]}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });
  });

  group('SplashConfigPayload enabled field', () {
    test('enabled as string defaults to true', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "enabled": "false"}',
      );
      expect(payload, isNotNull);
      expect(payload!.enabled, true); // non-bool defaults to true
    });

    test('enabled as integer defaults to true', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "enabled": 0}',
      );
      expect(payload, isNotNull);
      expect(payload!.enabled, true); // non-bool defaults to true
    });

    test('enabled as null defaults to true', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "enabled": null}',
      );
      expect(payload, isNotNull);
      expect(payload!.enabled, true);
    });
  });

  group('SplashConfigPayload expiresAt parsing', () {
    test('expiresAt as non-string is ignored', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "expiresAt": 12345}',
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAt, isNull);
    });

    test('expiresAt as invalid date string is null', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "expiresAt": "not-a-date"}',
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAt, isNull);
    });

    test('expires_at with valid ISO date', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "expires_at": "2030-06-15T12:00:00Z"}',
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAt, isNotNull);
      expect(payload.expiresAt!.year, 2030);
      expect(payload.expiresAt!.month, 6);
    });
  });

  group('SplashImageData constructor and toJson', () {
    test('constructor with all parameters', () {
      final now = DateTime.now();
      final data = SplashImageData(
        imageUrl: 'https://example.com/img.png',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        deepLinkUrl: 'picnic://vote/1',
        platform: 'android',
        metadata: {'key': 'value', 'num': 42},
      );

      expect(data.imageUrl, 'https://example.com/img.png');
      expect(data.startDate, now);
      expect(data.deepLinkUrl, 'picnic://vote/1');
      expect(data.platform, 'android');
      expect(data.metadata!['key'], 'value');
      expect(data.metadata!['num'], 42);
      expect(data.isValid, true);
      expect(data.isExpired, false);
    });

    test('toJson includes all fields', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 12, 31);
      final data = SplashImageData(
        imageUrl: 'https://example.com/img.png',
        startDate: start,
        endDate: end,
        deepLinkUrl: 'picnic://home',
        platform: 'ios',
        metadata: {'source': 'test'},
      );

      final json = data.toJson();
      expect(json['image_url'], 'https://example.com/img.png');
      expect(json['starts_at'], isNotNull);
      expect(json['ends_at'], isNotNull);
      expect(json['deep_link_url'], 'picnic://home');
      expect(json['platform'], 'ios');
      expect(json['metadata'], isA<Map>());
    });

    test('toJson with null optional fields', () {
      const data = SplashImageData(imageUrl: 'https://example.com/img.png');
      final json = data.toJson();
      expect(json['starts_at'], isNull);
      expect(json['ends_at'], isNull);
      expect(json['deep_link_url'], isNull);
      expect(json['platform'], isNull);
      expect(json['metadata'], isNull);
    });
  });

  group('SplashImageData.fromJson alternative keys', () {
    test('uses imageUrl key when image_url is missing', () {
      final data = SplashImageData.fromJson({
        'imageUrl': 'https://example.com/alt.png',
      });
      expect(data.imageUrl, 'https://example.com/alt.png');
    });

    test('image_url takes priority over imageUrl', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/primary.png',
        'imageUrl': 'https://example.com/alt.png',
      });
      expect(data.imageUrl, 'https://example.com/primary.png');
    });

    test('starts_at key for date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/img.png',
        'starts_at': '2025-03-15T08:00:00Z',
      });
      expect(data.startDate, isNotNull);
      expect(data.startDate!.month, 3);
      expect(data.startDate!.day, 15);
    });

    test('ends_at key for date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/img.png',
        'ends_at': '2025-12-25T00:00:00Z',
      });
      expect(data.endDate, isNotNull);
      expect(data.endDate!.month, 12);
      expect(data.endDate!.day, 25);
    });
  });

  group('SplashConfigPayload direct constructor', () {
    test('isValid with non-empty imageUrl', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://example.com/img.png',
        version: 1,
      );
      expect(payload.isValid, true);
    });

    test('isValid with empty imageUrl', () {
      final payload = SplashConfigPayload(
        imageUrl: '',
        version: 1,
      );
      expect(payload.isValid, false);
    });

    test('isExpired with null expiresAt', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://example.com/img.png',
        version: 1,
      );
      expect(payload.isExpired, false);
    });

    test('isExpired with future expiresAt', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://example.com/img.png',
        version: 1,
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
      expect(payload.isExpired, false);
    });

    test('isExpired with past expiresAt', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://example.com/img.png',
        version: 1,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(payload.isExpired, true);
    });

    test('enabled defaults to true', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://example.com/img.png',
        version: 1,
      );
      expect(payload.enabled, true);
    });

    test('enabled can be set to false', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://example.com/img.png',
        version: 1,
        enabled: false,
      );
      expect(payload.enabled, false);
    });
  });
}
