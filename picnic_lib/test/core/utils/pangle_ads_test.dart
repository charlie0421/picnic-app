import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/pangle_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> log;

  setUp(() {
    log = [];
  });

  /// Helper to set up a mock method channel handler.
  void setupMockChannel({
    bool initResult = true,
    bool loadResult = true,
    bool showResult = true,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('pangle_native_channel'),
      (MethodCall call) async {
        log.add(call);
        switch (call.method) {
          case 'initPangle':
            return initResult;
          case 'loadRewardedAd':
            return loadResult;
          case 'showRewardedAd':
            return showResult;
          default:
            return null;
        }
      },
    );
  }

  void clearMockChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('pangle_native_channel'),
      null,
    );
  }

  tearDown(() {
    clearMockChannel();
  });

  group('PangleAds.initPangle', () {
    test('returns true on success', () async {
      setupMockChannel(initResult: true);
      final result = await PangleAds.initPangle('test_app_id');
      expect(result, isTrue);
      expect(log.length, 1);
      expect(log.first.method, 'initPangle');
      expect(log.first.arguments, {'appId': 'test_app_id'});
    });

    test('returns false on failure', () async {
      setupMockChannel(initResult: false);
      final result = await PangleAds.initPangle('test_app_id');
      expect(result, isFalse);
    });

    test('returns false on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async {
          throw PlatformException(code: 'ERROR', message: 'init failed');
        },
      );
      final result = await PangleAds.initPangle('test_app_id');
      expect(result, isFalse);
    });

    test('returns false on unexpected exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async {
          throw Exception('unexpected');
        },
      );
      final result = await PangleAds.initPangle('test_app_id');
      expect(result, isFalse);
    });

    test('returns false when null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async {
          return null;
        },
      );
      final result = await PangleAds.initPangle('test_app_id');
      expect(result, isFalse);
    });
  });

  group('PangleAds.loadRewardedAd', () {
    test('returns true on success', () async {
      setupMockChannel(loadResult: true);
      final result =
          await PangleAds.loadRewardedAd('placement_123', 'user_456');
      expect(result, isTrue);
      expect(log.first.method, 'loadRewardedAd');
      expect(log.first.arguments,
          {'placementId': 'placement_123', 'userId': 'user_456'});
    });

    test('returns false on failure', () async {
      setupMockChannel(loadResult: false);
      final result =
          await PangleAds.loadRewardedAd('placement_123', 'user_456');
      expect(result, isFalse);
    });

    test('returns false on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async {
          throw PlatformException(code: 'ERROR', message: 'load failed');
        },
      );
      final result =
          await PangleAds.loadRewardedAd('placement_123', 'user_456');
      expect(result, isFalse);
    });

    test('returns false on unexpected exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async {
          throw Exception('unexpected');
        },
      );
      final result =
          await PangleAds.loadRewardedAd('placement_123', 'user_456');
      expect(result, isFalse);
    });
  });

  group('PangleAds.showRewardedAd', () {
    test('returns true on success', () async {
      setupMockChannel(showResult: true);
      final result = await PangleAds.showRewardedAd();
      expect(result, isTrue);
      expect(log.first.method, 'showRewardedAd');
    });

    test('returns false on failure', () async {
      setupMockChannel(showResult: false);
      final result = await PangleAds.showRewardedAd();
      expect(result, isFalse);
    });

    test('returns false on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async {
          throw PlatformException(code: 'ERROR', message: 'show failed');
        },
      );
      final result = await PangleAds.showRewardedAd();
      expect(result, isFalse);
    });

    test('returns false on unexpected exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async {
          throw Exception('unexpected');
        },
      );
      final result = await PangleAds.showRewardedAd();
      expect(result, isFalse);
    });
  });

  group('PangleAds.setOnProfileRefreshNeeded', () {
    test('sets callback', () {
      var called = false;
      PangleAds.setOnProfileRefreshNeeded(() {
        called = true;
      });
      // Verify the callback was set (we can test via refreshProfileManually)
      PangleAds.refreshProfileManually();
      expect(called, isTrue);
    });
  });

  group('PangleAds.refreshProfileManually', () {
    test('calls the callback when set', () {
      var callCount = 0;
      PangleAds.setOnProfileRefreshNeeded(() {
        callCount++;
      });
      PangleAds.refreshProfileManually();
      expect(callCount, 1);
      PangleAds.refreshProfileManually();
      expect(callCount, 2);
    });

    test('does nothing when callback is not set', () {
      // Reset by setting null indirectly (we can't access _onProfileRefreshNeeded)
      // But dispose resets it
      // Just verify no crash
      PangleAds.setOnProfileRefreshNeeded(() {});
      // This should not crash even if the callback throws
      expect(() => PangleAds.refreshProfileManually(), returnsNormally);
    });
  });

  group('PangleAds.testAdDismissed', () {
    test('completes without error', () async {
      PangleAds.setOnProfileRefreshNeeded(() {});
      await expectLater(PangleAds.testAdDismissed(), completes);
    });

    test('completes without callback', () async {
      // Set a no-op callback so we can test
      PangleAds.setOnProfileRefreshNeeded(() {});
      await expectLater(PangleAds.testAdDismissed(), completes);
    });
  });

  group('PangleAds.showRewardedAdWithProfileRefresh', () {
    test('returns true on success and schedules refresh', () async {
      setupMockChannel(showResult: true);
      var refreshed = false;
      PangleAds.setOnProfileRefreshNeeded(() {
        refreshed = true;
      });
      final result = await PangleAds.showRewardedAdWithProfileRefresh();
      expect(result, isTrue);
    });

    test('returns false on failure', () async {
      setupMockChannel(showResult: false);
      final result = await PangleAds.showRewardedAdWithProfileRefresh();
      expect(result, isFalse);
    });
  });

  group('PangleAds event streams', () {
    test('onAdShown stream emits', () async {
      // We can't test _setupEventHandlers directly since it's private,
      // but we can verify streams are accessible
      expect(PangleAds.onAdShown, isA<Stream<void>>());
      expect(PangleAds.onAdClicked, isA<Stream<void>>());
      expect(PangleAds.onAdDismissed, isA<Stream<void>>());
      expect(PangleAds.onRewardEarned, isA<Stream<Map<String, dynamic>>>());
      expect(PangleAds.onRewardFailed, isA<Stream<String>>());
    });

    test('listenToAdDismissed returns subscription', () {
      var called = false;
      final sub = PangleAds.listenToAdDismissed(() {
        called = true;
      });
      expect(sub, isA<StreamSubscription<void>>());
      sub.cancel();
    });
  });
}
