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
}
