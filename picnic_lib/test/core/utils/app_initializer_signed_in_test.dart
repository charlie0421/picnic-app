import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_reporter.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_store.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

class _InMemoryLocalStorage implements LocalStorage {
  final Map<String, String> data = <String, String>{};

  @override
  Future<void> clearStorage() async => data.clear();

  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      data[key] ?? defaultValue;

  @override
  Future<void> removeData(String key) async => data.remove(key);

  @override
  Future<void> saveData(String key, String value) async => data[key] = value;
}

/// 어떤 사용자로 어떤 파라미터가 나갔는지 그대로 붙잡는다.
class _RecordingReporter implements AuthAnalyticsReporter {
  final List<String> signedInUserIds = <String>[];
  final List<String?> lastSignInAts = <String?>[];
  int signedOutCount = 0;

  @override
  Duration get sendTimeout => const Duration(seconds: 5);

  @override
  Future<void> onSignedIn({
    required String userId,
    required String? provider,
    required String? createdAt,
    required String? lastSignInAt,
    required String? selectedLanguage,
  }) async {
    signedInUserIds.add(userId);
    lastSignInAts.add(lastSignInAt);
  }

  @override
  Future<void> onSignedOut() async {
    signedOutCount++;
  }
}

AuthState _signedIn(String userId, {String? lastSignInAt}) {
  final user = User(
    id: userId,
    appMetadata: <String, dynamic>{'provider': 'kakao'},
    userMetadata: <String, dynamic>{},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00.000Z',
    lastSignInAt: lastSignInAt,
  );
  return AuthState(
    AuthChangeEvent.signedIn,
    Session(accessToken: 'token-$userId', tokenType: 'bearer', user: user),
  );
}

