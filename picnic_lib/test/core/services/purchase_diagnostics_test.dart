// Real Sentry hub under test; only the transport is replaced (same harness as
// app_initializer_global_error_handling_test.dart).
// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/purchase_diagnostics.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_flutter/src/integrations/load_contexts_integration.dart';
import 'package:sentry_flutter/src/native/sentry_native_binding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PICNIC-2743 C-2: 422 만 있고 지급이 없는 7명을 Sentry 로도 가릴 수 없었다.
/// 앱이 scope 에 사용자 ID 를 넘기지 않았고(user.id 는 대문자 UUID - 기기
/// 식별자), 결제 서비스에는 Sentry 보고 호출이 없었다.
///
/// 이 테스트는 실제 Sentry 허브를 돌리고 전송 계층만 바꿔, 서버로 나갈
/// 이벤트 그 자체를 검사한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SentryHarness sentry;

  setUp(() async {
    sentry = _SentryHarness();
    await sentry.start();
  });

  tearDown(() => sentry.stop());

  const jws =
      'eyJhbGciOiJFUzI1NiJ9.eyJ0cmFuc2FjdGlvbklkIjoiMjAwMDAwMDAwMSJ9.c2lnbmF0dXJl';
  const accessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLWEifQ.dG9rZW4';
  const email = 'buyer@example.com';

  group('failure report', () {
    test('carries the purchasing account id, stage and a stable code',
        () async {
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: 'user-a',
        error: FunctionException(
          status: 422,
          details: {'error': 'APPLE_JWS_INVALID', 'retryable': false},
        ),
      );
      final event = await sentry.nextEvent();

      expect(event.user?.id, 'user-a');
      expect(event.tags?['purchase.stage'], 'settlement');
      expect(event.tags?['purchase.code'], 'http_422:APPLE_JWS_INVALID');
      expect(event.tags?['purchase.failure_class'], 'permanentRejection');
      expect(event.tags?['purchase.product_id'], 'STAR100');
      expect(event.level, SentryLevel.warning);
      expect(event.fingerprint, contains('http_422:APPLE_JWS_INVALID'));
    });

    test('never sends receipts, tokens, emails or raw exception text',
        () async {
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.sweepVerification,
        productId: 'STAR100',
        userId: 'user-a',
        error: FunctionException(
          status: 500,
          details: {
            'error': 'receipt $jws for $email failed',
            'token': accessToken,
          },
          reasonPhrase: 'bearer $accessToken',
        ),
      );
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: 'user-a',
        error: Exception('verify failed receipt=$jws token=$accessToken $email'),
      );
      final events = await sentry.events(2);

      for (final event in events) {
        final serialized = event.toJson().toString();
        expect(serialized, isNot(contains(jws)));
        expect(serialized, isNot(contains('eyJ0cmFuc2FjdGlvbklkIjoi')));
        expect(serialized, isNot(contains(accessToken)));
        expect(serialized, isNot(contains(email)));
        expect(serialized, isNot(contains('verify failed')));
        expect(event.exceptions ?? const [], isEmpty,
            reason: '예외 객체를 그대로 넘기면 toString() 이 원문째 실린다');
        expect(event.breadcrumbs ?? const [], isEmpty,
            reason: '브레드크럼에는 로그 원문(토큰 로그 포함)이 쌓인다');
      }
      expect(events[0].tags?['purchase.code'], 'http_500');
      expect(events[1].tags?['purchase.code'], 'type:_Exception');
    });

    test('drops breadcrumbs that the app already recorded', () async {
      await Sentry.addBreadcrumb(Breadcrumb(message: 'jwtToken: $accessToken'));

      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: 'user-a',
        error: TimeoutException('slow'),
      );
      final event = await sentry.nextEvent();

      expect(event.breadcrumbs ?? const [], isEmpty);
      expect(event.tags?['purchase.code'], 'timeout');
      expect(event.tags?['purchase.failure_class'], 'processing');
    });

    test('classifies network and duplicate failures without their text',
        () async {
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: 'user-a',
        error: const SocketException('host $email unreachable'),
      );
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.unconfirmedDuplicate,
        productId: 'STAR100',
        userId: 'user-a',
        error: ReusedPurchaseException(
          message: 'receipt $jws reused',
          receiptId: jws,
        ),
      );
      final events = await sentry.events(2);

      expect(events[0].tags?['purchase.code'], 'network');
      expect(events[1].tags?['purchase.code'], 'reused_unconfirmed');
    });

    test('an unauthenticated settlement is reported as such', () async {
      await PurchaseDiagnostics.bindUser('user-b');
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: null,
        error: Exception('USER_NOT_AUTHENTICATED'),
      );
      final event = await sentry.nextEvent();

      expect(event.tags?['purchase.code'], 'not_authenticated');
      expect(event.user, isNull,
          reason: '결제한 계정을 모르는데 scope 에 남은 다른 계정으로 귀속하면 안 된다');
    });

    test('a store error code is kept only in its code form', () async {
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.storeError,
        productId: 'STAR100',
        userId: 'user-a',
        storeErrorCode: 'storekit2_purchase_failed',
      );
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.storeError,
        productId: 'STAR100',
        userId: 'user-a',
        storeErrorCode: 'failed for $email',
      );
      final events = await sentry.events(2);

      expect(events[0].tags?['purchase.code'], 'storekit2_purchase_failed');
      expect(events[1].tags?['purchase.code'], 'unrecognized');
      expect(events[1].toJson().toString(), isNot(contains(email)));
    });

    test('an expected cancellation is not an error report', () async {
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.storeError,
        productId: 'STAR100',
        userId: 'user-a',
        storeErrorCode: 'storekit2_purchase_cancelled',
      );
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.storeError,
        productId: 'STAR100',
        userId: 'user-a',
        storeErrorCode: 'BillingResponse.userCanceled',
      );

      expect(await sentry.eventsWithin(const Duration(milliseconds: 300)),
          isEmpty);
    });

    test('the event keeps the purchasing account even after a switch',
        () async {
      await PurchaseDiagnostics.bindUser('user-b');

      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: 'user-a',
        error: TimeoutException('slow'),
      );
      final event = await sentry.nextEvent();

      expect(event.user?.id, 'user-a',
          reason: '실패는 결제를 시작한 계정의 것이다 - 전환 후 계정이 아니다');
    });

    test('reporting never throws into the purchase path', () async {
      await Sentry.close();

      expect(
        () => PurchaseDiagnostics.reportFailure(
          stage: PurchaseFailureStage.settlement,
          productId: 'STAR100',
          userId: 'user-a',
          error: TimeoutException('slow'),
        ),
        returnsNormally,
      );
    });
  });

  nativeEnrichmentTests();

  group('scope user binding', () {
    Future<SentryUser?> scopeUserOnNextEvent() async {
      await Sentry.captureMessage('probe');
      return (await sentry.nextEvent()).user;
    }

    test('binds only the account id - no email or other profile data',
        () async {
      await PurchaseDiagnostics.bindUserFromAuthState(
        AuthState(AuthChangeEvent.signedIn, _session('user-a', email)),
      );
      final user = await scopeUserOnNextEvent();

      expect(user?.id, 'user-a');
      expect(user?.email, isNull);
      expect(user?.username, isNull);
      expect(user?.ipAddress, isNull);
      expect(user?.data, isNull);
    });

    test('logout clears the account id', () async {
      await PurchaseDiagnostics.bindUserFromAuthState(
        AuthState(AuthChangeEvent.signedIn, _session('user-a', email)),
      );
      await PurchaseDiagnostics.bindUserFromAuthState(
        const AuthState(AuthChangeEvent.signedOut, null),
      );

      expect((await scopeUserOnNextEvent())?.id, isNot('user-a'));
    });

    test('an account switch rebinds to the new account', () async {
      await PurchaseDiagnostics.bindUserFromAuthState(
        AuthState(AuthChangeEvent.signedIn, _session('user-a', email)),
      );
      await PurchaseDiagnostics.bindUserFromAuthState(
        AuthState(AuthChangeEvent.signedIn, _session('user-b', email)),
      );

      expect((await scopeUserOnNextEvent())?.id, 'user-b');
    });

    test('a restored session binds too', () async {
      await PurchaseDiagnostics.bindUserFromAuthState(
        AuthState(AuthChangeEvent.initialSession, _session('user-a', email)),
      );

      expect((await scopeUserOnNextEvent())?.id, 'user-a');
    });
  });
}

