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

  group('LargePopupWidget top-right close (PICNIC-2695)', () {
    Future<void> showPopupRoute(WidgetTester tester, Widget popup) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showDialog<void>(context: context, builder: (_) => popup),
              child: const Text('open-popup'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open-popup'));
      await tester.pumpAndSettle();
      expect(find.byType(LargePopupWidget), findsOneWidget);
    }

    testWidgets('the top close occupies exactly 48px above the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            content: SizedBox(height: 200, child: Text('Content')),
            closeButtonPlacement: LargePopupCloseButtonPlacement.topRight,
          ),
        ),
      );
      await tester.pump();

      final popup = tester.getRect(find.byType(LargePopupWidget));
      final card = tester.getRect(_capsuleCard());
      expect(
        popup.height - card.height,
        closeTo(kLargePopupTopCloseStripHeight, 0.01),
        reason: 'the top mode must not also keep a trailing strip',
      );

      final close = tester.getRect(find.byKey(kLargePopupTopCloseKey));
      expect(close.height, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
      expect(close.width, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
      expect(
        close.bottom,
        lessThanOrEqualTo(card.top + 0.5),
        reason: 'the X must not overlap the rounded card',
      );
      expect(close.right, lessThanOrEqualTo(card.right + 0.5));
      expect(
        close.center.dx,
        greaterThan(card.center.dx),
        reason: 'the X belongs on the trailing side',
      );
      // The default bottom "닫기 + X" row is the other mode, not this one.
      expect(find.text(l10n.label_button_close), findsNothing);
    });

    testWidgets('the top close carries the localized close semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            content: SizedBox(height: 200, child: Text('Content')),
            closeButtonPlacement: LargePopupCloseButtonPlacement.topRight,
          ),
        ),
      );
      await tester.pump();

      final label = MaterialLocalizations.of(
        tester.element(find.byType(LargePopupWidget)),
      ).closeButtonLabel;
      expect(find.bySemanticsLabel(label), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a disabled top close keeps its geometry and cannot dismiss', (
      tester,
    ) async {
      var closes = 0;
      await showPopupRoute(
        tester,
        LargePopupWidget(
          content: const SizedBox(height: 200, child: Text('Content')),
          closeButtonPlacement: LargePopupCloseButtonPlacement.topRight,
          closeButtonEnabled: false,
          onClose: () => closes++,
        ),
      );

      final before = tester.getRect(find.byType(LargePopupWidget));
      final closeBefore = tester.getRect(find.byKey(kLargePopupTopCloseKey));

      await tester.tap(find.byKey(kLargePopupTopCloseKey), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(closes, 0);
      expect(
        find.byType(LargePopupWidget),
        findsOneWidget,
        reason: 'a disabled close must not dismiss the route',
      );
      expect(tester.getRect(find.byType(LargePopupWidget)), before);
      expect(tester.getRect(find.byKey(kLargePopupTopCloseKey)), closeBefore);
    });

    testWidgets('the empty half of the top strip is not a close target', (
      tester,
    ) async {
      // Measured off-route on purpose: inside a dialog the modal barrier would
      // answer for the empty area and hide whether the strip itself does.
      var closes = 0;
      await tester.pumpWidget(
        buildTestApp(
          LargePopupWidget(
            content: const SizedBox(height: 200, child: Text('Content')),
            closeButtonPlacement: LargePopupCloseButtonPlacement.topRight,
            onClose: () => closes++,
          ),
        ),
      );
      await tester.pump();

      final strip = tester.getRect(find.byKey(kLargePopupTopCloseKey));
      final popup = tester.getRect(find.byType(LargePopupWidget));
      await tester.tapAt(Offset(popup.left + 4, strip.center.dy));
      await tester.pump();

      expect(closes, 0);
    });

    testWidgets('onClose owns the dismissal without a second pop', (
      tester,
    ) async {
      var closes = 0;
      await showPopupRoute(
        tester,
        Builder(
          builder: (context) => LargePopupWidget(
            content: const SizedBox(height: 200, child: Text('Content')),
            closeButtonPlacement: LargePopupCloseButtonPlacement.topRight,
            onClose: () {
              closes++;
              Navigator.of(context).pop();
            },
          ),
        ),
      );

      await tester.tap(find.byKey(kLargePopupTopCloseKey));
      await tester.pumpAndSettle();

      expect(closes, 1);
      expect(find.byType(LargePopupWidget), findsNothing);
      expect(
        find.text('open-popup'),
        findsOneWidget,
        reason: 'only the popup route may leave',
      );
    });

    testWidgets('the top close pops once on its own when no onClose is given', (
      tester,
    ) async {
      await showPopupRoute(
        tester,
        const LargePopupWidget(
          content: SizedBox(height: 200, child: Text('Content')),
          closeButtonPlacement: LargePopupCloseButtonPlacement.topRight,
        ),
      );

      await tester.tap(find.byKey(kLargePopupTopCloseKey));
      await tester.pumpAndSettle();

      expect(find.byType(LargePopupWidget), findsNothing);
      expect(find.text('open-popup'), findsOneWidget);
    });
  });
}
