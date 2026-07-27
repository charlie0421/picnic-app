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
    List<http.Response> responses, {
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
        return responses[index++];
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
}