/// Native enrichment runs **after** the scope is applied: on iOS/Android
/// `LoadContextsIntegration` fills `event.user` from the native scope when it
/// is null (iOS substitutes the installation id) and replaces the event's
/// breadcrumbs with the native trail under `enableScopeSync`. Clearing the
/// cloned Dart scope cannot undo that, so the diagnostics contract has to be
/// enforced in `beforeSend` - after enrichment, before the transport.
void nativeEnrichmentTests() {
  group('after native enrichment', () {
    late _NativeHarness sentry;

    setUp(() async {
      sentry = _NativeHarness();
      await sentry.start();
    });

    tearDown(() => sentry.stop());

    test('a purchase report reaches the transport with no native breadcrumbs',
        () async {
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: 'user-a',
        error: TimeoutException('slow'),
      );
      final sent = await sentry.nextSent();

      expect(sent.toString(), isNot(contains('native-secret-breadcrumb')));
      expect((sent['breadcrumbs'] as List?) ?? const [], isEmpty);
      expect((sent['user'] as Map?)?['id'], 'user-a');
    });

    test('an unauthenticated report is not attributed to the native user',
        () async {
      PurchaseDiagnostics.reportFailure(
        stage: PurchaseFailureStage.settlement,
        productId: 'STAR100',
        userId: null,
        error: Exception('USER_NOT_AUTHENTICATED'),
      );
      final sent = await sentry.nextSent();

      expect(sent.toString(), isNot(contains('INSTALL-ID')));
      expect(sent.toString(), isNot(contains('other-account')));
      expect(sent['user'], isNull);
    });

    test('ordinary events keep native enrichment unchanged', () async {
      await Sentry.captureMessage('unrelated');
      final sent = await sentry.nextSent();

      expect(sent.toString(), contains('native-secret-breadcrumb'));
      expect((sent['user'] as Map?)?['id'], 'INSTALL-ID');
    });
  });
}

