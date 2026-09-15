import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/l10n/app_localizations_my.dart';
import 'package:picnic_lib/l10n/app_localizations_th.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_layout.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// PICNIC-2694: the popup has to show the amount input, "use all" and the vote
/// button at scroll offset 0 on a short or landscape viewport — a Flip in flex
/// mode, a folded/unfolded foldable, a phone in landscape, a tablet split view.
///
/// The ticket's own cases are keyboard-free (`viewInsets.bottom == 0`), because
/// the bug reproduces with no keyboard at all: decoration sized off the *width*
/// scale eats the vertical budget and pushes the controls below the fold. The
/// keyboard groups further down cover the insets the fix has to survive too.

class _WalletSummaryOverride extends WalletSummary {
  _WalletSummaryOverride(this.summary);

  final WalletSummaryModel summary;

  @override
  Future<WalletSummaryModel> build() async => summary;
}

final _wallet = WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(500),
  bonus: BigInt.from(50),
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 7, 21),
);

/// The viewports the ticket names, plus the ones the plan's matrix flags as
/// already broken without a keyboard.
const _viewports = <String, Size>{
  'flip flex top half': Size(412, 500),
  'flip flex shorter parent': Size(412, 448),
  'phone landscape': Size(851, 393),
  'phone landscape wide': Size(926, 428),
  'iphone landscape': Size(844, 390),
  'tablet split third': Size(375, 834),
  'tablet landscape': Size(1194, 834),
  'stage manager window': Size(600, 500),
  'flip flex shortest': Size(412, 430),
  'narrow window edge': Size(280, 480),
  // The plan's smallest acceptance size. 280 high leaves the JMA popup 200
  // between its margins, and the review found the vote button hanging below
  // the capsule at 200% text there.
  'narrow short window': Size(280, 280),
};

const _scalers = <double>[1.0, 1.3, 2.0];

/// The card the popup actually clips to — the hidden close strip below it is
/// not part of the capsule.
Finder _capsuleCard() => find
    .descendant(
      of: find.byType(LargePopupWidget),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.clipBehavior == Clip.antiAlias,
      ),
    )
    .first;

Finder _amountInputSurface() => find
    .ancestor(
      of: find.byType(TextFormField),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    )
    .first;

Finder _nearestGestureTarget(Finder child) =>
    find.ancestor(of: child, matching: find.byType(GestureDetector)).first;

/// How far the worst corner of [inner] falls outside the capsule's *rounded*
/// corner. Negative means unclipped.
///
/// A bounding-box check passes a control whose corner the `Clip.antiAlias`
/// card has actually cut, which is how the 280x280 JMA popup looked fine to a
/// rectangular assertion while its "use all" row lost 8.5px of its top left.
double _capsuleCornerOverhang(WidgetTester tester, Rect inner) {
  final capsule = tester.getRect(_capsuleCard());
  final radius =
      tester
          .widget<LargePopupWidget>(find.byType(LargePopupWidget))
          .cardBorderRadius
          ?.topLeft
          .x ??
      0.0;
  if (radius <= 0) return double.negativeInfinity;
  var worst = double.negativeInfinity;
  for (final corner in <Offset>[
    inner.topLeft,
    inner.topRight,
    inner.bottomLeft,
    inner.bottomRight,
  ]) {
    final onLeft = corner.dx < capsule.center.dx;
    final onTop = corner.dy < capsule.center.dy;
    final cx = onLeft ? capsule.left + radius : capsule.right - radius;
    final cy = onTop ? capsule.top + radius : capsule.bottom - radius;
    // Only the corner quadrants are rounded; the straight bands between them
    // are already covered by the bounding-box check.
    if (onLeft ? corner.dx >= cx : corner.dx <= cx) continue;
    if (onTop ? corner.dy >= cy : corner.dy <= cy) continue;
    final distance = math.sqrt(
      math.pow(corner.dx - cx, 2) + math.pow(corner.dy - cy, 2),
    );
    worst = math.max(worst, distance - radius);
  }
  return worst;
}

/// Settles a state change inside the popup.
///
/// Two frames, not one: the popup sizes its own route inset from the controls it
/// has to show, and `Dialog` runs that inset through a 100ms `AnimatedPadding`,
/// so the frame that reacts to the input still carries the old margin.
Future<void> settleDialogState(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void _expectContained(Rect outer, Rect inner, String label) {
  expect(inner.left, greaterThanOrEqualTo(outer.left - 0.5), reason: label);
  expect(inner.top, greaterThanOrEqualTo(outer.top - 0.5), reason: label);
  expect(inner.right, lessThanOrEqualTo(outer.right + 0.5), reason: label);
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom + 0.5), reason: label);
}

