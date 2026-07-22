import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/supabase_environment_policy.dart';

Map<String, dynamic> config({
  required String url,
  required String storageUrl,
  String anon = 'anon',
}) {
  return {
    'supabase': {
      'url': url,
      'anon_key': anon,
      'storage': {'url': storageUrl, 'anon_key': anon},
    },
  };
}

void main() {
  test('rejects local config that targets production', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'local',
      config: config(
        url: 'https://xtijtefcycoeqludlngc.supabase.co',
        storageUrl: 'https://api.picnic.fan',
      ),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
    );

    expect(result.isValid, isFalse);
    expect(result.reason, contains('production'));
  });

  test('accepts local endpoints and rejects production tuple equality', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'local',
      config: config(
        url: 'http://127.0.0.1:54321',
        storageUrl: 'http://127.0.0.1:54321/storage/v1',
      ),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
    );

    expect(result.isValid, isTrue);
  });

  test('requires a non-production staging ref for dev', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'dev',
      stagingProjectRef: 'staging-ref',
      config: config(
        url: 'https://staging-ref.supabase.co',
        storageUrl: 'https://staging-ref.supabase.co/storage/v1',
      ),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
    );

    expect(result.isValid, isTrue);
  });
}
