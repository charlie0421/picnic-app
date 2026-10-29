import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_widget.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';

import '../../picnic_lib/test/helpers/foldable_test_app.dart';
import '../../picnic_lib/test/helpers/ignore_image_errors.dart';
import '../../picnic_lib/test/helpers/load_test_fonts.dart';
import '../../picnic_lib/test/helpers/mock_supabase.dart';
import '../../picnic_lib/test/helpers/test_environment.dart';
import 'helpers/current_service_test_app.dart';

Future<void> serviceFrames(WidgetTester tester, [int count = 15]) async {
  for (var i = 0; i < count; i++) {
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
  }
}

Finder serviceMenu(int index) =>
    find.byWidgetPredicate((w) => w is MenuItem && w.index == index);

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    initTestColors();
    resetFoldableTestPlugins();
  });
  tearDown(() {
    expectNoServiceMutation();
    tearDownMockSupabase();
  });

  test('mutation guard rejects current vote and purchase function paths', () {
    for (final function in ['pic-voting-v2', 'voting-v2', 'verify_receipt']) {
      capturedMockRequests.add(
          Uri.parse('https://fixture.invalid/functions/v1/$function'));
      try {
        expect(expectNoServiceMutation, throwsA(isA<TestFailure>()));
      } finally {
        capturedMockRequests.clear();
      }
    }
  });

  for (final size in [
    const Size(466, 678),
    const Size(951, 669),
    const Size(400, 640),
    const Size(800, 600),
    const Size(320, 600),
    const Size(600, 400)
  ]) {
    for (final scale in [1.0, 2.6]) {
      testWidgets('current menu and drawer $size text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
        await setupMockSupabaseWithAuth(serviceFixtures(),
            userId: 'test-user-id');
        await pumpWidgetAndIgnoreErrors(
            tester, currentServiceTestApp(textScale: scale));
        await serviceFrames(tester);
        expect(find.byType(MenuItem), findsNWidgets(4));

        await tester.tap(serviceMenu(2));
        await serviceFrames(tester);
        expect(find.byType(VideoListItem), findsOneWidget);
        final channel = find.text('피크닠! - Picnic!');
        final media = tester.getRect(find.byType(VideoListItem));
        expect(tester.getRect(channel).right, lessThanOrEqualTo(media.right));

        await tester.tap(serviceMenu(3));
        await serviceFrames(tester);
        expect(find.byType(StorePage), findsOneWidget);
        await tester.scrollUntilVisible(
            find.byKey(const Key('purchase-price-cta')), 120,
            scrollable: find
                .descendant(
                    of: find.byType(PurchaseStarCandy),
                    matching: find.byType(Scrollable))
                .first);
        await tester.ensureVisible(find.byKey(const Key('purchase-price-cta')));
        await serviceFrames(tester);
        expect(find.byKey(const Key('purchase-price-cta')).hitTestable(),
            findsOneWidget);

        await tester.tap(find.byType(ProfileImageContainer).first);
        await serviceFrames(tester);
        expect(find.byType(MyPage), findsOneWidget);
        expect(find.text(serviceNickname), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await serviceFrames(tester, 30);
      });
    }
  }

  for (final scale in [1.0, 2.6]) {
    for (final size in [
      const Size(400, 640),
      const Size(800, 600),
      const Size(466, 678),
      const Size(951, 669),
      const Size(320, 600),
      const Size(600, 400),
    ]) {
      testWidgets('real vote list to input $size text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
        await setupMockSupabaseWithAuth(serviceFixtures(),
            userId: 'test-user-id');
        await pumpWidgetAndIgnoreErrors(
            tester, currentServiceTestApp(textScale: scale));
        await serviceFrames(tester);
        await tester.tap(serviceMenu(1));
        await serviceFrames(tester);
        expect(find.byType(VoteInfoCard), findsWidgets);
        await tester.tap(find.byType(VoteInfoCard).first);
        await serviceFrames(tester);
        expect(find.byType(VoteDetailPage), findsOneWidget);
        await tester.scrollUntilVisible(find.byType(VoteItemWidget), 120,
            scrollable: find
                .descendant(
                    of: find.byType(VoteDetailPage),
                    matching: find.byType(Scrollable))
                .first);
        await serviceFrames(tester);
        await tester.ensureVisible(find.byType(VoteItemWidget).first);
        await tester.tap(find.byType(VoteItemWidget).first);
        await serviceFrames(tester);
        expect(find.byType(VotingDialog), findsOneWidget);
        final input = find.descendant(
            of: find.byType(VotingDialog), matching: find.byType(TextField));
        expect(input, findsOneWidget);
        if (scale == 1 && size.height >= 600) {
          expect(find.byKey(kLargePopupTopCloseKey), findsOneWidget,
              reason:
                  'The normal-text tall window must keep its close control');
        }
        await tester.enterText(input, '10');
        await serviceFrames(tester);
        expect(find.text('10'), findsWidgets);
        final inset = size.height < 500 ? 160.0 : 300.0;
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await serviceFrames(tester);
        await tester.ensureVisible(input);
        await serviceFrames(tester);
        expect(tester.getRect(input).bottom,
            lessThanOrEqualTo(size.height - inset + 1));
        expect(find.text('10'), findsWidgets);
        await tester.tapAt(const Offset(10, 10));
        await serviceFrames(tester);
        expect(find.byType(VotingDialog), findsNothing);
        expect(find.byType(VoteDetailPage), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await serviceFrames(tester, 30);
      });
    }
  }
}
