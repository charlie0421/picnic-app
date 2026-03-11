import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';

void main() {
  group('ArticleImageModel', () {
    test('필수 필드로 생성', () {
      const model = ArticleImageModel(
        id: 1,
        titleKo: '이미지 제목',
        titleEn: 'Image Title',
        articleImageUser: null,
      );
      expect(model.id, equals(1));
      expect(model.titleKo, equals('이미지 제목'));
      expect(model.titleEn, equals('Image Title'));
      expect(model.image, isNull);
      expect(model.articleImageUser, isNull);
    });

    test('image 포함 생성', () {
      const model = ArticleImageModel(
        id: 10,
        titleKo: '사진',
        titleEn: 'Photo',
        image: 'https://example.com/photo.jpg',
        articleImageUser: null,
      );
      expect(model.image, equals('https://example.com/photo.jpg'));
    });

    test('빈 유저 리스트', () {
      const model = ArticleImageModel(
        id: 20,
        titleKo: '테스트',
        titleEn: 'Test',
        articleImageUser: [],
      );
      expect(model.articleImageUser, isNotNull);
      expect(model.articleImageUser!.length, equals(0));
    });
  });
}
