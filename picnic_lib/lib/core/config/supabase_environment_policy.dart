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
  }) {
    if (environment == 'prod' || environment == 'test') {
      return const SupabaseEnvironmentPolicyResult(true, 'ok');
    }
    if (environment != 'local' && environment != 'dev') {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'unknown environment',
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

    if (url!.contains(productionProjectRef) ||
        storageUrl!.contains(productionProjectRef)) {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'production Supabase target',
      );
    }

    if (productionConfig != null &&
        _tuple(config) == _tuple(productionConfig)) {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'non-production tuple equals production',
      );
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
        !url.startsWith('https://$stagingProjectRef.supabase.co')) {
      return const SupabaseEnvironmentPolicyResult(
        false,
        'dev environment requires staging Supabase',
      );
    }
    return const SupabaseEnvironmentPolicyResult(true, 'ok');
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  static String _tuple(Map<String, dynamic> config) {
    final supabase = _map(config['supabase']);
    final storage = _map(supabase['storage']);
    return [
      supabase['url'],
      supabase['anon_key'],
      storage['url'],
      storage['anon_key'],
    ].join('|');
  }
}
