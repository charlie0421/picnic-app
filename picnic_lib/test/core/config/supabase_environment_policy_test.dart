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

  test('accepts an entirely disabled Pangle tuple outside production', () {
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
        anon: 'prod-anon',
      ),
      pangleEnvironment: 'sandbox',
      paymentEnvironment: 'sandbox',
      pangleRuntimeConfig: const {
        'ios_app_id': '',
        'android_app_id': '',
        'ios_rewarded_video_id': '',
        'android_rewarded_video_id': '',
      },
      paymentProductNamespace: 'staging.',
    );
    expect(result.isValid, isTrue, reason: result.reason);
  });

  test('rejects a partially configured Pangle tuple outside production', () {
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
      pangleRuntimeConfig: const {
        'ios_app_id': 'sandbox-ios-app',
        'android_app_id': '',
        'ios_rewarded_video_id': '',
        'android_rewarded_video_id': '',
      },
      paymentProductNamespace: 'staging.',
    );
    expect(result.isValid, isFalse);
    expect(result.reason, contains('partial Pangle sandbox tuple'));
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

  test(
    'allows an empty payment product namespace outside prod '
    '(production SKU + license tester mode)',
    () {
      // 네임스페이스 미설정 dev 빌드는 프로덕션 SKU를 그대로 사용한다.
      // wallet.v1 서버가 정규화된 SKU로 Google을 조회하므로 이 구성이
      // 서버 설계와 정합하며, 과금 없는 테스트는 Play 라이선스 테스터가
      // 보장한다.
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
      expect(result.isValid, isTrue);
    },
  );
}
