import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';

import '../../helpers/l10n_layout_matrix.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

// PICNIC-2738.
//
// Every case here is a localized string inside a box whose size is pinned.
// That is the one shape behind the overflow defects of PICNIC-2694, 2697,
// 2699, 2700 and 2727; text that is free to grow does not overflow. The list
// comes from an audit of the operated screens
// (docs/operations/fixed-box-l10n-audit.html).
//
// A fixed-HEIGHT box is the dangerous kind: text that outgrows it throws
// nothing and is clipped in silence, so these tests compare what is drawn with
// the box it lives in instead of only counting overflow errors.
void main() {
  setUpAll(() async {
    initTestColors();
    await loadTestFonts();
  });

  Future<List<String>> pumpCase(
    WidgetTester tester,
    Widget child, {
    required L10nCase l10n,
    required double textScale,
    Size viewport = const Size(393, 852),
  }) {
    tester.view.physicalSize = viewport * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return collectOverflows(() async {
      await tester.pumpWidget(
        buildTestApp(
          Align(alignment: Alignment.topCenter, child: child),
          locale: l10n.locale,
          longestStrings: l10n.longest,
          textScaler: TextScaler.linear(textScale),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
        ),
      );
      await tester.pump();
    });
  }

  group('CountdownTimer "upcoming" label', () {
    for (final l10n in l10nLayoutCases) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '$l10n ${textScale}x';
        testWidgets(label, (tester) async {
          final overflows = await pumpCase(
            tester,
            CountdownTimer(
              endTime: DateTime.now().toUtc().add(const Duration(days: 3)),
              status: VoteStatus.upcoming,
            ),
            l10n: l10n,
            textScale: textScale,
          );
          expect(overflows, isEmpty, reason: label);

          final text = find.text(
            AppLocalizations.of(
              tester.element(find.byType(CountdownTimer)),
            ).label_vote_upcoming,
          );
          expectTextInsideBox(
            tester,
            text: text,
            box: find
                .ancestor(of: text, matching: find.byType(Container))
                .first,
            reason: label,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  });

  // The digit tiles are pinned at 18x18 and each digit paints inside its own
  // paragraph, which clips itself to the height it is given. From 1.2x the
  // digit's line is taller than 18; from about 1.5x the glyphs visibly lose
  // their bottom, and at 2.0x almost half of each digit is gone. Digits are not
  // translated, so the l10n audit missed them; the preview screenshots found
  // them. Scales go past 2.0 on purpose: the app does not clamp text scaling.
  group('CountdownTimer digit tiles', () {
    for (final textScale in const [1.0, 1.3, 1.5, 2.0, 2.6]) {
      final label = 'digits ${textScale}x';
      testWidgets(label, (tester) async {
        final overflows = await pumpCase(
          tester,
          CountdownTimer(
            endTime: DateTime.now().toUtc().add(
              const Duration(days: 12, hours: 3),
            ),
            status: VoteStatus.active,
          ),
          l10n: l10nLayoutCases.first,
          textScale: textScale,
        );
        expect(overflows, isEmpty, reason: label);

        for (var i = 0; i < 8; i++) {
          final tile = find.byKey(CountdownTimer.digitKey(i));
          expect(
            tester.getSize(tile).width,
            // The keyed box includes the tile's 1px side margins.
            closeTo(
              CountdownTimer.digitSize + CountdownTimer.digitGap * 2,
              0.01,
            ),
            reason:
                '$label tile $i: the width is the row\'s budget on a 320dp '
                'card and must not grow',
          );
          expectTextInsideBox(
            tester,
            text: find.descendant(of: tile, matching: find.byType(Text)),
            box: tile,
            reason: '$label tile $i',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}
