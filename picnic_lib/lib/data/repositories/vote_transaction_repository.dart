import 'dart:convert';
import 'dart:math';

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

  Future<VoteTransactionResultModel> performGeneralVote(
    VoteTransactionRequest request,
  ) async {
    var retries = 0;
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
      } on FunctionException catch (error) {
        if (!_isRetryableConflict(error) || retries >= _retryCaps.length) {
          rethrow;
        }
        final cap = _retryCaps[retries].inMilliseconds;
        retries += 1;
        await delay(Duration(milliseconds: nextJitter(cap + 1)));
      }
    }
  }
}
