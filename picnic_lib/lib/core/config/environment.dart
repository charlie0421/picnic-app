import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:picnic_lib/core/config/supabase_environment_policy.dart';

class Environment {
  static const _pangleEnvironment = String.fromEnvironment(
    'PANGLE_ENVIRONMENT',
  );
  static const _paymentEnvironment = String.fromEnvironment(
    'PAYMENT_ENVIRONMENT',
  );
  static const _paymentProductNamespace = String.fromEnvironment(
    'PICNIC_PAYMENT_PRODUCT_NAMESPACE',
  );

  /// 샌드박스(스테이징) 빌드가 스토어에서 **프로덕션 SKU 를 그대로** 조회하게
  /// 하는 명시적 옵트인. CI 스테이징 워크플로만 켠다.
  ///
  /// 기본(false)에서는 [ProductProviderHelper.validateSandboxProductIds] 가
  /// 네임스페이스 격리를 강제하므로, 로컬/dev 빌드가 실수로 프로덕션
  /// 카탈로그(= 실결제 가능)를 여는 사고를 막는다. 이 플래그는 그 보호를
  /// "스테이징에서 프로덕션 상품으로 테스트한다"는 운영 결정에 한해
  /// 의도적으로 해제한다. 구매 과금은 스토어 계정 설정(Apple sandbox 계정 /
  /// Google Play 라이선스 테스터)이 담당한다.
  static const _sandboxUsesProductionStoreSkus = bool.fromEnvironment(
    'PICNIC_SANDBOX_USES_PRODUCTION_STORE_SKUS',
  );
  static const _pangleRuntimeConfig = <String, String>{
    'ios_app_id': String.fromEnvironment('PICNIC_PANGLE_IOS_APP_ID'),
    'android_app_id': String.fromEnvironment('PICNIC_PANGLE_ANDROID_APP_ID'),
    'ios_rewarded_video_id': String.fromEnvironment(
      'PICNIC_PANGLE_IOS_REWARDED_ID',
    ),
    'android_rewarded_video_id': String.fromEnvironment(
      'PICNIC_PANGLE_ANDROID_REWARDED_ID',
    ),
  };
  static late Map<String, dynamic> _config;
  static late String _currentEnvironment;
  static bool _isInitialized = false;
  static Map<String, dynamic>? _productionPangleConfig;

  static Future<void> initConfig(String env) async {
    _currentEnvironment = env;
    final configString = await rootBundle.loadString('config/$env.json');
    _config = json.decode(configString) as Map<String, dynamic>;
    if (env == 'local' || env == 'dev') {
      final productionString = await rootBundle.loadString('config/prod.json');
      final productionConfig =
          json.decode(productionString) as Map<String, dynamic>;
      _productionPangleConfig = Map<String, dynamic>.from(
        (productionConfig['ads'] as Map<String, dynamic>)['pangle']
            as Map<String, dynamic>,
      );
      final result = SupabaseEnvironmentPolicy.validate(
        environment: env,
        config: _config,
        productionConfig: productionConfig,
        stagingProjectRef: const String.fromEnvironment(
          'PICNIC_STAGING_SUPABASE_PROJECT_REF',
        ),
        pangleEnvironment: _pangleEnvironment,
        paymentEnvironment: _paymentEnvironment,
        pangleRuntimeConfig: _pangleRuntimeConfig,
        paymentProductNamespace: _paymentProductNamespace,
      );
      if (!result.isValid) {
        throw StateError(
          'Supabase environment validation failed: ${result.reason}',
        );
      }
      _config['ads'] ??= <String, dynamic>{};
      (_config['ads'] as Map<String, dynamic>)['pangle'] =
          Map<String, dynamic>.from(_pangleRuntimeConfig);
    }
    if (env == 'prod') {
      final result = SupabaseEnvironmentPolicy.validate(
        environment: env,
        config: _config,
        pangleEnvironment: const String.fromEnvironment('PANGLE_ENVIRONMENT'),
        paymentEnvironment: const String.fromEnvironment('PAYMENT_ENVIRONMENT'),
      );
      if (!result.isValid) {
        throw StateError('Environment validation failed: ${result.reason}');
      }
    }
    _isInitialized = true;
  }

