import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

/// The card the popup clips to.
///
/// [LargePopupWidget]'s own Rect also covers the 24 hidden close strip below
/// the card, so using it as the clip box reads the keyboard boundary about 26px
/// looser than the capsule really is.
Finder _capsuleCard() => find
    .descendant(
      of: find.byType(LargePopupWidget),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.clipBehavior == Clip.antiAlias,
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
    // When given, drives the keyboard inset after the first frame so a test
    // can raise and lower the keyboard on a live dialog.
    ValueNotifier<double>? keyboardInsetNotifier,
    VoteItemModel? item,
    VoteModel? vote,
    VotePortal portal = VotePortal.vote,
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
          builder: (context) => ValueListenableBuilder<double>(
            valueListenable:
                keyboardInsetNotifier ?? ValueNotifier<double>(keyboardInset),
            builder: (context, inset, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(viewInsets: EdgeInsets.only(bottom: inset)),
              child: VotingDialog(
                voteModel: vote ?? voteModel,
                voteItemModel: item ?? voteItemModel,
                portalType: portal,
              ),
            ),
          ),
        ),
        textScaler: textScaler,
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        userProfile: MockData.userProfile(starCandy: 500, starCandyBonus: 50),
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

    // Centring the focused input inside the scrolling middle pushed the
    // balance row half under the pinned names when the input was already in
    // view. Pinned, the middle should only move as far as it has to.
    testWidgets('focusing the input does not scroll the balance row away', (
      tester,
    ) async {
      await pumpPhoneDialog(tester, keyboardInset: _phoneKeyboardInset);
      await focusAmountInput(tester);
      expect(tester.takeException(), isNull);

      final names = tester.getRect(find.byType(VotingMemberInfo));
      final balance = tester.getRect(find.byType(VotingStarCandyInfo));
      expect(
        balance.top,
        greaterThanOrEqualTo(names.bottom - 0.5),
        reason: 'the balance row scrolled under the pinned names',
      );
      expect(find.byType(VotingStarCandyInfo).hitTestable(), findsOneWidget);
    });

    // The pinned header and footer give up some of their breathing room while
    // the keyboard is up, so the bonus bubble under the input still fits the
    // scrolling window on a phone instead of showing as a sliver.
    testWidgets('the bonus bubble stays whole in the scrolling window', (
      tester,
    ) async {
      await pumpPhoneDialog(tester, keyboardInset: _phoneKeyboardInset);
      await focusAmountInput(tester);
      expect(tester.takeException(), isNull);

      final names = tester.getRect(find.byType(VotingMemberInfo));
      final submit = tester.getRect(find.byType(VotingSubmitButton));
      final bubble = tester.getRect(find.byType(VotingBubbleInfo));
      expect(bubble.top, greaterThanOrEqualTo(names.bottom - 0.5));
      expect(bubble.bottom, lessThanOrEqualTo(submit.top + 0.5));
      expect(find.byType(VotingBubbleInfo).hitTestable(), findsOneWidget);
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

    // The pinned header grows with the names. A budget that clears the
    // one-row minimum can still be too short for a name that wraps several
    // lines, and then the pinned layout has nothing left to give: it has to
    // fall back to the all-scroll body rather than overflow the capsule.
    testWidgets('a long wrapping name never overflows the pinned layout', (
      tester,
    ) async {
      final longName = List.filled(6, '아주긴아티스트이름').join(' ');
      await pumpCompactDialog(
        tester,
        textScaler: TextScaler.noScaling,
        viewport: const Size(320, 420),
        item: MockData.voteItem(
          artist: MockData.artist(
            nameKo: longName,
            nameEn: longName,
            artistGroup: MockData.artistGroup(
              nameKo: longName,
              nameEn: longName,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      final popup = tester.getRect(find.byType(LargePopupWidget));
      expect(popup.top, greaterThanOrEqualTo(-0.5));
      expect(popup.bottom, lessThanOrEqualTo(420 + 0.5));
      await tester.ensureVisible(find.byType(VotingSubmitButton));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(VotingSubmitButton).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Between "everything pins" and "nothing fits" there is a band of short
    // budgets (a 320x568 phone with a 280 keyboard at 1x) where the portrait
    // and the submit button still fit pinned if the names move into the
    // scrolling window. The portrait must not be unpinned there.
    testWidgets('a short budget pins the portrait and scrolls the names', (
      tester,
    ) async {
      await pumpCompactDialog(
        tester,
        textScaler: TextScaler.noScaling,
        keyboardInset: 280,
      );
      await focusAmountInput(tester);
      expect(tester.takeException(), isNull);

      final popup = tester.getRect(find.byType(LargePopupWidget));
      final portrait = tester.getRect(find.byType(VotingArtistImage));
      expect(
        portrait.top,
        greaterThanOrEqualTo(popup.top - 0.5),
        reason: 'the portrait scrolled above the capsule and is clipped',
      );
      expect(find.byType(VotingArtistImage).hitTestable(), findsOneWidget);
      expect(find.byType(VotingMemberInfo), findsOneWidget);

      final visibleBottom = _compactHeight - 280;
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

    // At 200% the amount input is taller than the 48 minimum (scaled line
    // plus its padding and border). A budget that clears portrait + submit +
    // 48 but not the real input used to pin a window the input could never be
    // shown whole in. PICNIC-2694 keeps the input out of the scrolling area
    // altogether while the budget can hold it, so the containment check moves
    // to whichever box actually clips it: its scroll viewport when it has one,
    // the capsule when it does not.
    testWidgets('a pinned window is never shorter than the scaled input', (
      tester,
    ) async {
      for (final inset in const [280.0, 284.0, 288.0, 292.0, 296.0]) {
        await pumpCompactDialog(tester, keyboardInset: inset);
        await focusAmountInput(tester);
        expect(tester.takeException(), isNull, reason: 'inset $inset');

        final scrollAncestor = find.ancestor(
          of: find.byType(TextFormField),
          matching: find.byType(Scrollable),
        );
        final clip = tester.getRect(
          scrollAncestor.evaluate().isNotEmpty
              ? scrollAncestor.first
              : _capsuleCard(),
        );
        final input = tester.getRect(_amountInputSurface());
        expect(
          input.top,
          greaterThanOrEqualTo(clip.top - 0.5),
          reason: 'inset $inset: input clipped at the top',
        );
        expect(
          input.bottom,
          lessThanOrEqualTo(clip.bottom + 0.5),
          reason: 'inset $inset: input clipped at the bottom',
        );
        expect(
          _amountInputSurface().hitTestable(),
          findsOneWidget,
          reason: 'inset $inset: input not reachable',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    VoteModel partnerVote() => VoteModel.fromJson({
      ...MockData.vote().toJson(),
      'is_partnership': true,
      'partner': 'jma',
    });

    testWidgets('the partner logo keeps its size without the keyboard', (
      tester,
    ) async {
      await pumpCompactDialog(
        tester,
        textScaler: TextScaler.noScaling,
        viewport: const Size(_phoneWidth, _phoneHeight),
        vote: partnerVote(),
      );
      expect(tester.takeException(), isNull);

      final logo = find.byType(VotingLogoImage);
      expect(logo, findsOneWidget);
      expect(logo.hitTestable(), findsOneWidget);
      expect(tester.getSize(logo).height, closeTo(100.w, 0.5));
      // The capsule keeps its intrinsic height: no keyboard, nothing pins.
      final popup = tester.getRect(find.byType(LargePopupWidget));
      expect(popup.height, lessThan(_phoneHeight - 48));
    });

    testWidgets('the partner logo yields its room while the keyboard is up', (
      tester,
    ) async {
      await pumpCompactDialog(
        tester,
        textScaler: TextScaler.noScaling,
        viewport: const Size(_phoneWidth, _phoneHeight),
        keyboardInset: _phoneKeyboardInset,
        vote: partnerVote(),
      );
      await focusAmountInput(tester);
      expect(tester.takeException(), isNull);

      expect(find.byType(VotingLogoImage), findsNothing);
      final popup = tester.getRect(find.byType(LargePopupWidget));
      final portrait = tester.getRect(find.byType(VotingArtistImage));
      expect(portrait.top, greaterThanOrEqualTo(popup.top - 0.5));
      expect(find.byType(VotingSubmitButton).hitTestable(), findsOneWidget);
    });

    // 320x568 at 1x is the one geometry that swaps bodies as the keyboard
    // moves: pinned without it, all-scroll with it. The swap must not drop
    // the focused input or what was typed into it. Both portals: pic reads
    // its balance from the profile instead of the wallet.
    for (final portal in VotePortal.values) {
      testWidgets(
        'raising and lowering the keyboard keeps focus and the amount ($portal)',
        (tester) async {
          final inset = ValueNotifier<double>(0);
          addTearDown(inset.dispose);
          await pumpCompactDialog(
            tester,
            textScaler: TextScaler.noScaling,
            keyboardInsetNotifier: inset,
            portal: portal,
          );
          expect(tester.takeException(), isNull);

          await tester.showKeyboard(find.byType(TextFormField));
          await tester.enterText(find.byType(TextFormField), '123');
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(VotingLogoImage), findsOneWidget);

          Future<void> setInset(double value) async {
            inset.value = value;
            // The Dialog animates its inset padding (100) before the layout
            // budget settles, and the settled body then animates the focused
            // input into view (300); give both a few frames.
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 400));
            }
            expect(tester.takeException(), isNull, reason: 'inset $value');
            final field = tester.widget<TextField>(find.byType(TextField));
            expect(field.focusNode?.hasFocus, isTrue, reason: 'inset $value');
            expect(field.controller?.text, '123', reason: 'inset $value');
            expect(
              _amountInputSurface().hitTestable(),
              findsOneWidget,
              reason: 'inset $value',
            );
            // With the keyboard up this geometry is in the all-scroll body,
            // where submit is reachable by scrolling rather than pinned.
            await tester.ensureVisible(find.byType(VotingSubmitButton));
            await tester.pump(const Duration(milliseconds: 400));
            expect(
              find.byType(VotingSubmitButton).hitTestable(),
              findsOneWidget,
              reason: 'inset $value',
            );
            expect(tester.takeException(), isNull, reason: 'inset $value');
          }

          await setInset(_keyboardInset);
          expect(find.byType(VotingLogoImage), findsNothing);
          await setInset(0);
          expect(find.byType(VotingLogoImage), findsOneWidget);
        },
      );
    }
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
