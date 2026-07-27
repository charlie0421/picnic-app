import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

FunctionException _functionException({required int status, Object? details}) {
  return FunctionException(
    status: status,
    details: details,
    reasonPhrase: status == 401 ? 'Unauthorized' : 'Error',
  );
}

void main() {
  group('isRecoverableEdgeAuthFailure', () {
    for (final code in const [
      'UNAUTHORIZED',
      'UNAUTHORIZED_LEGACY_JWT',
      'UNAUTHORIZED_ASYMMETRIC_JWT',
    ]) {
      test('accepts 401 FunctionException with $code details code', () {
        final error = _functionException(status: 401, details: {'code': code});

        expect(isRecoverableEdgeAuthFailure(error), isTrue);
      });
    }

    test('accepts 401 FunctionException with unstructured details', () {
      final error = _functionException(
        status: 401,
        details: 'gateway rejected the request',
      );

      expect(isRecoverableEdgeAuthFailure(error), isTrue);
    });

    test('rejects non-401 FunctionException even with an auth detail code', () {
      final error = _functionException(
        status: 403,
        details: {'code': 'UNAUTHORIZED'},
      );

      expect(isRecoverableEdgeAuthFailure(error), isFalse);
    });

    test('rejects non-FunctionException', () {
      expect(isRecoverableEdgeAuthFailure(Exception('401')), isFalse);
    });
  });

  group('invokeWithAuthRecovery', () {
    test(
      'refreshes once and retries once after the first auth failure',
      () async {
        var invokeCalls = 0;
        var refreshCalls = 0;

        final result = await invokeWithAuthRecovery<String>(
          invoke: () async {
            invokeCalls += 1;
            if (invokeCalls == 1) {
              throw _functionException(status: 401);
            }
            return 'ok';
          },
          refresh: () async {
            refreshCalls += 1;
            return true;
          },
        );

        expect(result, 'ok');
        expect(invokeCalls, 2);
        expect(refreshCalls, 1);
      },
    );

    test('wraps a false refresh result and does not retry invoke', () async {
      var invokeCalls = 0;
      var refreshCalls = 0;

      await expectLater(
        invokeWithAuthRecovery<void>(
          invoke: () async {
            invokeCalls += 1;
            throw _functionException(status: 401);
          },
          refresh: () async {
            refreshCalls += 1;
            return false;
          },
        ),
        throwsA(
          isA<EdgeAuthRecoveryException>().having(
            (error) => error.reason,
            'reason',
            EdgeAuthRecoveryFailureReason.refreshFailed,
          ),
        ),
      );
      expect(invokeCalls, 1);
      expect(refreshCalls, 1);
    });

    test('wraps a thrown refresh error without exposing it in text', () async {
      final cause = Exception('secret token value');

      await expectLater(
        invokeWithAuthRecovery<void>(
          invoke: () async => throw _functionException(status: 401),
          refresh: () async => throw cause,
        ),
        throwsA(
          isA<EdgeAuthRecoveryException>()
              .having(
                (error) => error.reason,
                'reason',
                EdgeAuthRecoveryFailureReason.refreshFailed,
              )
              .having((error) => error.cause, 'cause', same(cause))
              .having(
                (error) => error.toString(),
                'safe text',
                'EdgeAuthRecoveryException(refreshFailed)',
              ),
        ),
      );
    });

    test('wraps a second auth failure without another refresh', () async {
      var invokeCalls = 0;
      var refreshCalls = 0;

      await expectLater(
        invokeWithAuthRecovery<void>(
          invoke: () async {
            invokeCalls += 1;
            throw _functionException(status: 401);
          },
          refresh: () async {
            refreshCalls += 1;
            return true;
          },
        ),
        throwsA(
          isA<EdgeAuthRecoveryException>().having(
            (error) => error.reason,
            'reason',
            EdgeAuthRecoveryFailureReason.retryUnauthorized,
          ),
        ),
      );
      expect(invokeCalls, 2);
      expect(refreshCalls, 1);
    });

    test('propagates the first non-auth error without refreshing', () async {
      final error = StateError('request failed');
      var invokeCalls = 0;
      var refreshCalls = 0;

      await expectLater(
        invokeWithAuthRecovery<void>(
          invoke: () async {
            invokeCalls += 1;
            throw error;
          },
          refresh: () async {
            refreshCalls += 1;
            return true;
          },
        ),
        throwsA(same(error)),
      );
      expect(invokeCalls, 1);
      expect(refreshCalls, 0);
    });

    test('propagates a non-auth retry error unchanged', () async {
      final retryError = StateError('retry failed');
      var invokeCalls = 0;
      var refreshCalls = 0;

      await expectLater(
        invokeWithAuthRecovery<void>(
          invoke: () async {
            invokeCalls += 1;
            if (invokeCalls == 1) {
              throw _functionException(status: 401);
            }
            throw retryError;
          },
          refresh: () async {
            refreshCalls += 1;
            return true;
          },
        ),
        throwsA(same(retryError)),
      );
      expect(invokeCalls, 2);
      expect(refreshCalls, 1);
    });
  });
}
