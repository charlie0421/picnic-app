import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/presentation/widgets/article/article_content.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('ArticleContent', () {
    testWidgets('renders article content text', (WidgetTester tester) async {
      final article = ArticleModel(
        id: 1,
        titleKo: '제목',
        titleEn: 'Title',
        content: '이것은 기사 내용입니다.',
        gallery: null,
        articleImage: null,
        createdAt: DateTime(2025, 1, 1),
        commentCount: null,
        comment: null,
        mostLikedComment: null,
      );

      await tester.pumpWidget(
        buildTestApp(ArticleContent(article: article)),
      );
      await tester.pump();

      expect(find.byType(ArticleContent), findsOneWidget);
      expect(find.text('이것은 기사 내용입니다.'), findsOneWidget);
    });

    testWidgets('renders empty content', (WidgetTester tester) async {
      final article = ArticleModel(
        id: 2,
        titleKo: '제목',
        titleEn: 'Title',
        content: '',
        gallery: null,
        articleImage: null,
        createdAt: DateTime(2025, 1, 1),
        commentCount: null,
        comment: null,
        mostLikedComment: null,
      );

      await tester.pumpWidget(
        buildTestApp(ArticleContent(article: article)),
      );
      await tester.pump();

      expect(find.byType(ArticleContent), findsOneWidget);
    });
  });
}
