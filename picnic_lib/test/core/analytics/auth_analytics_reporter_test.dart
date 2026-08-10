import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_reporter.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_store.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// 파일/플랫폼 채널 없이 동작하는 인메모리 LocalStorage.
class _InMemoryLocalStorage implements LocalStorage {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<void> clearStorage() async => _data.clear();

  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      _data[key] ?? defaultValue;

  @override
  Future<void> removeData(String key) async => _data.remove(key);

  @override
  Future<void> saveData(String key, String value) async => _data[key] = value;
}

/// 서명 읽기가 항상 실패하는 저장소. 체인이 실패로 잠기지 않는지 확인한다.
class _ThrowingSignatureStore extends AuthAnalyticsStore {
  _ThrowingSignatureStore({required LocalStorage storage})
    : super(storage: storage);

  @override
  Future<String?> readLoginSignature() async {
    throw StateError('storage down');
  }
}

/// sign_up 종류의 enqueue 만 지정 횟수만큼 실패시키는 outbox.
/// "sign_up outbox 저장만 실패, login 저장은 성공" 시나리오를 재현한다.
class _SignUpEnqueueFailingOutbox extends AnalyticsOutbox {
  _SignUpEnqueueFailingOutbox({
    required LocalStorage storage,
    required Ga4Sink sink,
  }) : super(storage: storage, sink: sink);

  int failSignUpEnqueues = 0;

  @override
  Future<bool> enqueue(AnalyticsOutboxEntry entry, {bool flush = false}) {
    if (failSignUpEnqueues > 0 &&
        entry.kind == AnalyticsOutboxEventKind.signUp) {
      failSignUpEnqueues--;
      return Future<bool>.value(false);
    }
    return super.enqueue(entry, flush: flush);
  }
}

/// sign_up 마커 저장이 항상 실패하는 저장소. enqueue 성공 뒤 마커만 남지 않은
/// 상태에서 outbox dedup 이 재발송을 막는지 검증한다.
class _MarkerFailingStore extends AuthAnalyticsStore {
  _MarkerFailingStore({required LocalStorage storage})
    : super(storage: storage);

  @override
  Future<bool> markSignUpLogged(String userId) => Future<bool>.value(false);
}

class _NeverFirstEventSink extends RecordingGa4Sink {
  var _calls = 0;

  @override
  Future<bool> logEvent(String name, Map<String, Object> parameters) {
    events.add(RecordedGa4Event(name, parameters));
    _calls++;
    if (_calls == 1) return Completer<bool>().future;
    return Future<bool>.value(true);
  }
}

