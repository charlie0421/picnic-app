import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Minimal config to initialize Environment (needed by SplashConfigPayload.fromRaw)
  final _minimalConfig = {
    'storage': {'cdn_url': 'https://cdn.test.co'},
  };

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final codec = const StringCodec();
        final requestedAsset = codec.decodeMessage(message!);
        if (requestedAsset == 'config/test.json') {
          return codec.encodeMessage(json.encode(_minimalConfig));
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  // Initialize Environment before SplashConfigPayload tests
  Future<void> ensureEnvironmentInitialized() async {
    try {
      // ignore if already initialized
      Environment.cdnUrl;
    } catch (_) {
      await Environment.initConfig('test');
    }
  }

  group('SplashImageData', () {
    test('creates from json with image_url', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
      });
      expect(data.imageUrl, 'https://example.com/splash.png');
      expect(data.isValid, true);
    });

    test('creates from json with imageUrl', () {
      final data = SplashImageData.fromJson({
        'imageUrl': 'https://example.com/splash.png',
      });
      expect(data.imageUrl, 'https://example.com/splash.png');
    });

    test('isValid returns false for empty url', () {
      final data = SplashImageData.fromJson({});
      expect(data.isValid, false);
    });

    test('isExpired returns true for past date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'ends_at': '2020-01-01T00:00:00Z',
      });
      expect(data.isExpired, true);
    });

    test('isExpired returns false for future date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'ends_at': '2099-01-01T00:00:00Z',
      });
      expect(data.isExpired, false);
    });

    test('isExpired returns false when endDate is null', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
      });
      expect(data.isExpired, false);
    });

    test('toJson roundtrip', () {
      final original = SplashImageData(
        imageUrl: 'https://example.com/img.png',
        deepLinkUrl: 'picnic://home',
        platform: 'ios',
      );
      final json = original.toJson();
      final restored = SplashImageData.fromJson(json);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.deepLinkUrl, original.deepLinkUrl);
      expect(restored.platform, original.platform);
    });

    test('parses dates correctly', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'starts_at': '2025-06-01T10:00:00Z',
        'ends_at': '2025-12-31T23:59:59Z',
      });
      expect(data.startDate, isNotNull);
      expect(data.endDate, isNotNull);
      expect(data.startDate!.year, 2025);
      expect(data.endDate!.month, 12);
    });

    test('handles null dates gracefully', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'starts_at': null,
        'ends_at': null,
      });
      expect(data.startDate, isNull);
      expect(data.endDate, isNull);
    });
  });

  group('SplashConfigPayload', () {
    setUp(() async {
      await ensureEnvironmentInitialized();
    });

    test('parses valid json', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.png", "version": 2}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/splash.png');
      expect(payload.version, 2);
      expect(payload.isValid, true);
    });

    test('returns null for empty string', () {
      expect(SplashConfigPayload.fromRaw(''), isNull);
    });

    test('returns null for null', () {
      expect(SplashConfigPayload.fromRaw(null), isNull);
    });

    test('returns null for invalid json', () {
      expect(SplashConfigPayload.fromRaw('not json'), isNull);
    });

    test('returns null when no image url', () {
      final payload = SplashConfigPayload.fromRaw('{"version": 1}');
      expect(payload, isNull);
    });

    test('handles version as string', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": "3"}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 3);
    });

    test('defaults version to 1', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png"}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });

    test('isExpired returns true for past date', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "expiresAt": "2020-01-01T00:00:00Z"}',
      );
      expect(payload, isNotNull);
      expect(payload!.isExpired, true);
    });

    test('isExpired returns false for future date', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "expiresAt": "2099-12-31T23:59:59Z"}',
      );
      expect(payload, isNotNull);
      expect(payload!.isExpired, false);
    });

    test('enabled defaults to true', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1}',
      );
      expect(payload!.enabled, true);
    });

    test('respects enabled false', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "enabled": false}',
      );
      expect(payload!.enabled, false);
    });

    test('handles cdn_path with full url', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "https://full-url.com/splash.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://full-url.com/splash.png');
    });

    test('returns null for non-map json', () {
      expect(SplashConfigPayload.fromRaw('"just a string"'), isNull);
    });

    test('parses Version key (capitalized)', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "Version": 5}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 5);
    });

    test('parses VERSION key (uppercase)', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "VERSION": 7}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 7);
    });

    test('parses expires_at key', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "expires_at": "2025-06-01T00:00:00Z"}',
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAt, isNotNull);
      expect(payload.expiresAt!.year, 2025);
    });

    test('handles cdn_url key', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_url": "https://cdn.example.com/splash.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/splash.png');
    });

    test('cdnPath key (alternative)', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnPath": "https://full-url.com/splash.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://full-url.com/splash.png');
    });

    test('isValid returns false for empty imageUrl', () {
      final payload = SplashConfigPayload(imageUrl: '', version: 1);
      expect(payload.isValid, isFalse);
    });

    test('isExpired returns false when expiresAt is null', () {
      final payload = SplashConfigPayload(
        imageUrl: 'https://example.com',
        version: 1,
      );
      expect(payload.isExpired, isFalse);
    });

    test('handles empty expiresAt string', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "expiresAt": ""}',
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAt, isNull);
    });

    test('handles null version value', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": null}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });
  });

  group('SplashImageData metadata', () {
    test('parses metadata as map', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/img.png',
        'metadata': {'campaign': 'summer', 'priority': 1},
      });
      expect(data.metadata, isNotNull);
      expect(data.metadata!['campaign'], 'summer');
    });

    test('null metadata when not present', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/img.png',
      });
      expect(data.metadata, isNull);
    });

    test('toJson includes null fields', () {
      const data = SplashImageData(imageUrl: 'https://example.com/img.png');
      final json = data.toJson();
      expect(json.containsKey('starts_at'), isTrue);
      expect(json['starts_at'], isNull);
    });
  });

  group('SplashImageData date parsing edge cases', () {
    test('empty date string returns null', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/img.png',
        'starts_at': '',
      });
      expect(data.startDate, isNull);
    });

    test('invalid date string returns null', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/img.png',
        'starts_at': 'not-a-date',
      });
      expect(data.startDate, isNull);
    });

    test('numeric date value returns null', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/img.png',
        'starts_at': 12345,
      });
      expect(data.startDate, isNull);
    });
  });
}