  /// 테스트 전용: config를 직접 주입하여 초기화
  @visibleForTesting
  static void initTestConfig(
    Map<String, dynamic> config, {
    String environment = 'test',
  }) {
    _config = config;
    _currentEnvironment = environment;
    _isInitialized = true;
  }

  /// Environment가 초기화되었는지 확인
  static bool get isInitialized => _isInitialized;

  static String get currentEnvironment => _currentEnvironment;
  static String get pangleEnvironment =>
      _currentEnvironment == 'prod' ? 'prod' : 'sandbox';
  static String get paymentEnvironment =>
      _currentEnvironment == 'prod' ? 'production' : 'sandbox';
  static String get paymentProductNamespace => _currentEnvironment == 'prod'
      ? inappAppNamePrefix
      : _paymentProductNamespace;

  /// 프로덕션에서는 항상 false — 이 플래그는 샌드박스 전용 의미만 갖는다.
  static bool get sandboxUsesProductionStoreSkus =>
      _currentEnvironment != 'prod' && _sandboxUsesProductionStoreSkus;

  // 중첩된 설정값을 가져오는 헬퍼 메서드
  static dynamic _getValue(List<String> path) {
    dynamic current = _config;
    for (final key in path) {
      if (current is! Map<String, dynamic> || !current.containsKey(key)) {
        throw Exception('설정 경로를 찾을 수 없습니다: ${path.join(".")}');
      }
      current = current[key];
    }
    return current;
  }

  // 설정값을 가져오되, 없으면 기본값 사용
  static dynamic _getValueOrDefault(List<String> path, dynamic defaultValue) {
    try {
      return _getValue(path);
    } catch (e) {
      return defaultValue;
    }
  }

  // 로그 관련 설정
  static Level get logLevel {
    final levelName = _getValueOrDefault([
      'logging',
      'level',
    ], 'info').toString().toLowerCase();
    switch (levelName) {
      case 'off':
        return Level.off;
      case 'verbose':
        return Level.trace;
      case 'debug':
        return Level.debug;
      case 'info':
        return Level.info;
      case 'warning':
        return Level.warning;
      case 'error':
        return Level.error;
      case 'all':
        return Level.all;
      default:
        return Level.info;
    }
  }

  static int get imageLoadWarningThreshold =>
      _getValueOrDefault([
            'logging',
            'image_load_warning_threshold_seconds',
          ], 10)
          as int;

  static int get imageLoadErrorThreshold =>
      _getValueOrDefault(['logging', 'image_load_error_threshold_seconds'], 20)
          as int;

  // Supabase 관련 설정
  static String get supabaseUrl => _getValue(['supabase', 'url']) as String;
  static String get supabaseAnonKey =>
      _getValue(['supabase', 'anon_key']) as String;
  static String get supabaseStorageUrl =>
      _getValue(['supabase', 'storage', 'url']) as String;
  static String get supabaseStorageAnonKey =>
      _getValue(['supabase', 'storage', 'anon_key']) as String;

  // Auth 관련 설정
  static String get appleClientId =>
      _getValue(['auth', 'apple', 'client_id']) as String;
  static String get appleRedirectUri =>
      _getValue(['auth', 'apple', 'redirect_uri']) as String;
  static String get googleClientId =>
      _getValue(['auth', 'google', 'client_id']) as String;
  static String get googleServerClientId =>
      _getValue(['auth', 'google', 'server_client_id']) as String;
  static String get kakaoNativeAppKey =>
      _getValue(['auth', 'kakao', 'native_app_key']) as String;
  static String get kakaoJavascriptKey =>
      _getValue(['auth', 'kakao', 'javascript_key']) as String;
  // Sentry 관련 설정
  static bool get enableSentry => _getValue(['sentry', 'enable']) as bool;
  static String get sentryAppDsn => _getValue(['sentry', 'app_dsn']) as String;
  static String get sentryWebDsn => _getValue(['sentry', 'web_dsn']) as String;
  static double get sentryTraceSampleRate =>
      _getValue(['sentry', 'sample_rates', 'trace']) as double;
  static double get sentryProfileSampleRate =>
      _getValue(['sentry', 'sample_rates', 'profile']) as double;
  static double get sentrySessionSampleRate =>
      _getValue(['sentry', 'sample_rates', 'session']) as double;
  static double get sentryErrorSampleRate =>
      _getValue(['sentry', 'sample_rates', 'error']) as double;

