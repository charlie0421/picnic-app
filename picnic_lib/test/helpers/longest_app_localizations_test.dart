import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'longest_app_localizations.dart';

/// FNV-1a 32 over every arb file in name order — the same computation as
/// scripts/i18n/gen_longest_l10n.py.
int _arbChecksum() {
  final files =
      Directory('lib/l10n').listSync().whereType<File>().where((f) {
        final name = f.uri.pathSegments.last;
        return name.startsWith('app_') && name.endsWith('.arb');
      }).toList()..sort(
        (a, b) => a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last),
      );
  var h = 0x811C9DC5;
  for (final file in files) {
    for (final b in [
      ...file.uri.pathSegments.last.codeUnits,
      ...file.readAsBytesSync(),
    ]) {
      h ^= b;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
  }
  return h;
}

void main() {
  // The longest-string pseudo-locale is generated from the arb files. When
  // they change and it is not regenerated, layout tests quietly measure old
  // strings: new keys answer in English, edited ones keep their old length.
  test('longest_app_localizations.dart matches the arb files', () {
    expect(
      _arbChecksum(),
      longestArbChecksum,
      reason:
          'The arb files changed since the longest-string test locale was '
          'generated. Run: python3 scripts/i18n/gen_longest_l10n.py',
    );
  });
}
