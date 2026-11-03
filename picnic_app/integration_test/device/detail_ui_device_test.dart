// Real production widgets and OS keyboard; every service uses local fixtures.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import '../../../picnic_lib/test/helpers/detail_ui_fixtures.dart';
import '../../../picnic_lib/test/helpers/extended_ui_fixtures.dart';
import '../../../picnic_lib/test/helpers/foldable_test_app.dart';
import '../../../picnic_lib/test/helpers/mock_supabase.dart';
import '../../../picnic_lib/test/helpers/test_environment.dart';
import 'current_service_foldable_device_test.dart'
    show frames, capture, fold, keyboard, window;

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('External network is forbidden in the UI fixture');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final previous = HttpOverrides.current;
  setUpAll(() => HttpOverrides.global = _NoNetwork());
  tearDownAll(() => HttpOverrides.global = previous);
  setUp(() async {
    initTestColors();
    resetFoldableTestPlugins();
    DetailQnaRepository.sendAttempts = 0;
    await setupMockSupabaseWithAuth(detailVoteFixtures(),
        userId: 'test-user-id');
  });
  tearDown(() {
    expect(DetailQnaRepository.sendAttempts, 0);
    expect(
        capturedMockRequests
            .where((uri) => uri.path.contains('/functions/v1/')),
        isEmpty);
    tearDownMockSupabase();
  });
  testWidgets(
      'QnA and partner draft survive OS keyboard fold; achievement remains readable',
      (tester) async {
    tester.testTextInput.unregister();
    addTearDown(tester.testTextInput.register);
    Future<void> show(Widget page, {bool scaffold = false}) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester, 2);
      await tester.pumpWidget(buildFoldableTestApp(page,
          textScale: 2.6,
          locale: const Locale('en'),
          deviceAssets: true,
          pageHasScaffold: scaffold,
          overrides: [walletSummaryProvider.overrideWith(LayoutWallet.new)]));
      await frames(tester);
    }

    Future<void> checkDraft(String text, String label) async {
      final field = find.byType(TextField);
      final editable = find.byType(EditableText);
      await tester.ensureVisible(field);
      await frames(tester);
      await tester.tap(field);
      await frames(tester);
      tester.state<EditableTextState>(editable).updateEditingValue(
          TextEditingValue(
              text: text, selection: const TextSelection.collapsed(offset: 1)));
      await frames(tester);
      expect(keyboard(tester), greaterThan(0));
      tester.widget<EditableText>(editable).controller.selection =
          const TextSelection.collapsed(offset: 1);
      await frames(tester);
      expect(
          tester.widget<EditableText>(editable).controller.selection.baseOffset,
          1);
      await capture(tester, '$label-before');
      await fold(tester, label);
      expect(tester.widget<EditableText>(editable).controller.text, text);
      expect(
          tester.widget<EditableText>(editable).controller.selection.baseOffset,
          1);
      await tester.ensureVisible(field);
      await frames(tester);
      await tester.tap(field);
      await frames(tester, 25);
      expect(keyboard(tester), greaterThan(0));
      expect(tester.getRect(field).bottom,
          lessThanOrEqualTo(window(tester).height - keyboard(tester) + 1));
      await capture(tester, '$label-after');
      FocusManager.instance.primaryFocus?.unfocus();
      await frames(tester);
    }

    await show(detailQnaPage(), scaffold: true);
    await checkDraft('Keep this draft', 'detail-qna');
    await show(VotingDialog(
        voteModel: detailPartnerVote,
        voteItemModel: detailVoteItem,
        portalType: VotePortal.vote));
    await checkDraft('123', 'detail-partner');
    await show(const VoteDetailAchievePage(voteId: 1));
    final target = find.text('123,456,789');
    await tester.ensureVisible(target);
    await frames(tester);
    expect(target.hitTestable(), findsOneWidget);
    await capture(tester, 'detail-achievement');
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
  });
}
