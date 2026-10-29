import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import '../../helpers/detail_ui_fixtures.dart';
import '../../helpers/extended_ui_fixtures.dart';
import '../../helpers/foldable_test_app.dart';
import '../../helpers/ignore_image_errors.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';
import 'active_subpages_foldable_test.dart'
    show showPage, frames, expectCompleteAmount;

void main() {
  setUpAll(loadTestFonts);
  setUp(() async {
    initTestColors();
    resetFoldableTestPlugins();
    await setupMockSupabaseWithAuth(
      detailVoteFixtures(),
      userId: 'test-user-id',
    );
  });
  tearDown(() {
    expect(
      capturedMockRequests.where((uri) => uri.path.contains('/functions/v1/')),
      isEmpty,
    );
    tearDownMockSupabase();
  });
  for (final size in [
    const Size(320, 600),
    const Size(800, 600),
    const Size(600, 400),
  ]) {
    for (final scale in [1.0, 2.6]) {
      for (final language in ['ko', 'en', 'es']) {
        final name = '$size text=$scale $language';
        testWidgets('achievement target digits are readable $name', (
          tester,
        ) async {
          await showPage(
            tester,
            const VoteDetailAchievePage(voteId: 1),
            size,
            scale,
            language,
          );
          final amount = find.text('123,456,789');
          await tester.ensureVisible(amount);
          await frames(tester);
          expectCompleteAmount(tester, '123,456,789', 1);
          expect(amount.hitTestable(), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 6));
        });
        testWidgets('partner vote input survives resize and keyboard $name', (
          tester,
        ) async {
          await showPage(
            tester,
            VotingDialog(
              voteModel: detailPartnerVote,
              voteItemModel: detailVoteItem,
              portalType: VotePortal.vote,
            ),
            size,
            scale,
            language,
            overrides: [walletSummaryProvider.overrideWith(LayoutWallet.new)],
          );
          final field = find.byType(TextField);
          await tester.ensureVisible(field);
          await frames(tester);
          await tester.enterText(field, '123');
          final controller = tester.widget<TextField>(field).controller!;
          controller.selection = const TextSelection.collapsed(offset: 1);
          tester.view.physicalSize = const Size(600, 400);
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          await frames(tester);
          await tester.ensureVisible(field);
          await frames(tester);
          expect(controller.text, '123');
          expect(controller.selection.baseOffset, 1);
          expect(field.hitTestable(), findsOneWidget);
          expect(tester.getRect(field).bottom, lessThanOrEqualTo(221));
          drainExpectedImageErrors(tester);
        });
      }
    }
  }
}
