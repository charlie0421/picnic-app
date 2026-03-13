import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/presentation/widgets/article/article_images.dart';

Map<String, dynamic> _makeArticleJson({
  int id = 1,
  List<Map<String, dynamic>>? articleImage,
}) {
  return {
    'id': id,
    'title_ko': '테스트 기사',
    'title_en': 'Test Article',
    'content': 'Content here',
    'gallery': null,
    'article_image': articleImage,
    'created_at': '2024-06-15T10:00:00.000Z',
    'comment_count': 0,
    'comment': null,
    'most_liked_comment': null,
  };
}

void main() {
  group('ArticleModel fromJson', () {
    test('parses basic article', () {
      final article = ArticleModel.fromJson(_makeArticleJson());
      expect(article.id, 1);
      expect(article.titleKo, '테스트 기사');
      expect(article.titleEn, 'Test Article');
      expect(article.content, 'Content here');
      expect(article.articleImage, isNull);
    });

    test('parses article with images', () {
      final article = ArticleModel.fromJson(_makeArticleJson(
        articleImage: [
          {
            'id': 10,
            'title_ko': '이미지 제목',
            'title_en': 'Image Title',
            'image': 'https://example.com/img1.png',
            'article_image_user': [],
          },
        ],
      ));
      expect(article.articleImage, isNotNull);
      expect(article.articleImage!.length, 1);
      expect(article.articleImage!.first.image, 'https://example.com/img1.png');
      expect(article.articleImage!.first.titleKo, '이미지 제목');
    });
  });

  group('ArticleImages widget', () {
    test('can be constructed with ArticleModel', () {
      final article = ArticleModel.fromJson(_makeArticleJson());
      final widget = ArticleImages(article: article);
      expect(widget, isA<ArticleImages>());
    });

    test('with key can be constructed', () {
      final article = ArticleModel.fromJson(_makeArticleJson());
      final widget = ArticleImages(
        key: const ValueKey('article_images'),
        article: article,
      );
      expect(widget.key, equals(const ValueKey('article_images')));
    });
  });

  group('FullScreenImageViewer widget', () {
    test('can be constructed with imageUrl', () {
      const viewer = FullScreenImageViewer(
        imageUrl: 'https://example.com/img.png',
      );
      expect(viewer, isA<FullScreenImageViewer>());
      expect(viewer.imageUrl, 'https://example.com/img.png');
    });

    test('with key can be constructed', () {
      const viewer = FullScreenImageViewer(
        key: ValueKey('fullscreen'),
        imageUrl: 'https://example.com/img.png',
      );
      expect(viewer.key, equals(const ValueKey('fullscreen')));
    });
  });
}
