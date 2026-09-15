import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/tapjoy_session.dart';

/// PICNIC-2682.
///
/// Tapjoy 서버 콜백의 `snuid` 가 Picnic UUID 가 아니라 64자리 hex 로 도착해
/// `user_profiles.id` 조회가 22P02 로 실패했고, 그 사용자들의 보상이 지급되지
/// 않았다. tapjoy_offerwall 14.6.0 의 Android 플러그인은 `setUserID` 요청 직후
/// `result.success(null)` 을 돌려주고 실제 성공/실패는 별도 채널 이벤트로 보낸다
/// (TapjoyOfferwallPlugin.kt:160/:170). 즉 `await Tapjoy.setUserID(...)` 는 ID
/// 반영을 보장하지 않으며, 그 사이에 오퍼월을 요청하면 SDK 가 아직 들고 있는
/// 기본 기기 ID 로 오퍼가 만들어질 수 있다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tapjoy_offerwall');
  const uid = '00000000-0000-0000-0000-000000000001';
  const otherUid = '00000000-0000-0000-0000-000000000002';

  group('sendTapjoyUserId', () {
    late List<MethodCall> calls;
    late TestDefaultBinaryMessenger messenger;

    void mockNative({Object? Function(MethodCall call)? reply}) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (reply != null) return reply(call);
        // Android 네이티브의 result.success(null) 을 그대로 재현한다.
        return null;
      });
    }

    /// SDK 가 뒤늦게 보내는 채널 이벤트.
    Future<void> deliverSdkEvent(String method, [dynamic arguments]) {
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

    setUp(() {
      calls = <MethodCall>[];
      messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    testWidgets('네이티브 메서드 반환만으로는 완료되지 않는다 — 성공 이벤트까지 기다린다', (tester) async {
      mockNative();

      var completed = false;
      final pending = sendTapjoyUserId(uid).terminal.then((_) {
        completed = true;
      });

      await tester.pump();
      expect(
        calls.map((c) => c.method),
        contains('setUserID'),
        reason: 'setUserID 자체는 즉시 나가야 한다',
      );
      expect(calls.firstWhere((c) => c.method == 'setUserID').arguments, {
        'userId': uid,
      });
      // 여기서 완료되면 오퍼월 요청이 기기 ID 상태에서 나간다 (PICNIC-2682).
      expect(completed, isFalse);

      await deliverSdkEvent('TapjoyOnSetUserIDSuccess');
      await tester.pump();
      await pending;
      expect(completed, isTrue);
    });

    testWidgets('실패 이벤트는 Future 실패로 전파된다', (tester) async {
      mockNative();

      final pending = sendTapjoyUserId(uid).terminal;
      final matcher = expectLater(
        pending,
        throwsA(isA<TapjoySessionException>()),
      );

      await tester.pump();
      await deliverSdkEvent('TapjoyOnSetUserIDFailure', 'bad user id');
      await tester.pump();
      await matcher;
    });

    testWidgets('채널 예외도 Future 실패로 전파된다', (tester) async {
      mockNative(
        reply: (_) =>
            throw PlatformException(code: 'ERROR', message: 'no activity'),
      );

      // 채널 호출은 실패해도 리스너가 이미 등록돼 있으므로 attempt 는 반환되고,
      // 실패는 dispatch 로 관찰된다.
      final attempt = sendTapjoyUserId(uid);
      await expectLater(attempt.dispatch, throwsA(isA<PlatformException>()));
      attempt.terminal.ignore();
    });
  });

  group('TapjoySession', () {
    /// 테스트용 setUserID 스텁. 완료 시점을 테스트가 통제한다.
    late List<String> setCalls;
    late List<Completer<void>> gates;
    late String? currentUser;

    /// 네이티브 SDK 가 들고 있는 사용자 ID. 성공 게이트가 열리면 반영된다.
    late String? nativeUserId;

    TapjoyUserIdAttempt fakeSetUserId(String userId) {
      setCalls.add(userId);
      final gate = Completer<void>();
      gates.add(gate);
      // Android SDK 는 HTTP 검증 이전에 로컬 ID 를 먼저 반영한다.
      nativeUserId = userId;
      return TapjoyUserIdAttempt(
        userId,
        dispatch: Future<void>.value(),
        terminal: gate.future,
      );
    }

    setUp(() {
      setCalls = <String>[];
      gates = <Completer<void>>[];
      currentUser = uid;
      nativeUserId = null;
    });

    TapjoySession makeSession({TapjoyConnector? connect}) => TapjoySession(
      setUserIdAndWait: fakeSetUserId,
      currentUserId: () => currentUser,
      connect: connect ?? _immediateSuccessConnector(),
      nativeUserId: () async => nativeUserId,
      nativeConnected: () async => false,
      userIdTimeout: const Duration(seconds: 10),
      connectTimeout: const Duration(seconds: 15),
    );

    test('connect 성공 이벤트 전에는 setUserID 를 보내지 않는다', () async {
      final connectSuccess = Completer<void>();
      final session = makeSession(connect: _deferredConnector(connectSuccess));
      await session.connect(sdkKey: 'sdk-key');

      var ready = false;
      unawaited(session.ensureUserReady().then((_) => ready = true));
      await pumpEventQueue();

      expect(setCalls, isEmpty, reason: 'connect 미완료 상태에서 ID 를 설정하면 안 된다');
      expect(ready, isFalse);

      connectSuccess.complete();
      await pumpEventQueue();
      expect(setCalls, [uid]);
    });

    test('이미 로그인 상태면 connect 옵션으로 UUID 를 넘긴다', () async {
      Map<String, dynamic>? seenOptions;
      final session = makeSession(
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
              seenOptions = options;
              onConnectSuccess();
            },
      );

      await session.connect(sdkKey: 'sdk-key', initialUserId: uid);

      // 옵션 없이 연결하면 SDK 가 기본 기기 ID 로 첫 오퍼를 만들 수 있다.
      expect(seenOptions, {'TJC_OPTION_USER_ID': uid});
    });

    test('Auth 가 늦으면 connect 옵션에 사용자 ID 를 넣지 않는다', () async {
      Map<String, dynamic>? seenOptions;
      final session = makeSession(
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
              seenOptions = options;
              onConnectSuccess();
            },
      );

      await session.connect(sdkKey: 'sdk-key', initialUserId: null);
      expect(seenOptions, isEmpty);

      // 그래도 오퍼월 진입 전에 setUserID 성공을 확인하고 나서야 열린다.
      var bodyRuns = 0;
      final pending = session.runOfferwall((_) async => bodyRuns++);
      await pumpEventQueue();
      expect(setCalls, [uid]);
      expect(bodyRuns, 0);
      gates.single.complete();
      await pending;
      expect(bodyRuns, 1);
    });

    test('connect 옵션으로 넘긴 UUID 도 확인된 것으로 치지 않는다', () async {
      final session = makeSession();
      await session.connect(sdkKey: 'sdk-key', initialUserId: uid);

      // SDK 는 connect 옵션의 user_id 에 대해 성공 이벤트를 주지 않는다.
      // 확인 없이 ready 로 캐시하면 PICNIC-2682 가 그대로 남는다.
      expect(session.readyUserId, isNull);
      final pending = session.ensureUserReady();
      await pumpEventQueue();
      expect(setCalls, [uid]);
      gates.single.complete();
      await pending;
      expect(session.readyUserId, uid);
    });

    test('connect 실패면 ensureUserReady 가 실패하고 ready 를 캐시하지 않는다', () async {
      final session = makeSession(connect: _failingConnector());
      await session.connect(sdkKey: 'sdk-key');

      await expectLater(
        session.ensureUserReady(),
        throwsA(isA<TapjoySessionException>()),
      );
      expect(setCalls, isEmpty);
    });

    test('로그인 사용자가 없으면 오퍼월을 실행하지 않는다', () async {
      final session = makeSession();
      await session.connect(sdkKey: 'sdk-key');
      currentUser = null;

      var bodyRuns = 0;
      await expectLater(
        session.runOfferwall((_) async => bodyRuns++),
        throwsA(isA<TapjoySessionException>()),
      );
      expect(bodyRuns, 0);
      expect(setCalls, isEmpty);
    });

    test('setUserID 가 실패하면 오퍼월 요청이 일어나지 않는다', () async {
      final session = makeSession();
      await session.connect(sdkKey: 'sdk-key');

      var bodyRuns = 0;
      final pending = session.runOfferwall((_) async => bodyRuns++);
      final matcher = expectLater(
        pending,
        throwsA(isA<TapjoySessionException>()),
      );

      await pumpEventQueue();
      gates.single.completeError(
        const TapjoySessionException('SET_USER_ID_FAILED'),
      );
      await matcher;

      expect(bodyRuns, 0, reason: 'ID 설정 실패 뒤 오퍼월을 열면 기기 ID 로 오퍼가 생성된다');
    });

    test('요청 직전 계정이 바뀌면 중단하고 ready 를 캐시하지 않는다', () async {
      final session = makeSession();
      await session.connect(sdkKey: 'sdk-key');

      var bodyRuns = 0;
      final pending = session.runOfferwall((_) async => bodyRuns++);
      final matcher = expectLater(
        pending,
        throwsA(isA<TapjoySessionException>()),
      );

      await pumpEventQueue();
      // setUserID 성공 이벤트를 기다리는 사이 계정이 바뀐 상황.
      currentUser = otherUid;
      gates.single.complete();
      await matcher;

      expect(bodyRuns, 0);

      // 이전 계정의 ready 가 남으면 다음 요청이 남의 UUID 로 나간다.
      final next = session.runOfferwall((_) async => bodyRuns++);
      await pumpEventQueue();
      expect(setCalls, [uid, otherUid]);
      gates.last.complete();
      await next;
      expect(bodyRuns, 1);
    });

    test('동시 호출은 직렬화된다 — 전역 단일 슬롯 리스너가 겹치지 않는다', () async {
      final session = makeSession();
      await session.connect(sdkKey: 'sdk-key');

      final order = <String>[];
      final first = session.runOfferwall((_) async => order.add('first'));
      final second = session.runOfferwall((_) async => order.add('second'));

      await pumpEventQueue();
      expect(
        setCalls.length,
        1,
        reason: 'Tapjoy 의 setUserID 성공/실패 리스너는 static 단일 슬롯이다',
      );

      gates.single.complete();
      await first;
      await pumpEventQueue();
      await second;

      expect(order, ['first', 'second']);
      // 두 번째는 이미 준비된 ID 를 재사용한다.
      expect(setCalls, [uid]);
    });

    test('invalidateUser 뒤에는 ID 를 다시 설정한다', () async {
      final session = makeSession();
      await session.connect(sdkKey: 'sdk-key');

      final first = session.ensureUserReady();
      await pumpEventQueue();
      gates.single.complete();
      await first;
      expect(setCalls, [uid]);

      // 로그아웃·계정 전환·dispose 로 SDK 상태를 신뢰할 수 없게 된 경우.
      session.invalidateUser();
      final second = session.ensureUserReady();
      await pumpEventQueue();
      gates.last.complete();
      await second;

      expect(setCalls, [uid, uid]);
    });
  });

  group('TapjoyAttemptGuard', () {
    test('지난 시도의 늦은 콜백은 현재 시도로 인정되지 않는다', () {
      final guard = TapjoyAttemptGuard();
      final first = guard.begin();
      final second = guard.begin();

      expect(guard.isCurrent(second), isTrue);
      expect(
        guard.isCurrent(first),
        isFalse,
        reason: '늦게 온 onContentReady 가 이전 시도의 화면을 열면 안 된다',
      );
    });

    test('cancel 뒤에는 어떤 시도도 현재가 아니다 — dispose/계정 전환', () {
      final guard = TapjoyAttemptGuard();
      final token = guard.begin();
      guard.cancel();

      expect(guard.isCurrent(token), isFalse);
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

TapjoyConnector _deferredConnector(Completer<void> trigger) =>
    ({
      required String sdkKey,
      required Map<String, dynamic> options,
      required void Function() onConnectSuccess,
      required void Function(int code, String? message) onConnectFailure,
      required void Function(int code, String? message) onConnectWarning,
    }) async {
      // Android 플러그인의 result.success(null) 은 연결 완료 전에 돌아온다.
      unawaited(trigger.future.then((_) => onConnectSuccess()));
    };

TapjoyConnector _failingConnector() =>
    ({
      required String sdkKey,
      required Map<String, dynamic> options,
      required void Function() onConnectSuccess,
      required void Function(int code, String? message) onConnectFailure,
      required void Function(int code, String? message) onConnectWarning,
    }) async {
      onConnectFailure(1, 'connect failed');
    };
