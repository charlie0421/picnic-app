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
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_layout.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';

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

// vi, fil and es are here on purpose: they are the real-font labels the fit
// shrinks most. th and my fall back to a box font in tests (only Pretendard is
// loaded), so their widths are overestimates — useful as stress, not as truth.
const _locales = <Locale>[
  Locale('ko'),
  Locale('en'),
  Locale('th'),
  Locale('my'),
  Locale('ja'),
  Locale('zh'),
  Locale('id'),
  Locale('vi'),
  Locale('fil'),
  Locale('es'),
];
// 2.6 is past the platform maximum; it is where the fit does most of its work.
const _textScales = <double>[1.0, 1.3, 2.0, 2.6];

/// Whether the label inside [button] is actually painted.
///
/// Every geometry assertion in this file still passes on a label that is laid
/// out but never drawn — Visibility(maintainSize) keeps the size and the
/// finders and only drops the paint. So the flag itself has to be asserted.
bool _labelIsPainted(WidgetTester tester, Finder button) => tester
    .widget<Visibility>(
      find.descendant(of: button, matching: find.byType(Visibility)),
    )
    .visible;

Finder _amountInputSurface() => find
    .ancestor(
      of: find.byType(TextFormField),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    )
    .first;

Finder _capsuleCard() => find
    .descendant(
      of: find.byType(LargePopupWidget),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.clipBehavior == Clip.antiAlias,
      ),
    )
    .first;

Finder _submitLabel(String text) => find.descendant(
  of: find.byType(VotingSubmitButton),
  matching: find.text(text),
);

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

void _expectOneRenderedLine(RenderParagraph paragraph, String reason) {
  expect(
    paragraph.size.height,
    lessThanOrEqualTo(paragraph.preferredLineHeight + 0.5),
    reason: reason,
  );
  expect(paragraph.didExceedMaxLines, isFalse, reason: '$reason (ellipsized)');
}

