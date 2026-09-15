import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_layout.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/load_test_fonts.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/picnic_ui_test_environment.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

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
  snapshotAt: DateTime.utc(2026, 9, 15),
);

const _viewports = <String, Size>{
  'phone landscape': Size(851, 393),
  'phone landscape wide': Size(926, 428),
  'iphone landscape': Size(844, 390),
  'tablet landscape': Size(1194, 834),
  'flip flex top half': Size(412, 500),
  'tablet split third': Size(375, 834),
  'narrow window': Size(280, 480),
  'narrow short window': Size(280, 280),
};

const _columnViewports = <Size>[Size(851, 393), Size(926, 428), Size(844, 390)];

const _textScales = <double>[1.0, 1.3, 2.0];
const _locales = <Locale>[
  Locale('ko'),
  Locale('en'),
  Locale('th'),
  Locale('my'),
];
const _keyboards = <double>[0, 280];

bool _expectsColumns({
  required Size viewport,
  required Locale locale,
  required double textScale,
  required double keyboard,
}) {
  if (keyboard > 0 || !_columnViewports.contains(viewport)) return false;

  // At Thai 2.0x the measured stacked action column is 288.56px tall. The
  // 851x393 and 844x390 hidden-close bodies cannot hold that plus their
  // radius-safe insets, so the actual-height condition intentionally rejects
  // those two candidates. The 926x428 body can still use columns.
  //
  // PICNIC-2700 moved this number and moved it back, so the two changes it
  // made are a pair and neither reverts alone. Measured at 926x428, Thai 2.0x:
  //
  //   PICNIC-2697, uncapped label   stacked column 340.56, popup height > 380
  //   PICNIC-2700 code only         stacked column 340.56, popup height = 380
  //   PICNIC-2700 code + โหวต      stacked column 288.56, popup height = 380
  //
  // The popup height moved because the route only gives up its preferred 24
  // inset while the one-column body is pressing on it. Capping the one-column
  // submit label at two lines relieved that press, the margin came back, and
  // the 340.56 column no longer fit — so the code change alone puts 926x428 on
  // the one-column path. Shortening the label then took 52px off the stacked
  // column itself and it fits again. Revert the shortened label without the
  // cap, or the cap without the label, and this premise has to move with it.
  return !(locale.languageCode == 'th' &&
      textScale == 2 &&
      viewport != const Size(926, 428));
}

Finder _capsuleCard() => find
    .descendant(
      of: find.byType(LargePopupWidget),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.clipBehavior == Clip.antiAlias,
      ),
    )
    .first;

/// The mint pill itself — the bordered box inside the balance row, not the
/// 48 tap area around it.
Finder _rechargePill() => find
    .descendant(
      of: find.byType(VotingStarCandyInfo),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).border != null,
      ),
    )
    .first;

/// Lets a test move `viewInsets` after the popup is already open.
///
/// The matrix above opens each combination with its inset already applied,
/// which never exercises the frames where the inset is *changing* — and that
/// is where `Dialog`'s `AnimatedPadding` hands the body less than the budget
/// the columns were selected against.
class _InsetHost extends StatefulWidget {
  const _InsetHost({
    super.key,
    required this.initialInset,
    required this.child,
  });

  final double initialInset;
  final Widget child;

  @override
  State<_InsetHost> createState() => _InsetHostState();
}

class _InsetHostState extends State<_InsetHost> {
  late double _inset = widget.initialInset;

  void setInset(double value) => setState(() => _inset = value);

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(viewInsets: EdgeInsets.only(bottom: _inset)),
    child: widget.child,
  );
}

Finder _amountInputSurface() => find
    .ancestor(
      of: find.byType(TextFormField),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    )
    .first;

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
    if (onLeft ? corner.dx >= cx : corner.dx <= cx) continue;
    if (onTop ? corner.dy >= cy : corner.dy <= cy) continue;
    final distance = math.sqrt(
      math.pow(corner.dx - cx, 2) + math.pow(corner.dy - cy, 2),
    );
    worst = math.max(worst, distance - radius);
  }
  return worst;
}

void _expectContained(Rect outer, Rect inner, String reason) {
  expect(inner.left, greaterThanOrEqualTo(outer.left - 0.5), reason: reason);
  expect(inner.top, greaterThanOrEqualTo(outer.top - 0.5), reason: reason);
  expect(inner.right, lessThanOrEqualTo(outer.right + 0.5), reason: reason);
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom + 0.5), reason: reason);
}

