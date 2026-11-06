// Host tests for the loopback backend of the full App retry QA harness.
//
// No test binding is initialized here on purpose: the widget test binding
// replaces HttpClient with one that answers 400, and these tests need real
// loopback HTTP. Requests go only to 127.0.0.1.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/app_version.dart';
import 'package:picnic_lib/presentation/providers/check_update_helper.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../test_support/full_app_retry/loopback_backend.dart';

void main() {
  late LoopbackBackend backend;
  late HttpClient http;

  setUp(() async {
    backend = await LoopbackBackend.start();
    http = HttpClient();
  });

  tearDown(() async {
    http.close(force: true);
    await backend.close();
  });

  Future<({int status, Object? body})> send(
    String method,
    String pathAndQuery, {
    Map<String, String> headers = const {},
    String? body,
  }) async {
    final request = await http.openUrl(
      method,
      backend.base.resolve(pathAndQuery),
    );
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    final response = await request.close();
    final text = await utf8.decodeStream(response);
    return (status: response.statusCode, body: jsonDecode(text));
  }

  test(
      'the update check reads one version object through the real '
      'PostgREST .single() client', () async {
    final client = SupabaseClient(
      backend.base.toString(),
      'qa-synthetic-local-anon-key',
    );
    addTearDown(client.dispose);

    final row = await client
        .from('version')
        .select()
        .filter('deleted_at', 'is', null)
        .limit(1)
        .single();
    final model = AppVersionModel.fromJson(row);

    expect(model.id, 1);
    for (final platform in ['android', 'ios']) {
      final info = CheckUpdateHelper.getPlatformInfo(model, platform)!;
      expect(info['version'], qaAppVersion);
      expect(info['force_version'], qaAppVersion);
      expect(Uri.parse(info['url'] as String).host, 'example.invalid');
    }
    expect(
      CheckUpdateHelper.determineUpdateStatus(
        currentVersion: qaAppVersion,
        latestVersion: model.android['version'] as String,
        forceVersion: model.android['force_version'] as String,
      ),
      isNot(UpdateStatus.updateRequired),
    );
    expect(backend.requests, ['GET /rest/v1/version']);
    expect(backend.unexpected, isEmpty);
  });

  test(
      'known startup reads get bounded synthetic answers; auth has no '
      'session', () async {
    expect((await send('GET', '/rest/v1/products?select=id&limit=1')).body, []);
    expect(
      (await send('POST', '/functions/v1/track-country', body: '{}')).body,
      {'ip_hash': 'unknown'},
    );
    final user = await send('GET', '/auth/v1/user');
    expect(user.status, 401);
    final token = await send(
      'POST',
      '/auth/v1/token?grant_type=refresh_token',
      body: '{"refresh_token":"qa"}',
    );
    expect(token.status, 401, reason: 'no session is ever granted');
    expect(backend.unexpected, isEmpty);
  });

  test('an unanticipated route is diagnosed, never answered as a success',
      () async {
    final mutation = await send(
      'POST',
      '/rest/v1/votes?select=*',
      body: '{"vote_id":1}',
      headers: {'authorization': 'Bearer qa-must-not-be-logged'},
    );
    final read = await send('GET', '/rest/v1/user_profiles?id=eq.qa-user');

    expect(mutation.status, 404);
    expect(read.status, 404);
    expect(backend.unexpected, [
      'POST /rest/v1/votes',
      'GET /rest/v1/user_profiles',
    ]);
    // Only method and path are kept: no query, header or body value.
    final logged = backend.requests.join('\n');
    expect(logged, isNot(contains('qa-must-not-be-logged')));
    expect(logged, isNot(contains('vote_id')));
    expect(logged, isNot(contains('qa-user')));
  });

  test(
      'a Sentry envelope to the loopback DSN is accepted without being '
      'kept', () async {
    final dsn = Uri.parse(backend.sentryDsn);
    expect(dsn.host, '127.0.0.1');
    expect(dsn.port, backend.base.port);

    final result = await send(
      'POST',
      '/api${dsn.path}/envelope/',
      body: '{"event_id":"qa-envelope-body"}',
    );
    expect(result.status, 200);
    expect(backend.requests, ['POST /api/1/envelope/']);
    expect(backend.unexpected, isEmpty);
  });
}
