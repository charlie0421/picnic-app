import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Map<String, dynamic> fixture(String name) =>
      jsonDecode(
            File('test/fixtures/wallet_contracts/$name').readAsStringSync(),
          )
          as Map<String, dynamic>;
  late List<http.Request> requests;
  late SupabaseClient client;
  setUp(() {
    requests = [];
    client = SupabaseClient(
      'http://localhost:54321',
      'anon',
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        Object? body;
        if (path.endsWith('/ad-reward-claim')) {
          final claimRequest = jsonDecode(request.body) as Map<String, dynamic>;
          body = {
            'reference': {
              'type': claimRequest['channel'] == 'ADMOB'
                  ? 'ADMOB_CLAIM'
                  : 'PANGLE_CLAIM',
              'id': '00000000-0000-4000-8000-000000000401',
            },
            'platform': 'ios',
            'signed_token': 'signed',
            'expires_at': '2026-07-21T01:00:00.000Z',
          };
        } else if (path.endsWith('/rpc/list_unacknowledged_ad_rewards')) {
          body = {
            'items': [fixture('ad_reward_pending_v1.json')],
            'total_count': '1',
            'next_cursor': null,
            'snapshot_at': '2026-07-21T00:00:00.000Z',
          };
        } else if (path.endsWith('/rpc/acknowledge_ad_reward')) {
          body = null;
        } else {
          body = fixture('ad_reward_pending_v1.json');
        }
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });
  test('claim uses only canonical edge parameters', () async {
    await AdRewardRepository(client).createPangleClaim(
      platform: 'ios',
      placementId: 'feed',
      clientRequestId: 'request-1',
    );
    expect(requests.single.url.path, endsWith('/functions/v1/ad-reward-claim'));
    expect(jsonDecode(requests.single.body), {
      'platform': 'ios',
      'placement_id': 'feed',
      'client_request_id': 'request-1',
    });
  });
  test('AdMob claim sends its channel and parses ADMOB_CLAIM', () async {
    final claim = await AdRewardRepository(client).createAdmobClaim(
      platform: 'android',
      placementId: 'ca-app-pub-1/2',
      clientRequestId: 'request-admob-1',
    );

    expect(claim.reference.type, AdRewardReferenceType.admobClaim);
    expect(claim.signedToken, 'signed');
    expect(jsonDecode(requests.single.body), {
      'channel': 'ADMOB',
      'platform': 'android',
      'placement_id': 'ca-app-pub-1/2',
      'client_request_id': 'request-admob-1',
    });
  });
  test('status list and ack use exact p_ RPC parameters', () async {
    const reference = AdRewardReference(
      type: AdRewardReferenceType.internalImpression,
      id: '00000000-0000-4000-8000-000000000402',
    );
    final repository = AdRewardRepository(client);
    await repository.getStatus(reference);
    await repository.listUnacknowledged(cursor: 'cursor', limit: 7);
    await repository.acknowledge(reference);
    expect(
      requests.map((r) => r.url.path),
      containsAll([
        '/rest/v1/rpc/get_ad_reward_status',
        '/rest/v1/rpc/list_unacknowledged_ad_rewards',
        '/rest/v1/rpc/acknowledge_ad_reward',
      ]),
    );
    expect(jsonDecode(requests[0].body), {
      'p_reference_type': 'INTERNAL_IMPRESSION',
      'p_reference_id': reference.id,
    });
    expect(jsonDecode(requests[1].body), {'p_cursor': 'cursor', 'p_limit': 7});
    expect(jsonDecode(requests[2].body), {
      'p_reference_type': 'INTERNAL_IMPRESSION',
      'p_reference_id': reference.id,
    });
  });
  test('internal response accepts only legacy and wallet-aware shapes', () {
    final repository = AdRewardRepository(client);
    final legacy = {
      'ok': true,
      'reward_added': 3,
      'impression_id': '00000000-0000-4000-8000-000000000402',
      'new_bonus': 9,
    };
    expect(repository.parseInternalViewResponse(legacy).reward, isNull);
    expect(
      repository.parseInternalViewResponse({
        ...legacy,
        'reward': fixture('ad_reward_granted_v1.json'),
      }).reward,
      isNotNull,
    );
    expect(
      () => repository.parseInternalViewResponse({
        ...legacy,
        'status': 'GRANTED',
      }),
      throwsFormatException,
    );
  });
}