Rect _bounds(Iterable<Rect> rects) =>
    rects.reduce((a, b) => a.expandToInclude(b));

void _expectColumnCoreVisible(WidgetTester tester, String label) {
  final core = <String, Finder>{
    'portrait': find.byType(VotingArtistImage),
    'name': find.byType(VotingMemberInfo),
    'balance': find.byType(VotingStarCandyInfo),
    'use all': find.byType(VotingCheckAllOption),
    'amount input': _amountInputSurface(),
    'submit': find.byType(VotingSubmitButton),
  };
  final capsule = tester.getRect(_capsuleCard());
  final rects = <String, Rect>{};

  for (final scrollable in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    expect(
      scrollable.position.pixels,
      closeTo(0, 0.01),
      reason: '$label: the two-column first frame must stay at offset zero',
    );
  }

  for (final entry in core.entries) {
    final reason = '$label / ${entry.key}';
    expect(entry.value, findsOneWidget, reason: reason);
    final rect = tester.getRect(entry.value);
    rects[entry.key] = rect;
    expect(rect.width, greaterThan(0), reason: reason);
    expect(rect.height, greaterThan(0), reason: reason);
    _expectContained(capsule, rect, reason);
    expect(
      _capsuleCornerOverhang(tester, rect),
      lessThanOrEqualTo(0.5),
      reason: '$reason is clipped by the capsule RRect',
    );
    for (final ancestor
        in find
            .ancestor(of: entry.value, matching: find.byType(Scrollable))
            .evaluate()) {
      _expectContained(
        tester.getRect(
          find.byElementPredicate((element) => element == ancestor),
        ),
        rect,
        '$reason inside every scrolling viewport',
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

  final left = _bounds([rects['portrait']!, rects['name']!, rects['balance']!]);
  final right = _bounds([
    rects['use all']!,
    rects['amount input']!,
    rects['submit']!,
  ]);
  expect(left.right, lessThanOrEqualTo(right.left - 15.5), reason: label);
}

void _expectSingleColumnContract(
  WidgetTester tester, {
  required bool keyboardVisible,
  required String label,
}) {
  final capsule = tester.getRect(_capsuleCard());
  expect(
    capsule.width,
    lessThanOrEqualTo(kVoteDialogMaxWidth + 0.5),
    reason: '$label: the one-column cap must remain 560',
  );

  for (final scrollable in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    expect(
      scrollable.position.pixels,
      closeTo(0, 0.01),
      reason: '$label: the existing path opens at offset zero',
    );
  }

  final controls = <String, Finder>{
    'use all': find.byType(VotingCheckAllOption),
    'amount input': _amountInputSurface(),
    'submit': find.byType(VotingSubmitButton),
  };
  for (final entry in controls.entries) {
    final reason = '$label / ${entry.key}';
    expect(entry.value, findsOneWidget, reason: reason);
    final rect = tester.getRect(entry.value);
    final scrollAncestors = find.ancestor(
      of: entry.value,
      matching: find.byType(Scrollable),
    );
    final insideCapsule =
        rect.left >= capsule.left - 0.5 &&
        rect.top >= capsule.top - 0.5 &&
        rect.right <= capsule.right + 0.5 &&
        rect.bottom <= capsule.bottom + 0.5;
    final insideScrollViewports = scrollAncestors.evaluate().every((element) {
      final viewport = tester.getRect(
        find.byElementPredicate((candidate) => candidate == element),
      );
      return rect.left >= viewport.left - 0.5 &&
          rect.top >= viewport.top - 0.5 &&
          rect.right <= viewport.right + 0.5 &&
          rect.bottom <= viewport.bottom + 0.5;
    });
    if (insideCapsule && insideScrollViewports) {
      expect(
        _capsuleCornerOverhang(tester, rect),
        lessThanOrEqualTo(0.5),
        reason: '$reason is RRect-clipped',
      );
      expect(entry.value.hitTestable(), findsOneWidget, reason: reason);
    } else {
      expect(
        scrollAncestors,
        findsWidgets,
        reason:
            '$reason must remain reachable through the legacy '
            '${keyboardVisible ? "keyboard" : "all-scroll"} path',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VoteModel voteModel;
  late VoteItemModel voteItemModel;

  setUpAll(() async {
    await loadTestFonts();
    await loadPicnicUiTestFontWeights();
  });

  setUp(() {
    initTestColors();
    voteModel = MockData.vote();
    voteItemModel = MockData.voteItem();
    setupMockSupabase(<String, dynamic>{});
  });

  tearDown(tearDownMockSupabase);

  Future<void> pumpAt(
    WidgetTester tester, {
    required Size viewport,
    required Locale locale,
    required double textScale,
    required double keyboard,
    Widget? dialog,
    WalletSummaryModel? wallet,
  }) async {
    tester.view.physicalSize = Size(viewport.width * 3, viewport.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(suppressImageErrors());

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboard)),
            child:
                dialog ??
                VotingDialog(
                  voteModel: voteModel,
                  voteItemModel: voteItemModel,
                  portalType: VotePortal.vote,
                ),
          ),
        ),
        locale: locale,
        textScaler: TextScaler.linear(textScale),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        userProfile: MockData.userProfile(starCandy: 500, starCandyBonus: 50),
        extraOverrides: [
          walletSummaryProvider.overrideWith(
            () => _WalletSummaryOverride(wallet ?? _wallet),
          ),
        ],
      ),
    );
    await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('PICNIC-2697 conditional columns matrix', () {
    for (final viewportEntry in _viewports.entries) {
      for (final scale in _textScales) {
        for (final locale in _locales) {
          for (final keyboard in _keyboards) {
            final expectsColumns = _expectsColumns(
              viewport: viewportEntry.value,
              locale: locale,
              textScale: scale,
              keyboard: keyboard,
            );
            final label =
                '${viewportEntry.key} ${locale.languageCode} ${scale}x K${keyboard.toInt()}';
            testWidgets('$label keeps the resolved layout contract', (
              tester,
            ) async {
              await pumpAt(
                tester,
                viewport: viewportEntry.value,
                locale: locale,
                textScale: scale,
                keyboard: keyboard,
              );
              expect(tester.takeException(), isNull, reason: label);

              final width = tester.getSize(_capsuleCard()).width;
              if (expectsColumns) {
                expect(
                  width,
                  greaterThan(kVoteDialogMaxWidth + 0.5),
                  reason:
                      '$label: the pressured one-column layout should split',
                );
                expect(
                  width,
                  lessThanOrEqualTo(800.5),
                  reason:
                      '$label: only the two-column candidate may use cap 800',
                );
                _expectColumnCoreVisible(tester, label);
              } else {
                _expectSingleColumnContract(
                  tester,
                  keyboardVisible: keyboard > 0,
                  label: label,
                );
              }
            });
          }
        }
      }
    }
  });

  group('PICNIC-2697 recharge pill measurement contract', () {
    testWidgets('column minimum width includes the rendered pill border', (
      tester,
    ) async {
      await pumpAt(
        tester,
        viewport: const Size(393, 852),
        locale: const Locale('my'),
        textScale: 2,
        keyboard: 0,
        dialog: Builder(
          builder: (context) => Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: VotingStarCandyInfo.columnMinimumWidth(context),
                  child: VotingStarCandyInfo(
                    myStarCandy: BigInt.from(550),
                    onRecharge: () {},
                    columns: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(VotingStarCandyInfo));
      final label = find.text(
        AppLocalizations.of(context).label_button_recharge,
      );
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason:
            'the minimum-width measurement must reserve both 1px border edges',
      );
    });

    testWidgets('column preferred height includes the rendered pill border', (
      tester,
    ) async {
      await pumpAt(
        tester,
        viewport: const Size(393, 852),
        locale: const Locale('my'),
        textScale: 3,
        keyboard: 0,
        dialog: Builder(
          builder: (context) => Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: VotingStarCandyInfo.columnMinimumWidth(context),
                  child: VotingStarCandyInfo(
                    myStarCandy: BigInt.from(550),
                    onRecharge: () {},
                    columns: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final info = find.byType(VotingStarCandyInfo);
      final width = tester.getSize(info).width;
      final measured = VotingStarCandyInfo.preferredHeight(
        tester.element(info),
        maxWidth: width,
        columns: true,
      );
      expect(
        measured,
        closeTo(tester.getSize(info).height, 0.1),
        reason:
            'the pre-layout height must include both 1px border edges rendered '
            'by the recharge pill',
      );
    });
  });

  group('PICNIC-2697 lazy column width measurement', () {
    testWidgets('keyboard fallback skips both column width measurements', (
      tester,
    ) async {
      var leftCalls = 0;
      var rightCalls = 0;

      final layout = resolveVoteDialogColumnsLayout(
        routeAvailableWidth: 800,
        popupAvailableHeight: 300,
        singleEssentialHeight: 200,
        singleDecorationComfortHeight: 200,
        singleTailLogoHeight: 40,
        singleHorizontalContentInset: 24,
        leftMinimumWidth: () {
          leftCalls += 1;
          return 200;
        },
        rightMinimumWidth: () {
          rightCalls += 1;
          return 300;
        },
        leftMinimumHeightForWidth: (_) => throw TestFailure(
          'keyboard fallback must not measure the left column height',
        ),
        rightMinimumHeightForWidth: (_) => throw TestFailure(
          'keyboard fallback must not measure the right column height',
        ),
        keyboardVisible: true,
      );

      expect(layout, isNull);
      expect(leftCalls, 0);
      expect(rightCalls, 0);
    });

    testWidgets('comfortable one-column layout skips both width measurements', (
      tester,
    ) async {
      await pumpAt(
        tester,
        viewport: const Size(851, 393),
        locale: const Locale('ko'),
        textScale: 1,
        keyboard: 0,
        dialog: const SizedBox(key: Key('screen-util-context')),
      );
      var leftCalls = 0;
      var rightCalls = 0;

      final layout = resolveVoteDialogColumnsLayout(
        routeAvailableWidth: 800,
        popupAvailableHeight: 600,
        singleEssentialHeight: 100,
        singleDecorationComfortHeight: 100,
        singleTailLogoHeight: 40,
        singleHorizontalContentInset: 24,
        leftMinimumWidth: () {
          leftCalls += 1;
          return 200;
        },
        rightMinimumWidth: () {
          rightCalls += 1;
          return 300;
        },
        leftMinimumHeightForWidth: (_) => throw TestFailure(
          'comfortable one-column layout must not measure the left height',
        ),
        rightMinimumHeightForWidth: (_) => throw TestFailure(
          'comfortable one-column layout must not measure the right height',
        ),
        keyboardVisible: false,
      );

      expect(layout, isNull);
      expect(leftCalls, 0);
      expect(rightCalls, 0);
    });

    testWidgets('two-column resolution measures each minimum width once', (
      tester,
    ) async {
      await pumpAt(
        tester,
        viewport: const Size(851, 393),
        locale: const Locale('ko'),
        textScale: 1,
        keyboard: 0,
        dialog: const SizedBox(key: Key('screen-util-columns-context')),
      );
      var leftCalls = 0;
      var rightCalls = 0;

      final layout = resolveVoteDialogColumnsLayout(
        routeAvailableWidth: 800,
        popupAvailableHeight: 400,
        singleEssentialHeight: 300,
        singleDecorationComfortHeight: 200,
        singleTailLogoHeight: 100,
        singleHorizontalContentInset: 24,
        leftMinimumWidth: () {
          leftCalls += 1;
          return 200;
        },
        rightMinimumWidth: () {
          rightCalls += 1;
          return 300;
        },
        leftMinimumHeightForWidth: (_) => 100,
        rightMinimumHeightForWidth: (_) => 100,
        keyboardVisible: false,
      );

      expect(layout, isNotNull);
      expect(leftCalls, 1);
      expect(rightCalls, 1);
    });
  });

  testWidgets(
    'PICNIC-2697 Burmese 2.0x ignores the input hint when selecting columns',
    (tester) async {
      await pumpAt(
        tester,
        viewport: const Size(851, 393),
        locale: const Locale('my'),
        textScale: 2,
        keyboard: 0,
      );

      expect(
        tester.getSize(_capsuleCard()).width,
        greaterThan(kVoteDialogMaxWidth + 0.5),
      );
      _expectColumnCoreVisible(tester, 'my 2.0x hint-independent minimum');
    },
  );

  testWidgets(
    'PICNIC-2697 empty valid and error states keep columns and card margins',
    (tester) async {
      await pumpAt(
        tester,
        viewport: const Size(851, 393),
        locale: const Locale('my'),
        textScale: 2,
        keyboard: 0,
      );

      Rect card() => tester.getRect(_capsuleCard());
      Rect horizontalBands() => _bounds([
        tester.getRect(find.byType(VotingArtistImage)),
        tester.getRect(find.byType(VotingMemberInfo)),
        tester.getRect(find.byType(VotingStarCandyInfo)),
        tester.getRect(find.byType(VotingCheckAllOption)),
        tester.getRect(_amountInputSurface()),
        tester.getRect(find.byType(VotingSubmitButton)),
      ]);

      final emptyCard = card();
      final emptyBands = horizontalBands();
      _expectColumnCoreVisible(tester, 'empty');

      await tester.enterText(find.byType(TextFormField), '5');
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
      expect(card(), rectMoreOrLessEquals(emptyCard, epsilon: 0.5));
      expect(horizontalBands().left, closeTo(emptyBands.left, 0.5));
      expect(horizontalBands().right, closeTo(emptyBands.right, 0.5));
      _expectColumnCoreVisible(tester, 'valid');

      await tester.enterText(find.byType(TextFormField), '999999999');
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
      expect(card(), rectMoreOrLessEquals(emptyCard, epsilon: 0.5));
      expect(horizontalBands().left, closeTo(emptyBands.left, 0.5));
      expect(horizontalBands().right, closeTo(emptyBands.right, 0.5));
      _expectColumnCoreVisible(tester, 'error');
    },
  );

  testWidgets('PICNIC-2697 top close stays outside the two-column capsule', (
    tester,
  ) async {
    await pumpAt(
      tester,
      viewport: const Size(851, 393),
      locale: const Locale('ko'),
      textScale: 1,
      keyboard: 0,
    );

    final close = tester.getRect(find.byKey(kLargePopupTopCloseKey));
    final capsule = tester.getRect(_capsuleCard());
    final recharge = tester.getRect(
      find
          .descendant(
            of: find.byType(VotingStarCandyInfo),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(close.width, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
    expect(close.height, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
    expect(close.bottom, lessThanOrEqualTo(capsule.top + 0.5));
    expect(close.overlaps(recharge), isFalse);
    expect(find.byKey(kLargePopupTopCloseKey).hitTestable(), findsOneWidget);
    _expectColumnCoreVisible(tester, 'visible top close');
  });

  testWidgets(
    'PICNIC-2697 columns use the hidden close chrome when only that budget fits',
    (tester) async {
      await pumpAt(
        tester,
        viewport: const Size(851, 270),
        locale: const Locale('ko'),
        textScale: 1,
        keyboard: 0,
      );

      expect(find.byKey(kLargePopupTopCloseKey), findsNothing);
      expect(
        tester.getSize(_capsuleCard()).width,
        greaterThan(kVoteDialogMaxWidth + 0.5),
      );
      _expectColumnCoreVisible(tester, 'hidden top close');
    },
  );

  testWidgets(
    'PICNIC-2697 an unexpectedly long balance cannot overflow the left column',
    (tester) async {
      await pumpAt(
        tester,
        viewport: const Size(851, 393),
        locale: const Locale('ko'),
        textScale: 1,
        keyboard: 0,
        wallet: WalletSummaryModel(
          contractVersion: 'wallet.v1',
          star: BigInt.parse('999999999999999999999999999999'),
          bonus: BigInt.zero,
          cotton: BigInt.zero,
          cottonExpiringAmount: BigInt.zero,
          cottonNextExpiresAt: null,
          snapshotAt: DateTime.utc(2026, 9, 15),
        ),
      );

      expect(tester.takeException(), isNull);
      _expectColumnCoreVisible(tester, 'long balance');
    },
  );

  group('PICNIC-2697 inset and size transitions', () {
    // `Dialog` applies `viewInsets + insetPadding` through an `AnimatedPadding`
    // with a 100ms curve, so for the frames right after the keyboard closes or
    // the window changes, the height the route actually hands the body is
    // *smaller* than the budget the two-column candidate was resolved against.
    // A body pinned to that budget overflowed the popup's own Column by up to
    // 248px. None of the matrix combinations can see it: they open with a
    // fixed inset and a single `pump(1s)` lands after the curve has settled.
    Future<GlobalKey<_InsetHostState>> openWithInset(
      WidgetTester tester, {
      required Size viewport,
      required double inset,
    }) async {
      tester.view.physicalSize = Size(viewport.width * 3, viewport.height * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(suppressImageErrors());

      final host = GlobalKey<_InsetHostState>();
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          _InsetHost(
            key: host,
            initialInset: inset,
            child: VotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          ),
          locale: const Locale('ko'),
          textScaler: TextScaler.linear(1),
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
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
      return host;
    }

    // One frame at a time, so the inset animation is observed while it runs.
    // `pumpAndIgnoreErrors` rethrows everything that is not an image/asset
    // failure, so an overflow on any of these frames fails the test.
    Future<void> stepFrames(WidgetTester tester, {int frames = 12}) async {
      for (var frame = 0; frame < frames; frame += 1) {
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 16));
      }
    }

    testWidgets('a keyboard dismissed in one step keeps the capsule inside '
        'the route', (tester) async {
      final host = await openWithInset(
        tester,
        viewport: const Size(851, 393),
        inset: 280,
      );
      expect(
        find.byType(VoteDialogColumns),
        findsNothing,
        reason: 'the keyboard must hold the one-column fallback',
      );

      host.currentState!.setInset(0);
      await stepFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(VoteDialogColumns), findsOneWidget);
      _expectColumnCoreVisible(tester, 'after a one-step keyboard dismissal');
    });

    testWidgets('a keyboard dismissed over several frames keeps the capsule '
        'inside the route', (tester) async {
      final host = await openWithInset(
        tester,
        viewport: const Size(851, 393),
        inset: 280,
      );

      for (final inset in const <double>[220, 160, 100, 40, 0]) {
        host.currentState!.setInset(inset);
        await stepFrames(tester, frames: 2);
      }
      await stepFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(VoteDialogColumns), findsOneWidget);
      _expectColumnCoreVisible(tester, 'after a gradual keyboard dismissal');
    });

    testWidgets('rotating into a two-column viewport keeps the capsule, amount '
        'and focus', (tester) async {
      final host = await openWithInset(
        tester,
        viewport: const Size(393, 852),
        inset: 0,
      );
      expect(
        find.byType(VoteDialogColumns),
        findsNothing,
        reason: 'a portrait phone stays one-column',
      );

      await tester.showKeyboard(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '123');
      await pumpAndIgnoreErrors(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
        isTrue,
      );

      tester.view.physicalSize = const Size(851 * 3, 393 * 3);
      host.currentState!.setInset(0);
      await stepFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(VoteDialogColumns), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '123');
      expect(field.focusNode?.hasFocus, isTrue);
      _expectColumnCoreVisible(
        tester,
        'after a portrait to landscape rotation',
      );
    });
  });

  group('PICNIC-2697 the one-column recharge pill keeps its content width', () {
    const viewports = <Size>[Size(393, 852), Size(375, 812), Size(412, 915)];
    const locales = <Locale>[
      Locale('ko'),
      Locale('en'),
      Locale('th'),
      Locale('my'),
    ];

    for (final viewport in viewports) {
      for (final locale in locales) {
        for (final textScale in _textScales) {
          testWidgets('${viewport.width.toInt()}x${viewport.height.toInt()} '
              '${locale.languageCode} ${textScale}x resolves pill width from '
              'content and the amount floor', (tester) async {
            await pumpAt(
              tester,
              viewport: viewport,
              locale: locale,
              textScale: textScale,
              keyboard: 0,
            );
            expect(
              find.byType(VoteDialogColumns),
              findsNothing,
              reason: '$viewport must stay one-column',
            );

            final context = tester.element(find.byType(VotingStarCandyInfo));
            final contentWidth = VotingStarCandyInfo.rechargeContentWidth(
              context,
            );
            final amountMinimumWidth = VotingStarCandyInfo.amountMinimumWidth(
              context,
            );
            final row = tester.getRect(find.byType(VotingStarCandyInfo));
            final pill = tester.getRect(_rechargePill());
            final room =
                row.width - PicnicUi.horizontal(32) - PicnicUi.horizontal(4);

            expect(tester.takeException(), isNull);
            // The pill never grows beyond content merely to consume a flex
            // share, which is the original B2 regression.
            expect(pill.width, lessThanOrEqualTo(contentWidth + 1));
            // Content keeps at least the available half share when it needs
            // it, so a long locale is not collapsed below that floor.
            expect(
              pill.width,
              greaterThanOrEqualTo(math.min(contentWidth, room / 2) - 1),
            );
            // The pill always remains contained by the balance row.
            expect(pill.width, lessThanOrEqualTo(room + 0.5));
            if (pill.width < contentWidth - 1 &&
                amountMinimumWidth <= room / 2) {
              // Yielding is justified only when it buys the fixed balance
              // fixture its minimum readable slot. When that slot and the
              // pill's half-share floor cannot both fit, the pill stops at
              // its floor and the amount necessarily gets less.
              expect(
                room - pill.width,
                greaterThanOrEqualTo(amountMinimumWidth - 1),
              );
            }
            // When the row can fit both measured contents, the pill must keep
            // its content width. Properties 1–4 alone also accepted the old
            // half-share clamp, so this is what makes that regression RED.
            if (contentWidth + amountMinimumWidth <= room + 0.5) {
              expect(pill.width, closeTo(contentWidth, 1.0));
            }
            expect(
              pill.right,
              closeTo(row.right, 0.5),
              reason: '$viewport ${locale.languageCode} ${textScale}x',
            );
          });
        }
      }
    }
  });

  group('PICNIC-2697 a squeezed one-column pill shares scarce room', () {
    for (final viewport in const <Size>[Size(851, 393), Size(844, 390)]) {
      for (final locale in const <Locale>[Locale('th'), Locale('my')]) {
        testWidgets('${viewport.width.toInt()}x${viewport.height.toInt()} '
            '${locale.languageCode} 2.0x stays inside the row', (tester) async {
          await pumpAt(
            tester,
            viewport: viewport,
            locale: locale,
            textScale: 2,
            keyboard: 0,
            dialog: Builder(
              builder: (context) {
                final oneColumnRowWidth =
                    resolveVoteDialogWidth() -
                    largePopupCardBorderWidth() * 2 -
                    voteDialogCardExtent(24) * 2;
                return Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: oneColumnRowWidth,
                        child: VotingStarCandyInfo(
                          myStarCandy: BigInt.from(550),
                          onRecharge: () {},
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );

          final context = tester.element(find.byType(VotingStarCandyInfo));
          final row = tester.getRect(find.byType(VotingStarCandyInfo));
          final pill = tester.getRect(_rechargePill());
          final contentWidth = VotingStarCandyInfo.rechargeContentWidth(
            context,
          );
          final amountMinimumWidth = VotingStarCandyInfo.amountMinimumWidth(
            context,
          );
          final room =
              row.width - PicnicUi.horizontal(32) - PicnicUi.horizontal(4);
          final expectedWidth = math.min(
            contentWidth,
            math.max(room / 2, room - amountMinimumWidth),
          );

          expect(tester.takeException(), isNull);
          expect(
            contentWidth + amountMinimumWidth,
            greaterThan(room),
            reason: 'this probe must exercise the scarce-room branch',
          );
          expect(pill.width, closeTo(expectedWidth, 1.0));
          expect(pill.width, greaterThanOrEqualTo(room / 2 - 0.5));
          expect(pill.left, greaterThanOrEqualTo(row.left - 0.5));
          expect(pill.right, lessThanOrEqualTo(row.right + 0.5));
        });
      }
    }
  });

  testWidgets(
    'PICNIC-2697 the two-column recharge pill keeps its 48 tap target',
    (tester) async {
      await pumpAt(
        tester,
        viewport: const Size(851, 393),
        locale: const Locale('ko'),
        textScale: 1,
        keyboard: 0,
      );
      expect(find.byType(VoteDialogColumns), findsOneWidget);

      final target = tester.getRect(
        find
            .descendant(
              of: find.byType(VotingStarCandyInfo),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      expect(target.height, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
      expect(target.width, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
      expect(tester.getRect(_rechargePill()).height, greaterThanOrEqualTo(32));
    },
  );

  testWidgets('PICNIC-2697 JMA stays on the legacy 560-wide path', (
    tester,
  ) async {
    for (final locale in _locales) {
      for (final scale in _textScales) {
        for (final keyboard in _keyboards) {
          await pumpAt(
            tester,
            viewport: const Size(851, 393),
            locale: locale,
            textScale: scale,
            keyboard: keyboard,
            dialog: JmaVotingDialog(
              voteModel: voteModel,
              voteItemModel: voteItemModel,
              portalType: VotePortal.vote,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(_capsuleCard()).width,
            lessThanOrEqualTo(kVoteDialogMaxWidth + 0.5),
            reason: 'JMA ${locale.languageCode} ${scale}x K${keyboard.toInt()}',
          );
        }
      }
    }
  });
}
