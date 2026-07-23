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
    'ads': {
      'pangle': {
        'ios_app_id': 'prod-ios-app',
        'android_app_id': 'prod-android-app',
        'ios_rewarded_video_id': 'prod-ios-slot',
        'android_rewarded_video_id': 'prod-android-slot',
      },
    },
  };
}

const sandboxPangle = <String, String>{
  'ios_app_id': 'sandbox-ios-app',
  'android_app_id': 'sandbox-android-app',
  'ios_rewarded_video_id': 'sandbox-ios-slot',
  'android_rewarded_video_id': 'sandbox-android-slot',
};

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
      pangleRuntimeConfig: sandboxPangle,
      paymentProductNamespace: 'staging.',
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
      pangleRuntimeConfig: sandboxPangle,
      paymentProductNamespace: 'staging.',
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
      pangleRuntimeConfig: sandboxPangle,
      paymentProductNamespace: 'staging.',
    );

    expect(result.isValid, isTrue);
  });

  test('rejects missing non-production SDK tuple before initialization', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'dev',
      stagingProjectRef: 'staging-ref',
      config: config(
        url: 'https://staging-ref.supabase.co',
        storageUrl: 'https://staging-ref.supabase.co/storage/v1',
      ),
      productionConfig: config(
        url: 'https://xtijtefcycoeqludlngc.supabase.co',
        storageUrl: 'https://api.picnic.fan',
      ),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
    );
    expect(result.isValid, isFalse);
    expect(result.reason, contains('Pangle sandbox tuple'));
  });

  test('rejects any Pangle production tuple item reused by dev', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'dev',
      stagingProjectRef: 'staging-ref',
      config: config(
        url: 'https://staging-ref.supabase.co',
        storageUrl: 'https://staging-ref.supabase.co/storage/v1',
      ),
      productionConfig: config(
        url: 'https://xtijtefcycoeqludlngc.supabase.co',
        storageUrl: 'https://api.picnic.fan',
      ),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: {...sandboxPangle, 'ios_app_id': 'prod-ios-app'},
      paymentProductNamespace: 'staging.',
    );
    expect(result.isValid, isFalse);
    expect(result.reason, contains('production Pangle'));
  });

  test('requires a separate payment product namespace outside prod', () {
    final result = SupabaseEnvironmentPolicy.validate(
      environment: 'dev',
      stagingProjectRef: 'staging-ref',
      config: config(
        url: 'https://staging-ref.supabase.co',
        storageUrl: 'https://staging-ref.supabase.co/storage/v1',
      ),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: sandboxPangle,
    );
    expect(result.isValid, isFalse);
    expect(result.reason, contains('payment product namespace'));
  });
}
