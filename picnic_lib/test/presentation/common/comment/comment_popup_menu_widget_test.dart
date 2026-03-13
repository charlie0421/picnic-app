import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/common/comment/comment_popup_menu.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
    setupMockSupabase({});
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  CommentModel createMockComment({
    String commentId = 'comment-1',
    String? userId = 'other-user-id',
    DateTime? deletedAt,
  }) {
    final now = DateTime.now();
    return CommentModel(
      commentId: commentId,
      userId: userId,
      children: null,
      myLike: null,
      user: null,
      likes: 0,
      replies: 0,
      content: {'ko': '테스트 댓글'},
      isLikedByMe: false,
      isReportedByMe: false,
      isBlindedByAdmin: false,
      isRepliedByMe: false,
      post: null,
      locale: 'ko',
      parentCommentId: null,
      createdAt: now,
      updatedAt: now,
      deletedAt: deletedAt,
    );
  }

  group('CommentPopupMenu widget rendering', () {
    testWidgets('renders PopupMenuButton when not processing', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          CommentPopupMenu(
            postId: 'post-1',
            comment: createMockComment(),
          ),
        ),
      );

      expect(find.byType(CommentPopupMenu), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('renders with all optional callbacks', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          CommentPopupMenu(
            postId: 'post-1',
            comment: createMockComment(),
            refreshFunction: () {},
            openReportModal: (title, target) {},
            onDelete: () {},
          ),
        ),
      );

      expect(find.byType(CommentPopupMenu), findsOneWidget);
    });

    testWidgets('renders with deleted comment', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          CommentPopupMenu(
            postId: 'post-1',
            comment: createMockComment(deletedAt: DateTime.now()),
          ),
        ),
      );

      expect(find.byType(CommentPopupMenu), findsOneWidget);
    });

    testWidgets('renders with authenticated user who can report', (tester) async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth({}, userId: 'my-user-id');

      await pumpAndDrain(
        tester,
        buildTestApp(
          CommentPopupMenu(
            postId: 'post-1',
            comment: createMockComment(userId: 'other-user-id'),
          ),
        ),
      );

      expect(find.byType(CommentPopupMenu), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('renders with authenticated user who owns comment', (tester) async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth({}, userId: 'my-user-id');

      await pumpAndDrain(
        tester,
        buildTestApp(
          CommentPopupMenu(
            postId: 'post-1',
            comment: createMockComment(userId: 'my-user-id'),
          ),
        ),
      );

      expect(find.byType(CommentPopupMenu), findsOneWidget);
    });

    testWidgets('tapping menu when not logged in', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          CommentPopupMenu(
            postId: 'post-1',
            comment: createMockComment(),
          ),
        ),
      );

      // Tap the GestureDetector wrapping the PopupMenuButton
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pump();
      while (tester.takeException() != null) {}
    });
  });
}