class _FakeNative extends Fake implements SentryNativeBinding {
  @override
  bool get supportsLoadContexts => true;

  @override
  FutureOr<Map<String, dynamic>?> loadContexts() => {
    'user': {'id': 'INSTALL-ID', 'email': 'other-account@example.com'},
    'breadcrumbs': [
      {
        'message': 'native-secret-breadcrumb',
        'category': 'log',
        'level': 'info',
        'timestamp': '2026-09-21T00:00:00.000Z',
      },
    ],
  };
}

class _EnvelopeTransport implements Transport {
  final sent = <Map<String, dynamic>>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    for (final item in envelope.items) {
      if (item.header.type == 'event') {
        final data = await item.dataFactory();
        sent.add(jsonDecode(utf8.decode(data)) as Map<String, dynamic>);
      }
    }
    return envelope.header.eventId;
  }
}

/// Real Sentry client with the real native-contexts integration; only the
/// native binding and the HTTP transport are fakes. `beforeSend` is the
/// production helper that `AppInitializer.initializeSentry` calls.
class _NativeHarness {
  final transport = _EnvelopeTransport();

  Future<void> start() async {
    final options = SentryFlutterOptions()
      ..dsn = 'https://public@o0.ingest.sentry.io/0'
      ..automatedTestMode = true
      ..transport = transport
      ..autoInitializeNativeSdk = false
      ..enableDartSymbolication = false
      ..enableDeduplication = false
      ..beforeSend = PurchaseDiagnostics.sanitizeForSend;
    options.addIntegration(LoadContextsIntegration(_FakeNative()));
    await Sentry.init((o) => o.debug = false, options: options);
  }

  Future<void> stop() => Sentry.close();

  Future<Map<String, dynamic>> nextSent() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (transport.sent.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(transport.sent, hasLength(1));
    return transport.sent.removeAt(0);
  }
}

Session _session(String userId, String email) => Session(
  accessToken: 'access-token',
  tokenType: 'bearer',
  user: User(
    id: userId,
    appMetadata: const {},
    userMetadata: const {'nickname': 'buyer'},
    aud: 'authenticated',
    email: email,
    createdAt: '2026-09-01T00:00:00Z',
  ),
);

class _RecordingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async =>
      envelope.header.eventId;
}

/// A real Sentry hub; only the HTTP transport is replaced, and `beforeSend`
/// records what would have left the device.
class _SentryHarness {
  final _events = StreamController<SentryEvent>.broadcast();
  final _buffer = <SentryEvent>[];

  Future<void> start() async {
    final options = SentryFlutterOptions()
      ..dsn = 'https://public@o0.ingest.sentry.io/0'
      ..automatedTestMode = true
      ..transport = _RecordingTransport()
      ..autoInitializeNativeSdk = false
      ..enableDartSymbolication = false
      ..enableDeduplication = false
      ..beforeSend = (event, hint) {
        _buffer.add(event);
        _events.add(event);
        return event;
      };
    await Sentry.init((o) => o.debug = false, options: options);
  }

  Future<void> stop() => Sentry.close();

  Future<List<SentryEvent>> events(int count) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (_buffer.length < count && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(_buffer, hasLength(count));
    final out = List<SentryEvent>.from(_buffer);
    _buffer.clear();
    return out;
  }

  Future<SentryEvent> nextEvent() async => (await events(1)).single;

  Future<List<SentryEvent>> eventsWithin(Duration window) async {
    await Future<void>.delayed(window);
    final out = List<SentryEvent>.from(_buffer);
    _buffer.clear();
    return out;
  }
}