  // Storage 관련 설정
  static String get cdnUrl => _getValue(['storage', 'cdn_url']) as String;
  static String get awsAccessKey =>
      _getValue(['storage', 'aws', 'access_key_id']) as String;
  static String get awsSecretKey =>
      _getValue(['storage', 'aws', 'secret_access_key']) as String;
  static String get awsRegion =>
      _getValue(['storage', 'aws', 'region']) as String;
  static String get awsBucket =>
      _getValue(['storage', 'aws', 's3_bucket']) as String;
  static String get awsS3Url =>
      _getValue(['storage', 'aws', 's3_bucket_url']) as String;

  // API 키 관련 설정
  static String get youtubeApiKey =>
      _getValue(['api_keys', 'youtube']) as String;
  static String get deepLApiKey => _getValue(['api_keys', 'deepl']) as String;
  static String get branchKey => _getValue(['api_keys', 'branch']) as String;

  // 앱 관련 설정
  static String get webDomain => _getValue(['app', 'web_domain']) as String;
  static String get downloadLink =>
      _getValue(['app', 'download_link']) as String;
  static String get appLinkPrefix =>
      _getValue(['app', 'app_link_prefix']) as String;
  static String get inappAppNamePrefix =>
      _getValue(['app', 'inapp_appname_prefix']) as String;

  // 테마 관련 설정
  static Color get primaryColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'primary']) as String));
  static Color get secondaryColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'secondary']) as String));
  static Color get subColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'sub']) as String));
  static Color get pointColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'point']) as String));
  static Color get point900Color =>
      Color(int.parse(_getValue(['theme', 'colors', 'point_900']) as String));

  // 광고 관련 설정
  static String? get tapjoyAndroidSdkKey =>
      _getValue(['ads', 'tapjoy', 'android_sdk_key']) as String;
  static String? get tapjoyIosSdkKey =>
      _getValue(['ads', 'tapjoy', 'ios_sdk_key']) as String;

  // Pincrux 관련 설정
  static String? get pincruxAndroidAppKey {
    try {
      return _getValue(['ads', 'pincrux', 'android_app_key']) as String;
    } catch (e) {
      return null;
    }
  }

  static String? get pincruxIosAppKey {
    try {
      return _getValue(['ads', 'pincrux', 'ios_app_key']) as String;
    } catch (e) {
      return null;
    }
  }

  // 다음 값들은 prod 환경에만 있고 나머지 환경에는 없을 수 있으므로 예외 처리 추가

  // Pangle 관련 설정
  static String? get pangleIosAppId {
    try {
      return _getValue(['ads', 'pangle', 'ios_app_id']) as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'app_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get pangleAndroidAppId {
    try {
      return _getValue(['ads', 'pangle', 'android_app_id']) as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'app_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get pangleIosRewardedVideoId {
    try {
      return _getValue(['ads', 'pangle', 'ios_rewarded_video_id']) as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'rewarded_video_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get pangleAndroidRewardedVideoId {
    try {
      return _getValue(['ads', 'pangle', 'android_rewarded_video_id'])
          as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'rewarded_video_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get productionPangleIosAppId =>
      _productionPangleConfig?['ios_app_id'] as String?;
  static String? get productionPangleAndroidAppId =>
      _productionPangleConfig?['android_app_id'] as String?;
  static String? get productionPangleIosRewardedVideoId =>
      _productionPangleConfig?['ios_rewarded_video_id'] as String?;
  static String? get productionPangleAndroidRewardedVideoId =>
      _productionPangleConfig?['android_rewarded_video_id'] as String?;

  static String? get admobIosRewardedVideoId {
    try {
      return _getValue(['ads', 'admob', 'ios_rewarded_video_id']) as String;
    } catch (e) {
      return null;
    }
  }

  static String? get admobAndroidRewardedVideoId {
    try {
      return _getValue(['ads', 'admob', 'android_rewarded_video_id']) as String;
    } catch (e) {
      return null;
    }
  }
}
