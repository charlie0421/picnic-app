import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';

void main() {
  group('BannerModel', () {
    test('creates from constructor', () {
      const model = BannerModel(
        id: 1,
        title: {'ko': '배너 제목', 'en': 'Banner Title'},
        thumbnail: 'https://example.com/thumb.jpg',
        image: {'ko': 'https://example.com/ko.jpg'},
        duration: 5000,
        link: 'https://example.com',
      );
      expect(model.id, 1);
      expect(model.title['ko'], '배너 제목');
      expect(model.thumbnail, 'https://example.com/thumb.jpg');
      expect(model.duration, 5000);
      expect(model.link, 'https://example.com');
    });

    test('creates with null link', () {
      const model = BannerModel(
        id: 2,
        title: {'ko': '제목'},
        thumbnail: 'thumb.jpg',
        image: {'ko': 'image.jpg'},
        duration: 3000,
        link: null,
      );
      expect(model.link, isNull);
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'title': {'ko': '테스트'},
        'thumbnail': 'thumb.jpg',
        'image': {'ko': 'img.jpg'},
        'duration': 4000,
        'link': 'https://test.com',
      };
      final model = BannerModel.fromJson(json);
      expect(model.id, 1);
      expect(model.duration, 4000);
    });

    test('toJson serializes correctly', () {
      const model = BannerModel(
        id: 1,
        title: {'ko': '제목'},
        thumbnail: 'thumb.jpg',
        image: {'ko': 'img.jpg'},
        duration: 3000,
        link: null,
      );
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['title'], {'ko': '제목'});
      expect(json['duration'], 3000);
    });

    test('copyWith updates fields', () {
      const model = BannerModel(
        id: 1,
        title: {'ko': '원래'},
        thumbnail: 'thumb.jpg',
        image: {'ko': 'img.jpg'},
        duration: 3000,
        link: null,
      );
      final updated = model.copyWith(duration: 5000, link: 'https://new.com');
      expect(updated.duration, 5000);
      expect(updated.link, 'https://new.com');
      expect(updated.id, 1);
    });

    test('equality works', () {
      const a = BannerModel(
        id: 1,
        title: {'ko': '제목'},
        thumbnail: 'thumb.jpg',
        image: {'ko': 'img.jpg'},
        duration: 3000,
        link: null,
      );
      const b = BannerModel(
        id: 1,
        title: {'ko': '제목'},
        thumbnail: 'thumb.jpg',
        image: {'ko': 'img.jpg'},
        duration: 3000,
        link: null,
      );
      expect(a, equals(b));
    });
  });
}
