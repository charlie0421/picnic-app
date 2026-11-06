// Host tests for the synthetic configuration of the full App retry harness.
//
// The 'Environment.initConfig' test needs the same defines the device run
// uses:
//   flutter test --dart-define=PANGLE_ENVIRONMENT=sandbox \
//     --dart-define=PAYMENT_ENVIRONMENT=sandbox test/full_app_retry/
// Only config/local.json.example is read from disk; no actual config file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/config/supabase_environment_policy.dart';

import '../../test_support/full_app_retry/loopback_backend.dart';

const _definesPresent =
    String.fromEnvironment('PANGLE_ENVIRONMENT') == 'sandbox' &&
        String.fromEnvironment('PAYMENT_ENVIRONMENT') == 'sandbox';

final _base = Uri.parse('http://127.0.0.1:40123');
const _dsn = 'http://qa-synthetic-public-key@127.0.0.1:40123/1';

Set<String> _leafPaths(Object? node, [String prefix = '']) {
  if (node is Map) {
    return {
      for (final entry in node.entries)
        ..._leafPaths(
          entry.value,
          prefix.isEmpty ? '${entry.key}' : '$prefix.${entry.key}',
        ),
    };
  }
  return {prefix};
}

Iterable<String> _stringLeaves(Object? node) sync* {
  if (node is Map) {
    for (final value in node.values) {
      yield* _stringLeaves(value);
    }
  } else if (node is String) {
    yield node;
  }
}

ByteData _key(String key) =>
    ByteData.sublistView(Uint8List.fromList(utf8.encode(key)));

String _text(ByteData? data) => utf8.decode(
      data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final example =
      jsonDecode(File('config/local.json.example').readAsStringSync())
          as Map<String, dynamic>;
  final local = syntheticLocalConfig(_base, sentryDsn: _dsn);
  final production = syntheticProductionConfig();

  test(
      'both synthetic configs have exactly the example key schema with no '
      'placeholder left', () {
    expect(_leafPaths(local), _leafPaths(example));
    expect(_leafPaths(production), _leafPaths(example));
    for (final value in [
      ..._stringLeaves(local),
      ..._stringLeaves(production)
    ]) {
      expect(value, isNot(contains(r'${')), reason: value);
    }
  });

  test('every fetchable product endpoint is loopback', () {
    final supabase = local['supabase'] as Map<String, dynamic>;
    final storage = supabase['storage'] as Map<String, dynamic>;
    final sentry = local['sentry'] as Map<String, dynamic>;
    final app = local['app'] as Map<String, dynamic>;
    final cdn = (local['storage'] as Map<String, dynamic>)['cdn_url'];
    for (final url in <Object?>[
      supabase['url'],
      storage['url'],
      sentry['app_dsn'],
      sentry['web_dsn'],
      cdn,
      app['web_domain'],
    ].cast<String>()) {
      expect(Uri.parse(url).host, '127.0.0.1', reason: url);
    }
    expect(supabase['url'], _base.toString());
    expect(sentry['app_dsn'], _dsn);
    for (final url in <Object?>[
      (production['supabase'] as Map<String, dynamic>)['url'],
      ((production['supabase'] as Map<String, dynamic>)['storage']
          as Map<String, dynamic>)['url'],
    ].cast<String>()) {
      expect(Uri.parse(url).host, '127.0.0.1', reason: url);
    }
  });

  test(
      'the product local policy accepts the synthetic pair with sandbox '
      'SDK environments', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'local',
      config: local,
      productionConfig: production,
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: const {
        'ios_app_id': '',
        'android_app_id': '',
        'ios_rewarded_video_id': '',
        'android_rewarded_video_id': '',
      },
      paymentProductNamespace: '',
    );
    expect(result.reason, 'ok');
    expect(result.isValid, isTrue);
  });

  test(
      'the asset handler serves only the two synthetic configs and forwards '
      'every other asset', () async {
    final assets = SyntheticConfigAssets(local: local, production: production);
    final forwarded = <String>[];
    Future<ByteData?> forward(ByteData? message) async {
      forwarded.add(_text(message));
      return _key('forwarded');
    }

    expect(
      jsonDecode(
          _text(await assets.handle(_key('config/local.json'), forward))),
      local,
    );
    expect(
      jsonDecode(_text(await assets.handle(_key('config/prod.json'), forward))),
      production,
    );
    expect(await assets.handle(_key('config/dev.json'), forward), isNull);
    expect(
      _text(await assets.handle(_key('assets/splash_key.png'), forward)),
      'forwarded',
    );
    expect(forwarded, ['assets/splash_key.png']);
    expect(assets.served, {'config/local.json': 1, 'config/prod.json': 1});
    expect(assets.refused, ['config/dev.json']);
  });

  test(
    'Environment.initConfig("local") loads the synthetic pair through the '
    'asset channel',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final assets =
          SyntheticConfigAssets(local: local, production: production);
      messenger.setMockMessageHandler(
        'flutter/assets',
        (message) => assets.handle(message, (_) async => null),
      );
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );

      await Environment.initConfig('local');

      expect(Environment.supabaseUrl, _base.toString());
      expect(Environment.sentryAppDsn, _dsn);
      expect(Environment.pangleEnvironment, 'sandbox');
      expect(assets.served, {'config/local.json': 1, 'config/prod.json': 1});
    },
    skip: _definesPresent
        ? false
        : 'needs --dart-define=PANGLE_ENVIRONMENT=sandbox '
            '--dart-define=PAYMENT_ENVIRONMENT=sandbox',
  );
}
