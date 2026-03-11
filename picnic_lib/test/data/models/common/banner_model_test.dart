import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';

void main() {
  group('BannerModel', () {
    test('필수 파라미터로 생성', () {
      const banner = BannerModel(
        id: 1,
        title: {'ko': '배너 제목'},
        thumbnail: 'https://example.com/thumb.jpg',
        image: {'ko': 'https://example.com/banner.jpg'},
        duration: 3000,
        link: null,
      );
      expect(banner.id, equals(1));
      expect(banner.title['ko'], equals('배너 제목'));
      expect(banner.thumbnail, isNotEmpty);
      expect(banner.duration, equals(3000));
      expect(banner.link, isNull);
    });

    test('링크 포함 생성', () {
      const banner = BannerModel(
        id: 2,
        title: {'ko': '이벤트'},
        thumbnail: 'thumb.jpg',
        image: {'ko': 'banner.jpg'},
        duration: 5000,
        link: 'https://picnic.app/event/1',
      );
      expect(banner.link, equals('https://picnic.app/event/1'));
      expect(banner.duration, equals(5000));
    });

    test('다국어 제목', () {
      const banner = BannerModel(
        id: 3,
        title: {'ko': '한국어', 'en': 'English', 'ja': '日本語'},
        thumbnail: 'thumb.jpg',
        image: {'ko': 'ko.jpg', 'en': 'en.jpg'},
        duration: 3000,
        link: null,
      );
      expect(banner.title.length, equals(3));
      expect(banner.image.length, equals(2));
    });
  });
}
