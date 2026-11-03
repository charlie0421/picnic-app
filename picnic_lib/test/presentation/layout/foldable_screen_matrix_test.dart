import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/l10n/app_localizations_th.dart';
import 'package:picnic_lib/presentation/common/comment/comment_list.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
import 'package:picnic_lib/presentation/pages/vote/home_page.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/popup_carousel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/foldable_test_app.dart';
import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';

const foldSizes = [
  Size(466, 678),
  Size(951, 669),
  Size(400, 640),
  Size(800, 600),
  Size(600, 800),
  Size(320, 400),
];
const popup = Popup(
  id: 9029,
  title: {'ko': '화면이 바뀌어도 읽을 수 있는 안내'},
  content: {'ko': '접거나 펼친 뒤에도 안내와 닫기 버튼을 확인할 수 있어야 합니다.'},
);

Future<void> settleScreen(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  drainExpectedImageErrors(tester);
}

void main() {
  setUp(() {
    initTestColors();
    SharedPreferences.setMockInitialValues({});
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });
  tearDown(tearDownMockSupabase);

  for (final name in ['home', 'home-loading', 'post', 'popup', 'popup-th']) {
    for (final scale in [1.0, 2.6]) {
      testWidgets('$name survives Duo and Fold8 ratio transitions at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = foldSizes.first;
        addTearDown(tester.view.reset);
        addTearDown(suppressImageErrors());
        setupMockSupabase(foldableScreenFixtures());
        final Widget page = switch (name) {
          'home' || 'home-loading' => const HomePage(),
          'post' => const PostViewPage('foldable-post', syncNavigation: false),
          _ => const PopupCarousel(),
        };
        await tester.pumpWidget(
          buildFoldableTestApp(
            page,
            textScale: scale,
            locale: Locale(name == 'popup-th' ? 'th' : 'ko'),
            overrides: [
              asyncActiveFeaturedVotesProvider.overrideWith(
                name == 'home-loading'
                    ? FoldableLoadingVotes.new
                    : FoldableFeaturedVotes.new,
              ),
              popupProvider.overrideWith((ref) async => [popup]),
            ],
          ),
        );
        await settleScreen(tester);
        final element = tester.element(find.byWidget(page));
        for (final size in foldSizes) {
          tester.view.physicalSize = size;
          await settleScreen(tester);
          expect(tester.element(find.byWidget(page)), same(element));
          if (name == 'home') {
            await tester.ensureVisible(find.byType(HomeFeaturedVoteCarousel));
            await settleScreen(tester);
            final share = find.byType(ShareSection).first;
            final cardRect = tester.getRect(
              find.byKey(HomeFeaturedVoteCard.frameKey).first,
            );
            for (final button
                in find
                    .descendant(
                      of: share,
                      matching: find.byType(ElevatedButton),
                    )
                    .evaluate()) {
              final rect = tester.getRect(find.byWidget(button.widget));
              expect(rect.left, greaterThanOrEqualTo(cardRect.left));
              expect(rect.right, lessThanOrEqualTo(cardRect.right));
            }
          }
          if (name == 'post') {
            expect(find.text('폴더블 화면에서 읽는 게시물'), findsWidgets);
          }
          if (name.startsWith('popup')) {
            final close = find.text(
              name == 'popup-th'
                  ? AppLocalizationsTh().label_popup_close
                  : AppLocalizationsKo().label_popup_close,
            );
            await tester.ensureVisible(close);
            await settleScreen(tester);
            expect(
              close.hitTestable(),
              findsOneWidget,
              reason: '$size / $scale',
            );
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$name $size / $scale',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        // Let the ad widget's existing one-shot retry finish after unmount.
        await tester.pump(const Duration(seconds: 16));
      });
    }
  }

  testWidgets(
    'Thai popup actions remain reachable around short-height boundary',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 480);
      addTearDown(tester.view.reset);
      addTearDown(suppressImageErrors());
      setupMockSupabase({});
      await tester.pumpWidget(
        buildFoldableTestApp(
          const PopupCarousel(),
          textScale: 2.6,
          locale: const Locale('th'),
          overrides: [
            popupProvider.overrideWith((ref) async => [popup]),
          ],
        ),
      );
      await settleScreen(tester);
      for (double height = 480; height >= 260; height -= 4) {
        tester.view.physicalSize = Size(320, height);
        await settleScreen(tester);
        final close = find.text(AppLocalizationsTh().label_popup_close);
        await tester.ensureVisible(close);
        await settleScreen(tester);
        expect(close.hitTestable(), findsOneWidget, reason: 'height=$height');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  for (final commentScale in [1.0, 2.6]) {
    testWidgets(
      'post comment sheet follows window height and keyboard at $commentScale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(951, 669);
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 16);
        addTearDown(tester.view.reset);
        addTearDown(suppressImageErrors());
        await setupMockSupabaseWithAuth({
          'posts': [foldablePostFixture()],
          'comments': [],
          'user_blocks': [],
        }, userId: 'test-user-id');
        await tester.pumpWidget(
          buildFoldableTestApp(
            const PostViewPage('foldable-post', syncNavigation: false),
            textScale: commentScale,
          ),
        );
        await settleScreen(tester);
        final open = find.text(AppLocalizationsKo().post_comment_write_label);
        await tester.ensureVisible(open);
        await tester.tap(open);
        await settleScreen(tester);
        expect(find.byType(CommentList), findsOneWidget);
        final input = find.byType(TextFormField);
        await tester.enterText(input, 'keep this comment draft');
        final fieldElement = tester.element(input);
        final inputState = tester.state<EditableTextState>(find.byType(EditableText));
        final commentsScroll = tester.state<ScrollableState>(find.descendant(
          of: find.byType(CommentList), matching: find.byType(Scrollable)).first);
        // Resize/scroll restoration can adjust the list without a user drag.
        commentsScroll.position.jumpTo(1);
        await settleScreen(tester);
        expect(inputState.widget.focusNode.hasFocus, isTrue,
          reason: 'Programmatic list movement must not interrupt the draft');
        for (final size in [
          const Size(951, 669),
          const Size(466, 900),
          const Size(800, 600),
        ]) {
          tester.view.physicalSize = size;
          final rightInset = size.width > 800 ? 84.0 : 0.0;
          final padding = FakeViewPadding(top: 24, bottom: 16, right: rightInset);
          tester.view.padding = padding;
          tester.view.viewPadding = padding;
          await settleScreen(tester);
          final rect = tester.getRect(find.byType(CommentList));
          expect(
            rect.height,
            closeTo(size.height - 24 - kToolbarHeight - 16, 1),
            reason: '$size',
          );
          expect(rect.top, greaterThanOrEqualTo(24 + kToolbarHeight));
          expect(
            rect.width,
            closeTo((size.width - rightInset).clamp(0, 600), 1),
          );
          expect(rect.center.dx, closeTo((size.width - rightInset) / 2, 1));
          tester.view.viewInsets = const FakeViewPadding(bottom: 200);
          await settleScreen(tester);
          expect(tester.element(input), same(fieldElement));
          expect(find.text('keep this comment draft'), findsOneWidget);
          expect(
            tester.getRect(input).bottom,
            lessThanOrEqualTo(size.height - 200),
          );
          final editable = tester
              .state<EditableTextState>(find.byType(EditableText))
              .renderEditable;
          expect(
            editable.size.height,
            greaterThanOrEqualTo(editable.preferredLineHeight),
          );
          tester.view.resetViewInsets();
          await settleScreen(tester);
          expect(tester.takeException(), isNull);
        }
        await tester.drag(find.descendant(of: find.byType(CommentList),
          matching: find.byType(Scrollable)).first, const Offset(0, -80));
        await settleScreen(tester);
        expect(inputState.widget.focusNode.hasFocus, isFalse,
          reason: 'A user drag should still dismiss the keyboard');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 16));
      },
    );
  }
}
