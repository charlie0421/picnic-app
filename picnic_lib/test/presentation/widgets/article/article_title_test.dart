import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/presentation/widgets/article/article_title.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('ArticleTitle', () {
    testWidgets('renders with title and date', (WidgetTester tester) async {
      final article = ArticleModel(
        id: 1,
        titleKo: '아티클 제목',
        titleEn: 'Article Title',
        content: 'content',
        gallery: null,
        articleImage: null,
        createdAt: DateTime(2025, 3, 15),
        commentCount: null,
        comment: null,
        mostLikedComment: null,
      );

      await tester.pumpWidget(
        buildTestApp(ArticleTitle(article: article)),
      );
      await tester.pump();

      expect(find.byType(ArticleTitle), findsOneWidget);
      expect(find.text('아티클 제목'), findsOneWidget);
      expect(find.text('2025-03-15'), findsOneWidget);
    });
  });
}
