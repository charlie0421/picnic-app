import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/utils/retry_http_client.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef VoteRetryJitter = int Function(int upperExclusive);

class VoteTransactionRepository {
  VoteTransactionRepository(
    this.client, {
    this.delay = Future<void>.delayed,
    VoteRetryJitter? nextJitter,
  }) : nextJitter = nextJitter ?? Random.secure().nextInt;

  final SupabaseClient client;
  final Future<void> Function(Duration) delay;
  final VoteRetryJitter nextJitter;

  static const _retryCaps = [
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
  ];

  /// Waits between reconcile attempts for a vote whose outcome is unknown.
  ///
  /// Deliberately short: each attempt blocks server-side on the per-user wallet
  /// advisory lock until the in-flight transaction finishes, so the wait that
  /// matters is the invoke itself, not this delay.
  static const _reconcileDelays = [Duration(seconds: 1), Duration(seconds: 3)];

  Map<String, dynamic>? _errorEnvelope(Object? details) {
    if (details is Map) return Map<String, dynamic>.from(details);
    if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  bool _isRetryableConflict(FunctionException error) {
    if (error.status == 429) return false;
    final envelope = _errorEnvelope(error.details);
    return envelope?['domain_code'] == 'TX_CONFLICT_RETRYABLE' &&
        envelope?['retryable'] == true;
  }

  /// Whether [error] leaves the vote's server-side outcome undecided.
  ///
  /// A 5xx covers both a genuine server error and the synthetic 500 that
  /// [RetryHttpClient] fabricates when its 30s budget expires — in the latter
  /// case the Edge Function is still running and its transaction can commit
  /// after the app has already given up. A transport failure that never
  /// produced a response is the same situation. Anything the server actually
  /// decided (4xx) is final and must surface to the user unchanged.
  bool _isOutcomeUnknown(Object error) {
    if (error is FunctionException) return error.status >= 500;
    return error is NetworkError ||
        error is http.ClientException ||
        error is TimeoutException ||
        error is SocketException;
  }

  Future<VoteTransactionResultModel> performGeneralVote(
    VoteTransactionRequest request,
  ) async {
    var retries = 0;
    var reconciles = 0;
    while (true) {
      try {
        final response = await client.functions.invoke(
          'voting-v2',
          body: {
            'vote_id': request.voteId,
            'vote_item_id': request.voteItemId,
            'amount': request.amount.toString(),
            'request_id': request.requestId,
          },
        );
        return VoteTransactionResultModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } catch (error, stackTrace) {
        if (error is FunctionException && _isRetryableConflict(error)) {
          if (retries >= _retryCaps.length) rethrow;
          final cap = _retryCaps[retries].inMilliseconds;
          retries += 1;
          await delay(Duration(milliseconds: nextJitter(cap + 1)));
          continue;
        }
        if (!_isOutcomeUnknown(error) ||
            reconciles >= _reconcileDelays.length) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        await delay(_reconcileDelays[reconciles]);
        reconciles += 1;
      }
    }
  }
}
