class SupabaseEnvironmentPolicyResult {
  const SupabaseEnvironmentPolicyResult(this.isValid, this.reason);

  final bool isValid;
  final String reason;
}

class SupabaseEnvironmentPolicy {
  static const productionProjectRef = 'xtijtefcycoeqludlngc';

  static SupabaseEnvironmentPolicyResult validate({
    required String environment,
    required Map<String, dynamic> config,
    Map<String, dynamic>? productionConfig,
    String? stagingProjectRef,
    String? pangleEnvironment,
    String? paymentEnvironment,
  }) {
    if (environment == 'test') {
      return const SupabaseEnvironmentPolicyResult(true, 'ok');
    }
    if (environment != 'local' &&
        environment != 'dev' &&
        environment != 'prod') {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'unknown environment',
      );
    }

    final expectedSdkEnvironment = environment == 'prod' ? 'prod' : 'sandbox';
    if (pangleEnvironment != expectedSdkEnvironment) {
      return SupabaseEnvironmentPolicyResult(
        false,
        'PANGLE_ENVIRONMENT must be $expectedSdkEnvironment',
      );
    }
    if (paymentEnvironment != expectedSdkEnvironment) {
      return SupabaseEnvironmentPolicyResult(
        false,
        'PAYMENT_ENVIRONMENT must be $expectedSdkEnvironment',
      );
    }

    final supabase = _map(config['supabase']);
    final url = supabase['url'] as String?;
    final anonKey = supabase['anon_key'] as String?;
    final storage = _map(supabase['storage']);
    final storageUrl = storage['url'] as String?;
    final storageAnonKey = storage['anon_key'] as String?;
    bool missing(String? value) => value == null || value.isEmpty;

    if (missing(url) ||
        missing(anonKey) ||
        missing(storageUrl) ||
        missing(storageAnonKey)) {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'missing Supabase tuple',
      );
    }

    if (environment == 'prod') {
      if (!url!.contains(productionProjectRef) ||
          !(storageUrl!.contains(productionProjectRef) ||
              Uri.tryParse(storageUrl)?.host == 'api.picnic.fan')) {
        return const SupabaseEnvironmentPolicyResult(
          false,
          'supabase.url must use the production project ref',
        );
      }
      return const SupabaseEnvironmentPolicyResult(true, 'ok');
    }

    if (url!.contains(productionProjectRef) ||
        storageUrl!.contains(productionProjectRef)) {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'production Supabase target',
      );
    }

    if (productionConfig != null) {
      final values = _tupleValues(config);
      final productionValues = _tupleValues(productionConfig);
      for (var index = 0; index < values.length; index++) {
        if (values[index] == productionValues[index]) {
          return const SupabaseEnvironmentPolicyResult(
            false,
            'non-production Supabase item equals production',
          );
        }
      }
    }

    if (environment == 'local') {
      final host = Uri.tryParse(url)?.host;
      if (host != '127.0.0.1' && host != 'localhost') {
        return const SupabaseEnvironmentPolicyResult(
          false,
          'local environment requires local Supabase',
        );
      }
      return const SupabaseEnvironmentPolicyResult(true, 'ok');
    }

    if (stagingProjectRef == null ||
        stagingProjectRef.isEmpty ||
        stagingProjectRef == productionProjectRef ||
        Uri.tryParse(url)?.host != '$stagingProjectRef.supabase.co' ||
        Uri.tryParse(storageUrl)?.host != '$stagingProjectRef.supabase.co') {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'dev environment requires staging Supabase',
      );
    }
    return const SupabaseEnvironmentPolicyResult(true, 'ok');
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  static List<Object?> _tupleValues(Map<String, dynamic> config) {
    final supabase = _map(config['supabase']);
    final storage = _map(supabase['storage']);
    return <Object?>[
      supabase['url'],
      supabase['anon_key'],
      storage['url'],
      storage['anon_key'],
    ];
  }
}
