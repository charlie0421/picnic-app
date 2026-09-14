import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

const double _screenHeight = 812;
const double _keyboardInset = 300;
const double _compactWidth = 320;
const double _compactHeight = 568;
const String _jmaTitle = 'Jupiter Music Awards';

Finder _nearestGestureTarget(Finder child) =>
    find.ancestor(of: child, matching: find.byType(GestureDetector)).first;

Finder _amountInputSurface() => find
    .ancestor(
      of: find.byType(TextFormField),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    )
    .first;

void main() {
  final l10n = AppLocalizationsKo();
  late VoteModel voteModel;
  late VoteItemModel voteItemModel;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    voteModel = MockData.vote();
    voteItemModel = MockData.voteItem();
    setupMockSupabase(<String, dynamic>{
      'vote': <dynamic>[],
      'vote_item': <dynamic>[],
    });
  });

  tearDown(tearDownMockSupabase);

  Future<void> pumpJma(WidgetTester tester, {double keyboardInset = 0}) async {
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(suppressImageErrors());

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Builder(
          // The single injection point for the keyboard inset. Both the
          // material dialog padding and the dialog's own sizing read it from
          // here, so a second consumer shows up as a doubled offset.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        ),
        userProfile: MockData.userProfile(starCandy: 3000, starCandyBonus: 10),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  // 320x568 with production ScreenUtil geometry: the smallest viewport the app
  // ships against, where the whole dialog budget (outer inset + capture strip)
  // actually matters.
  Future<void> pumpCompactJma(
    WidgetTester tester, {
    double keyboardInset = 0,
    TextScaler textScaler = const TextScaler.linear(2),
    // A parent that is shorter than MediaQuery.size, the way a route with a
    // safe area is on a notched phone. Sizing from the screen height alone
    // would overshoot it.
    double? parentHeight,
  }) async {
    tester.view.physicalSize = const Size(
      _compactWidth * 3,
      _compactHeight * 3,
    );
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    addTearDown(suppressImageErrors());

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Builder(
          builder: (context) {
            final dialog = MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
              child: JmaVotingDialog(
                voteModel: voteModel,
                voteItemModel: voteItemModel,
                portalType: VotePortal.vote,
              ),
            );
            if (parentHeight == null) return dialog;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(height: parentHeight, child: dialog),
            );
          },
        ),
        textScaler: textScaler,
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        userProfile: MockData.userProfile(starCandy: 3000, starCandyBonus: 10),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('JmaVotingDialog compact viewport', () {
    testWidgets('the JMA title is not truncated at 320px and 200%', (
      tester,
    ) async {
      await pumpCompactJma(tester);
      expect(tester.takeException(), isNull);

      final title = find.text(_jmaTitle);
      expect(title, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'the awards name must stay readable, not ellipsised',
      );

      // Natural growth only counts if the grown text is actually contained.
      final titleRect = tester.getRect(title);
      final popupRect = tester.getRect(find.byType(LargePopupWidget));
      expect(titleRect.left, greaterThanOrEqualTo(popupRect.left - 0.5));
      expect(titleRect.right, lessThanOrEqualTo(popupRect.right + 0.5));
      expect(titleRect.bottom, lessThanOrEqualTo(popupRect.bottom + 0.5));
    });

    testWidgets(
      'the whole dialog fits 320x568 at 200% with a 300 keyboard inset',
      (tester) async {
        await pumpCompactJma(tester, keyboardInset: _keyboardInset);

        // The inner cap is 0.85 * (568 - 300) = 227.8, but the real budget is
        // 568 - 300 - 2*20 outer inset = 228 minus the 24 capture strip.
        expect(tester.takeException(), isNull);

        final popup = tester.getRect(find.byType(LargePopupWidget));
        expect(popup.top, greaterThanOrEqualTo(-0.5));
        expect(
          popup.bottom,
          lessThanOrEqualTo(_compactHeight - _keyboardInset + 0.5),
        );
      },
    );

    testWidgets('a parent shorter than the screen still bounds the popup', (
      tester,
    ) async {
      // 210 tall parent minus the dialog's own 2x40 inset leaves 130 — below
      // both the 200 minimum and the 224 the capsule chrome needs, so the
      // minimum has to clamp DOWN instead of forcing an overflow.
      const parentHeight = 210.0;
      await pumpCompactJma(tester, parentHeight: parentHeight);
      expect(tester.takeException(), isNull);

      final popup = tester.getRect(find.byType(LargePopupWidget));
      expect(popup.top, greaterThanOrEqualTo(-0.5));
      expect(popup.bottom, lessThanOrEqualTo(parentHeight + 0.5));
      expect(popup.height, greaterThan(0));
    });

    testWidgets(
      'the amount input and vote action stay reachable with the keyboard up',
      (tester) async {
        await pumpCompactJma(tester, keyboardInset: _keyboardInset);
        expect(tester.takeException(), isNull);

        final visibleBottom = _compactHeight - _keyboardInset;
        for (final entry in <String, Finder>{
          'amount input': _amountInputSurface(),
          'vote': _nearestGestureTarget(find.text(l10n.label_button_vote)),
        }.entries) {
          expect(entry.value, findsOneWidget, reason: entry.key);
          await tester.ensureVisible(entry.value);
          // Not pumpAndSettle: the loading overlay owns a repeating animation.
          await tester.pump(const Duration(milliseconds: 400));
          final rect = tester.getRect(entry.value);
          expect(rect.top, greaterThanOrEqualTo(-0.5), reason: entry.key);
          expect(
            rect.bottom,
            lessThanOrEqualTo(visibleBottom + 0.5),
            reason: entry.key,
          );
          expect(entry.value.hitTestable(), findsOneWidget, reason: entry.key);
        }
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('JmaVotingDialog keyboard inset ownership', () {
    testWidgets('the dialog is centred in the full viewport with no keyboard', (
      tester,
    ) async {
      await pumpJma(tester);

      final popup = tester.getRect(find.byType(LargePopupWidget));
      expect((popup.top + popup.bottom) / 2, closeTo(_screenHeight / 2, 24));
    });

    testWidgets('the keyboard inset is applied exactly once', (tester) async {
      await pumpJma(tester, keyboardInset: _keyboardInset);

      final popup = tester.getRect(find.byType(LargePopupWidget));
      // Applying the same inset twice would centre the popup around
      // (812 - 600) / 2 = 106 instead of (812 - 300) / 2 = 256.
      expect(
        (popup.top + popup.bottom) / 2,
        closeTo((_screenHeight - _keyboardInset) / 2, 24),
      );
      expect(popup.top, greaterThanOrEqualTo(0));
      expect(
        popup.bottom,
        lessThanOrEqualTo(_screenHeight - _keyboardInset + 0.5),
      );
    });

    testWidgets('the vote action stays above the keyboard', (tester) async {
      await pumpJma(tester, keyboardInset: _keyboardInset);

      final voteButton = _nearestGestureTarget(
        find.text(l10n.label_button_vote),
      );
      expect(voteButton, findsOneWidget);
      expect(
        tester.getRect(voteButton).bottom,
        lessThanOrEqualTo(_screenHeight - _keyboardInset + 0.5),
      );
    });
  });

  group('JmaVotingDialog presentation', () {
    testWidgets('every interactive dialog control owns a 48px tap target', (
      tester,
    ) async {
      await pumpJma(tester);

      final controls = <String, Finder>{
        'use all': _nearestGestureTarget(
          find.byIcon(Icons.check_box_outline_blank),
        ),
        'amount input': _amountInputSurface(),
        'clear': _nearestGestureTarget(find.byIcon(Icons.clear)),
        'policy toggle': _nearestGestureTarget(
          find.text(l10n.label_button_view_policy),
        ),
        'vote': _nearestGestureTarget(find.text(l10n.label_button_vote)),
      };

      for (final entry in controls.entries) {
        expect(entry.value, findsOneWidget, reason: entry.key);
        expect(
          tester.getSize(entry.value).height,
          greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
          reason: entry.key,
        );
      }
    });

    testWidgets('the legacy check-all and clear icons are preserved', (
      tester,
    ) async {
      await pumpJma(tester);

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('the policy body stays collapsed until it is opened', (
      tester,
    ) async {
      await pumpJma(tester);

      final policyToggle = _nearestGestureTarget(
        find.text(l10n.label_button_view_policy),
      );
      final firstPolicyLine = l10n.jma_voting_info_text
          .split('\n')
          .map(
            (line) =>
                line.startsWith('-') ? line.substring(1).trim() : line.trim(),
          )
          .firstWhere((line) => line.isNotEmpty);

      expect(find.text(firstPolicyLine), findsNothing);
      await tester.tap(policyToggle);
      await tester.pump();
      expect(find.text(firstPolicyLine), findsOneWidget);
    });
  });
}
