// Host tests for the synthetic vote list loopback of the iOS notification
// delivery QA app (scripts/qa/run_notification_delivery_ios.py).
//
// No test binding is initialized here on purpose: the widget test binding
// replaces HttpClient with one that answers 400, and these tests need real
// loopback HTTP. Requests go only to 127.0.0.1.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../test_support/notification_delivery/vote_list_loopback.dart';

final _now = DateTime.utc(2026, 11, 5, 12);

Uri _voteUri(Map<String, String> query) =>
    Uri(path: '/rest/v1/vote', queryParameters: query);

const _active = {
  'visible_at': 'lt.now()',
  'start_at': 'lt.now()',
  'stop_at': 'gt.now()',
  'order': 'stop_at.asc.nullslast',
  'offset': '0',
  'limit': '10',
};

const _ended = {
  'stop_at': 'lt.now()',
  'order': 'stop_at.desc.nullslast',
  'offset': '0',
  'limit': '10',
};

const _upcoming = {
  'visible_at': 'lt.now()',
  'start_at': 'gt.now()',
  'order': 'start_at.asc.nullslast',
  'offset': '0',
  'limit': '10',
};

List<int> _ids(Object body) =>
    [for (final row in body as List) (row as Map)['id'] as int];

void main() {
  group('resolveVoteListRequest', () {
    test('active without an area returns both active votes, stop_at first',
        () {
      final reply = resolveVoteListRequest('GET', _voteUri(_active), now: _now);
      expect(reply.status, 200);
      expect(_ids(reply.body), [910001, 910002]);
      expect(reply.area, 'all');
      expect(reply.voteStatus, 'active');
    });

    test('the PICNIC area with ended status returns only the ended kpop vote',
        () {
      final reply = resolveVoteListRequest(
        'GET',
        _voteUri({..._ended, 'areas': 'cs.{"kpop"}'}),
        now: _now,
      );
      expect(reply.status, 200);
      expect(_ids(reply.body), [910003]);
      expect(reply.area, 'kpop');
      expect(reply.voteStatus, 'end');
    });

    test('ended without an area is ordered by stop_at descending', () {
      final reply = resolveVoteListRequest('GET', _voteUri(_ended), now: _now);
      expect(_ids(reply.body), [910004, 910003]);
    });

    test('upcoming returns only the vote that has not started', () {
      final reply =
          resolveVoteListRequest('GET', _voteUri(_upcoming), now: _now);
      expect(_ids(reply.body), [910005]);
      expect(reply.voteStatus, 'upcoming');
    });

    test('rows carry the selected columns, not the internal areas column', () {
      final reply = resolveVoteListRequest('GET', _voteUri(_active), now: _now);
      final first = (reply.body as List).first as Map<String, dynamic>;
      expect(first.containsKey('areas'), isFalse);
      expect(first['stop_at'], '2026-11-08T12:00:00.000Z');
      expect((first['vote_item'] as List).length, 2);
    });

    test('a filter combination that is not a known status is refused', () {
      final reply = resolveVoteListRequest(
        'GET',
        _voteUri({'stop_at': 'gt.now()', 'offset': '0', 'limit': '10'}),
        now: _now,
      );
      expect(reply.status, 400);
    });

    test('a repeated query key is refused', () {
      final uri = Uri.parse(
        '/rest/v1/vote?stop_at=lt.now()&stop_at=gt.now()&offset=0&limit=10',
      );
      expect(resolveVoteListRequest('GET', uri, now: _now).status, 400);
    });

    test('another path or method is 404', () {
      expect(
        resolveVoteListRequest('GET', Uri(path: '/rest/v1/vote_item'),
                now: _now)
            .status,
        404,
      );
      expect(
        resolveVoteListRequest('POST', _voteUri(_active), now: _now).status,
        404,
      );
    });

    test('offset and limit select one page', () {
      final reply = resolveVoteListRequest(
        'GET',
        _voteUri({..._active, 'offset': '1', 'limit': '1'}),
        now: _now,
      );
      expect(_ids(reply.body), [910002]);
    });
  });

  group('product vote list provider over the loopback', () {
    late VoteListLoopback backend;
    late ProviderContainer container;

    setUp(() async {
      backend = await VoteListLoopback.start();
      Environment.initTestConfig(syntheticQaConfig(backend.base));
      testSupabaseClient = SupabaseClient(
        backend.base.toString(),
        qaSyntheticAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      container = ProviderContainer(retry: (_, __) => null);
    });

    tearDown(() async {
      container.dispose();
      await testSupabaseClient?.dispose();
      testSupabaseClient = null;
      await backend.close();
    });

    Future<List<int>> load(String area, VoteStatus status) async {
      final votes = await container.read(
        asyncVoteListProvider(
          1,
          10,
          'id',
          'DESC',
          area,
          status: status,
          category: VoteCategory.all,
        ).future,
      );
      return [for (final vote in votes) vote.id];
    }

    test('ALL / active parses the synthetic active rows into VoteModel',
        () async {
      final votes = await container.read(
        asyncVoteListProvider(
          1,
          10,
          'id',
          'DESC',
          'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );
      expect([for (final vote in votes) vote.id], [910001, 910002]);
      expect(votes.first.title['en'], 'QA Active PICNIC');
      expect(votes.first.isEnded, isFalse);
      expect(votes.first.isUpcoming, isFalse);
      expect(
        [for (final item in votes.first.voteItem!) item.id],
        [9100012, 9100011],
        reason: 'vote_total descending',
      );
      expect(votes.first.voteItem!.first.artist?.name['en'], 'QA Artist B');
      expect(backend.unexpected, isEmpty);
      expect(backend.requests, [
        {
          'method': 'GET',
          'path': '/rest/v1/vote',
          'statusCode': 200,
          'area': 'all',
          'voteStatus': 'active',
          'ids': [910001, 910002],
        },
      ]);
    });

    test('PICNIC / ended returns only the ended kpop vote', () async {
      expect(await load('kpop', VoteStatus.end), [910003]);
      expect(backend.requests.single['area'], 'kpop');
      expect(backend.requests.single['voteStatus'], 'end');
      expect(backend.unexpected, isEmpty);
    });

    test('upcoming returns the not yet started vote', () async {
      expect(await load('all', VoteStatus.upcoming), [910005]);
    });
  });

  group('loopback HTTP', () {
    late VoteListLoopback backend;
    late HttpClient http;

    setUp(() async {
      backend = await VoteListLoopback.start();
      http = HttpClient();
    });

    tearDown(() async {
      http.close(force: true);
      await backend.close();
    });

    test('binds to 127.0.0.1 only', () {
      expect(backend.base.host, '127.0.0.1');
    });

    test('an unknown path is 404 and recorded as unexpected', () async {
      final request =
          await http.getUrl(backend.base.replace(path: '/rest/v1/user_profiles'));
      final response = await request.close();
      final body = jsonDecode(await response.transform(utf8.decoder).join());
      expect(response.statusCode, 404);
      expect((body as Map)['code'], 'QA_UNANTICIPATED');
      expect(backend.unexpected, ['GET /rest/v1/user_profiles']);
      expect(backend.requests.single['statusCode'], 404);
    });
  });

  test('the synthetic config points every fetchable endpoint at loopback', () {
    final config = syntheticQaConfig(Uri.parse('http://127.0.0.1:4321'));
    final supabase = config['supabase'] as Map<String, dynamic>;
    expect(supabase['url'], 'http://127.0.0.1:4321');
    expect((supabase['storage'] as Map)['url'], 'http://127.0.0.1:4321');
    expect((config['storage'] as Map)['cdn_url'], 'http://127.0.0.1:4321/qa-cdn');
    expect(supabase['anon_key'], qaSyntheticAnonKey);
  });
}