void main() {
  group('AppInitializer.handleSignedIn — 이벤트 주인 캡처', () {
    setUp(AppInitializer.resetSupabaseAuthListenerForTest);

    test('프로필 fetch 중에 사용자가 바뀌어도 A 이벤트는 A 로 보고된다', () async {
      // 리스너 콜백은 async 이고 스트림은 완료를 기다리지 않는다. A 의 콜백이
      // 프로필 fetch 에서 대기하는 동안 B 가 로그인하면, 전역 currentUser 를
      // 나중에 읽는 구현은 A 를 B 로 보고하고 A 의 login 을 통째로 잃는다.
      final reporter = _RecordingReporter();
      final aGate = Completer<void>();

      // "지금 로그인해 있는 사용자"는 B 로 바뀐 상태다.
      var activeUserId = 'user-a';

      final aFuture = AppInitializer.handleSignedIn(
        _signedIn('user-a', lastSignInAt: '2026-08-07T01:00:00.000Z'),
        ensureProfileLoaded: () => aGate.future,
        readUserRole: () => 'user',
        readLocale: () => 'ko',
        readActiveUserId: () => activeUserId,
        reporter: reporter,
        setUserProperties:
            ({
              required String userId,
              String? userRole,
              String? locale,
              bool? isTester,
              String? language,
              bool isLogin = true,
            }) async {},
      );

      // A 가 대기하는 사이 B 로 전환된다.
      activeUserId = 'user-b';
      final bFuture = AppInitializer.handleSignedIn(
        _signedIn('user-b', lastSignInAt: '2026-08-07T02:00:00.000Z'),
        ensureProfileLoaded: () async {},
        readUserRole: () => 'user',
        readLocale: () => 'ko',
        readActiveUserId: () => activeUserId,
        reporter: reporter,
        setUserProperties:
            ({
              required String userId,
              String? userRole,
              String? locale,
              bool? isTester,
              String? language,
              bool isLogin = true,
            }) async {},
      );

      aGate.complete();
      await Future.wait<void>(<Future<void>>[aFuture, bFuture]);

      expect(reporter.signedInUserIds, <String>[
        'user-a',
        'user-b',
      ], reason: 'auth 상태 이벤트는 유입 순서로 직렬화되어야 한다');

      final aIndex = reporter.signedInUserIds.indexOf('user-a');
      expect(
        reporter.lastSignInAts[aIndex],
        '2026-08-07T01:00:00.000Z',
        reason: 'A 의 서명이 B 의 값으로 오염되면 안 된다',
      );
    });

    test('사용자가 바뀌면 지난 사용자의 전역 속성은 덮어쓰지 않는다', () async {
      // 전역 user_id 를 A 로 되돌리면 이후 B 의 모든 이벤트가 A 로 귀속된다.
      final reporter = _RecordingReporter();
      final applied = <String>[];

      await AppInitializer.handleSignedIn(
        _signedIn('user-a'),
        ensureProfileLoaded: () async {},
        readUserRole: () => 'user',
        readLocale: () => 'ko',
        readActiveUserId: () => 'user-b',
        reporter: reporter,
        setUserProperties:
            ({
              required String userId,
              String? userRole,
              String? locale,
              bool? isTester,
              String? language,
              bool isLogin = true,
            }) async {
              applied.add(userId);
            },
      );

      expect(applied, isEmpty);
      expect(reporter.signedInUserIds, <String>[
        'user-a',
      ], reason: 'login 은 이 이벤트의 사실이므로 A 로 보고한다');
    });

    test('A 프로필 대기 중 logout이 와도 A 전역 속성을 되살리지 않는다', () async {
      final reporter = _RecordingReporter();
      final aGate = Completer<void>();
      String? activeUserId = 'user-a';
      final applied = <String>[];
      final cleared = <String>[];

      final aFuture = AppInitializer.handleSignedIn(
        _signedIn('user-a'),
        ensureProfileLoaded: () => aGate.future,
        readUserRole: () => 'user',
        readLocale: () => 'ko',
        readActiveUserId: () => activeUserId,
        reporter: reporter,
        setUserProperties:
            ({
              required String userId,
              String? userRole,
              String? locale,
              bool? isTester,
              String? language,
              bool isLogin = true,
            }) async {
              applied.add(userId);
            },
      );

      activeUserId = null;
      final logoutFuture = AppInitializer.handleSignedOut(
        reporter: reporter,
        clearUserProperties: () async {
          cleared.add('logout');
        },
      );
      aGate.complete();
      await Future.wait<void>(<Future<void>>[aFuture, logoutFuture]);

      expect(applied, isEmpty);
      expect(reporter.signedInUserIds, <String>['user-a']);
      expect(cleared, <String>['logout']);
      expect(reporter.signedOutCount, 1);
    });

    test('전환이 없으면 전역 속성을 정상 갱신한다', () async {
      final applied = <String>[];

      await AppInitializer.handleSignedIn(
        _signedIn('user-a'),
        ensureProfileLoaded: () async {},
        readUserRole: () => 'admin',
        readLocale: () => 'ja',
        readActiveUserId: () => 'user-a',
        reporter: _RecordingReporter(),
        setUserProperties:
            ({
              required String userId,
              String? userRole,
              String? locale,
              bool? isTester,
              String? language,
              bool isLogin = true,
            }) async {
              applied.add('$userId/$userRole/$locale');
            },
      );

      expect(applied, <String>['user-a/admin/ja']);
    });

    test('프로필 fetch 가 던져도 login 은 보고된다', () async {
      final reporter = _RecordingReporter();

      await AppInitializer.handleSignedIn(
        _signedIn('user-a'),
        ensureProfileLoaded: () async => throw StateError('ref disposed'),
        readUserRole: () => throw StateError('ref disposed'),
        readLocale: () => throw StateError('ref disposed'),
        readActiveUserId: () => 'user-a',
        reporter: reporter,
        setUserProperties:
            ({
              required String userId,
              String? userRole,
              String? locale,
              bool? isTester,
              String? language,
              bool isLogin = true,
            }) async {},
      );

      expect(reporter.signedInUserIds, <String>['user-a']);
    });

    test('세션이 없는 signedIn 은 조용히 건너뛴다', () async {
      final reporter = _RecordingReporter();

      await AppInitializer.handleSignedIn(
        AuthState(AuthChangeEvent.signedIn, null),
        ensureProfileLoaded: () async {},
        readUserRole: () => null,
        readLocale: () => null,
        readActiveUserId: () => null,
        reporter: reporter,
        setUserProperties:
            ({
              required String userId,
              String? userRole,
              String? locale,
              bool? isTester,
              String? language,
              bool isLogin = true,
            }) async {},
      );

      expect(reporter.signedInUserIds, isEmpty);
    });
  });

  group('AuthAnalyticsReporter — 전송 실패 시 마커를 남기지 않는다', () {
    late _InMemoryLocalStorage storage;
    late RecordingGa4Sink sink;
    late AuthAnalyticsReporter reporter;

    setUp(() {
      AuthAnalyticsStore.resetProcessCacheForTest();
      storage = _InMemoryLocalStorage();
      sink = RecordingGa4Sink();
      reporter = AuthAnalyticsReporter(
        store: AuthAnalyticsStore(storage: storage),
        analytics: PicnicAnalytics(sink: sink),
      );
    });
    tearDown(AuthAnalyticsStore.resetProcessCacheForTest);

    Future<void> signIn({
      String userId = 'u1',
      String createdAt = '2026-01-01T00:00:00.000Z',
      String? lastSignInAt = '2026-08-07T01:00:00.000Z',
    }) {
      return reporter.onSignedIn(
        userId: userId,
        provider: 'kakao',
        createdAt: createdAt,
        lastSignInAt: lastSignInAt,
        selectedLanguage: 'ko',
      );
    }

    test('login 전송이 실패하면 서명이 저장되지 않고 다음 시도에서 다시 나간다', () async {
      sink.deliver = false;
      await signIn();

      expect(
        storage.data[AuthAnalyticsStore.loginSignatureKey],
        isNull,
        reason: '보내지 않았는데 서명을 남기면 그 로그인은 영구히 사라진다',
      );

      sink
        ..deliver = true
        ..clear();
      await signIn();

      expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
    });

    test('sign_up 전송이 실패하면 마커가 남지 않고 다음 시도에서 다시 나간다', () async {
      const created = '2026-08-07T01:00:00.000Z';
      const signedIn = '2026-08-07T01:00:00.200Z';

      sink.deliver = false;
      await signIn(createdAt: created, lastSignInAt: signedIn);

      expect(storage.data[AuthAnalyticsStore.signUpUserIdsKey], isNull);

      sink
        ..deliver = true
        ..clear();
      await signIn(createdAt: created, lastSignInAt: signedIn);

      expect(sink.events.map((e) => e.name), <String>[
        Ga4Event.signUp,
        Ga4Event.login,
      ]);
    });

    test('저장소가 죽어도 발송은 계속된다 (누락 < 중복)', () async {
      final failing = AuthAnalyticsReporter(
        store: _FailingWriteStore(storage: storage),
        analytics: PicnicAnalytics(sink: sink),
      );

      await failing.onSignedIn(
        userId: 'u1',
        provider: 'kakao',
        createdAt: '2026-01-01T00:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.000Z',
        selectedLanguage: 'ko',
      );

      expect(sink.events.map((e) => e.name), <String>[Ga4Event.login]);
    });

    test('서로 다른 사용자의 sign_up 마커가 동시에 저장돼도 서로를 덮어쓰지 않는다', () async {
      final store = AuthAnalyticsStore(storage: _SlowLocalStorage());

      await Future.wait<bool>(<Future<bool>>[
        store.markSignUpLogged('a'),
        store.markSignUpLogged('b'),
      ]);

      expect(await store.hasLoggedSignUp('a'), isTrue);
      expect(await store.hasLoggedSignUp('b'), isTrue);
    });
  });
}

class _FailingWriteStore extends AuthAnalyticsStore {
  _FailingWriteStore({required LocalStorage storage}) : super(storage: storage);

  @override
  Future<bool> writeLoginSignature(String signature) async => false;
}

class _SlowLocalStorage extends _InMemoryLocalStorage {
  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.loadData(key, defaultValue);
  }

  @override
  Future<void> saveData(String key, String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.saveData(key, value);
  }
}
