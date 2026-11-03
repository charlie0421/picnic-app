import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level guard for the debug-only AdMob test device policy.
///
/// Every `MobileAds.instance.initialize()` call site under `lib/` must apply
/// `AdMobTestDevicePolicy` earlier in the same method body, so a debug build
/// with `ADMOB_TEST_DEVICE_IDS` registers its test devices before the SDK
/// initializes — on every reachable path, including the non-personalized one.
///
/// The check is textual on purpose: the call sites live in private methods
/// that need ATT/UMP platform channels, so they cannot be exercised directly.
void main() {
  const initCall = 'MobileAds.instance.initialize(';
  const policyMarker = 'AdMobTestDevicePolicy.';
  final methodDeclaration = RegExp(r'\n\s*(static\s+)?Future<[^>]*>\s+\w+\(');

  Iterable<File> dartFilesUnder(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  test('every MobileAds.instance.initialize() call site applies '
      'AdMobTestDevicePolicy earlier in the same method', () {
    final uncovered = <String>[];
    var callSites = 0;

    for (final file in dartFilesUnder('lib')) {
      final source = file.readAsStringSync();
      var from = 0;
      while (true) {
        final at = source.indexOf(initCall, from);
        if (at < 0) break;
        from = at + initCall.length;

        // Skip doc/line comments that merely mention the call.
        final lineStart = source.lastIndexOf('\n', at) + 1;
        if (source.substring(lineStart, at).trimLeft().startsWith('//')) {
          continue;
        }
        callSites++;

        final methodStart = source.lastIndexOf(methodDeclaration, at);
        final bodyBeforeCall = source.substring(
          methodStart < 0 ? 0 : methodStart,
          at,
        );
        if (!bodyBeforeCall.contains(policyMarker)) {
          final line = '\n'.allMatches(source.substring(0, at)).length + 1;
          uncovered.add('${file.path}:$line');
        }
      }
    }

    expect(
      callSites,
      greaterThan(0),
      reason: 'expected at least one $initCall call site under lib/',
    );
    expect(
      uncovered,
      isEmpty,
      reason:
          'call sites that initialize MobileAds without applying '
          'AdMobTestDevicePolicy first: $uncovered',
    );
  });
}
