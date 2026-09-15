import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
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
/// Every case here is keyboard-free (`viewInsets.bottom == 0`), because the bug
/// reproduces with no keyboard at all: decoration sized off the *width* scale
/// eats the vertical budget and pushes the controls below the fold.

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
            data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
            child: dialog,
          ),
        ),
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

          _expectControlsVisibleAtRest(tester, <String, Finder>{
            'amount input': _amountInputSurface(),
            'use all': find.byType(VotingCheckAllOption),
            'submit': find.byType(VotingSubmitButton),
          }, '${viewport.key} @ ${scale}x');
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

          _expectControlsVisibleAtRest(tester, <String, Finder>{
            'amount input': _amountInputSurface(),
            'use all': _nearestGestureTarget(
              find.byIcon(Icons.check_box_outline_blank),
            ),
            'submit': _nearestGestureTarget(find.text(l10n.label_button_vote)),
          }, 'JMA ${viewport.key} @ ${scale}x');
        });
      }
    }
  });
}
