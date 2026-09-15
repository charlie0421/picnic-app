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
        case 'setUserID':
          // Android SDK 14.6.0 의 TJUser.setUserIdRequest 는 HTTP 검증 **이전에**
          // 로컬 TJUser.setUserId 를 먼저 실행한다. 따라서 setUserID 를 보낸
          // 직후부터 getUserID 는 그 값을 돌려준다 — 네이티브 ID 조회만으로는
          // "누구의 성공 이벤트인지"를 증명할 수 없다.
          nativeUserId =
              (call.arguments as Map)['userId'] as String?;
          return null;
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
        // blocker-A: 앞선 시도의 네이티브 terminal 이벤트를 아직 소비하지 못했다.
        // 여기서 B 의 setUserID 를 보내면 static 단일 슬롯 리스너를 덮어써
        // A 의 늦은 이벤트가 B 의 것으로 오인된다.
        final callsAfterB = countOf('setUserID');

        // 3) A 의 늦은 성공 이벤트가 도착한다. 이 시점 네이티브 ID 는 (실제
        //    SDK 처럼) 마지막으로 보낸 setUserID 값이라 B 를 돌려준다.
        await deliver('TapjoyOnSetUserIDSuccess');
        await tester.pump(const Duration(seconds: 11));

        await bSettled;
        expect(session.readyUserId, isNull);
        expect(
          callsAfterB,
          1,
          reason: 'A 의 terminal 이벤트를 소비하기 전에는 B 요청을 보내면 안 된다',
        );
      },
    );

    testWidgets('앞선 시도의 terminal 이벤트를 소비하면 격리가 풀리고 다시 설정할 수 있다', (
      tester,
    ) async {
      var currentUser = userA;
      final session = makeSession(currentUserId: () => currentUser);
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);

      final a = session.ensureUserReady();
      final aFailed = expectLater(a, throwsA(isA<TapjoySessionException>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await aFailed;

      // A 의 진짜 terminal 이벤트가 뒤늦게 도착해 소유권이 정리된다.
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();

      currentUser = userB;
      final b = session.ensureUserReady();
      await tester.pump();
      expect(
        countOf('setUserID'),
        2,
        reason: '격리가 풀렸으면 새 계정의 ID 설정은 정상적으로 진행돼야 한다',
      );
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      expect(await b, userB);
    });

    testWidgets('격리 중에는 앞선 시도의 늦은 실패도 새 시도로 새지 않는다', (tester) async {
      var currentUser = userA;
      final session = makeSession(currentUserId: () => currentUser);
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);

      final a = session.ensureUserReady();
      final aFailed = expectLater(a, throwsA(isA<TapjoySessionException>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await aFailed;

      currentUser = userB;
      final b = session.ensureUserReady();
      final bFailed = expectLater(b, throwsA(isA<TapjoySessionException>()));
      await tester.pump(const Duration(seconds: 11));
      await bFailed;

      // A 의 늦은 **실패** 이벤트. 격리 해제에만 쓰이고 B 에는 영향이 없다.
      await deliver('TapjoyOnSetUserIDFailure', 'late failure for A');
      await tester.pump();
      expect(session.readyUserId, isNull);

      final retry = session.ensureUserReady();
      await tester.pump();
      final callsAfterRetry = countOf('setUserID');
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump(const Duration(seconds: 11));
      expect(await retry, userB);
      expect(callsAfterRetry, 2);
    });

    testWidgets('네이티브 ID 가 캡처한 UUID 와 같으면 정상적으로 ready 가 된다', (tester) async {
      final session = makeSession(currentUserId: () => userA);
      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);

      final pending = session.ensureUserReady();
      await tester.pump();
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

      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      expect(await second, userA);
    });
  });

  group('major-C: connect fallback 의 privacy hook', () {
    testWidgets('성공 이벤트가 유실되고 네이티브 probe 로 확정돼도 hook 이 정확히 한 번 실행된다', (
      tester,
    ) async {
      var hookCalls = 0;
      final session = makeSession(
        currentUserId: () => userA,
        connect: _silentConnector(),
      );
      nativeConnected = true;

      await session.connect(
        sdkKey: 'sdk-key',
        initialUserId: userA,
        onConnected: () async => hookCalls++,
      );

      final pending = session.ensureUserReady();
      await tester.pump();

      // 이 hook 이 앱 안에서 Tapjoy GDPR·user consent·age·US privacy 를 설정하는
      // 유일한 지점이다(app_initializer.dart 의 _onTapjoyConnectSuccess).
      expect(
        hookCalls,
        1,
        reason: 'fallback 으로 오퍼월만 열고 개인정보 설정을 건너뛰면 안 된다',
      );

      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      expect(await pending, userA);

      // 두 번째 진입에서 다시 실행되면 안 된다.
      final again = session.ensureUserReady();
      await tester.pump();
      await again;
      expect(hookCalls, 1);
    });
  });

  group('major-D: 실제 connect 실패 후 복구', () {
    testWidgets('진짜 CONNECT_FAILED 뒤 다음 사용자 시도에서 한 번 재연결한다', (tester) async {
      var connectCalls = 0;
      void Function() fireSuccess = () {};
      void Function(int, String?) fireFailure = (_, _) {};
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
              connectCalls++;
              fireSuccess = onConnectSuccess;
              fireFailure = onConnectFailure;
            },
      );

      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);
      expect(connectCalls, 1);

      // MethodChannel 은 이미 반환해 startup stage 는 성공으로 캐시됐고,
      // 진짜 실패는 뒤늦게 도착한다.
      fireFailure(1, 'network unavailable');
      await tester.pump();

      // 네트워크가 정상화된 뒤 사용자가 무료충전소를 누른다.
      final retry = session.ensureUserReady();
      final retrySettled = expectLater(retry, completion(userA));
      await tester.pump();
      final callsAfterRetry = connectCalls;

      fireSuccess();
      await tester.pump();
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump(const Duration(seconds: 20));
      await retrySettled;

      expect(
        callsAfterRetry,
        2,
        reason: '재연결 경로가 없으면 프로세스 재시작 전까지 Tapjoy 가 전면 차단된다',
      );
    });

    testWidgets('재연결도 실패하면 쿨다운 동안 연타해도 다시 시도하지 않는다', (tester) async {
      var connectCalls = 0;
      void Function(int, String?) fireFailure = (_, _) {};
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
              connectCalls++;
              fireFailure = onConnectFailure;
            },
      );

      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);
      fireFailure(1, 'network unavailable');
      await tester.pump();

      // 1차 시도 — 재연결이 일어나지만 그것도 실패한다.
      final first = session.ensureUserReady();
      final firstFailed = expectLater(
        first,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump();
      final callsAfterFirst = connectCalls;
      fireFailure(1, 'still unavailable');
      await tester.pump(const Duration(seconds: 20));
      await firstFailed;

      // 쿨다운 중의 연타는 새 connect 를 만들지 않는다.
      final second = session.ensureUserReady();
      final secondFailed = expectLater(
        second,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump(const Duration(seconds: 20));
      await secondFailed;

      expect(
        callsAfterFirst,
        2,
        reason: '진짜 실패 뒤 첫 사용자 시도는 한 번 재연결해야 한다',
      );
      expect(
        connectCalls,
        2,
        reason: '실패한 재연결을 연타마다 반복하면 SDK 를 두들기게 된다',
      );

      // 쿨다운 타이머를 소진해 pending timer 없이 끝낸다.
      await tester.pump(const Duration(seconds: 40));
    });
  });

  group('major-F: 재연결 쿨다운은 탭마다 연장되지 않는다', () {
    testWidgets('원 실패 기준 30초가 지나면 연타했더라도 다시 재연결한다', (tester) async {
      var connectCalls = 0;
      void Function(int, String?) fireFailure = (_, _) {};
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
              connectCalls++;
              fireFailure = onConnectFailure;
            },
      );

      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);
      fireFailure(1, 'network unavailable');
      await tester.pump();

      // t=0 재연결 시도 → 실패 → 쿨다운 30초 시작.
      final first = session.ensureUserReady();
      final firstFailed = expectLater(
        first,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump();
      expect(connectCalls, 2);
      fireFailure(1, 'still unavailable');
      await tester.pump(const Duration(seconds: 1));
      await firstFailed;

      // t=10s 연타 — 거절돼야 하지만 쿨다운을 **연장하면 안 된다**.
      await tester.pump(const Duration(seconds: 9));
      final tap = session.ensureUserReady();
      final tapFailed = expectLater(
        tap,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump();
      await tapFailed;
      expect(connectCalls, 2);

      // t=31s — 원 실패 기준으로 쿨다운이 끝났으니 다시 시도해야 한다.
      await tester.pump(const Duration(seconds: 21));
      final after = session.ensureUserReady();
      final afterSettled = expectLater(
        after,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump();
      final callsAfterCooldown = connectCalls;
      fireFailure(1, 'still unavailable');
      await tester.pump(const Duration(seconds: 1));
      await afterSettled;

      expect(
        callsAfterCooldown,
        3,
        reason: '탭마다 쿨다운이 연장되면 연타하는 사용자는 무기한 재연결 불가다',
      );
      await tester.pump(const Duration(seconds: 40));
    });
  });

  group('major-G: CONNECT_TIMEOUT 복구', () {
    testWidgets('timeout 뒤 다음 사용자 시도에서 재연결한다', (tester) async {
      var connectCalls = 0;
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
              connectCalls++;
              fireSuccess = onConnectSuccess;
            },
      );

      await session.connect(sdkKey: 'sdk-key', initialUserId: userA);
      nativeConnected = false;

      // 성공·실패 이벤트가 모두 유실돼 15초 timeout.
      final first = session.ensureUserReady();
      final firstFailed = expectLater(
        first,
        throwsA(isA<TapjoySessionException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      await firstFailed;
      expect(connectCalls, 1);

      // 다음 사용자 시도 — 캐시된 timeout 을 그대로 재사용하면 안 된다.
      final retry = session.ensureUserReady();
      final retrySettled = expectLater(retry, completion(userA));
      await tester.pump();
      final callsAfterRetry = connectCalls;

      fireSuccess();
      await tester.pump();
      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump(const Duration(seconds: 20));
      await retrySettled;

      expect(
        callsAfterRetry,
        2,
        reason: 'timeout 을 영구 캐시하면 프로세스 재시작 전까지 복구할 수 없다',
      );
      await tester.pump(const Duration(seconds: 40));
    });

    testWidgets('재연결 뒤 도착한 앞선 connect 의 늦은 성공이 사용자 확인을 건너뛰지 않는다', (
      tester,
    ) async {
      // connect 리스너도 static 단일 슬롯이라 늦은 이벤트가 새 세대의 closure 로
      // 들어온다. 그래도 setUserID 성공 이벤트와 getUserID 대조를 거치지 않고는
      // ready 가 되지 않아야 한다.
      var connectCalls = 0;
      final successHandles = <void Function()>[];
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
              connectCalls++;
              successHandles.add(onConnectSuccess);
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

      final retry = session.ensureUserReady();
      final retrySettled = expectLater(retry, completion(userA));
      await tester.pump();
      expect(connectCalls, 2);

      // 1세대 connect 의 늦은 성공 이벤트가 2세대 슬롯으로 들어온다.
      successHandles.first();
      await tester.pump();

      // 연결은 확정되더라도 사용자 ID 는 별도 확인을 거쳐야 한다.
      expect(session.readyUserId, isNull);
      expect(countOf('setUserID'), 1);

      await deliver('TapjoyOnSetUserIDSuccess');
      await tester.pump(const Duration(seconds: 20));
      await retrySettled;
      expect(session.readyUserId, userA);
      await tester.pump(const Duration(seconds: 40));
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
