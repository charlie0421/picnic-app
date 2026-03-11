import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';

void main() {
  group('GalleryModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'title_ko': '갤러리 제목',
        'title_en': 'Gallery Title',
        'cover': 'cover.jpg',
        'celeb': null,
      };
      final gallery = GalleryModel.fromJson(json);
      expect(gallery.id, equals(1));
      expect(gallery.titleKo, equals('갤러리 제목'));
      expect(gallery.titleEn, equals('Gallery Title'));
      expect(gallery.cover, equals('cover.jpg'));
      expect(gallery.celeb, isNull);

      final output = gallery.toJson();
      expect(output['id'], equals(1));
      expect(output['title_ko'], equals('갤러리 제목'));
    });

    test('cover null', () {
      final json = {
        'id': 2,
        'title_ko': '제목',
        'title_en': 'Title',
        'cover': null,
        'celeb': null,
      };
      final gallery = GalleryModel.fromJson(json);
      expect(gallery.cover, isNull);
    });

    test('celeb 있는 갤러리', () {
      final json = {
        'id': 3,
        'title_ko': '셀럽 갤러리',
        'title_en': 'Celeb Gallery',
        'cover': null,
        'celeb': {
          'id': 1,
          'name_ko': '셀럽',
          'name_en': 'Celeb',
          'thumbnail': 'thumb.jpg',
          'users': null,
        },
      };
      final gallery = GalleryModel.fromJson(json);
      expect(gallery.celeb, isNotNull);
      expect(gallery.celeb!.nameKo, equals('셀럽'));
    });
  });

  group('GalleryModel getCdnUrl', () {
    test('CDN URL 생성', () {
      final gallery = GalleryModel.fromJson({
        'id': 42,
        'title_ko': '제목',
        'title_en': 'Title',
        'cover': null,
        'celeb': null,
      });
      expect(
        gallery.getCdnUrl('photo.jpg'),
        equals('https://cdn-dev.picnic.fan/gallery/42/photo.jpg'),
      );
    });
  });
}
