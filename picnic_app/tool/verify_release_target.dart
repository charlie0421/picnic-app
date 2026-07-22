import 'dart:io';

class ReleaseTargetInput {
  const ReleaseTargetInput({
    required this.target,
    required this.ciProvider,
    required this.event,
    required this.environment,
    required this.headSha,
    required this.requestedSha,
    required this.mainSha,
    required this.tagSha,
    required this.approvalReference,
    required this.manifestChecksum,
    required this.expectedManifestChecksum,
    required this.isolationEvidence,
    required this.securityEvidence,
    required this.checkoutClean,
  });
  final String target, ciProvider, event, environment;
  final String headSha, requestedSha, mainSha, tagSha;
  final String approvalReference, manifestChecksum, expectedManifestChecksum;
  final String isolationEvidence, securityEvidence;
  final bool checkoutClean;

  ReleaseTargetInput copyWith({
    String? target,
    String? ciProvider,
    String? event,
    String? environment,
    String? headSha,
    String? requestedSha,
    String? mainSha,
    String? tagSha,
    String? approvalReference,
    String? manifestChecksum,
    String? expectedManifestChecksum,
    String? isolationEvidence,
    String? securityEvidence,
    bool? checkoutClean,
  }) =>
      ReleaseTargetInput(
        target: target ?? this.target,
        ciProvider: ciProvider ?? this.ciProvider,
        event: event ?? this.event,
        environment: environment ?? this.environment,
        headSha: headSha ?? this.headSha,
        requestedSha: requestedSha ?? this.requestedSha,
        mainSha: mainSha ?? this.mainSha,
        tagSha: tagSha ?? this.tagSha,
        approvalReference: approvalReference ?? this.approvalReference,
        manifestChecksum: manifestChecksum ?? this.manifestChecksum,
        expectedManifestChecksum:
            expectedManifestChecksum ?? this.expectedManifestChecksum,
        isolationEvidence: isolationEvidence ?? this.isolationEvidence,
        securityEvidence: securityEvidence ?? this.securityEvidence,
        checkoutClean: checkoutClean ?? this.checkoutClean,
      );
}

String? verifyReleaseTarget(ReleaseTargetInput input) {
  if (input.target != 'production') return 'unknown deploy target';
  if (input.ciProvider != 'codemagic' || input.event != 'production-release') {
    return 'protected production runner required';
  }
  if (input.environment != 'prod') return 'production environment required';
  if (!input.checkoutClean) return 'checkout must be clean';
  if ([input.headSha, input.requestedSha, input.mainSha, input.tagSha]
          .any((v) => v.isEmpty) ||
      {input.headSha, input.requestedSha, input.mainSha, input.tagSha}.length !=
          1) {
    return 'exact release SHA mismatch';
  }
  if (input.approvalReference.isEmpty) return 'approval reference missing';
  if (input.manifestChecksum.isEmpty ||
      input.manifestChecksum != input.expectedManifestChecksum) {
    return 'release manifest checksum mismatch';
  }
  if (input.isolationEvidence != 'complete' ||
      input.securityEvidence != 'complete') {
    return 'release evidence incomplete';
  }
  return null;
}

Future<void> main(List<String> args) async {
  final target = _option(args, 'target') ?? '';
  final env = Platform.environment;
  try {
    final head = _git(['rev-parse', 'HEAD']);
    final input = ReleaseTargetInput(
      target: target,
      ciProvider: env['CI_PROVIDER'] ?? '',
      event: env['PRODUCTION_RELEASE_EVENT'] ?? '',
      environment: env['ENVIRONMENT'] ?? '',
      headSha: head,
      requestedSha: env['RELEASE_SHA'] ?? '',
      mainSha: _git(['rev-parse', 'origin/main']),
      tagSha:
          _git(['rev-list', '-n', '1', env['RELEASE_TAG'] ?? '__missing__']),
      approvalReference: env['RELEASE_APPROVAL_REFERENCE'] ?? '',
      manifestChecksum: _sha256(env['RELEASE_MANIFEST'] ?? ''),
      expectedManifestChecksum: env['RELEASE_MANIFEST_SHA256'] ?? '',
      isolationEvidence: env['ENVIRONMENT_ISOLATION_EVIDENCE'] ?? '',
      securityEvidence: env['SECURITY_EVIDENCE'] ?? '',
      checkoutClean: _git(['status', '--porcelain']).isEmpty,
    );
    final error = verifyReleaseTarget(input);
    if (error != null) {
      stderr.writeln('NO-GO: $error');
      exitCode = 1;
      return;
    }
    stdout.writeln('GO: protected production target verified');
  } on Object {
    stderr.writeln('NO-GO: protected production runner required');
    exitCode = 1;
  }
}

String _git(List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: '..');
  if (result.exitCode != 0) throw StateError('git check failed');
  return (result.stdout as String).trim();
}

String _sha256(String path) {
  if (path.isEmpty || !File(path).existsSync()) return '';
  final result = Process.runSync('shasum', ['-a', '256', path]);
  if (result.exitCode != 0) return '';
  return (result.stdout as String).split(RegExp(r'\s+')).first;
}

String? _option(List<String> args, String name) {
  final prefix = '--$name=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
