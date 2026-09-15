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

const _locales = <Locale>[
  Locale('ko'),
  Locale('en'),
  Locale('th'),
  Locale('my'),
  Locale('ja'),
  Locale('zh'),
  Locale('id'),
];
const _textScales = <double>[1.0, 1.3, 2.0];

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

void _expectAtMostTwoRenderedLines(RenderParagraph paragraph, String reason) {
  expect(
    paragraph.size.height,
    lessThanOrEqualTo(paragraph.preferredLineHeight * 2 + 0.5),
    reason: reason,
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

  group('PICNIC-2700 one-column submit label geometry', () {
    for (final locale in _locales) {
      for (final textScale in _textScales) {
        final label = '${locale.languageCode} ${textScale}x';

        testWidgets('$label uses a wider corner-safe width and a true budget', (
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
          final paragraph = tester.renderObject<RenderParagraph>(
            _submitLabel(l10n.label_button_vote),
          );

          expect(
            submitSize.width,
            greaterThan(VotingSubmitButton.preferredWidth() + 0.5),
            reason:
                '$label: the production dialog must not fall back to the '
                'legacy fixed-width button',
          );
          expect(
            submitSize.width,
            lessThanOrEqualTo(inputSize.width + 0.5),
            reason: '$label: the vote button must stay within the action band',
          );
          expect(
            _capsuleCornerOverhang(tester, tester.getRect(submit)),
            lessThanOrEqualTo(0.5),
            reason: '$label: the wider button must stay inside the capsule arc',
          );
          _expectAtMostTwoRenderedLines(
            paragraph,
            '$label: the submit label must not grow past two rendered lines',
          );
          expect(
            submitSize.height,
            closeTo(
              VotingSubmitButton.preferredHeight(
                tester.element(submit),
                maxWidth: submitSize.width,
              ),
              0.5,
            ),
            reason:
                '$label: pre-layout budgeting and rendered width must describe '
                'the same button height',
          );
          expect(tester.takeException(), isNull, reason: label);
        });
      }
    }
  });

  testWidgets('PICNIC-2700 a roughly 47px label slot cannot make the button '
      'taller than two lines', (tester) async {
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
    final paragraph = tester.renderObject<RenderParagraph>(
      _submitLabel(l10n.label_button_vote),
    );

    expect(submitSize.width, closeTo(64, 0.5));
    _expectAtMostTwoRenderedLines(
      paragraph,
      'the label slot is about 47px after padding and would otherwise grow',
    );
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(
      submitSize.height,
      lessThan(120),
      reason: 'two 52px text lines plus padding fit below this measured bound',
    );
    expect(
      submitSize.height,
      closeTo(
        VotingSubmitButton.preferredHeight(
          tester.element(submit),
          maxWidth: submitSize.width,
        ),
        0.5,
      ),
      reason: 'the narrow stress case must use the same two-line height budget',
    );
    expect(tester.takeException(), isNull);
  });
}
