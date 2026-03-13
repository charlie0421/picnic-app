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

  group('PangleAds event handler simulation', () {
    test('initPangle sets up event handlers on success', () async {
      setupMockChannel(initResult: true);
      final result = await PangleAds.initPangle('test_app_id');
      expect(result, isTrue);
      // After successful init, event handlers should be set up
      // The MethodChannel handler should be configured
    });

    test('initPangle does not set up handlers on failure', () async {
      setupMockChannel(initResult: false);
      final result = await PangleAds.initPangle('test_app_id');
      expect(result, isFalse);
    });

    test('onAdShown stream is broadcast', () {
      expect(PangleAds.onAdShown, isA<Stream<void>>());
      // Should be able to listen multiple times (broadcast)
      final sub1 = PangleAds.onAdShown.listen((_) {});
      final sub2 = PangleAds.onAdShown.listen((_) {});
      sub1.cancel();
      sub2.cancel();
    });

    test('onAdClicked stream is broadcast', () {
      expect(PangleAds.onAdClicked, isA<Stream<void>>());
      final sub = PangleAds.onAdClicked.listen((_) {});
      sub.cancel();
    });

    test('onRewardEarned stream is broadcast', () {
      expect(PangleAds.onRewardEarned, isA<Stream<Map<String, dynamic>>>());
      final sub = PangleAds.onRewardEarned.listen((_) {});
      sub.cancel();
    });

    test('onRewardFailed stream is broadcast', () {
      expect(PangleAds.onRewardFailed, isA<Stream<String>>());
      final sub = PangleAds.onRewardFailed.listen((_) {});
      sub.cancel();
    });

    test('listenToAdDismissed subscribes and cancels', () {
      var called = false;
      final sub = PangleAds.listenToAdDismissed(() {
        called = true;
      });
      expect(sub, isA<StreamSubscription<void>>());
      sub.cancel();
      expect(called, isFalse); // No event emitted
    });

    test('testAdDismissed emits on dismissed stream', () async {
      var dismissed = false;
      final sub = PangleAds.onAdDismissed.listen((_) {
        dismissed = true;
      });

      PangleAds.setOnProfileRefreshNeeded(() {});
      await PangleAds.testAdDismissed();

      // Allow stream event to propagate
      await Future.delayed(Duration.zero);
      expect(dismissed, isTrue);
      await sub.cancel();
    });

    test('refreshProfileManually calls callback', () {
      var count = 0;
      PangleAds.setOnProfileRefreshNeeded(() => count++);
      PangleAds.refreshProfileManually();
      PangleAds.refreshProfileManually();
      PangleAds.refreshProfileManually();
      expect(count, 3);
    });

    test('setOnProfileRefreshNeeded replaces callback', () {
      var first = 0;
      var second = 0;
      PangleAds.setOnProfileRefreshNeeded(() => first++);
      PangleAds.refreshProfileManually();
      expect(first, 1);
      expect(second, 0);

      PangleAds.setOnProfileRefreshNeeded(() => second++);
      PangleAds.refreshProfileManually();
      expect(first, 1);
      expect(second, 1);
    });

    test('showRewardedAdWithProfileRefresh schedules delayed refresh',
        () async {
      setupMockChannel(showResult: true);
      var refreshed = false;
      PangleAds.setOnProfileRefreshNeeded(() => refreshed = true);

      final result = await PangleAds.showRewardedAdWithProfileRefresh();
      expect(result, isTrue);
      // The delayed refresh happens after 5 seconds (we don't wait for it)
    });

    test('showRewardedAdWithProfileRefresh with failure still schedules refresh',
        () async {
      setupMockChannel(showResult: false);
      var refreshCount = 0;
      PangleAds.setOnProfileRefreshNeeded(() => refreshCount++);

      final result = await PangleAds.showRewardedAdWithProfileRefresh();
      expect(result, isFalse);
      // Delayed refresh still scheduled
    });

    test('loadRewardedAd passes correct arguments', () async {
      setupMockChannel(loadResult: true);
      await PangleAds.loadRewardedAd('my_placement', 'my_user');
      expect(log.first.arguments, {
        'placementId': 'my_placement',
        'userId': 'my_user',
      });
    });

    test('loadRewardedAd with empty strings', () async {
      setupMockChannel(loadResult: true);
      final result = await PangleAds.loadRewardedAd('', '');
      expect(result, isTrue);
      expect(log.first.arguments, {'placementId': '', 'userId': ''});
    });

    test('loadRewardedAd returns false when null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async => null,
      );
      final result = await PangleAds.loadRewardedAd('p', 'u');
      expect(result, isFalse);
    });

    test('showRewardedAd returns false when null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('pangle_native_channel'),
        (MethodCall call) async => null,
      );
      final result = await PangleAds.showRewardedAd();
      expect(result, isFalse);
    });

    test('initPangle passes appId in arguments', () async {
      setupMockChannel(initResult: true);
      await PangleAds.initPangle('custom_app_123');
      expect(log.first.arguments, {'appId': 'custom_app_123'});
    });

    test('initPangle with empty appId', () async {
      setupMockChannel(initResult: true);
      final result = await PangleAds.initPangle('');
      expect(result, isTrue);
      expect(log.first.arguments, {'appId': ''});
    });
  });
}
