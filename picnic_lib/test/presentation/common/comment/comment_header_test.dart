import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/common/comment/comment_header.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommentHeader', () {
    testWidgets('renders with user nickname', (WidgetTester tester) async {
      final comment = CommentModel(
        commentId: 'c-1',
        children: null,
        myLike: null,
        user: UserProfilesModel(
          id: 'u1',
          nickname: 'TestUser',
          avatarUrl: null,
          isAdmin: null,
          starCandy: null,
          starCandyBonus: null,
          jmaCandy: null,
        ),
        likes: 5,
        replies: 2,
        content: {'ko': 'test'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        updatedAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        buildTestApp(CommentHeader(item: comment)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommentHeader), findsOneWidget);
      expect(find.textContaining('TestUser'), findsOneWidget);
    });

    testWidgets('renders with null user', (WidgetTester tester) async {
      final comment = CommentModel(
        commentId: 'c-2',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'ko': 'test'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        buildTestApp(CommentHeader(item: comment)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommentHeader), findsOneWidget);
    });
  });
}
