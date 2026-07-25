import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/supabase_environment_policy.dart';

Map<String, dynamic> fixture({
  String url = 'https://staging-ref.supabase.co',
  String key = 'do-not-print-secret',
  String storageUrl = 'https://staging-ref.supabase.co/storage/v1',
}) =>
    {
      'supabase': {
        'url': url,
        'anon_key': key,
        'storage': {'url': storageUrl, 'anon_key': key},
      },
    };

const sandboxPangle = <String, String>{
  'ios_app_id': 'sandbox-ios-app',
  'android_app_id': 'sandbox-android-app',
  'ios_rewarded_video_id': 'sandbox-ios-slot',
  'android_rewarded_video_id': 'sandbox-android-slot',
};

Map<String, dynamic> readConfig(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

const supabaseTupleLabels = <String>[
  'supabase.url',
  'supabase.anon_key',
  'supabase.storage.url',
  'supabase.storage.anon_key',
];

List<String> supabaseTuple(Map<String, dynamic> config) {
  final supabase = config['supabase'] as Map<String, dynamic>;
  final storage = supabase['storage'] as Map<String, dynamic>;
  return <String>[
    supabase['url'] as String,
    supabase['anon_key'] as String,
    storage['url'] as String,
    storage['anon_key'] as String,
  ];
}

/// Names the Supabase tuple entries of [config] that leak production.
///
/// Reports labels only: a finding must never print the endpoint or key it
/// found. Used to hold `config/dev.json` to the same standard as
/// `config/local.json` -- dev.json is the file CI rewrites for staging builds,
/// and the one that previously shipped the production Supabase tuple.
List<String> productionSupabaseLeaks(
  Map<String, dynamic> config,
  Map<String, dynamic> production,
) {
  final tuple = supabaseTuple(config);
  final productionTuple = supabaseTuple(production);
  final leaks = <String>[];
  for (var index = 0; index < tuple.length; index++) {
    if (tuple[index].contains(SupabaseEnvironmentPolicy.productionProjectRef)) {
      leaks.add('${supabaseTupleLabels[index]} names the production project');
    } else if (tuple[index] == productionTuple[index]) {
      leaks.add('${supabaseTupleLabels[index]} equals the production value');
    }
  }
  return leaks;
}

void main() {
  test('rejects missing sandbox boundaries without exposing values', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'dev',
      config: fixture(),
      stagingProjectRef: 'staging-ref',
    );
    expect(result.isValid, isFalse);
    expect(result.reason, contains('PANGLE_ENVIRONMENT'));
    expect(result.reason, isNot(contains('do-not-print-secret')));
  });

  test('accepts isolated dev tuple with explicit sandbox boundaries', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'dev',
      config: fixture(),
      stagingProjectRef: 'staging-ref',
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: sandboxPangle,
      paymentProductNamespace: 'staging.',
    );
    expect(result.isValid, isTrue, reason: result.reason);
  });

  test('requires explicit production SDK modes for prod', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'prod',
      config: fixture(url: 'https://xtijtefcycoeqludlngc.supabase.co'),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: sandboxPangle,
      paymentProductNamespace: 'staging.',
    );
    expect(result.isValid, isFalse);
  });

  test('production host matching rejects substring and query attacks', () {
    for (final url in [
      'https://xtijtefcycoeqludlngc.supabase.co.attacker.test',
      'https://attacker.test/?next=xtijtefcycoeqludlngc.supabase.co',
    ]) {
      final result = SupabaseEnvironmentPolicy.validate(
        environment: 'prod',
        config: fixture(
          url: url,
          storageUrl: 'https://api.picnic.fan/storage/v1',
        ),
        pangleEnvironment: 'prod',
        paymentEnvironment: 'prod',
      );
      expect(result.isValid, isFalse, reason: url);
    }
  });

  test('production accepts only exact application and storage hosts', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'prod',
      config: fixture(
        url: 'https://xtijtefcycoeqludlngc.supabase.co',
        storageUrl: 'https://api.picnic.fan/storage/v1',
      ),
      pangleEnvironment: 'prod',
      paymentEnvironment: 'prod',
    );
    expect(result.isValid, isTrue, reason: result.reason);
  });

  test('production storage host matching rejects substring and query attacks',
      () {
    for (final storageUrl in [
      'https://api.picnic.fan.attacker.test/storage/v1',
      'https://attacker.test/?next=api.picnic.fan',
      'https://xtijtefcycoeqludlngc.supabase.co.attacker.test/storage/v1',
    ]) {
      final result = SupabaseEnvironmentPolicy.validate(
        environment: 'prod',
        config: fixture(
          url: 'https://xtijtefcycoeqludlngc.supabase.co',
          storageUrl: storageUrl,
        ),
        pangleEnvironment: 'prod',
        paymentEnvironment: 'prod',
      );
      expect(result.isValid, isFalse, reason: storageUrl);
    }
  });

  test('local tracked config contains only local Supabase endpoints', () {
    final config = readConfig('config/local.json');
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'local',
      config: config,
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: sandboxPangle,
      paymentProductNamespace: 'local.',
    );
    expect(result.isValid, isTrue, reason: result.reason);
  });

  test('dev tracked config contains no production Supabase endpoint or key',
      () {
    expect(
      productionSupabaseLeaks(
        readConfig('config/dev.json'),
        readConfig('config/prod.json'),
      ),
      isEmpty,
    );
  });

  test('the dev leak check really detects a production Supabase tuple', () {
    // config/dev.json once carried the production tuple verbatim. Without this
    // the assertion above could pass by being unable to recognise one.
    final production = readConfig('config/prod.json');
    final leaks = productionSupabaseLeaks(production, production);
    expect(leaks, hasLength(supabaseTupleLabels.length));
    for (final value in supabaseTuple(production)) {
      expect(leaks.any((leak) => leak.contains(value)), isFalse);
    }
  });

  test('dev config is either awaiting CI secrets or an isolated staging tuple',
      () {
    final config = readConfig('config/dev.json');
    final tuple = supabaseTuple(config);
    // The staging project ref comes from the file under test on purpose: the
    // point is not to re-state the ref but to require that every endpoint in
    // the tuple resolves to that same non-production project.
    final host = tuple.first.isEmpty ? '' : Uri.parse(tuple.first).host;
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'dev',
      config: config,
      productionConfig: readConfig('config/prod.json'),
      stagingProjectRef: host.split('.').first,
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: sandboxPangle,
      paymentProductNamespace: 'staging.',
    );
    if (tuple.any((value) => value.isEmpty)) {
      // Tracked state: the tuple is blank and CI fills it from the staging
      // secrets. A blank tuple must never pass as a shippable dev config.
      expect(result.isValid, isFalse);
      expect(result.reason, contains('missing Supabase tuple'));
    } else {
      expect(result.isValid, isTrue, reason: result.reason);
    }
  });
}
