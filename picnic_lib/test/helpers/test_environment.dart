import 'package:flutter/material.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/ui/style.dart';

/// 테스트 환경에서 AppColors와 Environment를 초기화합니다.
/// Environment._config가 필요한 동적 색상(primary500 등)을 테스트용 기본값으로 설정합니다.
void initTestColors() {
  AppColors.primary500 = const Color(0xFF6200EE);
  AppColors.secondary500 = const Color(0xFF03DAC6);
  AppColors.sub500 = const Color(0xFFBB86FC);
  AppColors.point500 = const Color(0xFFFF0266);
  AppColors.point900 = const Color(0xFFCF6679);

  // Environment가 초기화되지 않은 경우 테스트용 기본값으로 초기화
  if (!Environment.isInitialized) {
    Environment.initTestConfig({
      'storage': {
        'cdn_url': 'https://test-cdn.example.com',
        'aws': {
          'access_key_id': 'test',
          'secret_access_key': 'test',
          'region': 'ap-northeast-2',
          's3_bucket': 'test',
          's3_bucket_url': 'https://test-s3.example.com',
        },
      },
      'logging': {
        'level': 'off',
        'image_load_warning_threshold_seconds': 10,
        'image_load_error_threshold_seconds': 20,
      },
      'app': {
        'web_domain': 'test.example.com',
        'download_link': 'https://test.example.com',
        'app_link_prefix': 'https://test.example.com',
        'inapp_appname_prefix': 'test',
      },
      // Supabase 접속 정보. 실제로 붙지는 않지만(mock_supabase 가 가로챈다),
      // 일부 위젯이 빌드 중에 Environment.supabaseUrl 등을 읽는다.
      'supabase': {
        'url': 'https://test.supabase.co',
        'anon_key': 'test-anon-key',
        'storage': {
          'url': 'https://test-storage.supabase.co',
          'anon_key': 'test-storage-anon-key',
        },
      },
      // 광고 SDK 키. 값 자체는 쓰이지 않지만, 무료충전소 계열 위젯이 빌드 중에
      // Environment.tapjoy*/pincrux* 를 읽기 때문에 경로가 없으면
      // "설정 경로를 찾을 수 없습니다" 로 죽는다.
      'ads': {
        'tapjoy': {
          'android_sdk_key': 'test-tapjoy-android',
          'ios_sdk_key': 'test-tapjoy-ios',
        },
        'pincrux': {
          'android_app_key': 'test-pincrux-android',
          'ios_app_key': 'test-pincrux-ios',
        },
      },
    });
  }
}
