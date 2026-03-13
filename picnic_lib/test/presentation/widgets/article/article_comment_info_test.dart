import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/presentation/providers/article_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/article/article_comment_info.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  final testArticle = ArticleModel(
    id: 1,
    titleKo: 'Test Title',
    titleEn: 'Test Title EN',
    content: 'Test content',
    gallery: null,
    articleImage: null,
    createdAt: DateTime(2024, 1, 1),
    commentCount: 5,
    comment: null,
    mostLikedComment: null,
  );

  group('ArticleCommentInfo', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          ArticleCommentInfo(
            article: testArticle,
            showComments: (_, __) {},
          ),
          extraOverrides: [
            commentCountProvider(testArticle.id)
                .overrideWith(() => _MockCommentCount(5)),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ArticleCommentInfo), findsOneWidget);
    });

    testWidgets('contains GestureDetector', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          ArticleCommentInfo(
            article: testArticle,
            showComments: (_, __) {},
          ),
          extraOverrides: [
            commentCountProvider(testArticle.id)
                .overrideWith(() => _MockCommentCount(5)),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('shows comment count text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          ArticleCommentInfo(
            article: testArticle,
            showComments: (_, __) {},
          ),
          extraOverrides: [
            commentCountProvider(testArticle.id)
                .overrideWith(() => _MockCommentCount(5)),
          ],
        ),
      );
      await tester.pump();

      // The widget shows localized text with count; verify Text widget exists
      expect(find.byType(Text), findsOneWidget);
      // Verify the text contains the count "5"
      expect(find.textContaining('5'), findsOneWidget);
    });

    testWidgets('calls showComments callback on tap', (tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          ArticleCommentInfo(
            article: testArticle,
            showComments: (_, __) {
              callbackCalled = true;
            },
          ),
          extraOverrides: [
            commentCountProvider(testArticle.id)
                .overrideWith(() => _MockCommentCount(5)),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets('contains Padding with EdgeInsets.all(8.0)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          ArticleCommentInfo(
            article: testArticle,
            showComments: (_, __) {},
          ),
          extraOverrides: [
            commentCountProvider(testArticle.id)
                .overrideWith(() => _MockCommentCount(5)),
          ],
        ),
      );
      await tester.pump();

      final paddingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.all(8.0),
      );
      expect(paddingFinder, findsOneWidget);
    });
  });
}

class _MockCommentCount extends CommentCount {
  final int _initial;

  _MockCommentCount(this._initial);

  @override
  Future<int> build(int articleId) async => _initial;
}
