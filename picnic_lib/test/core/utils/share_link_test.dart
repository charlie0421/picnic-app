import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';

/// PICNIC-APP-5N6: a failed Branch link request threw out of every share
/// handler, so the share stopped with no message to the user.
///
/// [createShareLink] must give the share a usable link or null (the caller
/// then uses the configured download link), and must report each failure
/// with closed values only.
void main() {
  const title = 'vote title 1234';
  const longUrl = 'https://applink.example.com/vote/detail/1234';
  const branchKey = 'key_live_secret_value';

  setUpAll(() {
    Environment.initTestConfig({
      'api_keys': {'branch': branchKey},
    });
  });

  late List<BranchLinkFailure> reports;

  setUp(() => reports = <BranchLinkFailure>[]);

  void record(BranchLinkFailure failure, StackTrace _) => reports.add(failure);

  Future<String?> run(
    http.Client Function() client, {
    Duration timeout = const Duration(seconds: 5),
  }) => http.runWithClient(
    () => createShareLink(title, longUrl, timeout: timeout, onFailure: record),
    client,
  );

  test('returns the Branch link and reports nothing on success', () async {
    final link = await run(
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({'url': 'https://picnic.app.link/abc'}),
          200,
        ),
      ),
    );

    expect(link, 'https://picnic.app.link/abc');
    expect(reports, isEmpty);
  });

  test('returns null and reports the status for a non-200 response', () async {
    final link = await run(
      () => MockClient((_) async => http.Response('{"error":"x"}', 500)),
    );

    expect(link, isNull);
    expect(reports.single.kind, BranchLinkFailureKind.httpStatus);
    expect(reports.single.statusCode, 500);
  });

  test('returns null and reports a transport failure', () async {
    final link = await run(
      () => MockClient(
        (_) async => throw http.ClientException('Connection reset'),
      ),
    );

    expect(link, isNull);
    expect(reports.single.kind, BranchLinkFailureKind.transport);
  });

  test('returns null and reports a socket failure', () async {
    final link = await run(
      () => MockClient((_) async => throw const SocketException('offline')),
    );

    expect(link, isNull);
    expect(reports.single.kind, BranchLinkFailureKind.transport);
  });

  test('returns null and reports a TLS handshake failure', () async {
    // IOClient wraps SocketException and HttpException in ClientException,
    // but a HandshakeException (captive portal, TLS interception) reaches
    // the caller as it is.
    final link = await run(
      () => MockClient(
        (_) async => throw const HandshakeException('handshake failed'),
      ),
    );

    expect(link, isNull);
    expect(reports.single.kind, BranchLinkFailureKind.transport);
  });

  test('sends only Branch answers to Sentry, not user network failures', () {
    // The app's beforeSend drops ClientException, SocketException,
    // HandshakeException and wrapped timeouts as user network noise. A share
    // link failure follows the same rule: the user's network is not an app
    // or Branch integration defect.
    expect(BranchLinkFailure.status(500).isReportable, isTrue);
    expect(
      const BranchLinkFailure(
        BranchLinkFailureKind.invalidResponse,
      ).isReportable,
      isTrue,
    );
    expect(
      const BranchLinkFailure(BranchLinkFailureKind.transport).isReportable,
      isFalse,
    );
    expect(
      const BranchLinkFailure(BranchLinkFailureKind.timeout).isReportable,
      isFalse,
    );
  });

  test(
    'returns null and reports a timeout when Branch does not answer',
    () async {
      final never = Completer<http.Response>();
      final link = await run(
        () => MockClient((_) => never.future),
        timeout: const Duration(milliseconds: 50),
      );

      expect(link, isNull);
      expect(reports.single.kind, BranchLinkFailureKind.timeout);
    },
  );

  for (final body in <String>[
    'not json',
    '{}',
    '{"url": 7}',
    '{"url": ""}',
    '{"url": "javascript:alert(1)"}',
    '[]',
  ]) {
    test('returns null and reports an invalid 200 body: $body', () async {
      final link = await run(
        () => MockClient((_) async => http.Response(body, 200)),
      );

      expect(link, isNull);
      expect(reports.single.kind, BranchLinkFailureKind.invalidResponse);
    });
  }

  test('rethrows an error that is not a Branch request failure', () async {
    expect(
      run(() => MockClient((_) async => throw StateError('defect'))),
      throwsStateError,
    );
  });

  test('a report holds no title, destination, key or response text', () async {
    await run(
      () => MockClient(
        (_) async => http.Response('{"error":"$title $longUrl"}', 503),
      ),
    );

    final text = '${reports.single}';
    expect(text, isNot(contains(title)));
    expect(text, isNot(contains(longUrl)));
    expect(text, isNot(contains(branchKey)));
    expect(text, isNot(contains('error')));
  });

  test('a report never fails the share when the reporter throws', () async {
    final link = await http.runWithClient(
      () => createShareLink(
        title,
        longUrl,
        onFailure: (_, _) => throw StateError('reporter broke'),
      ),
      () => MockClient((_) async => http.Response('', 500)),
    );

    expect(link, isNull);
  });

  test('share handlers do not call createBranchLink directly', () {
    // createBranchLink throws on every failure. A share handler that awaits
    // it while it builds the shareToSocial arguments loses the share and
    // leaks the error (5N6). Share handlers must use createShareLink.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('core/utils/deeplink.dart')) continue;
      if (entity.readAsStringSync().contains('createBranchLink(')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
