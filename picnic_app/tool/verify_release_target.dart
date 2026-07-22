import 'dart:io';

const defaultDeveloperScriptPaths = <String>[
  'scripts/shorebird-patch.sh',
  'scripts/build_android.sh',
  'test_release.sh',
  'scripts/common_functions.sh',
  'aws/resize_image_lambda/deploy.sh',
  '../scripts/run_tests.sh',
  '../test_signing_local.sh',
  '../test_codemagic_local.sh',
];

List<String> scanDeveloperScripts(Map<String, String> scripts) {
  final findings = <String>[];
  for (final entry in scripts.entries) {
    for (final command in _logicalCommands(entry.value)) {
      if (command == _ambiguousShellMarker) {
        findings.add('${entry.key}: ambiguous shell syntax');
        continue;
      }
      if (command.contains('--no-confirm')) {
        findings.add('${entry.key}: unattended confirmation bypass');
        continue;
      }
      if (RegExp(r'\baws\s+lambda\s+update-function-code\b')
          .hasMatch(command)) {
        findings.add('${entry.key}: direct Lambda mutation');
        continue;
      }
      final supabaseStart = RegExp(r'\bsupabase\b').firstMatch(command)?.start;
      if (supabaseStart != null) {
        final invocation = command.substring(supabaseStart);
        final hasLinkedOperation = RegExp(
          r'\b(db|storage|functions|migration|secrets)\b',
        ).hasMatch(invocation);
        final hasExplicitTarget = RegExp(
          r'(^|\s)--local(\s|$)|(^|\s)--project-ref(?:=|\s+)\S+',
        ).hasMatch(invocation);
        if (hasLinkedOperation && !hasExplicitTarget) {
          findings.add('${entry.key}: linked Supabase command');
        }
      }
    }
  }
  return findings;
}

Iterable<String> _logicalCommands(String source) sync* {
  var pending = '';
  for (final rawLine in source.split('\n')) {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final code = trimmed.split(' #').first.trimRight();
    final continued = code.endsWith(r'\');
    pending += '${continued ? code.substring(0, code.length - 1) : code} ';
    if (!continued) {
      final split = _splitShellUnits(pending.trim());
      if (split.ambiguous) {
        if (_mayContainGuardedCommand(pending)) {
          yield _ambiguousShellMarker;
        }
      } else {
        yield* split.units;
      }
      pending = '';
    }
  }
  if (pending.trim().isNotEmpty) yield _ambiguousShellMarker;
}

bool _mayContainGuardedCommand(String command) =>
    RegExp(r'\bsupabase\b|--no-confirm|\baws\s+lambda\b').hasMatch(command);

const _ambiguousShellMarker = '<ambiguous-shell-syntax>';

({List<String> units, bool ambiguous}) _splitShellUnits(String command) {
  final units = <String>[];
  final buffer = StringBuffer();
  String? quote;
  var escaped = false;
  var ambiguousSyntax = false;

  void flush() {
    final unit = buffer.toString().trim();
    if (unit.isNotEmpty) units.add(unit);
    buffer.clear();
  }

  for (var index = 0; index < command.length; index++) {
    final char = command[index];
    if (escaped) {
      buffer.write(char);
      escaped = false;
      continue;
    }
    if (char == r'\' && quote != "'") {
      buffer.write(char);
      escaped = true;
      continue;
    }
    if (quote != null) {
      buffer.write(char);
      if (char == quote) quote = null;
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
      buffer.write(char);
      continue;
    }
    final next = index + 1 < command.length ? command[index + 1] : '';
    if (char == '`' ||
        (char == r'$' && next == '(') ||
        (char == '&' && next != '&')) {
      ambiguousSyntax = true;
    }
    if (char == ';' || char == '|' || (char == '&' && next == '&')) {
      flush();
      if ((char == '|' || char == '&') && next == char) index++;
      continue;
    }
    buffer.write(char);
  }
  flush();
  return (
    units: units,
    ambiguous: ambiguousSyntax || quote != null || escaped,
  );
}

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
    final scripts = <String, String>{};
    for (final path in defaultDeveloperScriptPaths) {
      final file = File(path);
      if (!file.existsSync()) throw StateError('developer script missing');
      scripts[path] = file.readAsStringSync();
    }
    if (scanDeveloperScripts(scripts).isNotEmpty) {
      stderr.writeln('NO-GO: unsafe developer release command detected');
      exitCode = 1;
      return;
    }
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
