import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';

void main() {
  group('ArticleModel', () {
    final now = DateTime.utc(2025, 6, 1, 12, 0, 0);

    Map<String, dynamic> _commentJson(String id) => {
          'comment_id': id,
          'children': null,
          'my_like': null,
          'user_profiles': null,
          'likes': 3,
          'replies': 0,
          'content': {'type': 'text', 'value': 'nice'},
          'is_liked_by_me': false,
          'is_reported_by_me': false,
          'is_blinded_by_admin': false,
          'is_replied_by_me': false,
          'post': null,
          'locale': 'ko',
          'parent_comment_id': null,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

    Map<String, dynamic> _fullJson() => {
          'id': 1,
          'title_ko': '기사 제목',
          'title_en': 'Article Title',
          'content': '<p>본문 내용</p>',
          'gallery': {
            'id': 10,
            'title_ko': '갤러리',
            'title_en': 'Gallery',
            'cover': 'cover.jpg',
            'celeb': {
              'id': 20,
              'name_ko': '셀럽',
              'name_en': 'Celeb',
              'thumbnail': null,
            },
          },
          'article_image': [
            {
              'id': 100,
              'title_ko': '이미지1',
              'title_en': 'Image1',
              'image': 'img.jpg',
              'article_image_user': null,
            },
          ],
          'created_at': now.toIso8601String(),
          'comment_count': 15,
          'comment': _commentJson('c-1'),
          'most_liked_comment': _commentJson('c-2'),
        };

    Map<String, dynamic> _minimalJson() => {
          'id': 2,
          'title_ko': '제목',
          'title_en': 'Title',
          'content': '',
          'gallery': null,
          'article_image': null,
          'created_at': now.toIso8601String(),
          'comment_count': null,
          'comment': null,
          'most_liked_comment': null,
        };

    test('fromJson with all fields', () {
      final article = ArticleModel.fromJson(_fullJson());

      expect(article.id, 1);
      expect(article.titleKo, '기사 제목');
      expect(article.titleEn, 'Article Title');
      expect(article.content, '<p>본문 내용</p>');
      expect(article.gallery, isNotNull);
      expect(article.gallery!.id, 10);
      expect(article.gallery!.celeb, isNotNull);
      expect(article.gallery!.celeb!.nameKo, '셀럽');
      expect(article.articleImage, isNotNull);
      expect(article.articleImage!.length, 1);
      expect(article.articleImage![0].id, 100);
      expect(article.articleImage![0].image, 'img.jpg');
      expect(article.createdAt, now);
      expect(article.commentCount, 15);
      expect(article.comment, isNotNull);
      expect(article.comment!.commentId, 'c-1');
      expect(article.mostLikedComment, isNotNull);
      expect(article.mostLikedComment!.commentId, 'c-2');
    });

    test('fromJson with minimal/null optional fields', () {
      final article = ArticleModel.fromJson(_minimalJson());

      expect(article.id, 2);
      expect(article.titleKo, '제목');
      expect(article.titleEn, 'Title');
      expect(article.content, '');
      expect(article.gallery, isNull);
      expect(article.articleImage, isNull);
      expect(article.commentCount, isNull);
      expect(article.comment, isNull);
      expect(article.mostLikedComment, isNull);
    });

    test('toJson round-trip', () {
      final original = ArticleModel.fromJson(_fullJson());
      final json = original.toJson();
      final restored = ArticleModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.titleKo, original.titleKo);
      expect(restored.titleEn, original.titleEn);
      expect(restored.content, original.content);
      expect(restored.createdAt, original.createdAt);
      expect(restored.commentCount, original.commentCount);
      expect(restored.gallery?.id, original.gallery?.id);
      expect(restored.gallery?.celeb?.id, original.gallery?.celeb?.id);
      expect(restored.articleImage?.length, original.articleImage?.length);
      expect(
          restored.articleImage?[0].id, original.articleImage?[0].id);
      expect(restored.comment?.commentId, original.comment?.commentId);
      expect(restored.mostLikedComment?.commentId,
          original.mostLikedComment?.commentId);
    });
  });
}
