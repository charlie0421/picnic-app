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
}