/// The label as it is *drawn*: inside the button on both sides, whatever scale
/// the fit applied. getRect carries the transform, so a label that was laid out
/// wider than the button but scaled to fit still has to land inside it.
void _expectLabelDrawnInsideButton(
  WidgetTester tester,
  Finder label,
  Finder button,
  String reason,
) {
  final drawn = tester.getRect(label);
  final box = tester.getRect(button).inflate(0.5);
  expect(
    drawn.left >= box.left && drawn.right <= box.right,
    isTrue,
    reason: '$reason: label $drawn is not inside button $box',
  );
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

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Locale locale,
    required double textScale,
    Size viewport = const Size(280, 480),
    double keyboard = 0,
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
            child: VotingDialog(
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
            () => _WalletSummaryOverride(_wallet),
          ),
        ],
      ),
    );
    await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  // PICNIC-2700 first widened this button to the input's width. The design
  // review (docs/operations/vote-ui-design-options) chose to keep the design's
  // fixed pill instead and let a long label shrink to fit on one line: 94% of
  // active users (ko, en) see the original design, the button no longer
  // resizes while the keyboard animates, and no label is ever ellipsized.
  group('PICNIC-2700 one-column submit button keeps its design width', () {
    for (final locale in _locales) {
      for (final textScale in _textScales) {
        final label = '${locale.languageCode} ${textScale}x';

        testWidgets('$label is a fixed pill with a one-line fitted label', (
          tester,
        ) async {
          await pumpDialog(tester, locale: locale, textScale: textScale);

          expect(
            find.byType(VoteDialogColumns),
            findsNothing,
            reason: '$label must exercise the one-column production path',
          );
          final submit = find.byType(VotingSubmitButton);
          final submitSize = tester.getSize(submit);
          final inputSize = tester.getSize(_amountInputSurface());
          final l10n = AppLocalizations.of(tester.element(submit));
          final labelFinder = _submitLabel(l10n.label_button_vote);
          final paragraph = tester.renderObject<RenderParagraph>(labelFinder);

          expect(
            submitSize.width,
            closeTo(VotingSubmitButton.preferredWidth(), 0.5),
            reason: '$label: the button is the design pill, not a full bar',
          );
          expect(
            submitSize.width,
            lessThanOrEqualTo(inputSize.width + 0.5),
            reason: '$label: the vote button must stay within the action band',
          );
          expect(
            _capsuleCornerOverhang(tester, tester.getRect(submit)),
            lessThanOrEqualTo(0.5),
            reason: '$label: the button must stay inside the capsule arc',
          );
          _expectOneRenderedLine(
            paragraph,
            '$label: the label is one line and never ellipsized',
          );
          _expectLabelDrawnInsideButton(tester, labelFinder, submit, label);
          expect(
            _labelIsPainted(tester, submit),
            isTrue,
            reason: '$label: an idle button has to show its label',
          );
          expect(
            submitSize.height,
            closeTo(
              VotingSubmitButton.preferredHeight(tester.element(submit)),
              0.5,
            ),
            reason:
                '$label: pre-layout budgeting and the rendered button must '
                'describe the same height',
          );
          expect(tester.takeException(), isNull, reason: label);
        });
      }
    }
  });

  group('PICNIC-2700 the submit button does not resize with the keyboard', () {
    for (final locale in const [Locale('ko'), Locale('vi')]) {
      for (final textScale in const [1.0, 2.0]) {
        final label = '${locale.languageCode} ${textScale}x';
        testWidgets(label, (tester) async {
          await pumpDialog(
            tester,
            locale: locale,
            textScale: textScale,
            viewport: const Size(393, 852),
          );
          final idle = tester.getSize(find.byType(VotingSubmitButton));

          await pumpDialog(
            tester,
            locale: locale,
            textScale: textScale,
            viewport: const Size(393, 852),
            keyboard: 300,
          );
          final withKeyboard = tester.getSize(find.byType(VotingSubmitButton));

          expect(
            withKeyboard.width,
            closeTo(idle.width, 0.01),
            reason:
                '$label: the primary button changed width when the keyboard '
                'opened (${idle.width} -> ${withKeyboard.width})',
          );
          expect(tester.takeException(), isNull, reason: label);
        });
      }
    }
  });

  testWidgets('PICNIC-2700 a roughly 47px label slot shrinks the label '
      'instead of growing the button', (tester) async {
    tester.view.physicalSize = const Size(280 * 3, 480 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        const Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                child: VotingSubmitButton(canVote: true, isVoting: false),
              ),
            ],
          ),
        ),
        locale: const Locale('th'),
        textScaler: const TextScaler.linear(2),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
      ),
    );

    final submit = find.byType(VotingSubmitButton);
    final submitSize = tester.getSize(submit);
    final l10n = AppLocalizations.of(tester.element(submit));
    final labelFinder = _submitLabel(l10n.label_button_vote);
    final paragraph = tester.renderObject<RenderParagraph>(labelFinder);

    expect(submitSize.width, closeTo(64, 0.5));
    _expectOneRenderedLine(
      paragraph,
      'the label slot is about 47px after padding; the label must shrink',
    );
    _expectLabelDrawnInsideButton(tester, labelFinder, submit, 'narrow slot');
    expect(
      submitSize.height,
      closeTo(VotingSubmitButton.preferredHeight(tester.element(submit)), 0.5),
      reason: 'the button height does not depend on the width it is given',
    );
    expect(tester.takeException(), isNull);
  });

  // The loading indicator is a fixed 24px while the label grows with the text
  // scale, so swapping one for the other used to shrink the button the moment
  // a vote was submitted: 7.6px at 2.0x, 23.6px at 2.6x. The dialog budgets
  // the idle height, so the whole card jumped under the user's finger.
  group('PICNIC-2700 the submit button keeps its height while voting', () {
    for (final columns in const [false, true]) {
      for (final textScale in const [1.0, 2.0, 2.6]) {
        final label = '${columns ? "two-column" : "one-column"} ${textScale}x';
        testWidgets(label, (tester) async {
          Future<double> heightWhen({required bool isVoting}) async {
            await tester.pumpWidget(
              buildTestApp(
                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 240,
                        child: VotingSubmitButton(
                          canVote: true,
                          isVoting: isVoting,
                          columns: columns,
                        ),
                      ),
                    ],
                  ),
                ),
                locale: const Locale('vi'),
                textScaler: TextScaler.linear(textScale),
                designSize: kAppDesignSize,
                splitScreenMode: kAppSplitScreenMode,
              ),
            );
            // The indicator animates forever; one frame is enough to lay out.
            await tester.pump();
            final button = find.byType(VotingSubmitButton);
            expect(
              _labelIsPainted(tester, button),
              !isVoting,
              reason: '$label: the label is shown exactly when not voting',
            );
            expect(
              tester.getSize(button).height,
              closeTo(
                VotingSubmitButton.preferredHeight(
                  tester.element(button),
                  maxWidth: columns ? 240 : null,
                  columns: columns,
                ),
                0.01,
              ),
              reason: '$label: both states have to equal the budgeted height',
            );
            return tester.getSize(button).height;
          }

          final idle = await heightWhen(isVoting: false);
          final voting = await heightWhen(isVoting: true);
          expect(
            voting,
            closeTo(idle, 0.01),
            reason: '$label: the button went from $idle to $voting on submit',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  });
}