/// Every control has to be whole inside the capsule, inside whatever scroll
/// viewport it lives in, and reachable — all in the first frame, with no
/// scrolling, focusing or keyboard.
void _expectControlsVisibleAtRest(
  WidgetTester tester,
  Map<String, Finder> controls,
  String label,
) {
  expect(tester.takeException(), isNull, reason: label);

  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    expect(
      state.position.pixels,
      closeTo(0, 0.01),
      reason: '$label: a scroll view already moved off the first frame',
    );
  }

  final capsule = tester.getRect(_capsuleCard());
  final rects = <String, Rect>{};
  for (final entry in controls.entries) {
    final reason = '$label / ${entry.key}';
    expect(entry.value, findsOneWidget, reason: reason);
    final rect = tester.getRect(entry.value);
    rects[entry.key] = rect;
    expect(rect.height, greaterThan(0), reason: reason);
    _expectContained(capsule, rect, reason);
    expect(
      _capsuleCornerOverhang(tester, rect),
      lessThanOrEqualTo(0.5),
      reason: '$reason cut by the capsule\'s rounded corner',
    );

    final scrollAncestor = find.ancestor(
      of: entry.value,
      matching: find.byType(Scrollable),
    );
    if (scrollAncestor.evaluate().isNotEmpty) {
      _expectContained(
        tester.getRect(scrollAncestor.first),
        rect,
        '$reason inside its scrolling viewport',
      );
    }
    expect(entry.value.hitTestable(), findsOneWidget, reason: reason);
  }

  final entries = rects.entries.toList();
  for (var i = 0; i < entries.length; i += 1) {
    for (var j = i + 1; j < entries.length; j += 1) {
      expect(
        entries[i].value.overlaps(entries[j].value),
        isFalse,
        reason: '$label: ${entries[i].key} overlaps ${entries[j].key}',
      );
    }
  }
}

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

  Future<void> pumpAt(
    WidgetTester tester,
    Widget dialog, {
    required Size viewport,
    required double textScale,
    double keyboard = 0,
    EdgeInsets padding = EdgeInsets.zero,
    Locale locale = const Locale('ko'),
    double? parentHeight,
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
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: EdgeInsets.only(bottom: keyboard),
              padding: padding,
            ),
            child: parentHeight == null
                ? dialog
                : Center(
                    child: SizedBox(height: parentHeight, child: dialog),
                  ),
          ),
        ),
        locale: locale,
        textScaler: TextScaler.linear(textScale),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        userProfile: MockData.userProfile(starCandy: 3000, starCandyBonus: 50),
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

  /// The three controls the ticket is about, for the plain popup.
  Map<String, Finder> plainControls() => <String, Finder>{
    'amount input': _amountInputSurface(),
    'use all': find.byType(VotingCheckAllOption),
    'submit': find.byType(VotingSubmitButton),
  };

  /// The same three for the JMA popup, whose controls are private widgets.
  Map<String, Finder> jmaControls(String voteLabel) => <String, Finder>{
    'amount input': _amountInputSurface(),
    'use all': _nearestGestureTarget(
      find.byIcon(Icons.check_box_outline_blank),
    ),
    'submit': _nearestGestureTarget(find.text(voteLabel)),
  };

  Widget plainDialog({
    VoteModel? vote,
    VoteItemModel? item,
    VotePortal portal = VotePortal.vote,
  }) => VotingDialog(
    voteModel: vote ?? voteModel,
    voteItemModel: item ?? voteItemModel,
    portalType: portal,
  );

  Widget jmaDialog({VotePortal portal = VotePortal.vote}) => JmaVotingDialog(
    voteModel: voteModel,
    voteItemModel: voteItemModel,
    portalType: portal,
  );

  VoteModel partnerVote() => VoteModel.fromJson({
    ...MockData.vote().toJson(),
    'is_partnership': true,
    'partner': 'jma',
  });

  group('VotingDialog short and landscape viewports (PICNIC-2694)', () {
    for (final viewport in _viewports.entries) {
      for (final scale in _scalers) {
        testWidgets('the amount input, use all and vote are visible at rest '
            'on ${viewport.key} ${viewport.value.width.toInt()}x'
            '${viewport.value.height.toInt()} at ${scale}x', (tester) async {
          await pumpAt(
            tester,
            VotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            viewport: viewport.value,
            textScale: scale,
          );

          _expectControlsVisibleAtRest(
            tester,
            plainControls(),
            '${viewport.key} @ ${scale}x',
          );
        });
      }
    }

    testWidgets('a partner logo does not push the controls off a landscape '
        'viewport', (tester) async {
      await pumpAt(
        tester,
        VotingDialog(
          voteModel: partnerVote(),
          voteItemModel: voteItemModel,
          portalType: VotePortal.vote,
        ),
        viewport: const Size(851, 393),
        textScale: 1.0,
      );

      _expectControlsVisibleAtRest(tester, <String, Finder>{
        'amount input': _amountInputSurface(),
        'use all': find.byType(VotingCheckAllOption),
        'submit': find.byType(VotingSubmitButton),
      }, 'partner landscape');
    });

    // A name long enough to wrap several lines is exactly the content that
    // used to push the controls out: it grows the header the old layout pinned.
    testWidgets('a long wrapping name does not push the controls off a '
        'landscape viewport', (tester) async {
      final longName = List.filled(6, '아주긴아티스트이름').join(' ');
      await pumpAt(
        tester,
        VotingDialog(
          voteModel: voteModel,
          voteItemModel: MockData.voteItem(
            artist: MockData.artist(
              nameKo: longName,
              nameEn: longName,
              artistGroup: MockData.artistGroup(
                nameKo: longName,
                nameEn: longName,
              ),
            ),
          ),
          portalType: VotePortal.vote,
        ),
        viewport: const Size(851, 393),
        textScale: 1.3,
      );

      _expectControlsVisibleAtRest(tester, <String, Finder>{
        'amount input': _amountInputSurface(),
        'use all': find.byType(VotingCheckAllOption),
        'submit': find.byType(VotingSubmitButton),
      }, 'long name landscape');
    });

    // Rotating is the way a user actually reaches the landscape viewport, and
    // the popup has to survive it with what was typed still in the field.
    testWidgets('rotating to landscape keeps the controls and the amount', (
      tester,
    ) async {
      await pumpAt(
        tester,
        VotingDialog(
          voteModel: voteModel,
          voteItemModel: voteItemModel,
          portalType: VotePortal.vote,
        ),
        viewport: const Size(393, 852),
        textScale: 1.0,
      );

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.pump(const Duration(milliseconds: 400));

      tester.view.physicalSize = const Size(852 * 3, 393 * 3);
      for (var i = 0; i < 3; i += 1) {
        await tester.pump(const Duration(milliseconds: 400));
      }

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '123',
      );
      _expectControlsVisibleAtRest(tester, <String, Finder>{
        'amount input': _amountInputSurface(),
        'use all': find.byType(VotingCheckAllOption),
        'submit': find.byType(VotingSubmitButton),
      }, 'after rotation');
    });

    // The portrait, the logo and the card width are authored in design pixels
    // and scaled with `.w`, which is the *width* factor: on a 851 wide viewport
    // that is 2.17, so an 80 high portrait renders 173 high and eats the
    // vertical budget the controls need.
    testWidgets('decoration authored in design pixels does not grow with the '
        'viewport width', (tester) async {
      await pumpAt(
        tester,
        VotingDialog(
          voteModel: voteModel,
          voteItemModel: voteItemModel,
          portalType: VotePortal.vote,
        ),
        viewport: const Size(851, 393),
        textScale: 1.0,
      );

      expect(
        tester.getSize(find.byType(VotingArtistImage)).height,
        lessThanOrEqualTo(80.5),
        reason: 'the portrait grew with the viewport width',
      );
      expect(
        tester.getSize(_capsuleCard()).width,
        lessThanOrEqualTo(560.5),
        reason: 'the capsule grew with the viewport width',
      );
    });
  });

  group('JmaVotingDialog short and landscape viewports (PICNIC-2694)', () {
    for (final viewport in _viewports.entries) {
      for (final scale in _scalers) {
        testWidgets('the amount input, use all and vote are visible at rest '
            'on ${viewport.key} ${viewport.value.width.toInt()}x'
            '${viewport.value.height.toInt()} at ${scale}x', (tester) async {
          await pumpAt(
            tester,
            JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
            viewport: viewport.value,
            textScale: scale,
          );

          _expectControlsVisibleAtRest(
            tester,
            jmaControls(l10n.label_button_vote),
            'JMA ${viewport.key} @ ${scale}x',
          );
        });
      }
    }
  });

  group('the PIC portal variant shares the policy (PICNIC-2694)', () {
    // The PIC portal spends the same popup on a different balance row, so the
    // review is right that a matrix without it proves nothing about it.
    for (final size in <Size>[Size(280, 280), Size(412, 430), Size(851, 393)]) {
      for (final scale in <double>[1.0, 2.0]) {
        testWidgets('the controls are visible at rest on PIC '
            '${size.width.toInt()}x${size.height.toInt()} at ${scale}x', (
          tester,
        ) async {
          await pumpAt(
            tester,
            plainDialog(portal: VotePortal.pic),
            viewport: size,
            textScale: scale,
          );

          _expectControlsVisibleAtRest(
            tester,
            plainControls(),
            'PIC ${size.width.toInt()}x${size.height.toInt()} @ ${scale}x',
          );
        });
      }
    }
  });

  group('a real route and its safe area (PICNIC-2694)', () {
    // Pumping the dialog widget directly skips `showDialog`, the route's
    // barrier and the window padding. This is the same popup the app opens.
    testWidgets('showJmaVotingDialog opens with its controls whole on a '
        'landscape phone with a notch', (tester) async {
      tester.view.physicalSize = const Size(851 * 3, 393 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      addTearDown(suppressImageErrors());

      late BuildContext hostContext;
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: EdgeInsets.zero,
                padding: const EdgeInsets.only(top: 44, bottom: 34, left: 48),
              ),
              child: Builder(
                builder: (context) {
                  hostContext = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
          textScaler: const TextScaler.linear(2.0),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          userProfile: MockData.userProfile(
            starCandy: 3000,
            starCandyBonus: 50,
          ),
          extraOverrides: [
            walletSummaryProvider.overrideWith(
              () => _WalletSummaryOverride(_wallet),
            ),
          ],
        ),
      );

      showJmaVotingDialog(
        context: hostContext,
        voteModel: voteModel,
        voteItemModel: voteItemModel,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      _expectControlsVisibleAtRest(
        tester,
        jmaControls(l10n.label_button_vote),
        'JMA via showDialog with a notch',
      );
    });

    // A parent that hands the popup less than the window — a host sheet, a
    // hinge-aware pane — still may not clip the controls.
    testWidgets('a parent shorter than the window keeps the controls inside '
        'whatever clips them', (tester) async {
      await pumpAt(
        tester,
        jmaDialog(),
        viewport: const Size(412, 892),
        textScale: 1.3,
        parentHeight: 360,
      );

      expect(tester.takeException(), isNull);
      final capsule = tester.getRect(_capsuleCard());
      for (final entry in jmaControls(l10n.label_button_vote).entries) {
        final rect = tester.getRect(entry.value);
        final scrollAncestor = find.ancestor(
          of: entry.value,
          matching: find.byType(Scrollable),
        );
        _expectContained(
          scrollAncestor.evaluate().isEmpty
              ? capsule
              : tester.getRect(scrollAncestor.first),
          rect,
          'partial parent / ${entry.key}',
        );
      }
    });
  });

  group('with the keyboard up (PICNIC-2694)', () {
    // A 280 keyboard is the inset the PICNIC-2688 tests use. Where the window
    // still has room for the controls, they stay whole; the cases below that
    // are listed separately because no layout can fit 48+48+48 of tap targets
    // into 62 logical pixels.
    for (final entry in <String, Size>{
      'portrait phone': Size(393, 852),
      'flip flex top half': Size(412, 500),
    }.entries) {
      testWidgets('the JMA controls survive a 280 keyboard on ${entry.key}', (
        tester,
      ) async {
        await pumpAt(
          tester,
          jmaDialog(),
          viewport: entry.value,
          textScale: 1.0,
          keyboard: 280,
        );

        _expectControlsVisibleAtRest(
          tester,
          jmaControls(l10n.label_button_vote),
          'JMA K=280 ${entry.key}',
        );
      });

      testWidgets('the plain controls survive a 280 keyboard on ${entry.key}', (
        tester,
      ) async {
        await pumpAt(
          tester,
          plainDialog(),
          viewport: entry.value,
          textScale: 1.0,
          keyboard: 280,
        );

        _expectControlsVisibleAtRest(
          tester,
          plainControls(),
          'plain K=280 ${entry.key}',
        );
      });
    }

    // 393 high minus a 280 keyboard leaves 113, and the popup's own chrome and
    // minimum margins take it down to about 62 — less than the input alone.
    // What the popup still owes the user there is the scrolling fallback with
    // the controls first, and no overflow.
    for (final jma in <bool>[false, true]) {
      testWidgets('a window too short for the controls scrolls them instead of '
          'throwing (${jma ? "JMA" : "vote"})', (tester) async {
        await pumpAt(
          tester,
          jma ? jmaDialog() : plainDialog(),
          viewport: const Size(851, 393),
          textScale: 2.0,
          keyboard: 280,
        );

        expect(tester.takeException(), isNull);
        final input = _amountInputSurface();
        final scrollAncestor = find.ancestor(
          of: input,
          matching: find.byType(Scrollable),
        );
        expect(
          scrollAncestor,
          findsWidgets,
          reason: 'the input has to be reachable by scrolling',
        );
        // Scrolling the input into view is exactly what the user can do, and
        // it has to actually work.
        await tester.ensureVisible(input);
        await tester.pumpAndSettle();
        // 393 less a 280 keyboard leaves the body about 62, and at 200% the
        // input is taller than that, so "revealed" means as much of it as the
        // window can hold — starting at its top edge.
        final viewport = tester.getRect(scrollAncestor.first);
        final revealed = viewport.intersect(tester.getRect(input));
        expect(
          revealed.height,
          greaterThanOrEqualTo(
            math.min(tester.getRect(input).height, viewport.height) - 0.5,
          ),
          reason: '${jma ? "JMA" : "vote"} input was not revealed by scrolling',
        );
        expect(
          tester.getRect(input).top,
          greaterThanOrEqualTo(viewport.top - 0.5),
          reason: '${jma ? "JMA" : "vote"} input top still above the viewport',
        );
      });
    }
  });

  group('JmaVotingDialog state transitions (PICNIC-2694)', () {
    // Claim 2: the reason the input turned red used to live in the decoration
    // scroll, behind the portrait, the balance and the daily limit, so a short
    // window showed a red border, a dead button and no explanation.
    for (final size in <Size>[Size(851, 393), Size(412, 430), Size(280, 280)]) {
      testWidgets('an over-the-maximum amount explains itself on '
          '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await pumpAt(tester, jmaDialog(), viewport: size, textScale: 1.0);

        // 3000 star candy at 30:1 plus the 5 bonus votes the daily limit
        // allows is 105, so 106 is the first rejected amount.
        await tester.enterText(find.byType(TextFormField), '106');
        await settleDialogState(tester);

        final message = find.text(l10n.jma_voting_max_votes_exceeded(105));
        expect(message, findsOneWidget);
        _expectControlsVisibleAtRest(tester, <String, Finder>{
          ...jmaControls(l10n.label_button_vote),
          'validation': message,
        }, 'JMA invalid ${size.width.toInt()}x${size.height.toInt()}');
        // Right under the input, not somewhere in the decoration.
        expect(
          tester.getRect(message).top,
          greaterThanOrEqualTo(
            tester.getRect(_amountInputSurface()).bottom - 0.5,
          ),
        );
        // The decoration has its own scroll view; the actions band does not.
        // Sharing the input's scroll ancestry is what keeps the explanation
        // from scrolling away on its own.
        expect(
          find
              .ancestor(of: message, matching: find.byType(Scrollable))
              .evaluate()
              .map((element) => element.widget)
              .toList(),
          find
              .ancestor(
                of: _amountInputSurface(),
                matching: find.byType(Scrollable),
              )
              .evaluate()
              .map((element) => element.widget)
              .toList(),
          reason: 'the explanation may not live in the scrolling decoration',
        );
      });
    }

    testWidgets('the validation line is a live region so it is announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAt(
        tester,
        jmaDialog(),
        viewport: const Size(851, 393),
        textScale: 1.0,
      );
      await tester.enterText(find.byType(TextFormField), '106');
      await settleDialogState(tester);

      expect(
        tester.getSemantics(
          find
              .ancestor(
                of: find.text(l10n.jma_voting_max_votes_exceeded(105)),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          isLiveRegion: true,
          label: l10n.jma_voting_max_votes_exceeded(105),
        ),
      );
      handle.dispose();
    });

    // Claim 3: the active button puts a 20 icon and its gap before the label,
    // so the label wraps in a narrower box than the idle one. The budget used
    // to be measured on the idle width, which under-reserves the state the
    // user actually submits from.
    for (final size in <Size>[
      Size(280, 280),
      Size(412, 430),
      Size(851, 393),
      Size(393, 852),
    ]) {
      for (final scale in <double>[1.0, 2.0]) {
        testWidgets(
          'a votable amount keeps the active button inside the capsule on '
          '${size.width.toInt()}x${size.height.toInt()} at ${scale}x',
          (tester) async {
            await pumpAt(tester, jmaDialog(), viewport: size, textScale: scale);
            await tester.enterText(find.byType(TextFormField), '5');
            await settleDialogState(tester);

            expect(
              find.byIcon(Icons.how_to_vote),
              findsOneWidget,
              reason: 'the button has to be in its active state',
            );
            _expectControlsVisibleAtRest(
              tester,
              jmaControls(l10n.label_button_vote),
              'JMA active ${size.width.toInt()}x${size.height.toInt()} '
              '@ ${scale}x',
            );
          },
        );
      }
    }

    // The boundary the review describes: a window whose body clears the idle
    // label but not the active one. Thai and Burmese are the longest vote
    // labels the app ships, and at 280 wide the active box is 79.7 against the
    // idle 105.4 — two extra wrapped lines, 52 logical pixels the old budget
    // never reserved. 320 high is where that difference decided the mode.
    for (final locale in <String, String>{
      'th': AppLocalizationsTh().label_button_vote,
      'my': AppLocalizationsMy().label_button_vote,
    }.entries) {
      testWidgets(
        'the active label in ${locale.key} does not overflow the pinned '
        'layout at the budget boundary',
        (tester) async {
          await pumpAt(
            tester,
            jmaDialog(),
            viewport: const Size(280, 320),
            textScale: 1.0,
            locale: Locale(locale.key),
          );
          await tester.enterText(find.byType(TextFormField), '5');
          await settleDialogState(tester);

          expect(find.byIcon(Icons.how_to_vote), findsOneWidget);
          _expectControlsVisibleAtRest(
            tester,
            jmaControls(locale.value),
            'JMA active ${locale.key} 280x320',
          );
        },
      );
    }

    // The budget is only sound if it is an upper bound on every state the
    // button can render in — idle, active and voting. The shared button is the
    // one whose states can be built directly, without firing a vote.
    for (final scale in <double>[1.0, 2.0]) {
      testWidgets('the submit budget covers every button state at ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(280 * 3, 430 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        late double budget;
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) {
                budget = VotingSubmitButton.preferredHeight(context);
                // The Thai label at 200% makes each button taller than a
                // third of the window, so the harness scrolls rather than
                // reporting its own overflow as a product defect.
                return SingleChildScrollView(
                  child: Column(
                    children: const [
                      VotingSubmitButton(
                        key: Key('idle'),
                        canVote: false,
                        isVoting: false,
                      ),
                      VotingSubmitButton(
                        key: Key('active'),
                        canVote: true,
                        isVoting: false,
                      ),
                      VotingSubmitButton(
                        key: Key('voting'),
                        canVote: true,
                        isVoting: true,
                      ),
                    ],
                  ),
                );
              },
            ),
            locale: const Locale('th'),
            textScaler: TextScaler.linear(scale),
            designSize: kAppDesignSize,
            splitScreenMode: kAppSplitScreenMode,
          ),
        );

        for (final state in <String>['idle', 'active', 'voting']) {
          expect(
            tester.getSize(find.byKey(Key(state))).height,
            lessThanOrEqualTo(budget + 0.5),
            reason: 'the $state button outgrew the height the budget reserved',
          );
        }
      });
    }

    // The band the explanation lives in is a bordered row, not a bare line of
    // text: a 20 icon box on the left, 1 of border on each side. Budgeting the
    // text height alone is not an upper bound on it — a single 1.0x line is
    // 17 against the icon's 20 — and a mode chosen from an under-estimate pins
    // a group the body cannot hold.
    for (final size in <Size>[
      Size(851, 393),
      Size(1194, 834),
      Size(393, 852),
      Size(280, 480),
    ]) {
      for (final locale in <String, AppLocalizations>{
        'ko': AppLocalizationsKo(),
        'th': AppLocalizationsTh(),
        'my': AppLocalizationsMy(),
      }.entries) {
        for (final scale in <double>[1.0, 2.0]) {
          testWidgets(
            'the validation band never outgrows the height it is budgeted on '
            '${size.width.toInt()}x${size.height.toInt()} in ${locale.key} '
            'at ${scale}x',
            (tester) async {
              await pumpAt(
                tester,
                jmaDialog(),
                viewport: size,
                textScale: scale,
                locale: Locale(locale.key),
              );
              await tester.enterText(find.byType(TextFormField), '106');
              await settleDialogState(tester);

              final text = locale.value.jma_voting_max_votes_exceeded(105);
              final message = find.text(text);
              expect(message, findsOneWidget);
              final band = find
                  .ancestor(of: message, matching: find.byType(Container))
                  .first;
              final context = tester.element(find.byType(JmaVotingDialog));

              expect(
                tester.getSize(band).height,
                lessThanOrEqualTo(
                  jmaValidationBandHeight(
                        context,
                        message: text,
                        contentWidth: jmaVoteDialogContentWidth(
                          resolveVoteDialogWidth(),
                        ),
                      ) +
                      0.5,
                ),
                reason:
                    'the band the popup reserves room for is shorter than the '
                    'one it renders',
              );
            },
          );
        }
      }
    }

    // PICNIC-2695: the close X is overlaid on the card, so it wins the hit
    // test over anything the decoration scrolls under it. The balance row ends
    // with a 48 recharge button at the card's right edge, so if the decoration
    // can bring that row up to the card's top the user taps recharge and the
    // popup closes instead, losing the amount they typed.
    for (final entry in <String, Size>{
      'phone landscape': Size(851, 393),
      'flip flex top half': Size(412, 500),
      'portrait phone': Size(393, 852),
    }.entries) {
      testWidgets('the recharge button never sits under the close X on '
          '${entry.key}', (tester) async {
        await pumpAt(
          tester,
          plainDialog(),
          viewport: entry.value,
          textScale: 1.0,
          keyboard: 280,
        );

        final close = find.byKey(kLargePopupTopCloseKey);
        final recharge = find.byType(VotingStarCandyInfo);
        if (close.evaluate().isEmpty || recharge.evaluate().isEmpty) return;

        // The hazard needs the decoration scrolled to its end: that is what
        // lifts the balance row to the card's top edge.
        final scrollable = find.descendant(
          of: find.byType(VotingArtistImage),
          matching: find.byType(Scrollable),
        );
        final decorationScroll = scrollable.evaluate().isNotEmpty
            ? scrollable
            : find.ancestor(
                of: find.byType(VotingArtistImage),
                matching: find.byType(Scrollable),
              );
        if (decorationScroll.evaluate().isNotEmpty) {
          await tester.drag(
            decorationScroll.first,
            const Offset(0, -400),
            warnIfMissed: false,
          );
          await settleDialogState(tester);
        }

        final closeRect = tester.getRect(close);
        final balanceRect = tester.getRect(recharge);
        final overlapsVertically =
            balanceRect.top < closeRect.bottom &&
            balanceRect.bottom > closeRect.top;
        final overlapsHorizontally =
            balanceRect.right > closeRect.left &&
            balanceRect.left < closeRect.right;
        expect(
          overlapsVertically && overlapsHorizontally,
          isFalse,
          reason:
              'balance row $balanceRect runs under the close X $closeRect on '
              '${entry.key} — a recharge tap would close the popup',
        );
      });
    }

    // The consequence of that under-estimate, at the height where it decides
    // the mode: 851x393 in Korean is a single wrapped line, so the band is 3
    // taller than its budget, and a parent right at the boundary pins an
    // action group the body cannot hold. 311 is where this overflowed by
    // 0.668 before the icon box entered the budget; the sweep around it keeps
    // the regression from sliding off a single pixel.
    testWidgets('a short parent at the validation budget boundary never pins '
        'more than it can hold', (tester) async {
      final text = l10n.jma_voting_max_votes_exceeded(105);
      for (var parent = 300.0; parent <= 320.0; parent += 1.0) {
        await pumpAt(
          tester,
          jmaDialog(),
          viewport: const Size(851, 393),
          textScale: 1.0,
          parentHeight: parent,
        );
        await tester.enterText(find.byType(TextFormField), '106');
        await settleDialogState(tester);

        expect(find.text(text), findsOneWidget);
        _expectControlsVisibleAtRest(tester, <String, Finder>{
          ...jmaControls(l10n.label_button_vote),
          'validation': find.text(text),
        }, 'JMA invalid 851x393 in a ${parent.toInt()} high parent');

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    // Claim 3, the other direction: the budget has to describe the state on
    // screen. Measuring the idle button at the *active* label width reserves
    // room the idle button does not use — 52 at 280 wide in Thai — and the
    // popup then gives up its margin and its band order on a first screen
    // whose controls actually fit. Keeping the label's width the same in both
    // states is what makes one budget true for both.
    for (final locale in <String, AppLocalizations>{
      'th': AppLocalizationsTh(),
      'my': AppLocalizationsMy(),
      'ko': AppLocalizationsKo(),
    }.entries) {
      for (final scale in <double>[1.0, 2.0]) {
        testWidgets('the vote button is the same height idle and active in '
            '${locale.key} at ${scale}x', (tester) async {
          await pumpAt(
            tester,
            jmaDialog(),
            viewport: const Size(280, 320),
            textScale: scale,
            locale: Locale(locale.key),
          );
          Finder button() => find
              .ancestor(
                of: find.text(locale.value.label_button_vote),
                matching: find.byType(Container),
              )
              .first;

          final idle = tester.getSize(button()).height;
          await tester.enterText(find.byType(TextFormField), '5');
          await settleDialogState(tester);
          expect(find.byIcon(Icons.how_to_vote), findsOneWidget);

          expect(
            tester.getSize(button()).height,
            closeTo(idle, 0.5),
            reason:
                'the active button changed height, so no single budget can '
                'be true for both states',
          );
        });
      }
    }

    // What the over-reserved idle budget costs on screen: the popup drops to
    // the 8 floor of its margin and lays the artist and the balance out
    // *under* the controls, on a first screen whose idle controls fit with
    // room to spare. Typing a votable amount may not move either.
    for (final locale in <String, AppLocalizations>{
      'th': AppLocalizationsTh(),
      'my': AppLocalizationsMy(),
    }.entries) {
      testWidgets(
        'an idle popup in ${locale.key} keeps its margin and its band order '
        'on 280x320',
        (tester) async {
          await pumpAt(
            tester,
            jmaDialog(),
            viewport: const Size(280, 320),
            textScale: 1.0,
            locale: Locale(locale.key),
          );

          double inset() =>
              tester
                  .widget<AlertDialog>(find.byType(AlertDialog))
                  .insetPadding!
                  .vertical /
              2;
          double badgeTop() =>
              tester.getRect(find.text('Jupiter Music Awards')).top;
          double useAllTop() => tester
              .getRect(
                _nearestGestureTarget(
                  find.byIcon(Icons.check_box_outline_blank),
                ),
              )
              .top;

          final idleInset = inset();
          expect(
            idleInset,
            greaterThan(kVoteDialogMinimumVerticalInset),
            reason:
                'the idle controls fit, so the popup may not fall back to the '
                'smallest margin it has',
          );
          expect(
            badgeTop(),
            lessThan(useAllTop()),
            reason: 'the decoration belongs above the controls while they fit',
          );
          _expectControlsVisibleAtRest(
            tester,
            jmaControls(locale.value.label_button_vote),
            'JMA idle ${locale.key} 280x320',
          );

          await tester.enterText(find.byType(TextFormField), '5');
          await settleDialogState(tester);

          expect(find.byIcon(Icons.how_to_vote), findsOneWidget);
          expect(
            inset(),
            closeTo(idleInset, 0.5),
            reason: 'the margin jumped when the amount became votable',
          );
          expect(
            badgeTop(),
            lessThan(useAllTop()),
            reason: 'the bands reordered when the amount became votable',
          );
          _expectControlsVisibleAtRest(
            tester,
            jmaControls(locale.value.label_button_vote),
            'JMA active ${locale.key} 280x320',
          );
        },
      );
    }

    testWidgets('expanding the policy panel does not push the controls out', (
      tester,
    ) async {
      await pumpAt(
        tester,
        jmaDialog(),
        viewport: const Size(851, 393),
        textScale: 1.3,
      );
      await tester.tap(find.text(l10n.label_button_view_policy));
      await settleDialogState(tester);

      _expectControlsVisibleAtRest(
        tester,
        jmaControls(l10n.label_button_vote),
        'JMA policy expanded',
      );
    });

    // An in-flight IME composition is state the popup must not drop when the
    // layout mode changes under it. The amount formatter deliberately
    // normalises the selection to a collapsed caret after the digits, so that
    // — not the incoming range — is what has to hold.
    testWidgets('an IME composition survives a rotation', (tester) async {
      await pumpAt(
        tester,
        jmaDialog(),
        viewport: const Size(393, 852),
        textScale: 1.0,
      );
      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '123',
          selection: TextSelection(baseOffset: 1, extentOffset: 3),
          composing: TextRange(start: 1, end: 3),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      tester.view.physicalSize = const Size(852 * 3, 393 * 3);
      for (var i = 0; i < 3; i += 1) {
        await tester.pump(const Duration(milliseconds: 400));
      }

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '123');
      expect(field.controller?.selection.isCollapsed, isTrue);
      expect(field.controller?.selection.baseOffset, 3);
      _expectControlsVisibleAtRest(
        tester,
        jmaControls(l10n.label_button_vote),
        'JMA after rotation with a selection',
      );
    });
  });
}
