import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// The capsule card, located by the 120 radius the design brief freezes.
Finder _capsuleCard() => find.descendant(
  of: find.byType(LargePopupWidget),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration! as BoxDecoration).borderRadius ==
            BorderRadius.circular(120.r),
  ),
);

Finder _nearestGestureTarget(Finder child) =>
    find.ancestor(of: child, matching: find.byType(GestureDetector)).first;

void main() {
  final l10n = AppLocalizationsKo();

  setUp(() {
    initTestColors();
  });

  group('LargePopupWidget presentation', () {
    testWidgets('the visible close affordance owns a 48px tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const LargePopupWidget(content: Text('Content'))),
      );
      await tester.pump();

      final closeLabel = find.text(l10n.label_button_close);
      expect(closeLabel, findsOneWidget);
      expect(
        tester.getSize(_nearestGestureTarget(closeLabel)).height,
        greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
      );
    });

    testWidgets(
      'a hidden close affordance keeps the captured 24px trailing strip',
      (tester) async {
        // voting_complete renders this popup inside a capture RepaintBoundary.
        // With no affordance there is nothing to enlarge, and growing the strip
        // would change every shared vote image.
        await tester.pumpWidget(
          buildTestApp(
            const LargePopupWidget(
              content: SizedBox(height: 200, child: Text('Content')),
              showCloseButton: false,
            ),
          ),
        );
        await tester.pump();

        expect(find.text(l10n.label_button_close), findsNothing);
        final popupHeight = tester
            .getSize(find.byType(LargePopupWidget))
            .height;
        final cardHeight = tester.getSize(_capsuleCard()).height;
        expect(popupHeight - cardHeight, 24);
      },
    );

    testWidgets(
      'a placeholder close button keeps the captured 24px trailing strip',
      (tester) async {
        // voting_complete passes `closeButton: _isSaving ? Container() : null`
        // together with `showCloseButton: false`. That placeholder is not an
        // affordance — it is an empty box kept only so the saving branch has a
        // child — so the captured strip must stay at the same 24 the
        // no-close branch already keeps. Growing it to 48 mid-capture changes
        // the shared vote image for exactly the frames that get captured.
        await tester.pumpWidget(
          buildTestApp(
            LargePopupWidget(
              content: const SizedBox(height: 200, child: Text('Content')),
              showCloseButton: false,
              closeButton: Container(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(l10n.label_button_close), findsNothing);
        final popupHeight = tester
            .getSize(find.byType(LargePopupWidget))
            .height;
        final cardHeight = tester.getSize(_capsuleCard()).height;
        expect(
          popupHeight - cardHeight,
          24,
          reason: 'the hidden capture strip must not grow for a placeholder',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a visible custom close button still owns a 48px strip', (
      tester,
    ) async {
      // The placeholder rule must not cost the real custom-close contract:
      // when the popup does show a close affordance, a caller-supplied button
      // keeps the full tap target.
      await tester.pumpWidget(
        buildTestApp(
          LargePopupWidget(
            content: const SizedBox(height: 200, child: Text('Content')),
            closeButton: const Text('CUSTOM'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CUSTOM'), findsOneWidget);
      final popupHeight = tester.getSize(find.byType(LargePopupWidget)).height;
      final cardHeight = tester.getSize(_capsuleCard()).height;
      expect(
        popupHeight - cardHeight,
        greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the title area is never shorter than its own text', (
      tester,
    ) async {
      const longTitle = '한 줄에 담기지 않는 아주 긴 팝업 제목 텍스트 - a very long popup title';

      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            titleWidget: Text(longTitle),
            content: SizedBox(height: 240),
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      final titleArea = find
          .ancestor(of: find.text(longTitle), matching: find.byType(Container))
          .first;
      // A fixed 48 box reports 48 even while it crops the wrapped title, so
      // the growth itself is the observable acceptance here.
      expect(
        tester.getSize(titleArea).height,
        greaterThan(PicnicUi.minimumTapTarget),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the capsule 120 card radius is preserved', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const LargePopupWidget(content: Text('Content'))),
      );
      await tester.pump();

      expect(_capsuleCard(), findsOneWidget);
    });
  });
}
