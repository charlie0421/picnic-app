import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/tapjoy_session.dart';

/// PICNIC-2682 독립 리뷰 지적(blocker-1 / major-3 / major-4) 재현.
///
/// 여기서는 `setUserIdAndWait` 를 fake 로 갈아끼우지 않고 **실제 MethodChannel**
/// 을 통해 SDK 계약을 그대로 구동한다. 전역 단일 슬롯 리스너
/// (`TapjoyMethodCallHandler` :102-110)와 이름 하나로 캐시되는 placement 는
/// 주입된 fake 로는 재현되지 않기 때문이다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tapjoy_offerwall');
  const userA = '00000000-0000-0000-0000-00000000000a';
  const userB = '00000000-0000-0000-0000-00000000000b';
  const deviceHex =
      '3a1db1ef7c9e117a20a19e513eff7939f31b323c33dd2eb687303879047d2929';

  late TestDefaultBinaryMessenger messenger;
  late List<MethodCall> calls;

  /// 네이티브 SDK 가 현재 들고 있다고 답할 사용자 ID.
  String? nativeUserId;

  /// `Tapjoy.isConnected()` 가 돌려줄 값.
  bool nativeConnected = false;

  setUp(() {
    calls = <MethodCall>[];
    nativeUserId = null;
    nativeConnected = false;
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getUserID':
          return nativeUserId;
        case 'isConnected':
          return nativeConnected;
        default:
          // Android 플러그인의 result.success(null) 을 그대로 재현한다.
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  /// SDK 가 뒤늦게 보내는 채널 이벤트.
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

  int countOf(String method) =>
      calls.where((c) => c.method == method).length;

  TapjoySession makeSession({
    required String? Function() currentUserId,
    TapjoyConnector? connect,
  }) => TapjoySession(
    currentUserId: currentUserId,
    connect: connect ?? _immediateSuccessConnector(),
  );

  group('blocker-1: timeout 이후 늦은 성공 이벤트의 소유권', () {
    testWidgets(
      'A 의 timeout 뒤 B 가 리스너를 덮어쓴 상태에서 도착한 A 의 성공 이벤트로 B 를 ready 로 만들지 않는다',
      (tester) async {
        var currentUser = userA;
        final session = makeSession(currentUserId: () => currentUser);
        await session.connect(sdkKey: 'sdk-key', initialUserId: userA);

        // 1) 계정 A 의 setUserID — 성공 이벤트가 오지 않아 10초 뒤 timeout.
        final a = session.ensureUserReady();
        final aFailed = expectLater(
          a,
          throwsA(isA<TapjoySessionException>()),
        );
        await tester.pump();
        expect(countOf('setUserID'), 1);
        await tester.pump(const Duration(seconds: 11));
        await aFailed;

        // 2) 계정이 B 로 바뀌고 B 가 전역 단일 슬롯 리스너를 덮어쓴다.
        currentUser = userB;
        final b = session.ensureUserReady();
        final bSettled = expectLater(
          b,
          throwsA(isA<TapjoySessionException>()),
          reason: '네이티브가 아직 A 인데 B 를 ready 로 만들면 A 의 snuid 로 오퍼가 열린다',
        );
        await tester.pump();
        expect(countOf('setUserID'), 2);

        // 3) A 의 늦은 성공 이벤트가 도착한다. 네이티브 사용자 ID 는 아직 A.
        nativeUserId = userA;
        await deliver('TapjoyOnSetUserIDSuccess');
        await tester.pump();

        await bSettled;
        expect(session.readyUserId, isNull);
      },
    );

    testWidgets('네이티브 ID 가 캡처한 UUID 와 같으면 정상적으로 ready 가 된다', (tester) async {
      final session = makeSession(currentUserId: () => userA);
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);

      final pending = session.ensureUserReady();
      await tester.pump();
      nativeUserId = userA;
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();

      expect(await pending, userA);
      expect(session.readyUserId, userA);
      expect(countOf('getUserID'), greaterThanOrEqualTo(1));
    });
  });

  group('major-4: 네이티브 ID 캐시 재검증', () {
    testWidgets('Auth 가 그대로여도 네이티브가 ID 를 잃으면 캐시를 믿지 않고 다시 설정한다', (
      tester,
    ) async {
      final session = makeSession(currentUserId: () => userA);
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);

      final first = session.ensureUserReady();
      await tester.pump();
      nativeUserId = userA;
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      expect(await first, userA);
      expect(countOf('setUserID'), 1);

      // reconnect/복귀 중 SDK 가 기본 기기 ID 로 되돌아간 상황.
      nativeUserId = deviceHex;

      final second = session.ensureUserReady();
      await tester.pump();
      expect(
        countOf('setUserID'),
        2,
        reason: 'Dart 캐시만 보고 즉시 반환하면 기기 ID 로 오퍼가 열린다 (PICNIC-2682 재발)',
      );

      nativeUserId = userA;
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      expect(await second, userA);
    });
  });

  group('major-3: connect 성공 이벤트 유실', () {
    testWidgets('이벤트가 유실돼도 네이티브가 연결돼 있으면 진행한다', (tester) async {
      final session = makeSession(
        currentUserId: () => userA,
        connect: _silentConnector(),
      );
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);

      // SDK 는 연결됐지만 TapjoyOnConnectSuccess 채널 이벤트가 오지 않았다.
      nativeConnected = true;

      final pending = session.ensureUserReady();
      await tester.pump();

      expect(
        countOf('setUserID'),
        1,
        reason: '연결돼 있는데도 오퍼월이 영구히 막히면 정상 사용자가 Tapjoy 를 못 쓴다',
      );
      nativeUserId = userA;
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      expect(await pending, userA);
    });

    testWidgets('재연결하면 앞선 연결의 실패한 공유 대기를 버린다', (tester) async {
      // 두 번째 connect 의 성공 이벤트 시점을 테스트가 통제한다.
      void Function() fireSuccess = () {};
      final session = makeSession(
        currentUserId: () => userA,
        connect:
            ({
              required String sdkKey,
              required Map<String, dynamic> options,
              required void Function() onConnectSuccess,
              required void Function(int code, String? message) onConnectFailure,
              required void Function(int code, String? message)
              onConnectWarning,
            }) async {
              fireSuccess = onConnectSuccess;
            },
      );

      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);
      nativeConnected = false;

      final first = session.ensureUserReady();
      final firstFailed = expectLater(
        first,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      await firstFailed;

      // 앱이 다시 연결한다.
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);
      final pending = session.ensureUserReady();
      await tester.pump();
      fireSuccess();
      await tester.pump();

      expect(
        countOf('setUserID'),
        1,
        reason: '낡은 실패 대기를 들고 있으면 재연결해도 영영 열리지 않는다',
      );
      nativeUserId = userA;
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      expect(await pending, userA);
    });

    testWidgets('연결도 이벤트도 없으면 두 번째 대기자가 15초를 또 지불하지 않는다', (tester) async {
      final session = makeSession(
        currentUserId: () => userA,
        connect: _silentConnector(),
      );
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);
      nativeConnected = false;

      final first = session.ensureUserReady();
      final firstFailed = expectLater(
        first,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      await firstFailed;

      var secondSettled = false;
      final second = session.ensureUserReady();
      unawaited(
        second.then(
          (_) => secondSettled = true,
          onError: (Object _) => secondSettled = true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        secondSettled,
        isTrue,
        reason: 'waiter 마다 connect timeout 을 새로 시작하면 탭마다 15초씩 멈춘다',
      );
      await expectLater(second, throwsA(isA<TapjoySessionException>()));
      expect(countOf('setUserID'), 0);
    });
  });
}

TapjoyConnector _immediateSuccessConnector() =>
    ({
      required String sdkKey,
      required Map<String, dynamic> options,
      required void Function() onConnectSuccess,
      required void Function(int code, String? message) onConnectFailure,
      required void Function(int code, String? message) onConnectWarning,
    }) async {
      onConnectSuccess();
    };

/// MethodChannel 은 돌아오지만 성공/실패 이벤트가 끝내 오지 않는 연결.
TapjoyConnector _silentConnector() =>
    ({
      required String sdkKey,
      required Map<String, dynamic> options,
      required void Function() onConnectSuccess,
      required void Function(int code, String? message) onConnectFailure,
      required void Function(int code, String? message) onConnectWarning,
    }) async {};
