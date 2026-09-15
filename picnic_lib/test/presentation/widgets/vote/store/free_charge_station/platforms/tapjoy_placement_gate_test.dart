import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/utils/tapjoy_session.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/tapjoy_platform.dart';

import '../../../../../../helpers/factories/user_factory.dart';
import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

/// PICNIC-2682 독립 리뷰 지적(major-2) 재현.
///
/// tapjoy_offerwall 14.6.0 의 [TJPlacement] 는 placement **이름 하나**로 객체를
/// 캐시하고(`_placementMap`, models/tapjoy_placement.dart:9,33-41) `getPlacement`
/// 가 불릴 때마다 그 객체의 콜백을 통째로 덮어쓴다. `requestContent` 의
/// MethodChannel 반환은 즉시이므로 runOfferwall 큐가 바로 풀리고, 두 번째 탭이
/// 같은 'mission' placement 의 콜백을 가져간다. 그러면 첫 요청의 늦은
/// `onContentReady` 도 최신 콜백으로 라우팅돼 시도 토큰이 지난 시도를 구별하지
/// 못한다.
///
/// 여기서는 `requestPlacement` 를 override 하지 않고 실제 SDK placement 경로를
/// MethodChannel 로 구동한다.
void main() {
  const channel = MethodChannel('tapjoy_offerwall');
  const uid = 'test-user-id-001'; // UserFactory.create() 의 기본 id

  late TestDefaultBinaryMessenger messenger;
  late List<MethodCall> calls;
  String? nativeUserId;

  setUp(initTestColors);

  setUp(() {
    calls = <MethodCall>[];
    nativeUserId = uid;
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getUserID':
          return nativeUserId;
        case 'isConnected':
          return true;
        default:
          return null;
      }
    });
    TapjoySession.setInstanceForTest(
      TapjoySession(
        currentUserId: () => uid,
        connect:
            ({
              required String sdkKey,
              required Map<String, dynamic> options,
              required void Function() onConnectSuccess,
              required void Function(int code, String? message) onConnectFailure,
              required void Function(int code, String? message)
              onConnectWarning,
            }) async {
              onConnectSuccess();
            },
      ),
    );
  });

  tearDown(() {
    TapjoyPlacementGate.resetForTest();
    messenger.setMockMethodCallHandler(channel, null);
    TapjoySession.setInstanceForTest(TapjoySession());
    try {
      OverlayLoadingProgress.stop();
    } catch (error) {
      debugPrint('overlay teardown ignored: $error');
    }
  });

  Future<void> deliver(String method, [dynamic arguments]) {
    final delivered = Completer<void>();
    messenger.handlePlatformMessage(
      'tapjoy_offerwall',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) => delivered.complete(),
    );
    return delivered.future;
  }

  int countOf(String method) => calls.where((c) => c.method == method).length;

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await pumpAndIgnoreErrors(tester);
    }
  }

  Future<TapjoyPlatform> buildPlatform(WidgetTester tester) async {
    // connect 는 테스트 본문 zone 에서 보낸다 — setUp zone 의 Future 는
    // FakeAsync 가 돌려 주지 않는다.
    await TapjoySession.instance.connect(sdkKey: 'sdk-key', initialUserId: uid);
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            capturedContext = context;
            ref.watch(userInfoProvider);
            return const SizedBox.shrink();
          },
        ),
        userProfile: UserFactory.create(),
      ),
    );
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);
    expect(capturedRef.read(userInfoProvider).value, isNotNull);
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);
    return TapjoyPlatform(capturedRef, capturedContext, 'tapjoy', controller);
  }

  /// setUserID 성공 이벤트를 흘려 준비 상태를 만든다.
  Future<void> completeUserId(WidgetTester tester) async {
    await drain(tester);
    await deliver('TapjoyOnSetUserIDSuccess');
    await drain(tester);
  }

  testWidgets('열려 있는 mission placement 는 두 번째 요청이 콜백을 덮어쓰지 못한다', (
    tester,
  ) async {
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    await completeUserId(tester);
    expect(countOf('getPlacement'), 1);
    expect(countOf('requestContent'), 1);
    await first;

    // requestContent 의 채널 반환은 즉시라 큐가 이미 풀렸다 — 두 번째 탭.
    final second = platform.showAd();
    await completeUserId(tester);
    await second;

    expect(
      countOf('getPlacement'),
      1,
      reason: '같은 이름의 placement 를 다시 잡으면 첫 시도의 콜백이 통째로 덮어써진다',
    );
    expect(countOf('requestContent'), 1);

    // 30초 안전장치 타이머와 버튼 애니메이션을 테스트 종료 전에 정리한다.
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('콘텐츠가 닫히면 다음 요청이 다시 열린다', (tester) async {
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    await completeUserId(tester);
    await first;
    expect(countOf('getPlacement'), 1);

    await deliver('onContentReady', 'mission');
    await drain(tester);
    await deliver('onContentDismiss', 'mission');
    await drain(tester);

    final second = platform.showAd();
    await completeUserId(tester);
    await second;

    expect(
      countOf('getPlacement'),
      2,
      reason: '정상적으로 닫힌 뒤에는 다시 오퍼월을 열 수 있어야 한다',
    );

    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('dispose 뒤 도착한 콘텐츠 준비 콜백은 화면을 열지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    await completeUserId(tester);
    await first;
    expect(countOf('getPlacement'), 1);

    platform.dispose();
    await deliver('onContentReady', 'mission');
    await drain(tester);

    expect(countOf('showContent'), 0);
  });
}
