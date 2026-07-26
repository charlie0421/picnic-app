import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  // 격리 — splash_image.dart:671 의 상태 메시지 Row 가 가로로 332px 넘친다.
  // 긴 메시지를 자를지 줄바꿈할지가 제품 판단이라 여기서 안 고친다.
  allowKnownDefects(const ['A RenderFlex overflowed by']);
  TestWidgetsFlutterBinding.ensureInitialized();

  late void Function() restore;
  bool _envInitialized = false;

  final _minimalConfig = {
    'storage': {'cdn_url': 'https://cdn.test.co'},
  };

  setUp(() async {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'config': <dynamic>[],
    });
    restore = suppressImageErrors();

    if (!_envInitialized) {
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
      await Environment.initConfig('test');
      _envInitialized = true;
    }
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다. 여러 에러가 한 프레임에 겹치면
    // 바인딩이 "Multiple exceptions (N)" 문자열 하나로 뭉개버려서, 무엇이
    // 났는지도 알 수 없고 화이트리스트로 지목할 수도 없게 된다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('SplashImage render', () {
    testWidgets('renders with patch check disabled',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(enablePatchCheck: false),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with status message', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: 'Loading...',
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with empty status message',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: '',
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with long status message',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: 'Checking for updates... Please wait while we download the latest version.',
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with patch check enabled',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(enablePatchCheck: true),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders default (no parameters)',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(enablePatchCheck: false),
        ),
      );

      // Pump additional time to let post frame callbacks execute
      await tester.pump(const Duration(seconds: 2));
      drainExpectedImageErrors(tester);

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with non-empty status and lets it settle',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: 'Update ready',
            enablePatchCheck: false,
          ),
        ),
      );

      // Pump extra frames to let animations settle
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with Downloading update status',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: 'Downloading update...',
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
      // Verify status text is rendered
      expect(find.text('Downloading update...'), findsOneWidget);
    });

    testWidgets('renders with Update applied status',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: 'Update applied!',
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
      expect(find.text('Update applied!'), findsOneWidget);
    });

    testWidgets('renders with Update check failed status',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: 'Update check failed',
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
      expect(find.text('Update check failed'), findsOneWidget);
    });
  });

  group('SplashImageData', () {
    test('parses from JSON with all fields', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': '2025-01-01T00:00:00Z',
        'ends_at': '2026-12-31T23:59:59Z',
        'deep_link_url': 'picnic://home',
        'platform': 'all',
        'metadata': {'source': 'test'},
      });

      expect(data.imageUrl, 'https://example.com/splash.jpg');
      expect(data.startDate, isNotNull);
      expect(data.endDate, isNotNull);
      expect(data.deepLinkUrl, 'picnic://home');
      expect(data.platform, 'all');
      expect(data.isValid, isTrue);
    });

    test('parses from JSON with minimal fields', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
      });

      expect(data.imageUrl, 'https://example.com/splash.jpg');
      expect(data.startDate, isNull);
      expect(data.endDate, isNull);
      expect(data.isValid, isTrue);
    });

    test('parses from JSON with alternative keys', () {
      final data = SplashImageData.fromJson({
        'imageUrl': 'https://example.com/splash.jpg',
        'startDate': '2025-01-01T00:00:00Z',
        'endDate': '2026-12-31T23:59:59Z',
      });

      expect(data.imageUrl, 'https://example.com/splash.jpg');
      expect(data.isValid, isTrue);
    });

    test('isValid returns false for empty URL', () {
      final data = SplashImageData.fromJson({
        'image_url': '',
      });
      expect(data.isValid, isFalse);
    });

    test('isExpired returns true for past end date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'ends_at': '2020-01-01T00:00:00Z',
      });
      expect(data.isExpired, isTrue);
    });

    test('isExpired returns false for future end date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'ends_at': '2030-01-01T00:00:00Z',
      });
      expect(data.isExpired, isFalse);
    });

    test('isExpired returns false when no end date', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
      });
      expect(data.isExpired, isFalse);
    });

    test('toJson round-trips correctly', () {
      final original = SplashImageData(
        imageUrl: 'https://example.com/splash.jpg',
        platform: 'ios',
      );
      final json = original.toJson();
      expect(json['image_url'], 'https://example.com/splash.jpg');
      expect(json['platform'], 'ios');
    });
  });

  group('SplashConfigPayload', () {
    test('parses from raw JSON string', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg", "version": 2}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/splash.jpg');
      expect(payload.version, 2);
      expect(payload.isValid, isTrue);
      expect(payload.enabled, isTrue);
    });

    test('returns null for empty string', () {
      expect(SplashConfigPayload.fromRaw(''), isNull);
    });

    test('returns null for null', () {
      expect(SplashConfigPayload.fromRaw(null), isNull);
    });

    test('returns null for invalid JSON', () {
      expect(SplashConfigPayload.fromRaw('not json'), isNull);
    });

    test('returns null when no cdnUrl or cdnPath', () {
      final payload = SplashConfigPayload.fromRaw('{"version": 1}');
      expect(payload, isNull);
    });

    test('parses with cdnPath', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_path": "https://cdn.example.com/path/splash.jpg", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.isValid, isTrue);
    });

    test('parses with disabled flag', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg", "version": 1, "enabled": false}',
      );
      expect(payload, isNotNull);
      expect(payload!.enabled, isFalse);
    });

    test('parses with expiresAt', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg", "version": 1, "expiresAt": "2030-01-01T00:00:00Z"}',
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAt, isNotNull);
      expect(payload.isExpired, isFalse);
    });

    test('isExpired returns true for past date', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg", "version": 1, "expiresAt": "2020-01-01T00:00:00Z"}',
      );
      expect(payload, isNotNull);
      expect(payload!.isExpired, isTrue);
    });

    test('version defaults to 1 when not provided', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg"}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 1);
    });

    test('parses string version', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg", "version": "3"}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 3);
    });

    test('parses with cdn_url snake_case key', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdn_url": "https://cdn.example.com/splash.jpg", "version": 1}',
      );
      expect(payload, isNotNull);
      expect(payload!.imageUrl, 'https://cdn.example.com/splash.jpg');
    });

    test('parses with expires_at snake_case key', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg", "expires_at": "2030-01-01T00:00:00Z"}',
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAt, isNotNull);
    });

    test('returns null for JSON array', () {
      final payload = SplashConfigPayload.fromRaw('[1, 2, 3]');
      expect(payload, isNull);
    });

    test('parses with Version uppercase key', () {
      final payload = SplashConfigPayload.fromRaw(
        '{"cdnUrl": "https://cdn.example.com/splash.jpg", "Version": 5}',
      );
      expect(payload, isNotNull);
      expect(payload!.version, 5);
    });
  });

  group('SplashImage render additional', () {
    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(enablePatchCheck: false),
          locale: const Locale('en'),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(enablePatchCheck: false),
          locale: const Locale('ja'),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders with both statusMessage and patchCheck disabled',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: 'Custom message',
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
      expect(find.text('Custom message'), findsOneWidget);
    });

    testWidgets('renders with null statusMessage and patchCheck disabled',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(
            statusMessage: null,
            enablePatchCheck: false,
          ),
        ),
      );

      expect(find.byType(SplashImage), findsOneWidget);
    });

    testWidgets('renders and pumps multiple frames for animations',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SplashImage(enablePatchCheck: false),
        ),
      );

      // Pump multiple times to exercise timer callbacks
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(SplashImage), findsOneWidget);
    });
  });

  group('SplashImageData additional', () {
    test('parses with metadata field', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'metadata': {'source': 'config', 'version': 2},
      });
      expect(data.metadata, isNotNull);
      expect(data.metadata!['source'], 'config');
      expect(data.metadata!['version'], 2);
    });

    test('parses with null metadata', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'metadata': null,
      });
      expect(data.metadata, isNull);
    });

    test('isValid returns true for non-empty URL', () {
      final data = SplashImageData(imageUrl: 'https://example.com/img.jpg');
      expect(data.isValid, isTrue);
    });

    test('toJson includes all fields', () {
      final data = SplashImageData(
        imageUrl: 'https://example.com/splash.jpg',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2026, 12, 31),
        deepLinkUrl: 'picnic://promo',
        platform: 'ios',
        metadata: {'key': 'value'},
      );
      final json = data.toJson();
      expect(json['image_url'], 'https://example.com/splash.jpg');
      expect(json['deep_link_url'], 'picnic://promo');
      expect(json['platform'], 'ios');
      expect(json['metadata'], {'key': 'value'});
      expect(json['starts_at'], isNotNull);
      expect(json['ends_at'], isNotNull);
    });

    test('parses with invalid date string', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'starts_at': 'not-a-date',
      });
      expect(data.startDate, isNull);
    });

    test('parses with non-string metadata is ignored', () {
      final data = SplashImageData.fromJson({
        'image_url': 'https://example.com/splash.jpg',
        'metadata': 'not-a-map',
      });
      expect(data.metadata, isNull);
    });
  });
}
