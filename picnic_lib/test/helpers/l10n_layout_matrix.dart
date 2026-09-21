import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// One language a layout test runs under.
///
/// [longest] is not a real language: it answers every l10n key with the
/// longest shipped translation (see `longest_app_localizations.dart`), so one
/// run stands in for "whatever the longest translation of this string is".
class L10nCase {
  const L10nCase(this.name, this.locale, {this.longest = false});

  final String name;
  final Locale locale;
  final bool longest;

  @override
  String toString() => name;
}

/// ko, en, id and vi are 98.8% of users active in the last 30 days
/// (2026-09-20, `user_profiles.language`); the longest pseudo-locale covers
/// string length for every other language at once.
const l10nLayoutCases = <L10nCase>[
  L10nCase('ko', Locale('ko')),
  L10nCase('en', Locale('en')),
  L10nCase('id', Locale('id')),
  L10nCase('vi', Locale('vi')),
  L10nCase('longest', Locale('en'), longest: true),
];

/// 2.0 is Android's largest font setting on most devices.
const l10nLayoutTextScales = <double>[1.0, 1.3, 2.0];

/// Runs [pump] and returns every `RenderFlex overflowed` it reported.
///
/// The handler is restored in a `finally`, not a teardown: a failing
/// expectation while it is still installed stalls the runner until its
/// ten-minute timeout.
Future<List<String>> collectOverflows(Future<void> Function() pump) async {
  final overflows = <String>[];
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exception.toString();
    if (text.contains('overflowed')) {
      overflows.add(text.split('\n').first);
      return;
    }
    original?.call(details);
  };
  try {
    await pump();
  } finally {
    FlutterError.onError = original;
  }
  return overflows;
}

/// Asserts that the text found by [text] is drawn entirely inside [box].
///
/// This is the assertion an overflow check cannot replace. A `Text` that
/// outgrows a fixed-**height** box throws nothing: it is clipped, or painted
/// over its neighbours, in silence. Only comparing what is drawn with the box
/// it lives in catches that. `getRect` carries transforms, so a label shrunk
/// by a `FittedBox` is judged by the size it is actually drawn at.
///
/// A paragraph that hit `maxLines` is also rejected unless [allowEllipsis]:
/// an ellipsis keeps the geometry tidy by throwing text away.
void expectTextInsideBox(
  WidgetTester tester, {
  required Finder text,
  required Finder box,
  required String reason,
  bool allowEllipsis = false,
  double tolerance = 0.5,
}) {
  expect(text, findsOneWidget, reason: '$reason: text not found');
  expect(box, findsOneWidget, reason: '$reason: box not found');

  final drawn = tester.getRect(text);
  final bounds = tester.getRect(box).inflate(tolerance);
  expect(
    bounds.contains(drawn.topLeft) && bounds.contains(drawn.bottomRight),
    isTrue,
    reason: '$reason: text drawn at $drawn leaves its box $bounds',
  );

  final paragraph = tester.renderObject(
    find.descendant(of: text, matching: find.byType(RichText)).first,
  );
  if (paragraph is! RenderParagraph) return;

  // The rect above is not enough on its own. A paragraph laid out under a
  // tight or capped height reports the *capped* size — a 29px line inside a
  // 20px box says it is 20px tall and paints the rest outside. What the text
  // needs is its intrinsic height at the width it was given.
  final needed = paragraph.getMinIntrinsicHeight(paragraph.size.width);
  expect(
    needed,
    lessThanOrEqualTo(paragraph.size.height + tolerance),
    reason:
        '$reason: the text needs ${needed.toStringAsFixed(1)}px of height but '
        'was laid out in ${paragraph.size.height.toStringAsFixed(1)}px — the '
        'rest is clipped or painted over its neighbours',
  );

  // The same question on the other axis. A single line that is not allowed to
  // wrap (softWrap: false, no maxLines) is clipped at its right edge without
  // ever exceeding a line limit, so neither check above sees it. textSize is
  // the laid-out text before the paragraph clips it to its own size.
  final laidOut = paragraph.textSize;
  expect(
    laidOut.width,
    lessThanOrEqualTo(paragraph.size.width + tolerance),
    reason:
        '$reason: the text is ${laidOut.width.toStringAsFixed(1)}px wide but '
        'its paragraph is ${paragraph.size.width.toStringAsFixed(1)}px — the '
        'rest is cut off at the edge',
  );

  if (!allowEllipsis) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '$reason: the text was cut at its line limit',
    );
  }
}
