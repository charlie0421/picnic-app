import 'dart:convert';
import 'dart:io';

import 'package:picnic_lib/core/config/supabase_environment_policy.dart';

Future<void> main(List<String> args) async {
  final environment = _option(args, 'environment');
  if (environment == null ||
      !const {'local', 'dev', 'prod'}.contains(environment)) {
    stderr.writeln('NO-GO: invalid --environment');
    exitCode = 1;
    return;
  }
  try {
    final config = _load('config/$environment.json');
    final production = environment == 'prod' ? null : _load('config/prod.json');
    if (environment == 'dev') {
      _applyPublicDevConfig(config, Platform.environment);
    }
    final result = SupabaseEnvironmentPolicy.validate(
      environment: environment,
      config: config,
      productionConfig: production,
      stagingProjectRef:
          Platform.environment['PICNIC_STAGING_SUPABASE_PROJECT_REF'],
      pangleEnvironment: Platform.environment['PANGLE_ENVIRONMENT'],
      paymentEnvironment: Platform.environment['PAYMENT_ENVIRONMENT'],
    );
    if (!result.isValid) {
      stderr.writeln(
          'NO-GO: non-production environment is not isolated (${result.reason})');
      exitCode = 1;
      return;
    }
    stdout.writeln('GO: environment isolation verified for $environment');
  } on Object {
    stderr.writeln('NO-GO: unable to validate config source/key');
    exitCode = 1;
  }
}

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void _applyPublicDevConfig(
    Map<String, dynamic> config, Map<String, String> env) {
  final url = env['PICNIC_STAGING_SUPABASE_URL'];
  final key = env['PICNIC_STAGING_SUPABASE_ANON_KEY'];
  if (url == null || key == null) return;
  final supabase = config['supabase'] as Map<String, dynamic>;
  final storage = supabase['storage'] as Map<String, dynamic>;
  supabase['url'] = url;
  supabase['anon_key'] = key;
  storage['url'] = url;
  storage['anon_key'] = key;
}

String? _option(List<String> args, String name) {
  final prefix = '--$name=';
  return args
      .where((arg) => arg.startsWith(prefix))
      .firstOrNull
      ?.substring(prefix.length);
}
