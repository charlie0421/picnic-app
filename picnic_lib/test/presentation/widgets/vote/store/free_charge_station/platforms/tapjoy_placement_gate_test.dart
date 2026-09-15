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
  const otherUid = 'other-user-id-002';

  late TestDefaultBinaryMessenger messenger;
  late List<MethodCall> calls;
  String? nativeUserId;

  /// 서버가 내려준 오퍼가 있는지. false 면 정상 no-fill 이다.
  bool contentAvailable = true;

  /// 현재 로그인 사용자. 계정 전환 반례에서 바꾼다.
  late String currentUser;

  /// 채널 메서드별 거동: 'throw'(PlatformException), 'missing'
  /// (MissingPluginException), 'hang'(응답 없음). null 이면 정상.
  final channelBehavior = <String, String>{};

  setUp(initTestColors);

  setUp(() {
    calls = <MethodCall>[];
    nativeUserId = uid;
    contentAvailable = true;
    currentUser = uid;
    channelBehavior.clear();
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (channelBehavior[call.method]) {
        case 'throw':
          throw PlatformException(code: 'ERROR', message: 'channel failed');
        case 'missing':
          // 플러그인 자체가 없어 요청이 네이티브에 도달하지 못한 경우.
          throw MissingPluginException('No implementation for ${call.method}');
        case 'hang':
          return Completer<Object?>().future;
      }
      switch (call.method) {
        case 'getUserID':
          return nativeUserId;
        case 'isConnected':
          return true;
        case 'isContentAvailable':
        case 'isContentReady':
          return contentAvailable;
        default:
          return null;
      }
    });
    TapjoySession.setInstanceForTest(
      TapjoySession(
        currentUserId: () => currentUser,
        connect:
            ({
              required String sdkKey,
              required Map<String, dynamic> options,
              required void Function() onConnectSuccess,
              required void Function(int code, String? message)
              onConnectFailure,
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

  testWidgets('dispose 후 새 화면이 같은 placement 를 가져가 A 의 늦은 콘텐츠를 열지 않는다', (
    tester,
  ) async {
    final a = await buildPlatform(tester);

    final firstShow = a.showAd();
    await completeUserId(tester);
    await firstShow;
    expect(countOf('getPlacement'), 1);

    // 사용자가 화면을 떠난다. 네이티브 요청은 아직 살아 있고 SDK 의
    // _placementMap['mission'] 에는 A 의 콜백이 그대로 걸려 있다.
    a.dispose();

    // 새 화면 B 가 같은 mission placement 를 잡으려 한다.
    final b = await buildPlatform(tester);
    final secondShow = b.showAd();
    await completeUserId(tester);
    await secondShow;

    // A 요청의 늦은 콘텐츠 준비 이벤트가 도착한다.
    await deliver('onContentReady', 'mission');
    await drain(tester);

    expect(
      countOf('showContent'),
      0,
      reason: 'A 요청의 offer 를 B 화면에서 열면 계정 전환 시 오적립·미적립이 된다',
    );
    b.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  /// 네이티브가 **아무 콜백도 주지 않는** 경우. 정상 no-fill(onRequestSuccess 는
  /// 오지만 오퍼가 없는 경우)은 아래 별도 테스트가 다룬다 — 그쪽은 terminal 이
  /// 존재하므로 반드시 풀려야 한다.
  testWidgets('어떤 콜백도 오지 않으면 게이트를 임의로 풀지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final show = platform.showAd();
    await completeUserId(tester);
    await show;
    expect(countOf('getPlacement'), 1);

    // request failure 도 content dismiss 도 오지 않은 채 시간만 흐른다.
    await tester.pump(const Duration(minutes: 4));

    final second = platform.showAd();
    await completeUserId(tester);
    await second;

    expect(
      countOf('getPlacement'),
      1,
      reason: 'native terminal 이벤트 없이 풀면 앞 요청의 늦은 콜백이 새 시도로 샌다',
    );
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('오퍼가 없는 정상 no-fill 응답은 그 요청의 terminal 로 보고 게이트를 놓는다', (
    tester,
  ) async {
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    await completeUserId(tester);
    await first;
    expect(countOf('getPlacement'), 1);

    // 서버 요청은 성공했지만 내려줄 오퍼가 없다. 이 경우 onContentReady·show·
    // dismiss 는 오지 않으므로 onRequestSuccess 가 이 요청의 마지막 이벤트다.
    // (패키지 예제 home_widget.dart:161 도 여기서 isContentAvailable 을 본다.)
    contentAvailable = false;
    await deliver('onRequestSuccess', 'mission');
    await drain(tester);

    final second = platform.showAd();
    await completeUserId(tester);
    await second;

    expect(
      countOf('getPlacement'),
      2,
      reason: '정상 no-fill 은 흔한 응답이다 — 이걸로 잠기면 앱 재시작 전까지 오퍼월을 못 연다',
    );
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  testWidgets('오퍼가 있으면 no-fill 로 오인해 게이트를 놓지 않는다', (tester) async {
    final platform = await buildPlatform(tester);

    final first = platform.showAd();
    await completeUserId(tester);
    await first;

    contentAvailable = true;
    await deliver('onRequestSuccess', 'mission');
    await drain(tester);

    final second = platform.showAd();
    await completeUserId(tester);
    await second;

    expect(
      countOf('getPlacement'),
      1,
      reason: '오퍼가 있으면 content ready·dismiss 까지가 이 요청의 수명이다',
    );
    platform.dispose();
    await pumpAndIgnoreErrors(tester);
  });

  group('blocker-1: 네이티브 terminal 확인 없는 해제', () {
    testWidgets('isContentAvailable 조회 예외는 게이트를 놓지 않는다', (tester) async {
      final platform = await buildPlatform(tester);

      final first = platform.showAd();
      await completeUserId(tester);
      await first;
      expect(countOf('getPlacement'), 1);

      // 조회가 실패했을 뿐 오퍼가 없다는 증거는 아니다. 늦은 onContentReady 가
      // 아직 올 수 있으므로 게이트를 놓으면 그 이벤트가 새 시도로 샌다.
      channelBehavior['isContentAvailable'] = 'throw';
      await deliver('onRequestSuccess', 'mission');
      await drain(tester);

      final second = platform.showAd();
      await completeUserId(tester);
      await second;

      expect(
        countOf('getPlacement'),
        1,
        reason: '조회 예외는 no-fill 이 아니다 — terminal 까지 격리해야 한다',
      );
      platform.dispose();
      await pumpAndIgnoreErrors(tester);
    });

    testWidgets('requestContent 의 모호한 채널 실패는 게이트를 놓지 않는다', (tester) async {
      final platform = await buildPlatform(tester);

      // 네이티브는 requestContent 를 먼저 실행하고 result 를 나중에 돌려준다
      // (TapjoyOfferwallPlugin.kt:374-378). 채널 실패는 미전달의 증거가 아니다.
      channelBehavior['requestContent'] = 'throw';
      final first = platform.showAd();
      await completeUserId(tester);
      await first;
      expect(countOf('getPlacement'), 1);

      channelBehavior.remove('requestContent');
      final second = platform.showAd();
      await completeUserId(tester);
      await second;

      expect(
        countOf('getPlacement'),
        1,
        reason: '전달 여부가 모호하면 늦은 콜백이 새 시도로 샐 수 있다',
      );
      platform.dispose();
      await pumpAndIgnoreErrors(tester);
    });

    testWidgets('MissingPluginException 은 명확한 미전달이라 게이트를 놓는다', (tester) async {
      final platform = await buildPlatform(tester);

      channelBehavior['requestContent'] = 'missing';
      final first = platform.showAd();
      await completeUserId(tester);
      await first;
      expect(countOf('getPlacement'), 1);

      channelBehavior.remove('requestContent');
      final second = platform.showAd();
      await completeUserId(tester);
      await second;

      expect(
        countOf('getPlacement'),
        2,
        reason: '플러그인이 없으면 네이티브에 도달할 수 없어 늦은 콜백도 없다',
      );
      platform.dispose();
      await pumpAndIgnoreErrors(tester);
    });
  });

  group('blocker-2: 계정 A→B→A 회귀', () {
    testWidgets('A 의 늦은 콘텐츠는 계정이 한 번이라도 바뀌면 열리지 않는다', (tester) async {
      final platform = await buildPlatform(tester);

      final first = platform.showAd();
      await completeUserId(tester);
      await first;
      expect(countOf('getPlacement'), 1);

      // 계정 B 로 전환 — auth listener 가 하는 일과 같다.
      currentUser = otherUid;
      TapjoySession.instance.invalidateUser();

      // B 가 탭한다. 게이트가 A 의 것이라 거절돼야 하고, 거절될 탭이 전역 SDK
      // 사용자 ID 를 B 로 바꾸면 안 된다.
      final tap = platform.showAd();
      await completeUserId(tester);
      await tap;
      expect(
        nativeUserId,
        uid,
        reason: '거절될 탭이 전역 SDK ID 를 바꾸면 A 의 오퍼가 B 로 귀속된다',
      );

      // 다시 A 로 돌아온다.
      currentUser = uid;
      TapjoySession.instance.invalidateUser();

      await deliver('onContentReady', 'mission');
      await drain(tester);

      expect(
        countOf('showContent'),
        0,
        reason: '계정이 바뀐 뒤의 시도는 문자열 일치만으로 되살아나면 안 된다',
      );
      platform.dispose();
      await pumpAndIgnoreErrors(tester);
    });
  });

  group('blocker-3: placement dispatch 무응답', () {
    testWidgets('getPlacement 응답이 없어도 큐가 끝나고 게이트는 유지된다', (tester) async {
      final platform = await buildPlatform(tester);

      channelBehavior['getPlacement'] = 'hang';
      var settled = false;
      final first = platform.showAd();
      unawaited(
        first.then(
          (_) => settled = true,
          onError: (Object _) => settled = true,
        ),
      );
      await completeUserId(tester);
      await tester.pump(const Duration(seconds: 31));
      await drain(tester);

      expect(settled, isTrue, reason: '채널 응답을 무한정 기다리면 이후 모든 오퍼월 시도가 큐에서 멈춘다');
      platform.dispose();
      await pumpAndIgnoreErrors(tester);
    });

    testWidgets('requestContent 응답이 없어도 큐가 끝나고 게이트는 유지된다', (tester) async {
      final platform = await buildPlatform(tester);

      channelBehavior['requestContent'] = 'hang';
      var settled = false;
      final first = platform.showAd();
      unawaited(
        first.then(
          (_) => settled = true,
          onError: (Object _) => settled = true,
        ),
      );
      await completeUserId(tester);
      await tester.pump(const Duration(seconds: 31));
      await drain(tester);
      expect(settled, isTrue);

      channelBehavior.remove('requestContent');
      final second = platform.showAd();
      await completeUserId(tester);
      await second;

      expect(
        countOf('getPlacement'),
        1,
        reason: '전달 여부가 모호한 timeout 에서는 게이트 소유권을 유지해야 한다',
      );
      platform.dispose();
      await pumpAndIgnoreErrors(tester);
    });
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
