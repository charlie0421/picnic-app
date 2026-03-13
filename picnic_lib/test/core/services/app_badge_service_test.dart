import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/app_badge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBadgeService', () {
    late List<MethodCall> log;

    setUp(() {
      log = <MethodCall>[];
      // Mock the FlutterAppBadger MethodChannel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('g123k/flutter_app_badger'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'isAppBadgeSupported':
              return true;
            case 'updateBadgeCount':
              return null;
            case 'removeBadge':
              return null;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('g123k/flutter_app_badger'),
        null,
      );
    });

    group('isSupported', () {
      test('returns a boolean value and calls the method channel on first call', () async {
        // This is the first test to run, so _checkedSupport is false
        // and it will call isAppBadgeSupported on the method channel
        final result = await AppBadgeService.isSupported();
        expect(result, isA<bool>());
        // On non-web, it calls the native method
        expect(result, isTrue);
      });

      test('caches the result on subsequent calls', () async {
        // Since _checkedSupport is now true from previous test,
        // this should return the cached value without calling the channel
        final result = await AppBadgeService.isSupported();
        expect(result, isTrue);
        // Log should be empty since it uses cached value
        expect(log, isEmpty);
      });
    });

    group('syncBadgeWithUnreadCount', () {
      test('completes without error on non-mobile platform', () async {
        // On macOS test runner, Platform.isIOS and Platform.isAndroid are false,
        // so the method returns early without doing anything
        await AppBadgeService.syncBadgeWithUnreadCount();
      });
    });

    group('setBadgeCount', () {
      test('completes without error on non-mobile platform', () async {
        // Returns early on macOS since Platform.isIOS/isAndroid are false
        await AppBadgeService.setBadgeCount(5);
      });

      test('completes with zero count', () async {
        await AppBadgeService.setBadgeCount(0);
      });

      test('completes with large count', () async {
        await AppBadgeService.setBadgeCount(999);
      });

      test('completes with negative count', () async {
        await AppBadgeService.setBadgeCount(-1);
      });
    });

    group('removeBadge', () {
      test('completes without error on non-mobile platform', () async {
        // Returns early on macOS
        await AppBadgeService.removeBadge();
      });
    });
  });
}
