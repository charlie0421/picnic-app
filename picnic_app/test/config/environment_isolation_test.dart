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
    );
    expect(result.isValid, isTrue, reason: result.reason);
  });

  test('requires explicit production SDK modes for prod', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'prod',
      config: fixture(url: 'https://xtijtefcycoeqludlngc.supabase.co'),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
    );
    expect(result.isValid, isFalse);
  });

  test('local tracked config contains only local Supabase endpoints', () {
    final config = jsonDecode(File('config/local.json').readAsStringSync())
        as Map<String, dynamic>;
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'local',
      config: config,
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
    );
    expect(result.isValid, isTrue, reason: result.reason);
  });
}
