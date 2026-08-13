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

    test('passes explicit sandbox mode to native SDK initialization', () async {
      setupMockChannel(initResult: true);
      await PangleAds.initPangle(
        'test_app_id',
        environment: 'sandbox',
        productionAppId: 'production_app_id',
        sandboxPlacementId: 'sandbox_slot',
        productionPlacementId: 'production_slot',
      );
      expect(log.single.arguments, {
        'appId': 'test_app_id',
        'environment': 'sandbox',
        'productionAppId': 'production_app_id',
        'sandboxPlacementId': 'sandbox_slot',
        'productionPlacementId': 'production_slot',
      });
    });

    test(
      'sandbox rejects production app id before native SDK invocation',
      () async {
        setupMockChannel(initResult: true);
        final result = await PangleAds.initPangle(
          'same_app_id',
          environment: 'sandbox',
          productionAppId: 'same_app_id',
          sandboxPlacementId: 'sandbox_slot',
          productionPlacementId: 'production_slot',
        );
        expect(result, isFalse);
        expect(log, isEmpty);
      },
    );

    test(
      'sandbox rejects production placement before native SDK invocation',
      () async {
        setupMockChannel(initResult: true);
        final result = await PangleAds.initPangle(
          'sandbox_app_id',
          environment: 'sandbox',
          productionAppId: 'production_app_id',
          sandboxPlacementId: 'same_slot',
          productionPlacementId: 'same_slot',
        );
        expect(result, isFalse);
        expect(log, isEmpty);
      },
    );

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
    // 회귀 가드 (PICNIC-2377): 네이티브 로드 오류는 **삼키지 말고 올려보낸다**.
    //
    // 예전엔 PlatformException 을 잡아 false 를 돌려줬다. 그러면 호출부는 그걸
    // "지금 광고가 없다"(no-fill)로 해석해 하드코딩 라벨로 로깅하고, 사용자에겐
    // "모든 광고 소진" 이 뜨며 Sentry 보고까지 생략됐다. 실제로 아시아픽 #1 은
    // InvalidMediaExtra("Signed v2 mediaExtra is required")로 100% 실패하는
    // 동안 이 경로 때문에 텔레메트리가 한 건도 남지 않았다.
    //
    // 네이티브가 명시적으로 false 를 주는 것만 no-fill 이다.
    test('네이티브 오류(PlatformException)는 호출부로 전파된다', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('pangle_native_channel'),
            (MethodCall call) async {
              log.add(call);
              throw PlatformException(
                code: 'InvalidMediaExtra',
                message: 'Signed v2 mediaExtra is required',
              );
            },
          );
      await expectLater(
        PangleAds.loadRewardedAd('placement', 'user,android,v2.token'),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'InvalidMediaExtra',
          ),
        ),
      );
      clearMockChannel();
    });

    test('returns true on success', () async {
      setupMockChannel(loadResult: true);
      final result = await PangleAds.loadRewardedAd(
        'placement_123',
        'user_456,android,v2.signed',
      );
      expect(result, isTrue);
      expect(log.first.method, 'loadRewardedAd');
      expect(log.first.arguments, {
        'placementId': 'placement_123',
        'mediaExtra': 'user_456,android,v2.signed',
      });
    });

    test('returns false on failure', () async {
      setupMockChannel(loadResult: false);
      final result = await PangleAds.loadRewardedAd(
        'placement_123',
        'user_456',
      );
      expect(result, isFalse);
    });

    // 계약 변경 (PICNIC-2377): 네이티브 오류는 삼키지 않고 전파한다.
    //
    // 예전 두 테스트는 `expect(result, isFalse)` 로 **삼키는 동작을 계약으로
    // 고정**하고 있었다. 그 동작 때문에 호출부가 네이티브 오류를 no-fill 로
    // 오해해 "모든 광고 소진" 을 띄우고 Sentry 보고를 생략했고, 아시아픽 #1 이
    // 100% 실패하는 동안 텔레메트리가 한 건도 남지 않았다.
    test('PlatformException 은 호출부로 전파된다', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('pangle_native_channel'),
            (MethodCall call) async {
              throw PlatformException(code: 'ERROR', message: 'load failed');
            },
          );
      await expectLater(
        PangleAds.loadRewardedAd('placement_123', 'user_456'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('예상 못 한 예외도 전파된다', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('pangle_native_channel'),
            (MethodCall call) async {
              throw Exception('unexpected');
            },
          );
      await expectLater(
        PangleAds.loadRewardedAd('placement_123', 'user_456'),
        throwsA(anything),
      );
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

  group('PangleAds.testAdDismissed', () {
    test('completes without error', () async {
      await expectLater(PangleAds.testAdDismissed(), completes);
    });

    test('completes without callback', () async {
      await expectLater(PangleAds.testAdDismissed(), completes);
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
      expect(PangleAds.pollingSignals, isA<Stream<void>>());
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

  test('dismiss, earned and failed events are polling signals', () async {
    setupMockChannel();
    await PangleAds.initPangle('app');
    var signals = 0;
    final sub = PangleAds.pollingSignals.listen((_) => signals++);
    final codec = const StandardMethodCodec();
    for (final call in <MethodCall>[
      const MethodCall('onAdDismissed'),
      const MethodCall('onRewardEarned', {'rewardAmount': 1}),
      const MethodCall('onRewardFailed', {'errorMessage': 'nope'}),
    ]) {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'pangle_native_channel',
            codec.encodeMethodCall(call),
            (_) {},
          );
    }
    await Future<void>.delayed(Duration.zero);
    expect(signals, 3);
    await sub.cancel();
  });
}
