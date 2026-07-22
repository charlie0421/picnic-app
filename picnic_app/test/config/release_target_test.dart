import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify_release_target.dart' as guard;

guard.ReleaseTargetInput validInput() => const guard.ReleaseTargetInput(
      target: 'production',
      ciProvider: 'codemagic',
      event: 'production-release',
      environment: 'prod',
      headSha: 'abc',
      requestedSha: 'abc',
      mainSha: 'abc',
      tagSha: 'abc',
      approvalReference: 'approval-1',
      manifestChecksum: 'checksum',
      expectedManifestChecksum: 'checksum',
      isolationEvidence: 'complete',
      securityEvidence: 'complete',
      checkoutClean: true,
    );

void main() {
  test('accepts only complete exact-SHA protected runner evidence', () {
    expect(guard.verifyReleaseTarget(validInput()), isNull);
  });

  test('rejects local, mismatched SHA, missing evidence, and unknown target',
      () {
    expect(
      guard.verifyReleaseTarget(validInput().copyWith(ciProvider: 'local')),
      isNotNull,
    );
    expect(
      guard.verifyReleaseTarget(validInput().copyWith(mainSha: 'ancestor')),
      isNotNull,
    );
    expect(
      guard.verifyReleaseTarget(validInput().copyWith(securityEvidence: '')),
      isNotNull,
    );
    expect(
      guard.verifyReleaseTarget(validInput().copyWith(target: 'preview')),
      isNotNull,
    );
  });

  test('guard errors never include evidence values', () {
    const sentinel = 'do-not-print-secret';
    final error = guard.verifyReleaseTarget(
      validInput().copyWith(approvalReference: sentinel, headSha: 'wrong'),
    );
    expect(error, isNot(contains(sentinel)));
  });

  test('rejects every required release evidence failure independently', () {
    final invalid = <guard.ReleaseTargetInput>[
      validInput().copyWith(checkoutClean: false),
      validInput().copyWith(requestedSha: 'requested-mismatch'),
      validInput().copyWith(tagSha: 'tag-mismatch'),
      validInput().copyWith(approvalReference: ''),
      validInput().copyWith(expectedManifestChecksum: 'mismatch'),
      validInput().copyWith(isolationEvidence: ''),
      validInput().copyWith(event: 'tag'),
      validInput().copyWith(environment: 'dev'),
    ];
    for (final input in invalid) {
      expect(guard.verifyReleaseTarget(input), isNotNull);
    }
  });

  test('static scan rejects dangerous executable developer script lines', () {
    final findings = guard.scanDeveloperScripts({
      'linked.sh': 'supabase storage ls bucket',
      'confirm.sh': 'shorebird patch ios --no-confirm',
      'lambda.sh': 'aws lambda update-function-code --function-name demo',
    });
    expect(findings, hasLength(3));
  });

  test('static scan ignores comments and accepts explicit Supabase target', () {
    final findings = guard.scanDeveloperScripts({
      'safe.sh': '''
# shorebird patch ios --no-confirm
supabase functions deploy hello --project-ref explicit-ref
supabase storage ls bucket --local
''',
    });
    expect(findings, isEmpty);
  });

  test('static scan scope is explicit and current developer scripts are safe',
      () {
    final scripts = <String, String>{
      for (final path in guard.defaultDeveloperScriptPaths)
        path: File(path).readAsStringSync(),
    };
    expect(scripts.keys, orderedEquals(guard.defaultDeveloperScriptPaths));
    expect(guard.scanDeveloperScripts(scripts), isEmpty);
  });

  test('production CLI fails closed locally with sanitized output', () async {
    const sentinel = 'do-not-print-secret';
    final result = await Process.run(
      'dart',
      ['tool/verify_release_target.dart', '--target=production'],
      workingDirectory: Directory.current.path,
      environment: {
        ...Platform.environment,
        'RELEASE_APPROVAL_REFERENCE': sentinel
      },
    );
    expect(result.exitCode, 1);
    expect(result.stderr, contains('NO-GO:'));
    expect(result.stdout, isNot(contains(sentinel)));
    expect(result.stderr, isNot(contains(sentinel)));
  });
}
