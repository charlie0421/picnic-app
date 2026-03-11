import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';

void main() {
  group('GalleryModel', () {
    test('필수 필드로 생성', () {
      const gallery = GalleryModel(
        id: 1,
        titleKo: '갤러리 제목',
        titleEn: 'Gallery Title',
        celeb: null,
      );
      expect(gallery.id, equals(1));
      expect(gallery.titleKo, equals('갤러리 제목'));
      expect(gallery.titleEn, equals('Gallery Title'));
      expect(gallery.cover, isNull);
      expect(gallery.celeb, isNull);
    });

    test('cover 포함 생성', () {
      const gallery = GalleryModel(
        id: 5,
        titleKo: '커버 갤러리',
        titleEn: 'Cover Gallery',
        cover: 'cover.jpg',
        celeb: null,
      );
      expect(gallery.cover, equals('cover.jpg'));
    });

    test('getCdnUrl 올바른 URL 생성', () {
      const gallery = GalleryModel(
        id: 42,
        titleKo: '테스트',
        titleEn: 'Test',
        celeb: null,
      );
      expect(
        gallery.getCdnUrl('image.jpg'),
        equals('https://cdn-dev.picnic.fan/gallery/42/image.jpg'),
      );
    });

    test('getCdnUrl 다른 ID', () {
      const gallery = GalleryModel(
        id: 100,
        titleKo: '테스트',
        titleEn: 'Test',
        celeb: null,
      );
      expect(
        gallery.getCdnUrl('photo.png'),
        equals('https://cdn-dev.picnic.fan/gallery/100/photo.png'),
      );
    });

    test('getCdnUrl 경로 포함 파일명', () {
      const gallery = GalleryModel(
        id: 7,
        titleKo: '테스트',
        titleEn: 'Test',
        celeb: null,
      );
      expect(
        gallery.getCdnUrl('subdir/file.webp'),
        equals('https://cdn-dev.picnic.fan/gallery/7/subdir/file.webp'),
      );
    });
  });
}
