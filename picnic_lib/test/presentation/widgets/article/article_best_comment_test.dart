import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/widgets/article/article_best_comment.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('ArticleBestComment', () {
    testWidgets('renders with mostLikedComment', (WidgetTester tester) async {
      final comment = CommentModel(
        commentId: 'c-1',
        children: null,
        myLike: null,
        user: UserProfilesModel(
          id: 'u1',
          nickname: 'BestUser',
          avatarUrl: null,
          isAdmin: null,
          starCandy: null,
          starCandyBonus: null,
          jmaCandy: null,
        ),
        likes: 10,
        replies: 0,
        content: {'ko': '최고의 댓글입니다'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final article = ArticleModel(
        id: 1,
        titleKo: '제목',
        titleEn: 'Title',
        content: 'content',
        gallery: null,
        articleImage: null,
        createdAt: DateTime(2025, 1, 1),
        commentCount: 5,
        comment: null,
        mostLikedComment: comment,
      );

      bool showCommentsCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          ArticleBestComment(
            article: article,
            showComments: (context, article, {String? commentId}) {
              showCommentsCalled = true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ArticleBestComment), findsOneWidget);
      expect(find.textContaining('BestUser'), findsOneWidget);
    });

    testWidgets('renders empty container when no mostLikedComment',
        (WidgetTester tester) async {
      final article = ArticleModel(
        id: 2,
        titleKo: '제목',
        titleEn: 'Title',
        content: 'content',
        gallery: null,
        articleImage: null,
        createdAt: DateTime(2025, 1, 1),
        commentCount: 0,
        comment: null,
        mostLikedComment: null,
      );

      await tester.pumpWidget(
        buildTestApp(
          ArticleBestComment(
            article: article,
            showComments: (_, __, {String? commentId}) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ArticleBestComment), findsOneWidget);
      // Should render an empty Container when no comment
    });
  });
}
