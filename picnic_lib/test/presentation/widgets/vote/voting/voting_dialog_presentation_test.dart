import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

class _WalletSummaryOverride extends WalletSummary {
  _WalletSummaryOverride(this.summary);

  final WalletSummaryModel summary;

  @override
  Future<WalletSummaryModel> build() async => summary;
}

const double _compactWidth = 320;
const double _compactHeight = 568;
const double _keyboardInset = 300;

// A common phone viewport (logical 375x812) with the iOS keyboard plus its
// accessory bar. This is the geometry PICNIC-2688 was reported on: the popup
// body does not fit next to the keyboard, and centring the amount input used to
// scroll the artist portrait out of the capsule.
const double _phoneWidth = 375;
const double _phoneHeight = 812;
const double _phoneKeyboardInset = 336;

final _wallet = WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(500),
  bonus: BigInt.from(50),
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 7, 21),
);

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
    voteModel = MockData.vote();
    voteItemModel = MockData.voteItem();
    setupMockSupabase(<String, dynamic>{});
  });

  tearDown(tearDownMockSupabase);

  Future<void> pumpDialog(WidgetTester tester, {TextScaler? textScaler}) async {
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(suppressImageErrors());

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        VotingDialog(
          voteModel: voteModel,
          voteItemModel: voteItemModel,
          portalType: VotePortal.vote,
        ),
        textScaler: textScaler,
        extraOverrides: [
          walletSummaryProvider.overrideWith(
            () => _WalletSummaryOverride(_wallet),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  // The smallest viewport the app ships against, measured with production
  // ScreenUtil geometry rather than the legacy harness default.
  Future<void> pumpCompactDialog(
    WidgetTester tester, {
    double keyboardInset = 0,
    TextScaler textScaler = const TextScaler.linear(2),
    Size viewport = const Size(_compactWidth, _compactHeight),
  }) async {
    tester.view.physicalSize = Size(viewport.width * 3, viewport.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    addTearDown(suppressImageErrors());

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Builder(
          // The one injection point for the keyboard inset, so a second
          // consumer inside the dialog shows up as a doubled offset.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: VotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
        ),
        textScaler: textScaler,
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        extraOverrides: [
          walletSummaryProvider.overrideWith(
            () => _WalletSummaryOverride(_wallet),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('VotingDialog compact viewport', () {
    testWidgets('the popup fits 320x568 at 200% with a 300 keyboard inset', (
      tester,
    ) async {
      await pumpCompactDialog(tester, keyboardInset: _keyboardInset);

      // Keep the dialog inside the remaining height when the keyboard is open.
      expect(tester.takeException(), isNull);

      // The capsule itself stays inside the viewport — only its content
      // scrolls, so this is measured on the popup, not on the scroll view.
      final popup = tester.getRect(find.byType(LargePopupWidget));
      expect(popup.top, greaterThanOrEqualTo(-0.5));
      expect(
        popup.bottom,
        lessThanOrEqualTo(_compactHeight - _keyboardInset + 0.5),
      );
      expect(popup.left, greaterThanOrEqualTo(-0.5));
      expect(popup.right, lessThanOrEqualTo(_compactWidth + 0.5));
    });

    testWidgets(
      'the amount input and submit scroll into the visible area with the keyboard up',
      (tester) async {
        await pumpCompactDialog(tester, keyboardInset: _keyboardInset);
        expect(tester.takeException(), isNull);

        // `Scrollable.ensureVisible` is already wired to the input, but with no
        // Scrollable ancestor it is a silent no-op.
        expect(
          find.descendant(
            of: find.byType(VotingDialog),
            matching: find.byType(Scrollable),
          ),
          findsWidgets,
          reason: 'the popup body must be scrollable to be reachable',
        );

        final visibleBottom = _compactHeight - _keyboardInset;
        for (final entry in <String, Finder>{
          'amount input': _amountInputSurface(),
          'submit': find.byType(VotingSubmitButton),
        }.entries) {
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
        // Reaching the controls must not have fired a vote.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the recharge label stays inside its own mint pill at 200%', (
      tester,
    ) async {
      await pumpCompactDialog(tester);
      expect(tester.takeException(), isNull);

      final label = find.text(l10n.label_button_recharge);
      expect(label, findsOneWidget);
      final pill = find
          .ancestor(
            of: label,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container && widget.decoration is BoxDecoration,
            ),
          )
          .first;
      final target = _nearestGestureTarget(label);

      final labelRect = tester.getRect(label);
      final pillRect = tester.getRect(pill);
      final targetRect = tester.getRect(target);

      // A fixed 32 pill crops a 40.6 high scaled label; the label must sit
      // inside the pill, and the pill inside the 48 tap target.
      expect(
        labelRect.top,
        greaterThanOrEqualTo(pillRect.top - 0.5),
        reason: 'recharge label overflows the pill top',
      );
      expect(
        labelRect.bottom,
        lessThanOrEqualTo(pillRect.bottom + 0.5),
        reason: 'recharge label overflows the pill bottom',
      );
      expect(
        targetRect.height,
        greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
      );
      expect(pillRect.height, lessThanOrEqualTo(targetRect.height + 0.5));

      // And the balance row it lives in must still fit the compact width.
      final row = tester.getRect(find.byType(VotingStarCandyInfo));
      expect(targetRect.right, lessThanOrEqualTo(row.right + 0.5));
      expect(row.width, lessThanOrEqualTo(_compactWidth));
    });

    testWidgets('the mint pill keeps its 32 baseline when the label fits', (
      tester,
    ) async {
      await pumpCompactDialog(tester, textScaler: TextScaler.noScaling);
      expect(tester.takeException(), isNull);

      final pill = find
          .ancestor(
            of: find.text(l10n.label_button_recharge),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container && widget.decoration is BoxDecoration,
            ),
          )
          .first;
      expect(tester.getSize(pill).height, 32);
    });
  });

  group('VotingDialog with the keyboard up (PICNIC-2688)', () {
    Future<void> pumpPhoneDialog(
      WidgetTester tester, {
      double keyboardInset = 0,
    }) => pumpCompactDialog(
      tester,
      keyboardInset: keyboardInset,
      textScaler: TextScaler.noScaling,
      viewport: const Size(_phoneWidth, _phoneHeight),
    );

    Future<void> focusAmountInput(WidgetTester tester) async {
      await tester.showKeyboard(find.byType(TextFormField));
      // Not pumpAndSettle: the loading overlay owns a repeating animation.
      // 400 covers the 300 `Scrollable.ensureVisible` animation the input
      // schedules once it has focus.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('the artist portrait stays inside the capsule', (tester) async {
      await pumpPhoneDialog(tester, keyboardInset: _phoneKeyboardInset);
      await focusAmountInput(tester);
      expect(tester.takeException(), isNull);

      final popup = tester.getRect(find.byType(LargePopupWidget));
      final portrait = tester.getRect(find.byType(VotingArtistImage));
      expect(
        portrait.top,
        greaterThanOrEqualTo(popup.top - 0.5),
        reason: 'the portrait scrolled above the capsule and is clipped',
      );
      expect(portrait.bottom, lessThanOrEqualTo(popup.bottom + 0.5));
      expect(find.byType(VotingArtistImage).hitTestable(), findsOneWidget);
    });

    testWidgets('the amount input and submit are visible without scrolling', (
      tester,
    ) async {
      await pumpPhoneDialog(tester, keyboardInset: _phoneKeyboardInset);
      await focusAmountInput(tester);
      expect(tester.takeException(), isNull);

      final visibleBottom = _phoneHeight - _phoneKeyboardInset;
      for (final entry in <String, Finder>{
        'amount input': _amountInputSurface(),
        'submit': find.byType(VotingSubmitButton),
      }.entries) {
        final rect = tester.getRect(entry.value);
        expect(rect.top, greaterThanOrEqualTo(-0.5), reason: entry.key);
        expect(
          rect.bottom,
          lessThanOrEqualTo(visibleBottom + 0.5),
          reason: entry.key,
        );
        expect(entry.value.hitTestable(), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('the picnic logo yields its room while the keyboard is up', (
      tester,
    ) async {
      await pumpPhoneDialog(tester, keyboardInset: _phoneKeyboardInset);
      await focusAmountInput(tester);
      expect(tester.takeException(), isNull);

      expect(find.byType(VotingLogoImage), findsNothing);
    });

    testWidgets('the picnic logo is back once the keyboard is down', (
      tester,
    ) async {
      await pumpPhoneDialog(tester);
      expect(tester.takeException(), isNull);

      expect(find.byType(VotingLogoImage), findsOneWidget);
      expect(find.byType(VotingLogoImage).hitTestable(), findsOneWidget);
    });
  });

  group('VotingDialog presentation', () {
    testWidgets('every interactive dialog control owns a 48px tap target', (
      tester,
    ) async {
      await pumpDialog(tester);

      final controls = <String, Finder>{
        'recharge': _nearestGestureTarget(
          find.text(l10n.label_button_recharge),
        ),
        'use all': find.byType(VotingCheckAllOption),
        'amount input': _amountInputSurface(),
        'clear': find.byType(VotingClearButton),
        'submit': find.byType(VotingSubmitButton),
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

    testWidgets('the submit label uses the readable token style', (
      tester,
    ) async {
      await pumpDialog(tester);

      final label = tester.widget<Text>(
        find.descendant(
          of: find.byType(VotingSubmitButton),
          matching: find.text(l10n.label_button_vote),
        ),
      );
      expect(label.style?.height, 1.45);
      expect(label.style?.letterSpacing, 0);
    });

    testWidgets('the popup body fits the viewport at 200% text scale', (
      tester,
    ) async {
      await pumpDialog(tester, textScaler: const TextScaler.linear(2));

      expect(tester.takeException(), isNull);
    });
  });
}
