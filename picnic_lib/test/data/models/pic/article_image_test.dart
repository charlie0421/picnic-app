import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';

void main() {
  group('ArticleImageModel', () {
    test('creates from constructor', () {
      const model = ArticleImageModel(
        id: 1,
        titleKo: '테스트 이미지',
        titleEn: 'Test Image',
        articleImageUser: null,
      );
      expect(model.id, 1);
      expect(model.titleKo, '테스트 이미지');
      expect(model.titleEn, 'Test Image');
      expect(model.image, isNull);
      expect(model.articleImageUser, isNull);
    });

    test('creates with optional image', () {
      const model = ArticleImageModel(
        id: 2,
        titleKo: '사진',
        titleEn: 'Photo',
        image: 'https://example.com/photo.jpg',
        articleImageUser: null,
      );
      expect(model.image, 'https://example.com/photo.jpg');
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'title_ko': '테스트',
        'title_en': 'Test',
        'image': 'img.jpg',
        'article_image_user': null,
      };
      final model = ArticleImageModel.fromJson(json);
      expect(model.id, 1);
      expect(model.titleKo, '테스트');
      expect(model.image, 'img.jpg');
    });

    test('toJson serializes correctly', () {
      const model = ArticleImageModel(
        id: 1,
        titleKo: '제목',
        titleEn: 'Title',
        articleImageUser: null,
      );
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['title_ko'], '제목');
      expect(json['title_en'], 'Title');
    });

    test('copyWith updates fields', () {
      const model = ArticleImageModel(
        id: 1,
        titleKo: '원래',
        titleEn: 'Original',
        articleImageUser: null,
      );
      final updated = model.copyWith(titleKo: '새제목', image: 'new.jpg');
      expect(updated.titleKo, '새제목');
      expect(updated.image, 'new.jpg');
      expect(updated.id, 1);
    });

    test('equality works', () {
      const a = ArticleImageModel(
        id: 1,
        titleKo: '제목',
        titleEn: 'Title',
        articleImageUser: null,
      );
      const b = ArticleImageModel(
        id: 1,
        titleKo: '제목',
        titleEn: 'Title',
        articleImageUser: null,
      );
      expect(a, equals(b));
    });
  });
}
