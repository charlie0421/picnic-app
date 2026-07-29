import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify_release_target.dart' as guard;

guard.ReleaseTargetInput validInput() => const guard.ReleaseTargetInput(
      target: 'production',
      ciProvider: 'codemagic',
      event: 'production-release',
      environment: 'prod',
      headSha: 'abc',
      tagSha: 'abc',
      releaseCommitOnMain: true,
      checkoutClean: true,
    );

void main() {
  test('accepts a clean main-contained tag build on the protected runner', () {
    expect(guard.verifyReleaseTarget(validInput()), isNull);
  });

  test('rejects local runner, off-main commit, and unknown target', () {
    expect(
      guard.verifyReleaseTarget(validInput().copyWith(ciProvider: 'local')),
      isNotNull,
    );
    expect(
      guard.verifyReleaseTarget(
        validInput().copyWith(releaseCommitOnMain: false),
      ),
      isNotNull,
    );
    expect(
      guard.verifyReleaseTarget(validInput().copyWith(target: 'preview')),
      isNotNull,
    );
  });

  test('a tag stays releasable after main advances past it', () {
    // The release commit is pinned by headSha/tagSha. Requiring it to also
    // equal `git rev-parse origin/main` made every tag expire the instant the
    // next commit landed on main, which is every tag in this repo.
    expect(guard.verifyReleaseTarget(validInput()), isNull);
  });

  test('an off-main commit is never releasable, however well attested', () {
    final error = guard.verifyReleaseTarget(
      validInput().copyWith(releaseCommitOnMain: false),
    );
    expect(error, isNotNull);
    expect(error, contains('main'));
  });

  test('ancestry alone cannot substitute for the exact tagged commit', () {
    // Being on main must not make an arbitrary commit releasable: what is
    // checked out and what the tag names still have to be the same commit.
    for (final input in <guard.ReleaseTargetInput>[
      validInput().copyWith(headSha: 'other'),
      validInput().copyWith(tagSha: 'other'),
      validInput().copyWith(tagSha: ''),
    ]) {
      expect(guard.verifyReleaseTarget(input), isNotNull);
    }
  });

  test('guard errors never include input values', () {
    const sentinel = 'do-not-print-secret';
    final error = guard.verifyReleaseTarget(
      validInput().copyWith(tagSha: sentinel, headSha: 'wrong'),
    );
    expect(error, isNotNull);
    expect(error, isNot(contains(sentinel)));
  });

  test('rejects every accident-protection failure independently', () {
    final invalid = <guard.ReleaseTargetInput>[
      validInput().copyWith(checkoutClean: false),
      validInput().copyWith(tagSha: 'tag-mismatch'),
      validInput().copyWith(event: 'tag'),
      validInput().copyWith(environment: 'dev'),
    ];
    for (final input in invalid) {
      expect(guard.verifyReleaseTarget(input), isNotNull);
    }
  });

  test('tag name comes from CM_TAG with RELEASE_TAG as fallback', () {
    expect(
      guard.resolveReleaseTagName(
        {'CM_TAG': 'picnic-v1.3.0', 'RELEASE_TAG': 'picnic-v0.0.1'},
      ),
      'picnic-v1.3.0',
    );
    expect(
      guard.resolveReleaseTagName({'RELEASE_TAG': 'picnic-v1.3.0'}),
      'picnic-v1.3.0',
    );
    expect(
      guard.resolveReleaseTagName(
        {'CM_TAG': '', 'RELEASE_TAG': 'picnic-v1.3.0'},
      ),
      'picnic-v1.3.0',
    );
    expect(guard.resolveReleaseTagName({}), isEmpty);
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

  test('static scan does not borrow a target flag from another command', () {
    final findings = guard.scanDeveloperScripts({
      'bypass.sh': 'supabase db push; echo --project-ref harmless',
    });
    expect(findings, hasLength(1));
  });

  test('static scan finds linked commands after Supabase global options', () {
    final findings = guard.scanDeveloperScripts({
      'global.sh': 'supabase --workdir /tmp db push',
    });
    expect(findings, hasLength(1));
  });

  test('static scan accepts same-invocation safe targets with global options',
      () {
    final findings = guard.scanDeveloperScripts({
      'safe.sh': '''
supabase --workdir /tmp db push --local
supabase --debug functions deploy hello --project-ref approved-staging-ref
''',
    });
    expect(findings, isEmpty);
  });

  test('static scan fails closed on ambiguous guarded shell constructs', () {
    final findings = guard.scanDeveloperScripts({
      'ambiguous.sh': r'supabase $(echo db) push --local',
    });
    expect(findings, isNotEmpty);
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
        // Blanked explicitly: this test asserts the CLI fails closed, so it
        // must not depend on the ambient environment. Inheriting a real
        // production release environment would otherwise make it fail on the
        // one build that matters.
        'CI_PROVIDER': '',
        'PRODUCTION_RELEASE_EVENT': '',
        'ENVIRONMENT': '',
        'RELEASE_TAG': '',
        // A sentinel tag name: whatever the guard prints, it must be the
        // static NO-GO reason, never an environment value.
        'CM_TAG': sentinel,
      },
    );
    expect(result.exitCode, 1);
    expect(result.stderr, contains('NO-GO:'));
    expect(result.stdout, isNot(contains(sentinel)));
    expect(result.stderr, isNot(contains(sentinel)));
  });
}
