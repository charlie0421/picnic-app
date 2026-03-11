import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article.dart';

void main() {
  group('ArticleModel', () {
    test('필수 필드로 생성', () {
      final article = ArticleModel(
        id: 1,
        titleKo: '기사 제목',
        titleEn: 'Article Title',
        content: '내용입니다',
        gallery: null,
        articleImage: null,
        createdAt: DateTime(2025, 3, 1),
        commentCount: null,
        comment: null,
        mostLikedComment: null,
      );
      expect(article.id, equals(1));
      expect(article.titleKo, equals('기사 제목'));
      expect(article.titleEn, equals('Article Title'));
      expect(article.content, equals('내용입니다'));
      expect(article.gallery, isNull);
      expect(article.articleImage, isNull);
      expect(article.commentCount, isNull);
      expect(article.comment, isNull);
      expect(article.mostLikedComment, isNull);
    });

    test('commentCount 포함', () {
      final article = ArticleModel(
        id: 2,
        titleKo: '댓글 있는 기사',
        titleEn: 'Article with comments',
        content: 'content',
        gallery: null,
        articleImage: const [],
        createdAt: DateTime(2025, 6, 15),
        commentCount: 42,
        comment: null,
        mostLikedComment: null,
      );
      expect(article.commentCount, equals(42));
      expect(article.articleImage, isEmpty);
    });

    test('빈 이미지 리스트', () {
      final article = ArticleModel(
        id: 3,
        titleKo: '제목',
        titleEn: 'Title',
        content: '',
        gallery: null,
        articleImage: const [],
        createdAt: DateTime(2025, 1, 1),
        commentCount: 0,
        comment: null,
        mostLikedComment: null,
      );
      expect(article.articleImage, isNotNull);
      expect(article.articleImage!.length, equals(0));
    });
  });
}
