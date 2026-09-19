import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

// PICNIC-2727.
//
// Both buttons are pinned to one size (minimumSize == maximumSize, 120.w x 32)
// and the label plus icon inside was laid out at its natural width, so a
// localized label longer than the box ran out of it: 58px for Spanish and
// 128px for Bengali on an 851-wide window at 2.0x. Every caller in the app
// uses the default size and the same two localized strings, so this widget on
// its own stands in for all six screens that show it.
void main() {
  setUpAll(initTestColors);

  // Every locale with an arb file.
  const locales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('th'),
    Locale('my'),
    Locale('ja'),
    Locale('id'),
    Locale('vi'),
    Locale('fil'),
    Locale('es'),
    Locale('bn'),
    Locale('bn', 'BD'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];
  // The width changes what 120.w is; 851 is where the reported overflow lived.
  const widths = <double>[280, 393, 851];
  const textScales = <double>[1.0, 1.3, 2.0];

  Future<List<String>> pumpAt(
    WidgetTester tester, {
    required Locale locale,
    required double width,
    required double textScale,
  }) async {
    tester.view.physicalSize = Size(width * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <String>[];
    final original = FlutterError.onError;
    // Restore the handler as soon as the frame is laid out, not in a
    // teardown. If an expectation fails while this handler is still
    // installed, the runner stalls until its 10-minute timeout.
    FlutterError.onError = (details) {
      final text = details.exception.toString();
      if (text.contains('overflowed')) {
        overflows.add(text.split('\n').first);
        return;
      }
      if (text.contains('Unable to load asset')) return;
      original?.call(details);
    };
    try {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Center(
              child: ShareSection(
                saveButtonText: AppLocalizations.of(context).save,
                shareButtonText: AppLocalizations.of(context).share,
                onSave: () {},
                onShare: () {},
              ),
            ),
          ),
          locale: locale,
          textScaler: TextScaler.linear(textScale),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
        ),
      );
      await tester.pump();
    } finally {
      FlutterError.onError = original;
    }
    return overflows;
  }

  group('PICNIC-2727 save and share fit their buttons', () {
    for (final locale in locales) {
      final tag = locale.countryCode == null
          ? locale.languageCode
          : '${locale.languageCode}_${locale.countryCode}';
      for (final width in widths) {
        for (final textScale in textScales) {
          final label = '$tag ${width.toInt()}w ${textScale}x';
          testWidgets('$label has no overflow', (tester) async {
            final overflows = await pumpAt(
              tester,
              locale: locale,
              width: width,
              textScale: textScale,
            );
            expect(
              overflows,
              isEmpty,
              reason: '$label: the label ran out of its fixed-size button',
            );
          });
        }
      }
    }
  });

  group('PICNIC-2727 labels that already fit are left alone', () {
    // The fix may shrink a label that does not fit; it must not touch one
    // that does. Korean at 1.0x fits, so every label has to draw at exactly
    // its laid-out size — a transformed rect equal to the layout size means
    // no scale was applied, i.e. the six screens look as they did.
    for (final width in widths) {
      testWidgets('ko ${width.toInt()}w 1.0x draws labels unscaled', (
        tester,
      ) async {
        await pumpAt(
          tester,
          locale: const Locale('ko'),
          width: width,
          textScale: 1.0,
        );
        final labels = find.descendant(
          of: find.byType(ShareSection),
          matching: find.byType(Text),
        );
        expect(labels, findsNWidgets(2));
        for (final element in labels.evaluate()) {
          final finder = find.byElementPredicate((e) => e == element);
          expect(
            tester.getRect(finder).size.width,
            closeTo(tester.getSize(finder).width, 0.01),
            reason: 'a label that fits must not be scaled',
          );
        }
      });
    }
  });
}
