import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';
import 'package:picnic_lib/data/models/pic/library.dart';

void main() {
  group('LibraryModel', () {
    test('필수 필드로 생성', () {
      const model = LibraryModel(
        id: 1,
        title: '라이브러리',
        images: null,
      );
      expect(model.id, equals(1));
      expect(model.title, equals('라이브러리'));
      expect(model.images, isNull);
    });

    test('이미지 리스트 포함', () {
      const model = LibraryModel(
        id: 2,
        title: 'My Library',
        images: [
          ArticleImageModel(
            id: 100,
            titleKo: '사진1',
            titleEn: 'Photo1',
            articleImageUser: null,
          ),
          ArticleImageModel(
            id: 101,
            titleKo: '사진2',
            titleEn: 'Photo2',
            image: 'img.jpg',
            articleImageUser: null,
          ),
        ],
      );
      expect(model.images!.length, equals(2));
      expect(model.images![0].id, equals(100));
      expect(model.images![1].image, equals('img.jpg'));
    });

    test('빈 이미지 리스트', () {
      const model = LibraryModel(
        id: 3,
        title: 'Empty',
        images: [],
      );
      expect(model.images, isNotNull);
      expect(model.images, isEmpty);
    });
  });
}
