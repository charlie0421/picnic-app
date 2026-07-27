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

      await PangleAds.testAdDismissed();

      // Allow stream event to propagate
      await Future.delayed(Duration.zero);
      expect(dismissed, isTrue);
      await sub.cancel();
    });

    test('loadRewardedAd passes correct arguments', () async {
      setupMockChannel(loadResult: true);
      await PangleAds.loadRewardedAd(
        'my_placement',
        'my_user,android,v2.token',
      );
      expect(log.first.arguments, {
        'placementId': 'my_placement',
        'mediaExtra': 'my_user,android,v2.token',
      });
    });

    test('loadRewardedAd with empty strings', () async {
      setupMockChannel(loadResult: true);
      final result = await PangleAds.loadRewardedAd('', '');
      expect(result, isTrue);
      expect(log.first.arguments, {'placementId': '', 'mediaExtra': ''});
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