void main() {
  late _InMemoryLocalStorage storage;
  late RecordingGa4Sink sink;
  late AuthAnalyticsReporter reporter;

  setUp(() {
    storage = _InMemoryLocalStorage();
    sink = RecordingGa4Sink();
    reporter = AuthAnalyticsReporter(
      store: AuthAnalyticsStore(storage: storage),
      analytics: PicnicAnalytics(sink: sink),
    );
  });

  Future<void> signIn({
    String userId = 'u1',
    String? provider = 'kakao',
    String createdAt = '2026-01-01T00:00:00.000Z',
    String? lastSignInAt = '2026-08-07T01:00:00.000Z',
    String? selectedLanguage = 'ko',
  }) {
    return reporter.onSignedIn(
      userId: userId,
      provider: provider,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt,
      selectedLanguage: selectedLanguage,
    );
  }

  test('기존 사용자 로그인은 login 1건만 발송한다', () async {
    await signIn();

    expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
    expect(sink.last.parameters, <String, Object>{
      Ga4Param.method: 'kakao',
      Ga4Param.selectedLanguage: 'ko',
    });
  });

  test('신규 가입은 sign_up 다음에 login 을 발송한다', () async {
    await signIn(
      createdAt: '2026-08-07T01:00:00.000Z',
      lastSignInAt: '2026-08-07T01:00:00.300Z',
    );

    expect(sink.events.map((e) => e.name), <String>[
      Ga4Event.signUp,
      Ga4Event.login,
    ]);
  });

  test('앱 재시작으로 signedIn 이 재발화해도 login 이 중복 발송되지 않는다', () async {
    await signIn();
    sink.clear();

    // 동일 세션 복원: userId 와 last_sign_in_at 이 그대로다.
    await signIn();

    expect(sink.events, isEmpty);
  });

  test('실제 재로그인(last_sign_in_at 갱신)은 login 을 다시 발송한다', () async {
    await signIn(lastSignInAt: '2026-08-07T01:00:00.000Z');
    sink.clear();

    await signIn(lastSignInAt: '2026-08-08T09:30:00.000Z');

    expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
  });

  test('가입 직후 로그아웃→재로그인해도 sign_up 은 한 번만 나간다', () async {
    await signIn(
      createdAt: '2026-08-07T01:00:00.000Z',
      lastSignInAt: '2026-08-07T01:00:00.100Z',
    );
    await reporter.onSignedOut();
    sink.clear();

    // 30초 창 안에서 재로그인.
    await signIn(
      createdAt: '2026-08-07T01:00:00.000Z',
      lastSignInAt: '2026-08-07T01:00:20.000Z',
    );

    expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
  });

  test('로그아웃 후 last_sign_in_at 이 없는 재로그인도 login 이 발송된다', () async {
    await signIn(lastSignInAt: null);
    sink.clear();

    // 서명을 지우지 않았다면 여기서 중복으로 오인된다.
    await reporter.onSignedOut();
    await signIn(lastSignInAt: null);

    expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
  });

  test('provider 를 알 수 없으면 method 는 undefined 로 나간다', () async {
    await signIn(provider: null);

    expect(sink.last.parameters[Ga4Param.method], Ga4Value.undefined);
  });

  test('selected_language 가 없으면 undefined 로 대체된다', () async {
    await signIn(selectedLanguage: null);

    expect(sink.last.parameters[Ga4Param.selectedLanguage], Ga4Value.undefined);
  });

  test('사용자가 다르면 각각 sign_up 이 발송된다', () async {
    await signIn(
      userId: 'a',
      createdAt: '2026-08-07T01:00:00.000Z',
      lastSignInAt: '2026-08-07T01:00:00.100Z',
    );
    await reporter.onSignedOut();
    sink.clear();

    await signIn(
      userId: 'b',
      createdAt: '2026-08-07T02:00:00.000Z',
      lastSignInAt: '2026-08-07T02:00:00.100Z',
    );

    expect(sink.events.map((e) => e.name), <String>[
      Ga4Event.signUp,
      Ga4Event.login,
    ]);
  });

  group('동시 진입 (single-flight)', () {
    // auth 리스너는 `Stream.listen` 의 async 콜백이라 이전 콜백의 완료를
    // 기다리지 않는다. 직렬화가 없으면 두 호출이 readLoginSignature()
    // ~ writeLoginSignature() 사이의 await 창에서 동시에 "저장된 서명 없음"을
    // 읽고 각각 발송한다.
    test('signedIn 이 동시에 2번 들어와도 login 은 정확히 1회만 발송된다', () async {
      await Future.wait<void>(<Future<void>>[signIn(), signIn()]);

      expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
    });

    test('신규 가입이 동시에 2번 들어와도 sign_up 과 login 이 각각 1회만 발송된다', () async {
      Future<void> fresh() => signIn(
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.200Z',
      );

      await Future.wait<void>(<Future<void>>[fresh(), fresh()]);

      expect(sink.events.map((e) => e.name), <String>[
        Ga4Event.signUp,
        Ga4Event.login,
      ]);
    });

    test('동시 진입이 3건이어도 login 은 1회다', () async {
      await Future.wait<void>(<Future<void>>[signIn(), signIn(), signIn()]);

      expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
    });

    test('직렬화는 서로 다른 로그인 세션의 발송까지 막지는 않는다', () async {
      await Future.wait<void>(<Future<void>>[
        signIn(lastSignInAt: '2026-08-07T01:00:00.000Z'),
        signIn(lastSignInAt: '2026-08-08T09:30:00.000Z'),
      ]);

      expect(sink.events.map((e) => e.name), <String>[
        Ga4Event.login,
        Ga4Event.login,
      ]);
    });

    test('한 건이 실패해도 체인이 막히지 않고 다음 로그인이 발송된다', () async {
      final failing = AuthAnalyticsReporter(
        store: _ThrowingSignatureStore(storage: storage),
        analytics: PicnicAnalytics(sink: sink),
      );

      // 내부에서 잡아 로깅만 하므로 던지지 않는다.
      await failing.onSignedIn(
        userId: 'u1',
        provider: 'kakao',
        createdAt: '2026-01-01T00:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.000Z',
        selectedLanguage: 'ko',
      );
      sink.clear();

      await signIn();

      expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
    });

    test('never-completing auth sink는 timeout 후 다음 로그인을 막지 않는다', () async {
      final hangingSink = _NeverFirstEventSink();
      final bounded = AuthAnalyticsReporter(
        store: AuthAnalyticsStore(storage: storage),
        analytics: PicnicAnalytics(sink: hangingSink),
        sendTimeout: const Duration(milliseconds: 10),
      );

      await bounded.onSignedIn(
        userId: 'u1',
        provider: 'kakao',
        createdAt: '2026-01-01T00:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.000Z',
        selectedLanguage: 'ko',
      );
      await bounded.onSignedIn(
        userId: 'u1',
        provider: 'kakao',
        createdAt: '2026-01-01T00:00:00.000Z',
        lastSignInAt: '2026-08-08T01:00:00.000Z',
        selectedLanguage: 'ko',
      );

      expect(hangingSink.events.map((event) => event.name), <String>[
        Ga4Event.login,
        Ga4Event.login,
      ]);
      expect(
        await AuthAnalyticsStore(storage: storage).readLoginSignature(),
        'u1|2026-08-08T01:00:00.000Z',
      );
    });
  });

  group('outbox 경로 — sign_up 영구 누락 방지', () {
    setUp(AnalyticsOutbox.resetProcessStateForTest);
    tearDown(AnalyticsOutbox.resetProcessStateForTest);

    Future<void> freshSignIn(AuthAnalyticsReporter target) {
      return target.onSignedIn(
        userId: 'u1',
        provider: 'kakao',
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.300Z',
        selectedLanguage: 'ko',
      );
    }

    test('정상 신규 가입은 sign_up 과 login 을 각각 1회 발송한다', () async {
      final outboxStorage = _InMemoryLocalStorage();
      final outboxSink = RecordingGa4Sink();
      final outbox = AnalyticsOutbox(storage: outboxStorage, sink: outboxSink);
      final outboxReporter = AuthAnalyticsReporter(
        store: AuthAnalyticsStore(storage: outboxStorage),
        outbox: outbox,
      );

      await freshSignIn(outboxReporter);
      await outbox.flush();

      expect(outboxSink.events.map((e) => e.name), <String>[
        Ga4Event.signUp,
        Ga4Event.login,
      ]);
    });

    test('sign_up 저장만 실패하고 login 이 성공해도 다음 signedIn 이 sign_up 을 재시도한다', () async {
      final outboxStorage = _InMemoryLocalStorage();
      final outboxSink = RecordingGa4Sink();
      final outbox = _SignUpEnqueueFailingOutbox(
        storage: outboxStorage,
        sink: outboxSink,
      )..failSignUpEnqueues = 1;
      final outboxReporter = AuthAnalyticsReporter(
        store: AuthAnalyticsStore(storage: outboxStorage),
        outbox: outbox,
      );

      // 최초 가입: sign_up enqueue 실패, login enqueue 성공 → 서명이 남는다.
      await freshSignIn(outboxReporter);
      await outbox.flush();
      expect(outboxSink.events.map((e) => e.name), <String>[Ga4Event.login]);

      // 세션 복원 재발화: login 은 중복이지만 sign_up 은 재시도돼야 한다.
      // (수정 전에는 login 중복 판정이 sign_up 까지 억제해 영구 누락이었다.)
      await freshSignIn(outboxReporter);
      await outbox.flush();

      expect(outboxSink.events.map((e) => e.name), <String>[
        Ga4Event.login,
        Ga4Event.signUp,
      ]);
      expect(
        await AuthAnalyticsStore(storage: outboxStorage).hasLoggedSignUp('u1'),
        isTrue,
        reason: '재시도 성공 후 마커도 저장돼 이후 재발화에서 sign_up 판정이 꺼진다',
      );
    });

    test('마커 저장 실패 + 재시작 재발화에도 outbox dedup 이 sign_up 재발송을 막는다', () async {
      // 3차에서 복원했던 'login 중복 시 sign_up 억제' 게이트가 막으려던
      // 시나리오다: enqueue 성공 후 signUpAlreadyLogged 마커 저장만 실패.
      // 게이트 없이도 durable delivered 마커의 `signup:<userId>` dedup 이
      // 프로세스 재시작을 가로질러 재발송을 막는지 검증한다.
      final outboxStorage = _InMemoryLocalStorage();
      final firstSink = RecordingGa4Sink();
      final firstOutbox = AnalyticsOutbox(
        storage: outboxStorage,
        sink: firstSink,
      );
      final firstReporter = AuthAnalyticsReporter(
        store: _MarkerFailingStore(storage: outboxStorage),
        outbox: firstOutbox,
      );

      await freshSignIn(firstReporter);
      await firstOutbox.flush();
      expect(firstSink.events.map((e) => e.name), <String>[
        Ga4Event.signUp,
        Ga4Event.login,
      ]);

      // 프로세스 재시작을 재현: in-process 상태를 비우고 새 인스턴스를 만든다.
      AnalyticsOutbox.resetProcessStateForTest();
      final restartedSink = RecordingGa4Sink();
      final restartedOutbox = AnalyticsOutbox(
        storage: outboxStorage,
        sink: restartedSink,
      );
      final restartedReporter = AuthAnalyticsReporter(
        store: _MarkerFailingStore(storage: outboxStorage),
        outbox: restartedOutbox,
      );

      await freshSignIn(restartedReporter);
      await restartedOutbox.flush();

      expect(
        restartedSink.events.where((e) => e.name == Ga4Event.signUp),
        isEmpty,
        reason: 'delivered 마커의 signup:<userId> dedup 이 재발송을 막는다',
      );
    });

    test('정상 재로그인(신규 가입 아님)에서는 sign_up 이 발송되지 않는다', () async {
      final outboxStorage = _InMemoryLocalStorage();
      final outboxSink = RecordingGa4Sink();
      final outbox = AnalyticsOutbox(storage: outboxStorage, sink: outboxSink);
      final outboxReporter = AuthAnalyticsReporter(
        store: AuthAnalyticsStore(storage: outboxStorage),
        outbox: outbox,
      );

      await outboxReporter.onSignedIn(
        userId: 'u1',
        provider: 'kakao',
        createdAt: '2026-01-01T00:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.000Z',
        selectedLanguage: 'ko',
      );
      await outbox.flush();
      await outboxReporter.onSignedOut();

      await outboxReporter.onSignedIn(
        userId: 'u1',
        provider: 'kakao',
        createdAt: '2026-01-01T00:00:00.000Z',
        lastSignInAt: '2026-08-08T09:30:00.000Z',
        selectedLanguage: 'ko',
      );
      await outbox.flush();

      expect(outboxSink.events.map((e) => e.name), <String>[
        Ga4Event.login,
        Ga4Event.login,
      ]);
    });
  });

  group('AuthAnalyticsStore', () {
    test('서명을 저장/조회/삭제한다', () async {
      final store = AuthAnalyticsStore(storage: storage);

      expect(await store.readLoginSignature(), isNull);
      await store.writeLoginSignature('sig');
      expect(await store.readLoginSignature(), 'sig');
      await store.clearLoginSignature();
      expect(await store.readLoginSignature(), isNull);
    });

    test('sign_up 마커는 중복 저장되지 않고 상한을 넘지 않는다', () async {
      final store = AuthAnalyticsStore(storage: storage);

      await store.markSignUpLogged('u1');
      await store.markSignUpLogged('u1');
      expect(await store.hasLoggedSignUp('u1'), isTrue);
      expect(await store.hasLoggedSignUp('u2'), isFalse);

      for (var i = 0; i < AuthAnalyticsStore.maxTrackedSignUpUsers + 5; i++) {
        await store.markSignUpLogged('user$i');
      }

      final raw = await storage.loadData(
        AuthAnalyticsStore.signUpUserIdsKey,
        null,
      );
      expect(
        raw!.split(',').length,
        lessThanOrEqualTo(AuthAnalyticsStore.maxTrackedSignUpUsers),
      );
    });
  });
}
