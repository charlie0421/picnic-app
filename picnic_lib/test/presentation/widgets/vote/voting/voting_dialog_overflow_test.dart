import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';

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

// PICNIC-2700 regression guard.
//
// The submit button's two-line cap took roughly 55px off what the pinned
// action column requires. Two configurations that had been scrolling moved
// onto the pinned path, and there a latent defect surfaced: the "use all"
// checkbox reserved 20.w for its glyph while the glyph, being a square SVG
// pinned to a 20px height, always draws 20 regardless of the width it is
// handed. On a 320-wide screen that is a 3.72px under-reservation, enough to
// wrap the label to a second line, overflow the pinned column and let
// Clip.antiAlias eat the bottom of the controls.
//
// Neither configuration was in any existing matrix: PICNIC-2694, 2697 and the
// 2700 label tests each hold one viewport family, four locales, or no
// keyboard. So this file asserts the one thing that has to hold everywhere —
// the dialog raises nothing while laying out — across every shipped locale,
// both keyboard states, and a text scale past the platform maximum.
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

  // Every locale with an arb file, not just the four the other matrices loop.
  const locales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('th'),
    Locale('my'),
    Locale('ja'),
    Locale('id'),
    Locale('vi'),
    Locale('fil'),
    Locale('es'),
    Locale('bn'),
    Locale('bn', 'BD'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  // A small phone, the narrowest supported window, a stock phone, and a wide
  // short body. 320x568 is where both PICNIC-2700 regressions lived.
  const viewports = <Size>[
    Size(320, 568),
    Size(280, 480),
    Size(393, 852),
    Size(851, 393),
  ];

  // 2.1 and 2.6 are the two scales the PICNIC-2700 regressions actually landed
  // on, so they stay even though neither is a round number. 2.6 is past the
  // platform maximum on purpose: the guarantee is structural, not a list of
  // scales we happen to have seen.
  const textScales = <double>[1.0, 2.0, 2.1, 2.6];
  const keyboards = <double>[0, 300];

  group('PICNIC-2700 the dialog lays out without overflowing', () {
    for (final locale in locales) {
      final localeLabel = locale.countryCode == null
          ? locale.languageCode
          : '${locale.languageCode}_${locale.countryCode}';
      for (final viewport in viewports) {
        for (final keyboard in keyboards) {
          for (final textScale in textScales) {
            final label =
                '$localeLabel ${viewport.width.toInt()}x'
                '${viewport.height.toInt()} '
                'K${keyboard.toInt()} ${textScale}x';
            testWidgets(label, (tester) async {
              await pumpAt(
                tester,
                viewport: viewport,
                locale: locale,
                textScale: textScale,
                keyboard: keyboard,
              );
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '$label: the dialog must lay out without raising. An '
                    'overflow here means a pinned band was measured smaller '
                    'than it draws, and Clip.antiAlias will cut the controls.',
              );
            });
          }
        }
      }
    }
  });
}
