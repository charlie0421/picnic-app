import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:picnic_lib/data/repositories/vote_transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const fixturePath = 'test/fixtures/wallet_contracts/vote_result_v3.json';

  Future<
    ({VoteTransactionRepository repository, List<Map<String, dynamic>> calls})
  >
  repositoryWith(
    // Each element is either an [http.Response] to return or an [Object] to
    // throw, so a transport failure that never produced a response can be
    // scripted alongside ordinary replies.
    List<Object> responses, {
    Future<void> Function(Duration)? delay,
    VoteRetryJitter? nextJitter,
  }) async {
    final calls = <Map<String, dynamic>>[];
    var index = 0;
    final client = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      httpClient: MockClient((request) async {
        calls.add(jsonDecode(request.body) as Map<String, dynamic>);
        final next = responses[index++];
        if (next is http.Response) return next;
        throw next;
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    return (
      repository: VoteTransactionRepository(
        client,
        delay: delay ?? (_) async {},
        nextJitter: nextJitter ?? (_) => 0,
      ),
      calls: calls,
    );
  }

  http.Response response(int status, Object body) => http.Response(
    body is String ? body : jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  final request = VoteTransactionRequest(
    voteId: 10,
    voteItemId: 20,
    amount: BigInt.from(30),
    requestId: '00000000-0000-4000-8000-000000000030',
  );

  test('sends stable v3 request and parses canonical result', () async {
    final fixture = await File(fixturePath).readAsString();
    final setup = await repositoryWith([response(200, fixture)]);

    final result = await setup.repository.performGeneralVote(request);

    expect(setup.calls, hasLength(1));
    expect(setup.calls.single, {
      'vote_id': 10,
      'vote_item_id': 20,
      'amount': '30',
      'request_id': request.requestId,
    });
    expect(result.usage.cottonCandy, BigInt.from(5));
    expect(result.usage.bonusStarCandy, BigInt.from(7));
    expect(result.usage.starCandy, BigInt.from(5));
    expect(result.wallet.star, BigInt.from(95));
    expect(result.wallet.bonus, BigInt.from(23));
    expect(result.wallet.cotton, BigInt.zero);
    expect(result.operationId, '00000000-0000-4000-8000-000000000301');
    expect(result.replayed, isFalse);
  });

  for (final detailsAsString in [false, true]) {
    test('retries retryable conflicts three times with one request id '
        '(${detailsAsString ? 'JSON' : 'Map'} details)', () async {
      final fixture = await File(fixturePath).readAsString();
      final envelope = {
        'domain_code': 'TX_CONFLICT_RETRYABLE',
        'retryable': true,
      };
      final errorBody = detailsAsString ? jsonEncode(envelope) : envelope;
      final setup = await repositoryWith([
        response(409, errorBody),
        response(409, errorBody),
        response(409, errorBody),
        response(200, fixture),
      ]);

      await setup.repository.performGeneralVote(request);

      expect(setup.calls, hasLength(4));
      expect(setup.calls.map((call) => call['request_id']).toSet(), {
        request.requestId,
      });
    });
  }

  for (final detailsAsString in [false, true]) {
    for (final testCase in <({int status, Map<String, dynamic> envelope})>[
      (
        status: 429,
        envelope: {'domain_code': 'RATE_LIMITED', 'retryable': true},
      ),
      (
        status: 429,
        envelope: {'domain_code': 'TX_CONFLICT_RETRYABLE', 'retryable': true},
      ),
      (status: 409, envelope: {'domain_code': 'OTHER', 'retryable': true}),
      (
        status: 409,
        envelope: {'domain_code': 'TX_CONFLICT_RETRYABLE', 'retryable': false},
      ),
    ]) {
      test('does not retry ${testCase.status}/${testCase.envelope} '
          '(${detailsAsString ? 'JSON' : 'Map'} details)', () async {
        final body = detailsAsString
            ? jsonEncode(testCase.envelope)
            : testCase.envelope;
        final setup = await repositoryWith([response(testCase.status, body)]);
        await expectLater(
          setup.repository.performGeneralVote(request),
          throwsA(isA<FunctionException>()),
        );
        expect(setup.calls, hasLength(1));
      });
    }
  }

  test('uses bounded jitter caps and stops after the fourth error', () async {
    final envelope = {
      'domain_code': 'TX_CONFLICT_RETRYABLE',
      'retryable': true,
    };
    final delays = <Duration>[];
    final upperBounds = <int>[];
    final setup = await repositoryWith(
      List.generate(4, (_) => response(409, envelope)),
      delay: (duration) async => delays.add(duration),
      nextJitter: (upperExclusive) {
        upperBounds.add(upperExclusive);
        return upperExclusive - 1;
      },
    );

    await expectLater(
      setup.repository.performGeneralVote(request),
      throwsA(isA<FunctionException>()),
    );
    expect(setup.calls, hasLength(4));
    expect(upperBounds, [251, 501, 1001]);
    expect(delays, const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(milliseconds: 1000),
    ]);
  });

  // A vote whose HTTP response is lost is NOT a failed vote: the Edge Function
  // and its transaction keep running and can commit. RetryHttpClient turns its
  // own 30s timeout into a synthetic 500 body, so the client cannot tell "never
  // happened" from "committed, answer lost". Re-invoking with the same
  // request_id is the only way to learn the truth — the server replays the
  // stored settlement instead of voting twice.
  group('unknown outcome reconciliation', () {
    const timeoutBody = {
      'error':
          'Exception: TimeoutException after 0:00:30.000000: '
          'Request timed out after 30 seconds',
    };

    test('re-invokes with the same request id after a lost response', () async {
      final fixture = await File(fixturePath).readAsString();
      final setup = await repositoryWith([
        response(500, timeoutBody),
        response(200, fixture),
      ]);

      final result = await setup.repository.performGeneralVote(request);

      expect(setup.calls, hasLength(2));
      expect(setup.calls.map((call) => call['request_id']).toSet(), {
        request.requestId,
      });
      expect(result.operationId, '00000000-0000-4000-8000-000000000301');
    });

    test('reconciles a transport failure that never got a response', () async {
      final fixture = await File(fixturePath).readAsString();
      final setup = await repositoryWith([
        http.ClientException(
          'Connection closed before full header was received',
        ),
        response(200, fixture),
      ]);

      final result = await setup.repository.performGeneralVote(request);

      expect(setup.calls, hasLength(2));
      expect(result.replayed, isFalse);
    });

    test('gives up after two reconcile attempts', () async {
      final delays = <Duration>[];
      final setup = await repositoryWith(
        List.generate(3, (_) => response(500, timeoutBody)),
        delay: (duration) async => delays.add(duration),
      );

      await expectLater(
        setup.repository.performGeneralVote(request),
        throwsA(isA<FunctionException>()),
      );
      expect(setup.calls, hasLength(3));
      expect(delays, const [Duration(seconds: 1), Duration(seconds: 3)]);
    });

    test('does not reconcile a decided client error', () async {
      final setup = await repositoryWith([
        response(403, {'error': 'VOTE_ENDED'}),
      ]);

      await expectLater(
        setup.repository.performGeneralVote(request),
        throwsA(isA<FunctionException>()),
      );
      expect(setup.calls, hasLength(1));
    });
  });

  // After the deadline the server answers VOTE_ENDED for a request id it has
  // not seen committed, without waiting for an earlier attempt that is still
  // running. That attempt can still commit, so "ended" right after an unknown
  // outcome is not yet the answer.
  group('vote ended after an unknown outcome', () {
    const timeoutBody = {
      'error':
          'Exception: TimeoutException after 0:00:30.000000: '
          'Request timed out after 30 seconds',
    };
    const ended = {'error': 'VOTE_ENDED'};
    const settleDelay = Duration(seconds: 10);

    test(
      'waits for the earlier attempt to settle and reports its success',
      () async {
        final fixture = await File(fixturePath).readAsString();
        final delays = <Duration>[];
        final setup = await repositoryWith([
          response(500, timeoutBody),
          response(403, ended),
          response(200, fixture),
        ], delay: (duration) async => delays.add(duration));

        final result = await setup.repository.performGeneralVote(request);

        expect(setup.calls, hasLength(3));
        expect(setup.calls.map((call) => call['request_id']).toSet(), {
          request.requestId,
        });
        expect(delays, const [Duration(seconds: 1), settleDelay]);
        expect(result.operationId, '00000000-0000-4000-8000-000000000301');
      },
    );

    test(
      'reports ended when the settled attempt says so, asking only once',
      () async {
        final delays = <Duration>[];
        final setup = await repositoryWith([
          http.ClientException(
            'Connection closed before full header was received',
          ),
          response(403, ended),
          response(403, ended),
        ], delay: (duration) async => delays.add(duration));

        await expectLater(
          setup.repository.performGeneralVote(request),
          throwsA(
            isA<FunctionException>().having((e) => e.status, 'status', 403),
          ),
        );
        expect(setup.calls, hasLength(3));
        expect(delays, const [Duration(seconds: 1), settleDelay]);
      },
    );

    test('keeps reconciling when the settled attempt is lost too', () async {
      final fixture = await File(fixturePath).readAsString();
      final delays = <Duration>[];
      final setup = await repositoryWith([
        response(500, timeoutBody),
        response(403, ended),
        response(500, timeoutBody),
        response(200, fixture),
      ], delay: (duration) async => delays.add(duration));

      await setup.repository.performGeneralVote(request);

      expect(setup.calls, hasLength(4));
      expect(delays, const [
        Duration(seconds: 1),
        settleDelay,
        Duration(seconds: 3),
      ]);
    });

    test('does not wait when no earlier attempt can be running', () async {
      final delays = <Duration>[];
      final setup = await repositoryWith([
        response(409, {
          'domain_code': 'TX_CONFLICT_RETRYABLE',
          'retryable': true,
        }),
        response(403, ended),
      ], delay: (duration) async => delays.add(duration));

      await expectLater(
        setup.repository.performGeneralVote(request),
        throwsA(isA<FunctionException>()),
      );
      expect(setup.calls, hasLength(2));
      expect(delays, const [Duration.zero], reason: 'conflict backoff only');
    });

    test('settles after the second reconcile attempt too', () async {
      final fixture = await File(fixturePath).readAsString();
      final delays = <Duration>[];
      final setup = await repositoryWith([
        response(500, timeoutBody),
        response(500, timeoutBody),
        response(403, ended),
        response(200, fixture),
      ], delay: (duration) async => delays.add(duration));

      await setup.repository.performGeneralVote(request);

      expect(setup.calls, hasLength(4));
      expect(delays, const [
        Duration(seconds: 1),
        Duration(seconds: 3),
        settleDelay,
      ]);
    });

    test('the settle step does not extend the reconcile budget', () async {
      final delays = <Duration>[];
      final setup = await repositoryWith([
        response(500, timeoutBody),
        response(403, ended),
        response(500, timeoutBody),
        response(500, timeoutBody),
      ], delay: (duration) async => delays.add(duration));

      await expectLater(
        setup.repository.performGeneralVote(request),
        throwsA(
          isA<FunctionException>().having((e) => e.status, 'status', 500),
        ),
      );
      expect(setup.calls, hasLength(4));
      expect(delays, const [
        Duration(seconds: 1),
        settleDelay,
        Duration(seconds: 3),
      ]);
    });

    test(
      'ended after a lost settled attempt is final without a second wait',
      () async {
        final delays = <Duration>[];
        final setup = await repositoryWith([
          response(500, timeoutBody),
          response(403, ended),
          response(500, timeoutBody),
          response(403, ended),
        ], delay: (duration) async => delays.add(duration));

        await expectLater(
          setup.repository.performGeneralVote(request),
          throwsA(
            isA<FunctionException>().having((e) => e.status, 'status', 403),
          ),
        );
        expect(setup.calls, hasLength(4));
        expect(delays, const [
          Duration(seconds: 1),
          settleDelay,
          Duration(seconds: 3),
        ]);
      },
    );

    // Auth recovery calls performGeneralVote a second time with the same
    // request after it refreshes an expired session. The first call's unknown
    // outcome still counts.
    test(
      'remembers an unknown outcome when the same request is invoked again',
      () async {
        final fixture = await File(fixturePath).readAsString();
        final delays = <Duration>[];
        final setup = await repositoryWith([
          response(500, timeoutBody),
          response(401, {'message': 'Invalid JWT'}),
          response(403, ended),
          response(200, fixture),
        ], delay: (duration) async => delays.add(duration));

        await expectLater(
          setup.repository.performGeneralVote(request),
          throwsA(
            isA<FunctionException>().having((e) => e.status, 'status', 401),
          ),
        );
        final result = await setup.repository.performGeneralVote(request);

        expect(setup.calls, hasLength(4));
        expect(delays, const [Duration(seconds: 1), settleDelay]);
        expect(result.operationId, '00000000-0000-4000-8000-000000000301');
      },
    );

    test(
      'an unknown outcome of one request does not delay another request',
      () async {
        final delays = <Duration>[];
        final setup = await repositoryWith([
          response(500, timeoutBody),
          response(401, {'message': 'Invalid JWT'}),
          response(403, ended),
        ], delay: (duration) async => delays.add(duration));
        final other = VoteTransactionRequest(
          voteId: 10,
          voteItemId: 20,
          amount: BigInt.from(30),
          requestId: '00000000-0000-4000-8000-000000000031',
        );

        await expectLater(
          setup.repository.performGeneralVote(request),
          throwsA(isA<FunctionException>()),
        );
        await expectLater(
          setup.repository.performGeneralVote(other),
          throwsA(
            isA<FunctionException>().having((e) => e.status, 'status', 403),
          ),
        );
        expect(setup.calls, hasLength(3));
        expect(delays, const [Duration(seconds: 1)]);
      },
    );

    test('finds VOTE_ENDED in a plain-text body', () async {
      final fixture = await File(fixturePath).readAsString();
      final setup = await repositoryWith([
        response(500, timeoutBody),
        http.Response(
          'VOTE_ENDED',
          403,
          headers: {'content-type': 'text/plain'},
        ),
        response(200, fixture),
      ]);

      await setup.repository.performGeneralVote(request);

      expect(setup.calls, hasLength(3));
    });

    for (final reason in ['VOTE_DISABLED', 'VOTE_NOT_STARTED']) {
      test('$reason stays final after an unknown outcome', () async {
        final delays = <Duration>[];
        final setup = await repositoryWith([
          response(500, timeoutBody),
          response(403, {'error': reason}),
        ], delay: (duration) async => delays.add(duration));

        await expectLater(
          setup.repository.performGeneralVote(request),
          throwsA(
            isA<FunctionException>().having((e) => e.status, 'status', 403),
          ),
        );
        expect(setup.calls, hasLength(2));
        expect(delays, const [Duration(seconds: 1)]);
      });
    }

    test(
      'other decided rejections stay final after an unknown outcome',
      () async {
        final delays = <Duration>[];
        final setup = await repositoryWith([
          response(500, timeoutBody),
          response(409, {'error': 'WALLET_INSUFFICIENT_BALANCE'}),
        ], delay: (duration) async => delays.add(duration));

        await expectLater(
          setup.repository.performGeneralVote(request),
          throwsA(
            isA<FunctionException>().having((e) => e.status, 'status', 409),
          ),
        );
        expect(setup.calls, hasLength(2));
        expect(delays, const [Duration(seconds: 1)]);
      },
    );
  });
}
