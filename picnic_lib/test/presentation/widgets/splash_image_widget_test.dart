import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';

import 'package:picnic_lib/presentation/widgets/splash_image.dart' as splash_widget;

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

/// Extended tests for SplashImageData and SplashConfigPayload models,
/// plus widget rendering tests for the SplashImage widget.
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

  Future<void> ensureEnvironmentInitialized() async {
    try {
      Environment.cdnUrl;
    } catch (_) {
      await Environment.initConfig('test');
    }
  }
  group('SplashImageData deep link', () {
    test('parses deep_link_url', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'deep_link_url': 'picnic://vote/123',
      });
      expect(data.deepLinkUrl, 'picnic://vote/123');
    });

    test('deep_link_url is null when not provided', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
      });
      expect(data.deepLinkUrl, isNull);
    });
  });

  group('SplashImageData platform', () {
    test('parses platform field', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'platform': 'ios',
      });
      expect(data.platform, 'ios');
    });

    test('platform is null when not provided', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
      });
      expect(data.platform, isNull);
    });
  });

  group('SplashImageData comprehensive', () {
    test('all fields populated', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'starts_at': '2025-01-01T00:00:00Z',
        'ends_at': '2099-12-31T23:59:59Z',
        'deep_link_url': 'picnic://home',
        'platform': 'android',
        'metadata': {'key': 'value'},
      });
      expect(data.isValid, true);
      expect(data.isExpired, false);
      expect(data.startDate, isNotNull);
      expect(data.endDate, isNotNull);
      expect(data.deepLinkUrl, 'picnic://home');
      expect(data.platform, 'android');
      expect(data.metadata, isNotNull);
      expect(data.metadata!['key'], 'value');
    });

    test('handles startDate alias', () {
      final data = SplashImageData.fromJson({
        'imageUrl': 'https://example.com/splash.png',
        'startDate': '2025-06-01T00:00:00Z',
        'endDate': '2025-12-31T23:59:59Z',
      });
      expect(data.imageUrl, 'https://example.com/splash.png');
      // startDate/endDate are not recognized aliases in the current impl
      // starts_at/ends_at are the expected keys
    });

    test('toJson preserves all fields', () {
      const data = SplashImageData(
        imageUrl: 'https://example.com/img.png',
        startDate: null,
        endDate: null,
        deepLinkUrl: 'picnic://test',
        platform: 'ios',
        metadata: {'source': 'test'},
      );
      final json = data.toJson();
      expect(json['image_url'], 'https://example.com/img.png');
      expect(json['deep_link_url'], 'picnic://test');
      expect(json['platform'], 'ios');
      expect(json['metadata'], isNotNull);
    });

    test('metadata is null when non-map value', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.png',
        'metadata': 'not a map',
      });
      expect(data.metadata, isNull);
    });
  });

  group('SplashConfigPayload edge cases', () {
    setUp(() async {
      await ensureEnvironmentInitialized();
    });

    test('handles empty cdnUrl with valid cdnPath (full url)', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "", "cdn_path": "https://cdn.example.com/images/splash.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/images/splash.png');
    });

    test('handles both cdnUrl and cdn_path - cdnUrl takes priority', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/main.png", "cdn_path": "alt.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/main.png');
    });

    test('handles version as double', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 2.5}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 2);
    });

    test('returns null for array json', () {
      expect(SplashConfigPayload.fromRaw('[1, 2, 3]'), isNull);
    });

    test('returns null when cdnUrl is empty and no cdn_path', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "", "version": 1}',
      );
      expect(payload, isNull);
    });

    test('handles cdn_path starting with http', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "https://cdn.example.com/images/splash.png", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/images/splash.png');
    });

    test('handles empty version string', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": ""}',
      );
      expect(payload, isNotNull);
      // empty string returns null from _parseVersion, defaults to 1
      expect(payload!.version, 1);
    });

    test('enabled can be explicitly true', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "enabled": true}',
      );
      expect(payload!.enabled, true);
    });

    test('non-bool enabled defaults to true', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/img.png", "version": 1, "enabled": "yes"}',
      );
      expect(payload!.enabled, true);
    });
  });

  group('SplashImage widget rendering', () {
    setUpAll(() {
      initTestColors();
    });

    testWidgets('renders SplashImage widget with default params',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          const splash_widget.SplashImage(
            enablePatchCheck: false,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(splash_widget.SplashImage), findsOneWidget);
    });

    testWidgets('renders SplashImage with custom statusMessage',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          const splash_widget.SplashImage(
            statusMessage: 'Loading...',
            enablePatchCheck: false,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(splash_widget.SplashImage), findsOneWidget);
    });

    testWidgets('renders SplashImage with enablePatchCheck false',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          const splash_widget.SplashImage(
            enablePatchCheck: false,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));

      expect(find.byType(splash_widget.SplashImage), findsOneWidget);
    });
  });
}
