// Validates the environment artifact that this build will actually ship.
//
// Scope. This tool owns exactly one question: does the `config/<env>.json`
// file *as it exists on disk right now* describe an isolated environment?
// It deliberately does not reconstruct, patch or second-guess that file --
// an earlier revision overlaid the staging Supabase tuple from the
// environment before validating, which meant the generated file's real
// contents were never checked and a verbatim copy of production passed.
//
// The complementary question -- do the build commands in codemagic.yaml pass
// the defines that belong to this target? -- is owned by
// test_codemagic_environment_isolation.py, which resolves the DEPLOY_TARGET
// branch of every release invocation and pins its defines (including the env
// prefix used to invoke *this* tool) to the required tuple. Neither guard can
// be satisfied by restating its own inputs.

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
    // Read-only: whatever the build step generated is what gets validated.
    final config = _load('config/$environment.json');
    final production = environment == 'prod' ? null : _load('config/prod.json');
    final result = SupabaseEnvironmentPolicy.validate(
      environment: environment,
      config: config,
      productionConfig: production,
      stagingProjectRef:
          Platform.environment['PICNIC_STAGING_SUPABASE_PROJECT_REF'],
      pangleEnvironment: Platform.environment['PANGLE_ENVIRONMENT'],
      paymentEnvironment: Platform.environment['PAYMENT_ENVIRONMENT'],
      pangleRuntimeConfig: {
        'ios_app_id': Platform.environment['PICNIC_PANGLE_IOS_APP_ID'] ?? '',
        'android_app_id':
            Platform.environment['PICNIC_PANGLE_ANDROID_APP_ID'] ?? '',
        'ios_rewarded_video_id':
            Platform.environment['PICNIC_PANGLE_IOS_REWARDED_ID'] ?? '',
        'android_rewarded_video_id':
            Platform.environment['PICNIC_PANGLE_ANDROID_REWARDED_ID'] ?? '',
      },
      paymentProductNamespace:
          Platform.environment['PICNIC_PAYMENT_PRODUCT_NAMESPACE'],
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

String? _option(List<String> args, String name) {
  final prefix = '--$name=';
  return args
      .where((arg) => arg.startsWith(prefix))
      .firstOrNull
      ?.substring(prefix.length);
}
